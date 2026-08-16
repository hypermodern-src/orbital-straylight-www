# Project boundaries

This monorepo is a staging shape, not a permanent coupling mechanism.

1. Every directory in `projects/` owns its build definition, lockfiles,
   deployment configuration, environment contract, and checks.
2. A project must build from its own directory. Root orchestration may dispatch
   a build, but a production build must not require root-only runtime files.
3. Projects do not import files from sibling directories. Reusable code is
   exposed as a declared package, Buck2 cell, or pinned source dependency.
4. Vercel project configuration names one project root and an app-local output.
5. Secrets stay in the deployment provider. Only `.env.example` contracts are
   committed.
6. A project is extracted with a path filter, then has its original prefix
   removed. Imported histories are retained so that operation remains possible.

Example extraction after installing `git-filter-repo`:

```console
git filter-repo \
  --path projects/reinit-dx/ \
  --path-rename projects/reinit-dx/:
```

Do not add a direct sibling dependency for convenience. If a boundary is not
stable enough for a package, keep the implementation local until it is.

`projects/orbital-cms` demonstrates a released internal dependency: its flake locks the
forge-hosted `projects/web-middleware` subdirectory to an exact Git revision.
That preserves independent builds and makes a later repository split a URL
change rather than a source-tree surgery.
