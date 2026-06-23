-- | Hydrogen.Radix.Toolbar — a container for grouped controls with roving focus
-- | (radix `Toolbar`).
-- |
-- | Clones the Tabs/ToggleGroup roving-focus skeleton, but the children are
-- | HETEROGENEOUS (buttons, links, separators, a nested toggle-group), so they are
-- | modelled as a sum type (`Item`) in `Input` rather than a flat homogeneous array.
-- | The keyboard + tabindex behaviour is the EXISTING closed-form
-- | `Behavior.RovingFocus` (focusIntent/move/navigate/tabIndexFor) reused verbatim;
-- | the separator delegates to `Hydrogen.Radix.Separator.separator` with its
-- | orientation FLIPPED (toolbar horizontal → separator vertical), per upstream.
-- |
-- | UPSTREAM DOM CONTRACT (verified against the committed golden-dom oracles —
-- | toolbar.{default,vertical,roved}). RovingFocusGroupImpl is merged (asChild) onto
-- | the root and each item:
-- |   * Root  → `<div role="toolbar" aria-label aria-orientation data-orientation
-- |     dir style="outline: none;" tabindex>`. The root carries tabindex=0; every
-- |     item carries tabindex=-1 UNTIL focus enters the group, at which point the
-- |     tabindex=0 migrates onto the current roving item (the `roved` oracle proves
-- |     this — at rest ALL items are -1).
-- |   * Button → `<button type="button" data-orientation data-radix-collection-item
-- |     tabindex>` (+ native `disabled`).
-- |   * Link  → `<a href data-orientation data-radix-collection-item tabindex>` (NO
-- |     type); Space activates it (upstream wires ' ' → currentTarget.click()).
-- |   * Separator → `Separator` with FLIPPED orientation.
-- |   * ToggleGroup → `<div role="group" aria-label dir data-orientation>` with
-- |     `rovingFocus={false}` (the inner group adds NO tab stop / outline / entry
-- |     focus — its items rove as part of the OUTER toolbar). Each ToggleItem →
-- |     `<button type="button" data-state data-orientation data-radix-collection-item
-- |     tabindex role="radio" aria-checked>` (single mode; NO aria-pressed).
-- |
-- | At-rest is the oracle: no portal, no Presence, no Float, no minted ids.
module Hydrogen.Radix.Toolbar
  ( component
  , Item(..)
  , ButtonSpec
  , LinkSpec
  , ToggleGroupSpec
  , ToggleItemSpec
  , Input
  , Output(..)
  , Query(..)
  , Slot
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Array (concatMap, elem, filter, findIndex, length, mapWithIndex, snoc, (!!))
import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.Direction (Dir(..), dirName)
import Hydrogen.Radix.Behavior.RovingFocus (Move(..), navigate, tabIndexFor)
import Hydrogen.Radix.Foundation.Style (ClassNames, Orientation(..), cn, classes, dataOrientation, dataAttr, orientationName, role, aria)
import Hydrogen.Radix.Separator (separator)
import Web.HTML.HTMLElement as HTMLElement
import Web.UIEvent.KeyboardEvent as KE

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

type ButtonSpec =
  { value :: String, label :: Array HH.PlainHTML, disabled :: Boolean }

type LinkSpec =
  { value :: String, label :: Array HH.PlainHTML, href :: String, disabled :: Boolean }

type ToggleItemSpec =
  { value :: String, label :: Array HH.PlainHTML, disabled :: Boolean }

type ToggleGroupSpec =
  { items :: Array ToggleItemSpec
  , single :: Boolean             -- enforce at-most-one pressed (single mode → role=radio)
  , defaultValue :: Array String  -- initial pressed set
  , ariaLabel :: Maybe String
  }

-- | A heterogeneous toolbar child.
data Item
  = Button ButtonSpec
  | Link LinkSpec
  | Sep
  | ToggleGroup ToggleGroupSpec

type Style =
  { root :: ClassNames
  , button :: ClassNames
  , link :: ClassNames
  , separator :: ClassNames
  , toggleGroup :: ClassNames
  , toggleItem :: ClassNames
  }

defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-toolbar"
  , button: cn "rdx-toolbar-button"
  , link: cn "rdx-toolbar-link"
  , separator: cn "rdx-toolbar-separator"
  , toggleGroup: cn "rdx-toolbar-toggle-group"
  , toggleItem: cn "rdx-toolbar-toggle-item"
  }

