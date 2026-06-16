# Open-state DOM oracle (STR-331)

These `<id>.<state>.txt` files are the **normalized DOM of real `@radix-ui/themes`**
interactive components driven into a named state (open, item highlighted, option
selected, …). They are the external, non-circular oracle for the interactive Halogen
port — the open-state analogue of the at-rest sha256 pixel goldens.

`<id>:<state>` ⇒ "drive `?c=<id>` through the state script in
`testing/playwright/scripts/themes-open-dom.mjs`, snapshot the whole `body` (trigger +
every portaled layer), normalize". Normalization cancels the only two run-to-run
noise sources so a structural diff is exact:

- **radix `useId` ids** (`radix-:r3:`, `:r3:`) → `<idN>` in first-seen order, applied
  to the `id` *and* every reference (`aria-controls`/`aria-labelledby`/
  `aria-describedby`/`aria-activedescendant`), so id↔reference linkage still verifies.
- **layout-derived pixels** (Popper `transform: translate(x,y)`, `--radix-*` size vars,
  scroll-lock padding compensation) → `<px>`.

Everything structural stays exact: tag tree, class **set** (order-insensitive),
`data-*`/`aria-*`/`role`, and `data-side`/`data-align`. Positioning is verified
structurally (side/align), never by exact pixels — that exactness trap is what the
hand-rolled Bucket B fell into.

## Regenerate

```
testing/playwright/themes-open-capture.sh
```

Each state is captured **twice** and must be byte-identical after normalization, or the
capture fails rather than commit a non-deterministic baseline (the self-stability proof:
same upstream twice ⇒ identical, or it isn't an oracle).

## Gate the port

```
testing/playwright/themes-open-verify.sh [<id>[:<state>] …]   # default: all
```

Builds `//examples/themes-port:app`, drives the same state script, diffs against these
baselines. Exit 0 ⇒ the port's interacted DOM == upstream's. Every P2/P3 interactive
component must pass this to be "done".
