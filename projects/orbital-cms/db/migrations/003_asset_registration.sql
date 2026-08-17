begin;

create function cms.asset_json(p_asset_id uuid)
returns jsonb
language sql
stable
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'id', a.id,
    'kind', a.kind,
    'media_type', a.media_type,
    'object_key', a.object_key,
    'external_url', a.external_url,
    'byte_size', a.byte_size,
    'sha256', a.sha256,
    'alt_text', a.alt_text,
    'caption', a.caption,
    'credit', a.credit,
    'license_spdx', a.license_spdx,
    'created_at', a.created_at
  ))
  from cms.assets a
  where a.id = p_asset_id;
$$;

create function cms.register_asset(p_actor text, p_payload jsonb)
returns jsonb
language plpgsql
as $$
declare
  v_asset_id uuid;
  v_existing cms.assets%rowtype;
begin
  insert into cms.assets (
    kind, object_key, external_url, media_type, byte_size, sha256,
    alt_text, caption, credit, license_spdx, created_by
  ) values (
    (p_payload->>'kind')::cms.asset_kind,
    nullif(p_payload->>'object_key', ''),
    nullif(p_payload->>'external_url', ''),
    p_payload->>'media_type',
    nullif(p_payload->>'byte_size', '')::bigint,
    nullif(p_payload->>'sha256', ''),
    nullif(p_payload->>'alt_text', ''),
    nullif(p_payload->>'caption', ''),
    nullif(p_payload->>'credit', ''),
    nullif(p_payload->>'license_spdx', ''),
    p_actor
  )
  on conflict (object_key) do nothing
  returning id into v_asset_id;

  if v_asset_id is null then
    select * into v_existing
    from cms.assets
    where object_key = nullif(p_payload->>'object_key', '');

    if not found then
      raise exception using errcode = 'P0001', message = 'asset_conflict';
    end if;

    if v_existing.kind::text <> p_payload->>'kind'
      or v_existing.media_type <> p_payload->>'media_type'
      or v_existing.sha256 is distinct from nullif(p_payload->>'sha256', '')
      or v_existing.byte_size is distinct from nullif(p_payload->>'byte_size', '')::bigint
      or v_existing.external_url is distinct from nullif(p_payload->>'external_url', '')
    then
      raise exception using errcode = 'P0001', message = 'asset_conflict';
    end if;

    v_asset_id := v_existing.id;
  end if;

  return cms.asset_json(v_asset_id);
end;
$$;

create function cms.attach_paper_pdf()
returns trigger
language plpgsql
as $$
begin
  if new.pdf_asset_id is not null then
    insert into cms.revision_assets (document_id, revision, asset_id, purpose, position)
    values (new.document_id, new.revision, new.pdf_asset_id, 'pdf', 0)
    on conflict do nothing;
  end if;
  return new;
end;
$$;

create trigger paper_pdf_is_revision_asset
after insert on cms.paper_metadata
for each row execute function cms.attach_paper_pdf();

insert into cms.schema_migrations(version) values (3);

commit;
