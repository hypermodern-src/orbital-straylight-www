begin;

create extension if not exists pgcrypto;
create schema cms;

create table cms.schema_migrations (
  version integer primary key,
  applied_at timestamptz not null default clock_timestamp()
);

create type cms.document_kind as enum ('post', 'paper');
create type cms.document_state as enum ('draft', 'review', 'scheduled', 'published', 'archived');
create type cms.source_format as enum ('markdown', 'typst', 'latex');
create type cms.author_role as enum ('author', 'editor', 'translator', 'contributor');
create type cms.asset_kind as enum ('image', 'video', 'audio', 'pdf', 'source', 'dataset', 'archive');
create type cms.asset_purpose as enum ('hero', 'inline', 'attachment', 'source', 'pdf', 'dataset');

create table cms.channels (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null check (btrim(name) <> ''),
  base_url text,
  created_at timestamptz not null default clock_timestamp()
);

create table cms.people (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  display_name text not null check (btrim(display_name) <> ''),
  orcid text check (orcid is null or orcid ~ '^0000-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$'),
  bio text,
  url text,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp()
);

create table cms.assets (
  id uuid primary key default gen_random_uuid(),
  kind cms.asset_kind not null,
  object_key text unique,
  external_url text,
  media_type text not null check (media_type ~ '^[a-z0-9.+-]+/[a-zA-Z0-9.+-]+$'),
  byte_size bigint check (byte_size is null or byte_size >= 0),
  sha256 text check (sha256 is null or sha256 ~ '^[0-9a-f]{64}$'),
  alt_text text,
  caption text,
  credit text,
  license_spdx text,
  created_by text not null check (btrim(created_by) <> ''),
  created_at timestamptz not null default clock_timestamp(),
  check (object_key is not null or external_url is not null),
  check (external_url is null or (credit is not null and btrim(credit) <> ''))
);

create table cms.documents (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references cms.channels(id),
  kind cms.document_kind not null,
  slug text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  state cms.document_state not null default 'draft',
  current_revision integer not null default 0 check (current_revision >= 0),
  published_revision integer,
  scheduled_for timestamptz,
  first_published_at timestamptz,
  last_published_at timestamptz,
  created_by text not null check (btrim(created_by) <> ''),
  updated_by text not null check (btrim(updated_by) <> ''),
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp(),
  unique (channel_id, slug),
  check (published_revision is null or published_revision > 0),
  check ((state = 'scheduled') = (scheduled_for is not null))
);

create table cms.document_revisions (
  document_id uuid not null references cms.documents(id),
  revision integer not null check (revision > 0),
  title text not null,
  subtitle text,
  summary text not null,
  body text not null,
  source_format cms.source_format not null,
  language text not null default 'en' check (language ~ '^[a-z]{2,3}(-[A-Za-z0-9]+)*$'),
  content_sha256 text not null check (content_sha256 ~ '^[0-9a-f]{64}$'),
  created_by text not null check (btrim(created_by) <> ''),
  created_at timestamptz not null default clock_timestamp(),
  primary key (document_id, revision)
);

alter table cms.documents
  add constraint documents_published_revision_fk
  foreign key (id, published_revision)
  references cms.document_revisions(document_id, revision)
  deferrable initially deferred;

create table cms.document_authors (
  document_id uuid not null,
  revision integer not null,
  person_id uuid not null references cms.people(id),
  position integer not null check (position >= 0),
  role cms.author_role not null default 'author',
  display_name text not null check (btrim(display_name) <> ''),
  orcid text check (orcid is null or orcid ~ '^0000-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$'),
  affiliation text,
  primary key (document_id, revision, position),
  unique (document_id, revision, person_id, role),
  foreign key (document_id, revision)
    references cms.document_revisions(document_id, revision)
);

create table cms.tags (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  label text not null check (btrim(label) <> ''),
  created_at timestamptz not null default clock_timestamp()
);

create table cms.document_tags (
  document_id uuid not null,
  revision integer not null,
  tag_id uuid not null references cms.tags(id),
  primary key (document_id, revision, tag_id),
  foreign key (document_id, revision)
    references cms.document_revisions(document_id, revision)
);

create table cms.paper_metadata (
  document_id uuid not null,
  revision integer not null,
  doi text,
  arxiv_id text,
  venue text,
  version_label text,
  license_spdx text,
  bibliography_bibtex text,
  references_csl jsonb not null default '[]'::jsonb check (jsonb_typeof(references_csl) = 'array'),
  pdf_asset_id uuid references cms.assets(id),
  primary key (document_id, revision),
  foreign key (document_id, revision)
    references cms.document_revisions(document_id, revision)
);

