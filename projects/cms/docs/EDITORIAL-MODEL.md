# Editorial model

## Documents and revisions

A document owns its stable UUID, channel-scoped slug, kind, workflow state, and
revision pointers. Revision rows are append-only. Authors, tags, paper metadata,
and asset references are revision-scoped. Author names and identifiers are
snapshotted on the byline, and finalized asset records are immutable, so an old
public revision remains exactly reproducible while a replacement is edited.

`current_revision` is the newest editorial revision. `published_revision` is
the version public consumers receive. Appending to a published document starts
a new draft without withdrawing the previously published revision.

## Workflow

```text
draft <-> review -> scheduled -> published -> archived
  |          |          |            |
  +----------+----------+------------+-> draft
```

Small teams can publish or schedule directly from a draft; `review` records a
real editorial step without forcing performative process. Every transition uses
an expected revision number. Stale sessions receive a conflict instead of
overwriting newer work.

Archiving withdraws the public pointer without deleting history. Restoring an
archive creates an unpublished draft; it never makes the withdrawn revision
visible as a side effect.

Scheduling validates the revision immediately but does not pretend to be a
clock. A worker will call the same publish transition when due. Until that
worker exists, scheduled documents remain intentionally pending.

## Publication readiness

Draft authoring is permissive. Publication and scheduling require:

- a non-empty title, summary, and body;
- at least one author;
- paper metadata and an SPDX license for papers.

The database exposes defects as structured codes, and the readiness endpoint
uses exactly the same function that blocks a transition. The studio can show
why a document is not publishable before an editor presses publish.

## Vocabulary ownership

Workflow state, source format, document kind, author role, asset kind, and asset
purpose are closed structural vocabularies represented by PostgreSQL enums.
Tags, channels, people, and descriptive metadata remain editable records.
