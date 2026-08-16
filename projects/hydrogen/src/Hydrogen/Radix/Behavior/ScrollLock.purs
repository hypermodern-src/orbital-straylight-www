-- | Hydrogen.Radix.Behavior.ScrollLock — lock and restore body scroll while a
-- | modal surface is open.
-- |
-- | Reference-counted, so nested locks (a dialog opening a popover) compose: the
-- | body's `overflow` is saved on the first lock and restored only when the last
-- | one releases. The counter and the saved value are module-global mutable cells
-- | — the one piece of process-wide state the scroll lock fundamentally needs (the
-- | body is shared) — held in `Ref`s created once at load. No foreign code: the
-- | body is reached through typed `Web.HTML` bindings and its `overflow` read and
-- | written through the blessed `Hydrogen.Radix.Foundation.Dom` accessors.
module Hydrogen.Radix.Behavior.ScrollLock
  ( lock
  , unlock
  ) where

import Prelude

import Data.Foldable (for_)
import Effect (Effect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)
import Hydrogen.Radix.Foundation.Dom (inlineStyle, setInlineStyle)
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement (HTMLElement)
import Web.HTML.Window as Window

-- | How many locks are currently held. Created once at module load (a top-level
-- | `Ref` is the idiomatic module-global cell); shared by every lock/unlock.
lockDepth :: Ref Int
lockDepth = unsafePerformEffect (Ref.new 0)

-- | The body's `overflow` as it was before the first lock, restored at depth 0.
savedOverflow :: Ref String
savedOverflow = unsafePerformEffect (Ref.new "")

withBody :: (HTMLElement -> Effect Unit) -> Effect Unit
withBody f = do
  doc <- HTML.window >>= Window.document
  mbody <- HTMLDocument.body doc
  for_ mbody f

-- | Lock body scroll. Idempotent under nesting — only the outermost lock touches
-- | the DOM (saving the original `overflow`, then forcing `hidden`).
lock :: Effect Unit
lock = do
  n <- Ref.read lockDepth
  Ref.write (n + 1) lockDepth
  when (n == 0) $ withBody \body -> do
    orig <- inlineStyle body "overflow"
    Ref.write orig savedOverflow
    setInlineStyle body "overflow" "hidden"

-- | Release one lock; the innermost release restores the original `overflow`.
unlock :: Effect Unit
unlock = do
  n <- Ref.read lockDepth
  let n' = max 0 (n - 1)
  Ref.write n' lockDepth
  when (n' == 0) $ withBody \body -> do
    orig <- Ref.read savedOverflow
    setInlineStyle body "overflow" orig
