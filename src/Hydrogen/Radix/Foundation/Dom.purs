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
  ) where

import Data.Unit (Unit)
import Effect (Effect)
import Web.HTML.HTMLElement (HTMLElement)

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