create table cms.revision_assets (
  document_id uuid not null,
  revision integer not null,
  asset_id uuid not null references cms.assets(id),
  purpose cms.asset_purpose not null,
  position integer not null default 0 check (position >= 0),
  primary key (document_id, revision, purpose, position),
  unique (document_id, revision, asset_id, purpose),
  foreign key (document_id, revision)
    references cms.document_revisions(document_id, revision)
);

create table cms.publication_events (
  id bigint generated always as identity primary key,
  document_id uuid not null references cms.documents(id),
  revision integer not null,
  from_state cms.document_state,
  to_state cms.document_state not null,
  actor text not null check (btrim(actor) <> ''),
  note text,
  happened_at timestamptz not null default clock_timestamp(),
  foreign key (document_id, revision)
    references cms.document_revisions(document_id, revision)
);

create index documents_public_idx
  on cms.documents (channel_id, last_published_at desc)
  where published_revision is not null and state <> 'archived';
create index documents_kind_idx on cms.documents (kind, updated_at desc);
create index events_document_idx on cms.publication_events (document_id, happened_at desc);

create function cms.reject_immutable_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception using errcode = 'P0001', message = 'immutable_record';
end;
$$;

create trigger document_revisions_are_immutable
before update or delete on cms.document_revisions
for each row execute function cms.reject_immutable_mutation();

create trigger assets_are_immutable
before update or delete on cms.assets
for each row execute function cms.reject_immutable_mutation();

create trigger document_authors_are_immutable
before update or delete on cms.document_authors
for each row execute function cms.reject_immutable_mutation();

create trigger document_tags_are_immutable
before update or delete on cms.document_tags
for each row execute function cms.reject_immutable_mutation();

create trigger paper_metadata_is_immutable
before update or delete on cms.paper_metadata
for each row execute function cms.reject_immutable_mutation();

create trigger revision_assets_are_immutable
before update or delete on cms.revision_assets
for each row execute function cms.reject_immutable_mutation();

create trigger publication_events_are_immutable
before update or delete on cms.publication_events
for each row execute function cms.reject_immutable_mutation();

create function cms.publication_defects(p_document_id uuid, p_revision integer)
returns table (code text, message text)
language sql
stable
as $$
  select 'missing_title', 'title is required'
  from cms.document_revisions r
  where r.document_id = p_document_id and r.revision = p_revision and btrim(r.title) = ''
  union all
  select 'missing_summary', 'summary or abstract is required'
  from cms.document_revisions r
  where r.document_id = p_document_id and r.revision = p_revision and btrim(r.summary) = ''
  union all
  select 'missing_body', 'body is required'
  from cms.document_revisions r
  where r.document_id = p_document_id and r.revision = p_revision and btrim(r.body) = ''
  union all
  select 'missing_author', 'at least one author is required'
  where not exists (
    select 1 from cms.document_authors a
    where a.document_id = p_document_id and a.revision = p_revision
  )
  union all
  select 'missing_paper_metadata', 'paper metadata is required'
  from cms.documents d
  where d.id = p_document_id and d.kind = 'paper'
    and not exists (
      select 1 from cms.paper_metadata p
      where p.document_id = p_document_id and p.revision = p_revision
    )
  union all
  select 'missing_paper_license', 'an SPDX paper license is required'
  from cms.documents d
  join cms.paper_metadata p on p.document_id = d.id and p.revision = p_revision
  where d.id = p_document_id and d.kind = 'paper'
    and coalesce(btrim(p.license_spdx), '') = '';
$$;

