-- | Hydrogen.Radix.Foundation.Dom — the entire foreign-function surface of the radix port.
-- |
-- | There is exactly one `.js` file in this tree, and it lives here. That is a
-- | deliberate, load-bearing constraint: the FFI is the one place the type
-- | checker cannot vouch for us, so it is kept small enough to read in a glance
-- | and audit in a sitting. Everything else in `Hydrogen.Radix.*` — measuring a
-- | rectangle, focusing an element, testing node containment, reading reference
-- | identity, reaching the window's event target — is pure PureScript over the
-- | typed `Web.DOM.*` / `Web.HTML.*` bindings. Before adding a fourth import
-- | here, look there first; it is almost certainly already provided.
-- |
-- | What remains are the three primitives the web bindings genuinely do **not**
-- | expose, each irreducible for a precise reason:
-- |
-- |   * `computedStyle` — the *resolved* value of a CSS property: the cascade,
-- |     inheritance, and any running animation already applied. Only the engine
-- |     knows it; it cannot be reconstructed in user space. Focus management asks
-- |     "is this element actually visible?" and presence asks "is an exit
-- |     animation still running?" — both questions only `getComputedStyle` answers.
-- |
-- |   * `inlineStyle` / `setInlineStyle` — read and write a single property on an
-- |     element's *inline* `style`. `purescript-web-html` surfaces no
-- |     `CSSStyleDeclaration` accessor at all, so positioning (writing `left`/
-- |     `top`) and scroll-locking (saving then overwriting the body's `overflow`)
-- |     have no typed path. They are kept generic — a property *name* and a
-- |     *value* — so the whole port mutates style through one auditable writer.
-- |
-- | Each is total, observing or mutating only the element handed to it, and
-- | side-effecting solely through `Effect`. No element is retained, no listener
-- | installed, no global touched.
module Hydrogen.Radix.Foundation.Dom
  ( computedStyle
  , inlineStyle
  , setInlineStyle
  , queueMicrotask
  , OffsetMetrics
  , offsetMetrics
  , TimeoutId
  , setTimeout
  , clearTimeout
  , now
  , requestSubmit
  ) where

import Data.Unit (Unit)
import Effect (Effect)
import Web.HTML.HTMLElement (HTMLElement)
import Web.HTML.HTMLFormElement (HTMLFormElement)

-- | The resolved value of CSS property `prop` on `el` (`getComputedStyle`) — what
-- | the engine paints after the cascade and any animation, e.g.
-- | `computedStyle el "visibility"` or `computedStyle el "animation-name"`.
-- | Returns `""` for an unknown property, never throws.
foreign import computedStyle :: HTMLElement -> String -> Effect String

-- | The value of `prop` in `el`'s inline `style` (`el.style.getPropertyValue`),
-- | or `""` if unset. Used to remember a value before overwriting it — e.g. the
-- | body's `overflow` before a scroll lock, so it can be restored exactly.
foreign import inlineStyle :: HTMLElement -> String -> Effect String

-- | Set `prop` to `value` in `el`'s inline `style` (`el.style.setProperty`). The
-- | single point of style mutation in the port: positioning and scroll-lock are
-- | both built on it. Passing `""` clears the property.
foreign import setInlineStyle :: HTMLElement -> String -> String -> Effect Unit

-- | Schedule `eff` as a microtask: after the current synchronous work (including Halogen's
-- | render flush) but before the next macrotask. Used to focus a just-opened menu's content
-- | before a keypress can land on the stale focus — a `requestAnimationFrame` runs a frame
-- | too late and the first arrow key is lost.
queueMicrotask :: Effect Unit -> Effect Unit
queueMicrotask = queueMicrotask_

foreign import queueMicrotask_ :: Effect Unit -> Effect Unit

-- | An element's CSS *layout-box* offsets — its `offsetWidth`/`offsetHeight` (border-box
-- | size) and `offsetLeft`/`offsetTop` (position relative to its offsetParent). These are
-- | the values NavigationMenu's Indicator (active trigger offsetWidth/offsetLeft) and
-- | Viewport (active content offsetWidth/offsetHeight) measure to size/place themselves.
type OffsetMetrics = { width :: Number, height :: Number, left :: Number, top :: Number }

-- | Read an element's `offset*` layout metrics in one DOM touch. Distinct from
-- | `getBoundingClientRect` (Float.Popper.measureRect): `offset*` is the integral, layout-box
-- | geometry UNAFFECTED by CSS transforms, which is exactly what NavigationMenu measures —
-- | so the indicator/viewport numbers match upstream's structurally (both then normalize to
-- | `<px>` in the DOM oracle). Observing-only: retains nothing, mutates nothing.
foreign import offsetMetrics :: HTMLElement -> Effect OffsetMetrics

-- | An opaque handle for a scheduled `setTimeout`, passed back to `clearTimeout`
-- | to cancel it before it fires (window.setTimeout's numeric id).
foreign import data TimeoutId :: Type

-- | `window.setTimeout(eff, ms)`: run `eff` after at least `ms` milliseconds, returning a
-- | handle to cancel it. The port's open/close *delay* primitive — a tooltip waits
-- | `delayMs` before opening on hover, and a pending open is cancelled (`clearTimeout`) if
-- | the pointer leaves first. No web-* binding exposes a cancellable timer; `js-timers` is
-- | not in the closure, so this is the one place the port schedules wall-clock work.
foreign import setTimeout :: Int -> Effect Unit -> Effect TimeoutId

-- | `window.clearTimeout(id)`: cancel a timer scheduled by `setTimeout`. A no-op if it has
-- | already fired, so it is always safe to call on a stored handle.
foreign import clearTimeout :: TimeoutId -> Effect Unit

-- | `performance.now()`: a monotonic high-resolution timestamp in milliseconds. Used to
-- | measure elapsed time across a timer pause/resume (Toast pauses its auto-dismiss on hover
-- | and resumes with the REMAINING time) — independent of wall-clock jumps. Not `Date.now`.
foreign import now :: Effect Number

-- | `form.requestSubmit()`: submit `form` as if a submit button were pressed — it fires the
-- | `submit` event (so registered handlers run) and runs constraint validation first. This is
-- | NOT `HTMLFormElement.submit()` (which the bindings DO expose), because that bypasses both
-- | the event and validation. OneTimePasswordField's Enter and autoSubmit paths must trigger
-- | the form's real submit pipeline, and `requestSubmit` is the only call with that semantic.
foreign import requestSubmit :: HTMLFormElement -> Effect Unit
