# Forgejo parity gate

Orbital Forge is gated against the Forgejo product and API exposed by
`git.s4.gl`. “Equal” means a Straylight contributor can complete the same
repository workflow in Orbital Forge without dropping into another forge UI.
GitHub-specific concepts are explicitly out of scope.

## Milestone 1 — public read surface

- [x] Organization repository index and repository metadata
- [x] Conventional directory and blob URLs with path breadcrumbs
- [x] Branch and tag ref selection
- [x] Clone URLs and source archive links
- [x] Native syntax-highlighted source with raw and download actions
- [x] Locally rendered repository READMEs
- [x] Commit history and path-local latest commit
- [x] Issue, pull request, and release indexes with empty/error/loading states
- [x] Responsive keyboard-accessible application chrome
- [ ] Pagination and stable deep-link browser tests for every index
- [ ] Full Markdown inline syntax, tables, task lists, and relative asset links

## Milestone 2 — complete read surface

- [ ] Branch and tag index/detail pages
- [ ] Commit detail, changed-file diff, patch, and signature status
- [ ] File history, blame, permalinks, and line-range links
- [ ] Repository code search
- [ ] Issue detail, comments, labels, milestones, and attachments
- [ ] Pull request conversation, commits, changed files, reviews, and checks
- [ ] Release assets, signatures, source archives, and downloads
- [ ] Activity, contributors, watchers, stars, forks, licenses, and language data
- [ ] Wiki, packages, actions, projects, and repository-specific feature gates

## Milestone 3 — contributor surface

- [ ] Forgejo session/auth boundary with permission-aware navigation
- [ ] Create and edit issues, comments, labels, milestones, and assignments
- [ ] Create, review, approve, merge, and close pull requests
- [ ] Web source editing, commits, branches, tags, and releases
- [ ] Watch, star, fork, follow, notifications, and dashboard activity
- [ ] Organization/team views and repository administration allowed by role
- [ ] CSRF, credential, private-repository, audit, and destructive-action tests

## Graduation rule

Preview deployments may ship incomplete milestones. The product loses the
preview label only when all applicable items above are exercised against the
running Forgejo version, accessibility checks pass at desktop and handset
widths, and no workflow requires the stock Forgejo UI except administration
that Orbital intentionally declares out of scope.