type Input =
  { items :: Array Item
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
  , ariaLabel :: Maybe String
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { items: []
  , orientation: Horizontal
  , dir: LTR
  , loop: true
  , ariaLabel: Nothing
  , style: defaultStyle
  }

-- | A toolbar button or link was activated; a toggle-item selection bubbles as
-- | `ToggleChanged groupValue selectedSet`.
data Output
  = Activated String
  | ToggleChanged String (Array String)

data Query a
  = GetCurrent (Int -> a)
  | SetCurrent Int a

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { items :: Array Item
  , orientation :: Orientation
  , dir :: Dir
  , loop :: Boolean
  , ariaLabel :: Maybe String
  , style :: Style
  -- per-toggle-group selection, keyed by group index in `items` (stringified)
  , toggleValues :: Array (Array String)
  , currentIndex :: Int      -- roving cursor over the FOCUSABLE leaf space
  , focusEntered :: Boolean   -- false ⇒ every item -1 (root holds the tab stop)
  , tabbingOut :: Boolean    -- a Shift+Tab/Tab is in flight: the root's onFocus must NOT forward
                             -- focus to an item (RovingFocusGroup isTabbingBackOut), so focus escapes
  }

-- | A focusable leaf in the roving index space — identified by a stable ref key.
data Focusable
  = FButton ButtonSpec
  | FLink LinkSpec
  | FToggleItem Int ToggleItemSpec   -- group index + the item

data Action
  = Receive Input
  | ListKeyDown KE.KeyboardEvent
  | EntryFocus
  | ItemFocused String
  | ButtonActivated String
  | LinkKeyDown String KE.KeyboardEvent
  | LinkActivated String
  | ToggleItemClicked Int String
  | Initialize

itemRef :: String -> H.RefLabel
itemRef key = H.RefLabel ("toolbar-item-" <> key)

-- | Ref key for a focusable leaf (group items get a g<gi>- prefix so they never
-- | collide with a top-level button/link of the same value).
focusKey :: Focusable -> String
focusKey = case _ of
  FButton b -> b.value
  FLink l -> l.value
  FToggleItem gi it -> "g" <> show gi <> "-" <> it.value

component :: forall m. MonadEffect m => H.Component Query Input Output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , handleQuery = handleQuery
        , receive = Just <<< Receive
        , initialize = Just Initialize
        }
    }

initialState :: Input -> State
initialState input =
  { items: input.items
  , orientation: input.orientation
  , dir: input.dir
  , loop: input.loop
  , ariaLabel: input.ariaLabel
  , style: input.style
  , toggleValues: map initialToggle input.items
  , currentIndex: 0
  , focusEntered: false
  , tabbingOut: false
  }
  where
  initialToggle = case _ of
    ToggleGroup g -> g.defaultValue
    _ -> []

-- | The dense, ordered list of focusable leaves (separators excluded; disabled
-- | items excluded — they are not roving stops, matching RovingFocusGroup.Item
-- | focusable={!disabled}).
focusables :: State -> Array Focusable
focusables st = concatMap leavesOf (mapWithIndex (\i it -> { i, it }) st.items)
  where
  leavesOf { i, it } = case it of
    Button b -> if b.disabled then [] else [ FButton b ]
    Link l -> if l.disabled then [] else [ FLink l ]
    Sep -> []
    ToggleGroup g -> map (FToggleItem i) (filter (not <<< _.disabled) g.items)

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div
    ( [ role "toolbar"
      , aria "orientation" (orientationName st.orientation)
      , dataOrientation st.orientation
      , HP.attr (HH.AttrName "dir") (dirName st.dir)
      , HP.style "outline: none;"
      , HP.tabIndex 0
      , classes st.style.root
      , HE.onKeyDown ListKeyDown
      , HE.onFocus (const EntryFocus)
      ]
        <> labelAttr st.ariaLabel
    )
    (mapWithIndex (renderItem st) st.items)

