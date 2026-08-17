begin;

do $$
declare
  v_draft jsonb;
  v_published jsonb;
  v_id uuid;
  v_defects integer;
  v_failed boolean := false;
begin
  v_draft := cms.create_document(
    'orbital',
    'paper',
    'native-inference',
    'schema-test',
    '{
      "title": "",
      "summary": "",
      "body": "",
      "source_format": "markdown",
      "language": "en",
      "authors": [],
      "tags": []
    }'::jsonb
  );
  v_id := (v_draft->>'id')::uuid;

  select count(*) into v_defects from cms.publication_defects(v_id, 1);
  if v_defects <> 5 then
    raise exception 'expected five paper defects, got %', v_defects;
  end if;

  begin
    perform cms.transition_document(v_id, 1, 'published', 'schema-test');
  exception when sqlstate 'P0001' then
    v_failed := sqlerrm = 'publication_incomplete';
  end;
  if not v_failed then
    raise exception 'incomplete publication was not rejected';
  end if;

  perform cms.append_revision(
    v_id,
    1,
    'schema-test',
    '{
      "title": "Native inference",
      "summary": "A fast systems paper.",
      "body": "# Native inference",
      "source_format": "markdown",
      "language": "en",
      "authors": [{
        "slug": "orbital-research",
        "display_name": "Orbital Research",
        "position": 0,
        "role": "author",
        "affiliation": "Orbital"
      }],
      "tags": ["inference", "systems"],
      "paper": {
        "version_label": "preprint",
        "license_spdx": "CC-BY-4.0",
        "references_csl": []
      }
    }'::jsonb
  );

  if exists (select 1 from cms.publication_defects(v_id, 2)) then
    raise exception 'complete paper still has publication defects';
  end if;

  v_published := cms.transition_document(v_id, 2, 'published', 'schema-test', null, '2026-01-08T12:00:00Z');
  if v_published->>'published_revision' <> '2' then
    raise exception 'published revision was not recorded';
  end if;

  if v_published->>'published_at' <> '2026-01-08T12:00:00+00:00' then
    raise exception 'historical publication date was not recorded: %', v_published->>'published_at';
  end if;

  if not exists (
    select 1 from cms.documents
    where id = v_id and published_revision = 2 and state = 'published'
  ) then
    raise exception 'document did not enter published state';
  end if;

  perform cms.append_revision(
    v_id,
    2,
    'schema-test',
    '{
      "title": "Native inference, revised",
      "summary": "A faster systems paper.",
      "body": "# Native inference, revised",
      "source_format": "markdown",
      "language": "en",
      "authors": [{
        "slug": "orbital-research",
        "display_name": "Orbital Research Team",
        "position": 0,
        "role": "author"
      }],
      "tags": ["inference"],
      "paper": {"license_spdx": "CC-BY-4.0", "references_csl": []}
    }'::jsonb
  );

  if not exists (
    select 1 from cms.documents
    where id = v_id and state = 'draft' and current_revision = 3 and published_revision = 2
  ) then
    raise exception 'new draft did not preserve the public revision';
  end if;

  if cms.document_json(v_id, 2, false)->>'title' <> 'Native inference' then
    raise exception 'published revision changed under a new draft';
  end if;

  if cms.document_json(v_id, 2, false)->'authors'->0->>'display_name' <> 'Orbital Research' then
    raise exception 'published author snapshot changed under a new revision';
  end if;

  v_failed := false;
  begin
    update cms.document_revisions set title = 'mutated' where document_id = v_id and revision = 2;
  exception when sqlstate 'P0001' then
    v_failed := sqlerrm = 'immutable_record';
  end;
  if not v_failed then
    raise exception 'revision immutability trigger did not fire';
  end if;

  v_failed := false;
  begin
    perform cms.append_revision(v_id, 2, 'stale-editor', '{}'::jsonb);
  exception when sqlstate 'P0001' then
    v_failed := sqlerrm = 'revision_conflict';
  end;
  if not v_failed then
    raise exception 'stale editor did not receive a revision conflict';
  end if;

  perform cms.transition_document(v_id, 3, 'published', 'schema-test');
  perform cms.transition_document(v_id, 3, 'archived', 'schema-test');
  perform cms.transition_document(v_id, 3, 'draft', 'schema-test');
  if exists (select 1 from cms.documents where id = v_id and published_revision is not null) then
    raise exception 'restoring an archive silently restored public visibility';
  end if;
end;
$$;

rollback;
