-- | Hydrogen.Radix.Behavior.Id — a generated-id source (radix's `useId`).
-- |
-- | radix mints a unique, stable-per-mount id for each component that needs to wire an
-- | ARIA id-reference (`aria-controls`/`labelledby`/`describedby`/`activedescendant`),
-- | so two instances of the same primitive on one page never collide. The primitives
-- | here previously used fixed module-level id constants — a documented v1 simplification
-- | that broke multi-instance use. This replaces that.
-- |
-- | A primitive mints its id(s) ONCE in its `Initialize` action (which, unlike
-- | `initialState :: Input -> State`, runs in `MonadEffect`) and stores them in State.
-- | The id is available before the user can interact (Initialize runs right after the
-- | first render, before any open). The `radix-<n>` format matches radix-ui's own
-- | non-React id fallback (`radix-${count}`) — and the open-state DOM oracle's normalizer
-- | canonicalizes it, so id values never enter the upstream diff (only the id↔reference
-- | linkage does).
module Hydrogen.Radix.Behavior.Id
  ( useId
  ) where

import Prelude

import Effect.Class (class MonadEffect, liftEffect)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)

-- | Module-global monotonic counter. A top-level CAF, evaluated once at module load —
-- | the standard PureScript idiom for a process-global mutable cell.
counter :: Ref.Ref Int
counter = unsafePerformEffect (Ref.new 0)

-- | Mint a unique, stable-per-mount id (`radix-1`, `radix-2`, …). Call once on
-- | `Initialize` and cache in State; never call it in `render`.
useId :: forall m. MonadEffect m => m String
useId = liftEffect (Ref.modify (_ + 1) counter <#> \n -> "radix-" <> show n)
