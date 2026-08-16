-- | Hydrogen.Radix.Behavior.ControllableState — the controlled/uncontrolled
-- | value pattern (radix `useControllableState`), as a pure helper.
-- |
-- | Every stateful primitive supports BOTH modes from one code path:
-- |   * controlled   — the parent owns the value (`controlled = Just v`); the
-- |                    component never mutates it, it only reports desired changes.
-- |   * uncontrolled — the component owns the value (`controlled = Nothing`),
-- |                    advancing its own `uncontrolled` slot and reporting changes.
-- |
-- | The component keeps a `Controllable a` in its state. `controlled` is refreshed
-- | from input on every Halogen `receive`; `uncontrolled` is the internal value.
-- | `current` is what you render. On a change request, `change` returns the next
-- | `Controllable` (uncontrolled slot advanced only in uncontrolled mode) and the
-- | value to emit to the parent (always — controlled parents need the signal).
-- |
-- | This is THE idiom for Toggle, Switch, Checkbox, Tabs, Accordion, Dialog,
-- | Popover, Select, … — anything with a value/open state.
module Hydrogen.Radix.Behavior.ControllableState
  ( Controllable
  , controllable
  , current
  , isControlled
  , Resolution
  , change
  , sync
  ) where

import Data.Maybe (Maybe, fromMaybe, isJust)

-- | A value that may be controlled by the parent.
-- |  * `controlled`   — `Just v` when the parent drives the value; `Nothing` when
-- |                     the component is uncontrolled.
-- |  * `uncontrolled` — the component's own value, used only when uncontrolled.
type Controllable a =
  { controlled :: Maybe a
  , uncontrolled :: a
  }

-- | Construct from input: the controlled prop (often `Maybe a`) and the default.
controllable :: forall a. Maybe a -> a -> Controllable a
controllable controlled defaultValue =
  { controlled, uncontrolled: defaultValue }

-- | The effective value right now — the controlled value if present.
current :: forall a. Controllable a -> a
current c = fromMaybe c.uncontrolled c.controlled

-- | Whether the parent is driving the value.
isControlled :: forall a. Controllable a -> Boolean
isControlled c = isJust c.controlled

-- | Result of a requested change to `v`.
-- |  * `next` — the new `Controllable`: in controlled mode the `uncontrolled`
-- |             slot is left untouched (the parent owns the value); in
-- |             uncontrolled mode it advances to `v`.
-- |  * `emit` — always `v`: the parent is notified of the desired value either
-- |             way (a controlled parent updates its prop in response).
type Resolution a =
  { next :: Controllable a
  , emit :: a
  }

-- | Request that the value become `v`.
change :: forall a. a -> Controllable a -> Resolution a
change v c =
  { next: if isControlled c then c else c { uncontrolled = v }
  , emit: v
  }

-- | Refresh the controlled slot from fresh input (call from Halogen `receive`).
sync :: forall a. Maybe a -> Controllable a -> Controllable a
sync controlled c = c { controlled = controlled }
