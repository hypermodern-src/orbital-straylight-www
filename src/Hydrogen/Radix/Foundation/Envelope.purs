-- | Hydrogen.Radix.Foundation.Envelope — the document-level side effects an open overlay
-- | layers onto `<body>`, mirroring radix's RemoveScroll + FocusGuards + aria hideOthers.
-- | All of it is what the open-state DOM oracle sees around the portaled content:
-- |
-- |   * `lockScroll` — `data-scroll-locked=1` + `pointer-events:none` on the body (radix's
-- |     RemoveScroll; the themes CSS keys scroll-locking off the attribute). Ref-counted.
-- |   * `addFocusGuards` — the two `data-radix-focus-guard` sentinel spans bracketing the
-- |     body (first child + last child). Present whenever ANY overlay is open. Ref-counted.
-- |   * `hideOthers` — aria-hide every body child EXCEPT the given element (the modal's
-- |     portal root): `aria-hidden=true` + `data-aria-hidden=true`. Returns its own undo.
-- |
-- | Pure PureScript over typed `Web.DOM`/`Web.HTML` bindings — no new foreign module (the
-- | Radix tree keeps a single .js, `Foundation/Dom.js`). The body is shared process state,
-- | so the counters live in module-global `Ref`s created once at load.
module Hydrogen.Radix.Foundation.Envelope
  ( lockScroll
  , lockScrollMarker
  , unlockScroll
  , releaseScrollPointer
  , clearPointerEvents
  , addFocusGuards
  , removeFocusGuards
  , reAdoptBeforeTrail
  , hideOthers
  , showOthers
  ) where

import Prelude

import Data.Array (filter)
import Data.Foldable (for_, traverse_)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)
import Hydrogen.Radix.Foundation.Dom (setInlineStyle)
import Unsafe.Reference (unsafeRefEq)
import Web.DOM.Document (Document, createElement)
import Web.DOM.Element (Element, removeAttribute, setAttribute, toNode)
import Web.DOM.Element as Element
import Web.DOM.HTMLCollection (toArray)
import Web.DOM.Node (appendChild, firstChild, insertBefore, removeChild)
import Web.DOM.ParentNode (children)
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement (HTMLElement)
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window

-- ── body access ────────────────────────────────────────────────────────────────
withBody :: (HTMLElement -> Effect Unit) -> Effect Unit
withBody f = do
  doc <- HTML.window >>= Window.document
  mbody <- HTMLDocument.body doc
  for_ mbody f