labelAttr :: forall r i. Maybe String -> Array (HH.IProp r i)
labelAttr = case _ of
  Just l -> [ aria "label" l ]
  Nothing -> []

renderItem :: forall m. State -> Int -> Item -> H.ComponentHTML Action () m
renderItem st gi = case _ of
  Button b -> renderButton st b
  Link l -> renderLink st l
  Sep ->
    -- FLIPPED orientation: toolbar horizontal → separator vertical, and vice versa.
    HH.fromPlainHTML
      ( separator
          { orientation: flipOrientation st.orientation
          , decorative: false
          , class_: st.style.separator
          , attrs: []
          }
      )
  ToggleGroup g -> renderToggleGroup st gi g

flipOrientation :: Orientation -> Orientation
flipOrientation = case _ of
  Horizontal -> Vertical
  Vertical -> Horizontal

-- | The roving tabindex for a focusable identified by its key: -1 everywhere until
-- | focus enters the group, then 0 on the current cursor leaf.
tabIndexForKey :: State -> String -> Int
tabIndexForKey st key =
  if not st.focusEntered then (-1)
  else case findIndex (\f -> focusKey f == key) (focusables st) of
    Nothing -> (-1)
    Just idx -> tabIndexFor st.currentIndex idx

renderButton :: forall m. State -> ButtonSpec -> H.ComponentHTML Action () m
renderButton st b =
  HH.button
    ( [ HP.type_ HP.ButtonButton
      , HP.ref (itemRef b.value)
      , dataOrientation st.orientation
      , dataAttr "radix-collection-item" ""
      , HP.tabIndex (tabIndexForKey st b.value)
      , HP.disabled b.disabled
      , classes st.style.button
      , HE.onClick \_ -> ButtonActivated b.value
      , HE.onFocus (const (ItemFocused b.value))
      ]
    )
    (map HH.fromPlainHTML b.label)

renderLink :: forall m. State -> LinkSpec -> H.ComponentHTML Action () m
renderLink st l =
  HH.a
    [ HP.ref (itemRef l.value)
    , HP.href l.href
    , dataOrientation st.orientation
    , dataAttr "radix-collection-item" ""
    , HP.tabIndex (tabIndexForKey st l.value)
    , classes st.style.link
    , HE.onKeyDown (LinkKeyDown l.value)
    , HE.onClick \_ -> LinkActivated l.value
    , HE.onFocus (const (ItemFocused l.value))
    ]
    (map HH.fromPlainHTML l.label)

renderToggleGroup :: forall m. State -> Int -> ToggleGroupSpec -> H.ComponentHTML Action () m
renderToggleGroup st gi g =
  HH.div
    ( [ role "group"
      , HP.attr (HH.AttrName "dir") (dirName st.dir)
      , dataOrientation st.orientation
      , classes st.style.toggleGroup
      ]
        <> labelAttr g.ariaLabel
    )
    (map (renderToggleItem st gi) g.items)

renderToggleItem :: forall m. State -> Int -> ToggleItemSpec -> H.ComponentHTML Action () m
renderToggleItem st gi it =
  let
    pressed = fromMaybe [] (st.toggleValues !! gi)
    on = it.value `elem` pressed
    key = "g" <> show gi <> "-" <> it.value
    single = case st.items !! gi of
      Just (ToggleGroup g) -> g.single
      _ -> false
  in
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.ref (itemRef key)
        , dataAttr "state" (if on then "on" else "off")
        , dataOrientation st.orientation
        , dataAttr "radix-collection-item" ""
        , HP.tabIndex (tabIndexForKey st key)
        , HP.disabled it.disabled
        , classes st.style.toggleItem
        , HE.onClick \_ -> ToggleItemClicked gi it.value
        , HE.onFocus (const (ItemFocused key))
        ]
          <> (if single then [ role "radio", aria "checked" (if on then "true" else "false") ]
              else [ aria "pressed" (if on then "true" else "false") ])
      )
      (map HH.fromPlainHTML it.label)