create function cms.document_json(
  p_document_id uuid,
  p_revision integer,
  p_include_editorial boolean default false
)
returns jsonb
language sql
stable
as $$
  select jsonb_strip_nulls(
    jsonb_build_object(
      'id', d.id,
      'channel', c.slug,
      'kind', d.kind,
      'slug', d.slug,
      'revision', r.revision,
      'title', r.title,
      'subtitle', r.subtitle,
      'summary', r.summary,
      'body', r.body,
      'source_format', r.source_format,
      'language', r.language,
      'content_sha256', r.content_sha256,
      'authors', coalesce((
        select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
          'id', p.id,
          'slug', p.slug,
          'display_name', a.display_name,
          'orcid', a.orcid,
          'role', a.role,
          'position', a.position,
          'affiliation', a.affiliation
        )) order by a.position)
        from cms.document_authors a
        join cms.people p on p.id = a.person_id
        where a.document_id = r.document_id and a.revision = r.revision
      ), '[]'::jsonb),
      'tags', coalesce((
        select jsonb_agg(t.slug order by t.slug)
        from cms.document_tags dt
        join cms.tags t on t.id = dt.tag_id
        where dt.document_id = r.document_id and dt.revision = r.revision
      ), '[]'::jsonb),
      'paper', (
        select jsonb_strip_nulls(jsonb_build_object(
          'doi', pm.doi,
          'arxiv_id', pm.arxiv_id,
          'venue', pm.venue,
          'version_label', pm.version_label,
          'license_spdx', pm.license_spdx,
          'bibliography_bibtex', pm.bibliography_bibtex,
          'references_csl', pm.references_csl,
          'pdf_asset_id', pm.pdf_asset_id
        ))
        from cms.paper_metadata pm
        where pm.document_id = r.document_id and pm.revision = r.revision
      ),
      'assets', coalesce((
        select jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
          'id', a.id,
          'kind', a.kind,
          'purpose', ra.purpose,
          'position', ra.position,
          'media_type', a.media_type,
          'object_key', a.object_key,
          'external_url', a.external_url,
          'byte_size', a.byte_size,
          'sha256', a.sha256,
          'alt_text', a.alt_text,
          'caption', a.caption,
          'credit', a.credit,
          'license_spdx', a.license_spdx
        )) order by ra.purpose, ra.position)
        from cms.revision_assets ra
        join cms.assets a on a.id = ra.asset_id
        where ra.document_id = r.document_id and ra.revision = r.revision
      ), '[]'::jsonb),
      'published_at', case when r.revision = d.published_revision then d.last_published_at end,
      'revision_created_at', r.created_at
    ) || case when p_include_editorial then jsonb_build_object(
      'workflow_state', d.state,
      'current_revision', d.current_revision,
      'published_revision', d.published_revision,
      'scheduled_for', d.scheduled_for,
      'created_at', d.created_at,
      'updated_at', d.updated_at
    ) else '{}'::jsonb end
  )
  from cms.documents d
  join cms.channels c on c.id = d.channel_id
  join cms.document_revisions r on r.document_id = d.id and r.revision = p_revision
  where d.id = p_document_id;
$$;

create function cms.insert_revision(
  p_document_id uuid,
  p_revision integer,
  p_actor text,
  p_payload jsonb
)
returns void
language plpgsql
as $$
declare
  v_author jsonb;
  v_author_id uuid;
  v_tag text;
  v_tag_id uuid;
  v_kind cms.document_kind;
  v_format cms.source_format;
  v_paper jsonb;
begin
  select kind into strict v_kind from cms.documents where id = p_document_id;
  v_format := coalesce(p_payload->>'source_format', 'markdown')::cms.source_format;

  if v_kind = 'post' and v_format <> 'markdown' then
    raise exception using errcode = 'P0001', message = 'post_source_format';
  end if;

  insert into cms.document_revisions (
    document_id, revision, title, subtitle, summary, body, source_format,
    language, content_sha256, created_by
  ) values (
    p_document_id,
    p_revision,
    coalesce(p_payload->>'title', ''),
    nullif(p_payload->>'subtitle', ''),
    coalesce(p_payload->>'summary', ''),
    coalesce(p_payload->>'body', ''),
    v_format,
    coalesce(nullif(p_payload->>'language', ''), 'en'),
    encode(digest(convert_to(p_payload::text, 'UTF8'), 'sha256'), 'hex'),
    p_actor
  );

  for v_author in
    select value from jsonb_array_elements(coalesce(p_payload->'authors', '[]'::jsonb))
  loop
    insert into cms.people (slug, display_name, orcid)
    values (
      v_author->>'slug',
      v_author->>'display_name',
      nullif(v_author->>'orcid', '')
    )
    on conflict (slug) do update set
      display_name = excluded.display_name,
      orcid = coalesce(excluded.orcid, cms.people.orcid),
      updated_at = clock_timestamp()
    returning id into v_author_id;

    insert into cms.document_authors (
      document_id, revision, person_id, position, role, display_name, orcid, affiliation
    ) values (
      p_document_id,
      p_revision,
      v_author_id,
      coalesce((v_author->>'position')::integer, 0),
      coalesce(v_author->>'role', 'author')::cms.author_role,
      v_author->>'display_name',
      nullif(v_author->>'orcid', ''),
      nullif(v_author->>'affiliation', '')
    );
  end loop;

  for v_tag in
    select value #>> '{}' from jsonb_array_elements(coalesce(p_payload->'tags', '[]'::jsonb))
  loop
    insert into cms.tags (slug, label)
    values (v_tag, v_tag)
    on conflict (slug) do update set label = excluded.label
    returning id into v_tag_id;

    insert into cms.document_tags (document_id, revision, tag_id)
    values (p_document_id, p_revision, v_tag_id);
  end loop;

  v_paper := p_payload->'paper';
  if v_paper is not null and jsonb_typeof(v_paper) <> 'null' then
    if v_kind <> 'paper' then
      raise exception using errcode = 'P0001', message = 'paper_metadata_on_post';
    end if;

    insert into cms.paper_metadata (
      document_id, revision, doi, arxiv_id, venue, version_label,
      license_spdx, bibliography_bibtex, references_csl, pdf_asset_id
    ) values (
      p_document_id,
      p_revision,
      nullif(v_paper->>'doi', ''),
      nullif(v_paper->>'arxiv_id', ''),
      nullif(v_paper->>'venue', ''),
      nullif(v_paper->>'version_label', ''),
      nullif(v_paper->>'license_spdx', ''),
      nullif(v_paper->>'bibliography_bibtex', ''),
      coalesce(v_paper->'references_csl', '[]'::jsonb),
      nullif(v_paper->>'pdf_asset_id', '')::uuid
    );
  end if;
