begin;

drop function cms.transition_document(uuid, integer, cms.document_state, text, timestamptz);

create function cms.transition_document(
  p_document_id uuid,
  p_expected_revision integer,
  p_target cms.document_state,
  p_actor text,
  p_scheduled_for timestamptz default null,
  p_published_at timestamptz default null
)
returns jsonb
language plpgsql
as $$
declare
  v_document cms.documents%rowtype;
  v_defects jsonb;
  v_now timestamptz := clock_timestamp();
  v_publish_at timestamptz;
begin
  select * into v_document from cms.documents where id = p_document_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'document_not_found';
  end if;
  if v_document.current_revision <> p_expected_revision then
    raise exception using errcode = 'P0001', message = 'revision_conflict';
  end if;
  if not cms.transition_allowed(v_document.state, p_target) then
    raise exception using errcode = 'P0001', message = 'invalid_transition';
  end if;

  if p_target in ('scheduled', 'published') then
    select coalesce(jsonb_agg(jsonb_build_object('code', code, 'message', message)), '[]'::jsonb)
      into v_defects
      from cms.publication_defects(p_document_id, p_expected_revision);
    if jsonb_array_length(v_defects) > 0 then
      raise exception using
        errcode = 'P0001',
        message = 'publication_incomplete',
        detail = v_defects::text;
    end if;
  end if;

  if p_target = 'scheduled' and (p_scheduled_for is null or p_scheduled_for <= v_now) then
    raise exception using errcode = 'P0001', message = 'invalid_schedule';
  end if;
  if p_target <> 'scheduled' and p_scheduled_for is not null then
    raise exception using errcode = 'P0001', message = 'unexpected_schedule';
  end if;
  if p_target <> 'published' and p_published_at is not null then
    raise exception using errcode = 'P0001', message = 'unexpected_publication_date';
  end if;
  if p_published_at > v_now then
    raise exception using errcode = 'P0001', message = 'invalid_publication_date';
  end if;

  v_publish_at := coalesce(p_published_at, v_now);

  update cms.documents set
    state = p_target,
    scheduled_for = case when p_target = 'scheduled' then p_scheduled_for else null end,
    published_revision = case
      when p_target = 'published' then current_revision
      when v_document.state = 'archived' and p_target = 'draft' then null
      else published_revision
    end,
    first_published_at = case
      when p_target = 'published' then coalesce(first_published_at, v_publish_at)
      else first_published_at
    end,
    last_published_at = case when p_target = 'published' then v_publish_at else last_published_at end,
    updated_by = p_actor,
    updated_at = v_now
  where id = p_document_id;

  insert into cms.publication_events (document_id, revision, from_state, to_state, actor)
  values (p_document_id, p_expected_revision, v_document.state, p_target, p_actor);

  return cms.document_json(p_document_id, p_expected_revision, true);
end;
$$;

insert into cms.schema_migrations (version) values (2);

commit;