handleAction :: forall m. MonadEffect m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> pure unit
  Receive input ->
    H.modify_ \st -> st
      { items = input.items
      , orientation = input.orientation
      , dir = input.dir
      , loop = input.loop
      , ariaLabel = input.ariaLabel
      , style = input.style
      }
  ButtonActivated value -> H.raise (Activated value)
  LinkActivated value -> H.raise (Activated value)
  LinkKeyDown value ke ->
    -- Space activates a link (native <a> ignores Space) — upstream wires ' ' → click().
    when (KE.key ke == " ") do
      mel <- H.getHTMLElementRef (itemRef value)
      for_ mel (liftEffect <<< HTMLElement.click)
  ToggleItemClicked gi value -> do
    st <- H.get
    let
      single = case st.items !! gi of
        Just (ToggleGroup g) -> g.single
        _ -> false
      cur = fromMaybe [] (st.toggleValues !! gi)
      next =
        if value `elem` cur then filter (_ /= value) cur
        else if single then [ value ]
        else snoc cur value
      groupValue = "g" <> show gi
    H.modify_ \s -> s { toggleValues = updateAt' gi next s.toggleValues }
    H.raise (ToggleChanged groupValue next)
  ListKeyDown ke | KE.key ke == "Tab" ->
    -- Tab/Shift+Tab leaves the group: mark it so the root's onFocus (fired when Shift+Tab lands
    -- focus on the root from inside) does NOT bounce focus back onto an item. Let native Tab run.
    H.modify_ _ { tabbingOut = true }
  ListKeyDown ke -> do
    st <- H.get
    let
      -- upstream MAP_KEY_TO_FOCUS_INTENT maps PageUp→'first', PageDown→'last' identically to
      -- Home/End (roving-focus-group). The shared focusIntent only knows Home/End, so translate
      -- PageUp/PageDown LOCALLY here (keeps the closed-form Behavior untouched) before navigate.
      key = case KE.key ke of
        "PageUp" -> "Home"
        "PageDown" -> "End"
        k -> k
      cfg = { orientation: st.orientation, dir: st.dir, loop: st.loop }
      count = length (focusables st)
      pos = { count, current: st.currentIndex }
    case navigate cfg pos key of
      Stay -> pure unit
      MoveTo idx -> do
        H.modify_ _ { currentIndex = idx, focusEntered = true }
        focusAt idx
  EntryFocus -> do
    st <- H.get
    -- A Tab/Shift+Tab in flight means focus is LEAVING (it just landed on the root on its way
    -- out): consume the flag and do NOT forward focus, so it escapes. Otherwise this is a genuine
    -- Tab-INTO: forward container focus to the current roving leaf, migrating the tab stop.
    if st.tabbingOut then H.modify_ _ { tabbingOut = false }
    else do
      H.modify_ _ { focusEntered = true }
      focusAt st.currentIndex
  ItemFocused key -> do
    -- An item received focus directly (Tab into the toolbar lands on the current
    -- roving stop; a programmatic .focus() lands on any item) — make it the single
    -- tab stop, mirroring RovingFocusGroup.Item's onFocus (currentTabStopId ← me).
    st <- H.get
    case findIndex (\f -> focusKey f == key) (focusables st) of
      Nothing -> pure unit
      Just idx -> H.modify_ _ { currentIndex = idx, focusEntered = true }

-- | Focus the focusable leaf at index `idx` via its ref.
focusAt :: forall m. MonadEffect m => Int -> H.HalogenM State Action () Output m Unit
focusAt idx = do
  st <- H.get
  case focusables st !! idx of
    Nothing -> pure unit
    Just f -> do
      mel <- H.getHTMLElementRef (itemRef (focusKey f))
      for_ mel (liftEffect <<< HTMLElement.focus)

updateAt' :: forall a. Int -> a -> Array a -> Array a
updateAt' i v = mapWithIndex (\j x -> if j == i then v else x)

handleQuery :: forall m a. MonadEffect m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  GetCurrent reply -> do
    st <- H.get
    pure (Just (reply st.currentIndex))
  SetCurrent i a -> do
    H.modify_ _ { currentIndex = i }
    pure (Just a)