end;
$$;

create function cms.create_document(
  p_channel text,
  p_kind cms.document_kind,
  p_slug text,
  p_actor text,
  p_revision_payload jsonb
)
returns jsonb
language plpgsql
as $$
declare
  v_channel_id uuid;
  v_document_id uuid;
begin
  select id into v_channel_id from cms.channels where slug = p_channel;
  if v_channel_id is null then
    raise exception using errcode = 'P0002', message = 'channel_not_found';
  end if;

  insert into cms.documents (channel_id, kind, slug, current_revision, created_by, updated_by)
  values (v_channel_id, p_kind, p_slug, 1, p_actor, p_actor)
  returning id into v_document_id;

  perform cms.insert_revision(v_document_id, 1, p_actor, p_revision_payload);
  insert into cms.publication_events (document_id, revision, from_state, to_state, actor, note)
  values (v_document_id, 1, null, 'draft', p_actor, 'document_created');

  return cms.document_json(v_document_id, 1, true);
end;
$$;

create function cms.append_revision(
  p_document_id uuid,
  p_expected_revision integer,
  p_actor text,
  p_revision_payload jsonb
)
returns jsonb
language plpgsql
as $$
declare
  v_document cms.documents%rowtype;
  v_revision integer;
begin
  select * into v_document from cms.documents where id = p_document_id for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'document_not_found';
  end if;
  if v_document.current_revision <> p_expected_revision then
    raise exception using errcode = 'P0001', message = 'revision_conflict';
  end if;
  if v_document.state = 'archived' then
    raise exception using errcode = 'P0001', message = 'archived_document';
  end if;

  v_revision := v_document.current_revision + 1;
  perform cms.insert_revision(p_document_id, v_revision, p_actor, p_revision_payload);

  if v_document.state <> 'draft' then
    insert into cms.publication_events (document_id, revision, from_state, to_state, actor, note)
    values (p_document_id, v_revision, v_document.state, 'draft', p_actor, 'revision_appended');
  end if;

  update cms.documents set
    current_revision = v_revision,
    state = 'draft',
    scheduled_for = null,
    updated_by = p_actor,
    updated_at = clock_timestamp()
  where id = p_document_id;

  return cms.document_json(p_document_id, v_revision, true);
end;
$$;

create function cms.transition_allowed(
  p_from cms.document_state,
  p_to cms.document_state
)
returns boolean
language sql
immutable
as $$
  select case p_from
    when 'draft' then p_to in ('review', 'scheduled', 'published')
    when 'review' then p_to in ('draft', 'scheduled', 'published')
    when 'scheduled' then p_to in ('draft', 'published')
    when 'published' then p_to in ('draft', 'archived')
    when 'archived' then p_to = 'draft'
  end;
$$;

create function cms.transition_document(
  p_document_id uuid,
  p_expected_revision integer,
  p_target cms.document_state,
  p_actor text,
  p_scheduled_for timestamptz default null
)
returns jsonb
language plpgsql
as $$
declare
  v_document cms.documents%rowtype;
  v_defects jsonb;
  v_now timestamptz := clock_timestamp();
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

  update cms.documents set
    state = p_target,
    scheduled_for = case when p_target = 'scheduled' then p_scheduled_for else null end,
    published_revision = case
      when p_target = 'published' then current_revision
      when v_document.state = 'archived' and p_target = 'draft' then null
      else published_revision
    end,
    first_published_at = case
      when p_target = 'published' then coalesce(first_published_at, v_now)
      else first_published_at
    end,
    last_published_at = case when p_target = 'published' then v_now else last_published_at end,
    updated_by = p_actor,
    updated_at = v_now
  where id = p_document_id;

  insert into cms.publication_events (document_id, revision, from_state, to_state, actor)
  values (p_document_id, p_expected_revision, v_document.state, p_target, p_actor);

  return cms.document_json(p_document_id, p_expected_revision, true);
end;
$$;

insert into cms.channels (slug, name)
values ('orbital', 'Orbital');

insert into cms.schema_migrations (version) values (1);

commit;