documentEl :: Effect (Maybe { doc :: Document, body :: HTMLElement })
documentEl = do
  hdoc <- HTML.window >>= Window.document
  mbody <- HTMLDocument.body hdoc
  pure (mbody <#> \body -> { doc: HTMLDocument.toDocument hdoc, body })

-- ── scroll lock (ref-counted) ───────────────────────────────────────────────────
scrollDepth :: Ref Int
scrollDepth = unsafePerformEffect (Ref.new 0)

-- | Lock body scroll the radix way: stamp `data-scroll-locked=1` + `pointer-events:none`.
lockScroll :: Effect Unit
lockScroll = do
  n <- Ref.read scrollDepth
  Ref.write (n + 1) scrollDepth
  when (n == 0) $ withBody \body -> do
    setAttribute "data-scroll-locked" "1" (HTMLElement.toElement body)
    setInlineStyle body "pointer-events" "none"

-- | Stamp ONLY the `data-scroll-locked=1` marker (RemoveScroll's mount marker), WITHOUT the
-- | body `pointer-events:none` (that is DismissableLayer's open-gated block). Used by a CLOSED
-- | force-mounted dialog, whose RemoveScroll is mounted but whose DismissableLayer is inactive.
-- | Ref-counted like `lockScroll` so a later open/close balances correctly.
lockScrollMarker :: Effect Unit
lockScrollMarker = do
  n <- Ref.read scrollDepth
  Ref.write (n + 1) scrollDepth
  when (n == 0) $ withBody \body ->
    setAttribute "data-scroll-locked" "1" (HTMLElement.toElement body)

unlockScroll :: Effect Unit
unlockScroll = do
  n <- Ref.read scrollDepth
  let n' = max 0 (n - 1)
  Ref.write n' scrollDepth
  when (n' == 0) $ withBody \body -> do
    removeAttribute "data-scroll-locked" (HTMLElement.toElement body)
    setInlineStyle body "pointer-events" ""

-- | Release ONLY the `pointer-events:none` the scroll lock put on body, keeping the
-- | `data-scroll-locked` marker. Mirrors radix RemoveScroll disabling on close-start: the
-- | pointer block lifts immediately while the closing overlay lingers for its exit animation
-- | (the marker is dropped later by `unlockScroll` at unmount). Does NOT touch the ref count.
releaseScrollPointer :: Effect Unit
releaseScrollPointer = withBody \body -> setInlineStyle body "pointer-events" ""

-- | Clear the inline `pointer-events` on an element (the closing dialog content drops the
-- | `pointer-events:auto` the open RemoveScroll wrapper set), leaving its other inline style.
clearPointerEvents :: Element -> Effect Unit
clearPointerEvents el = for_ (HTMLElement.fromElement el) \he -> setInlineStyle he "pointer-events" ""

-- ── focus guards (ref-counted) ──────────────────────────────────────────────────
guardDepth :: Ref Int
guardDepth = unsafePerformEffect (Ref.new 0)

guardEls :: Ref (Maybe { lead :: Element, trail :: Element })
guardEls = unsafePerformEffect (Ref.new Nothing)

guardStyle :: String
guardStyle = "outline: none; opacity: 0; position: fixed; pointer-events: none;"

mkGuard :: Document -> Effect Element
mkGuard doc = do
  el <- createElement "span" doc
  setAttribute "data-radix-focus-guard" "" el
  setAttribute "tabindex" "0" el
  setAttribute "style" guardStyle el
  pure el

-- | Add the two focus-guard sentinels bracketing the body (first + last child). Call AFTER
-- | the overlay has been adopted into body, so the trailing guard lands after it.
addFocusGuards :: Effect Unit
addFocusGuards = do
  n <- Ref.read guardDepth
  Ref.write (n + 1) guardDepth
  when (n == 0) $ documentEl >>= traverse_ \{ doc, body } -> do
    let bodyNode = HTMLElement.toNode body
    lead <- mkGuard doc
    trail <- mkGuard doc
    mfirst <- firstChild bodyNode
    case mfirst of
      Just f -> insertBefore (toNode lead) f bodyNode
      Nothing -> appendChild (toNode lead) bodyNode
    appendChild (toNode trail) bodyNode
    Ref.write (Just { lead, trail }) guardEls

removeFocusGuards :: Effect Unit
removeFocusGuards = do
  n <- Ref.read guardDepth
  let n' = max 0 (n - 1)
  Ref.write n' guardDepth
  when (n' == 0) do
    mg <- Ref.read guardEls
    for_ mg \{ lead, trail } -> withBody \body -> do
      let bodyNode = HTMLElement.toNode body
      removeChild (toNode lead) bodyNode
      removeChild (toNode trail) bodyNode
    Ref.write Nothing guardEls

-- | Re-adopt a portaled element into body keeping it BEFORE the trailing focus guard (so
-- | the body order [lead, #root, el, trail] is preserved). A Halogen re-render re-parents
-- | the portaled node back under its vdom parent; this puts it back without disturbing the
-- | guards (plain appendChild would land it after the trailing guard).
reAdoptBeforeTrail :: HTMLElement -> Effect Unit
reAdoptBeforeTrail wrap = do
  mg <- Ref.read guardEls
  withBody \body -> do
    let bodyNode = HTMLElement.toNode body
        wrapNode = HTMLElement.toNode wrap
    case mg of
      Just { trail } -> insertBefore wrapNode (toNode trail) bodyNode
      Nothing -> appendChild wrapNode bodyNode

-- ── hideOthers / showOthers (modal) ─────────────────────────────────────────────
bodyChildren :: Effect (Array Element)
bodyChildren = do
  hdoc <- HTML.window >>= Window.document
  mbody <- HTMLDocument.body hdoc
  case mbody of
    Nothing -> pure []
    Just body -> children (Element.toParentNode (HTMLElement.toElement body)) >>= toArray

-- | aria-hide every body child EXCEPT `keep` (the modal's portal root): `aria-hidden=true`
-- | + radix's `data-aria-hidden=true` marker. Stateless — undo with `showOthers`.
hideOthers :: HTMLElement -> Effect Unit
hideOthers keep = do
  els <- bodyChildren
  let keepEl = HTMLElement.toElement keep
  for_ (filter (\e -> not (unsafeRefEq e keepEl)) els) \e -> do
    setAttribute "aria-hidden" "true" e
    setAttribute "data-aria-hidden" "true" e

-- | Remove the aria-hide from every body child radix marked (`data-aria-hidden`).
showOthers :: Effect Unit
showOthers = do
  els <- bodyChildren
  for_ els \e -> do
    m <- Element.getAttribute "data-aria-hidden" e
    case m of
      Just _ -> removeAttribute "aria-hidden" e *> removeAttribute "data-aria-hidden" e
      Nothing -> pure unit
