-- | Multi-component behavioral-invariance subject (STR-383), item-based stateful family.
-- | Renders Tabs, Accordion, and Collapsible, each in a `[data-invariance="<Component>"]`
-- | group containing four `[data-preset]` variants (unstyled · themes · shadcn · daisy)
-- | that differ ONLY in their Style class lists. The SAME items/inputs feed all four
-- | variants, so the behavioral DOM (role=tablist/tab/tabpanel, role=region,
-- | aria-selected/expanded/controls, data-state, hidden) is byte-identical across skins.
-- |
-- | Each subject renders AT REST with a deterministic selection (Tabs defaultValue,
-- | Accordion defaultValue, Collapsible defaultOpen) so there is a visible selected/open
-- | element whose stable surface the invariance gate can compare.
-- |
-- | NOT a pixel story — excluded from the gallery manifest.
module Gallery.Story.InvC (story) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Accordion as Accordion
import Hydrogen.Radix.Collapsible as Collapsible
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.Tabs as Tabs
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "inv-c", component }

type Slots =
  ( tabs :: Tabs.Slot Int
  , accordion :: Accordion.Slot Int
  , collapsible :: Collapsible.Slot Int
  )

_tabs :: Proxy "tabs"
_tabs = Proxy

_accordion :: Proxy "accordion"
_accordion = Proxy

_collapsible :: Proxy "collapsible"
_collapsible = Proxy

-- | Four skins, each a different class vocabulary on whatever parts a component has.
-- | The fields name the parts shared by these disclosure/tab primitives; a component
-- | uses whichever subset it has. The strings are deliberately unrelated design
-- | systems — invariance must hold regardless of class.
type Skin =
  { name :: String
  , root :: String
  , list :: String
  , item :: String
  , header :: String
  , trigger :: String
  , content :: String
  }

skins :: Array Skin
skins =
  [ { name: "unstyled", root: "", list: "", item: "", header: "", trigger: "", content: "" }
  , { name: "themes"
    , root: "rt-reset rt-TabsRoot"
    , list: "rt-TabsList"
    , item: "rt-AccordionItem"
    , header: "rt-AccordionHeader"
    , trigger: "rt-reset rt-TabsTrigger"
    , content: "rt-TabsContent"
    }
  , { name: "shadcn"
    , root: "flex flex-col gap-2"
    , list: "inline-flex h-9 items-center justify-center rounded-lg bg-muted p-1"
    , item: "border-b"
    , header: "flex"
    , trigger: "inline-flex items-center justify-center rounded-md px-3 py-1 text-sm font-medium"
    , content: "flex-1 outline-none"
    }
  , { name: "daisy"
    , root: "tabs tabs-boxed"
    , list: "tabs"
    , item: "collapse collapse-arrow"
    , header: "collapse-title"
    , trigger: "tab"
    , content: "tab-content collapse-content"
    }
  ]

component :: StoryComponent
component = H.mkComponent
  { initialState: const unit
  , render: const view
  , eval: H.mkEval H.defaultEval
  }

view :: H.ComponentHTML Void Slots Aff
view =
  HH.div
    [ HP.style "display:contents" ]
    [ group "Tabs" (mapWithIndex tabsCell skins)
    , group "Accordion" (mapWithIndex accordionCell skins)
    , group "Collapsible" (mapWithIndex collapsibleCell skins)
    ]
  where
  group name kids = HH.div [ HP.attr (HH.AttrName "data-invariance") name ] kids

  preset s kid = HH.div [ HP.attr (HH.AttrName "data-preset") s.name ] [ kid ]

  -- A small fixed set of tabs; `defaultValue` selects the first → one tab is
  -- aria-selected/data-state=active with a visible panel, the rest hidden.
  tabItems :: Array Tabs.Tab
  tabItems =
    [ { value: "account", label: [ HH.text "Account" ], content: [ HH.text "Account panel" ], disabled: false }
    , { value: "documents", label: [ HH.text "Documents" ], content: [ HH.text "Documents panel" ], disabled: false }
    , { value: "settings", label: [ HH.text "Settings" ], content: [ HH.text "Settings panel" ], disabled: false }
    ]

  tabsCell i s = preset s $
    HH.slot_ _tabs i Tabs.component
      (Tabs.defaultInput
        { tabs = tabItems
        , defaultValue = Just "account"
        , style =
            { root: cn s.root
            , list: cn s.list
            , trigger: cn s.trigger
            , content: cn s.content
            }
        })

  -- A small fixed set of accordion items; `defaultValue` opens the first →
  -- one item is data-state=open with aria-expanded=true and a visible region,
  -- the rest closed/hidden.
  accordionItems :: Array Accordion.Item
  accordionItems =
    [ { value: "item-1", header: [ HH.text "Section 1" ], content: [ HH.text "Content 1" ], disabled: false }
    , { value: "item-2", header: [ HH.text "Section 2" ], content: [ HH.text "Content 2" ], disabled: false }
    ]

  accordionCell i s = preset s $
    HH.slot_ _accordion i Accordion.component
      (Accordion.defaultInput
        { items = accordionItems
        , defaultValue = [ "item-1" ]
        , single = true
        , collapsible = false
        , style =
            { root: cn s.root
            , item: cn s.item
            , header: cn s.header
            , trigger: cn s.trigger
            , content: cn s.content
            }
        })

  -- Open at rest (`defaultOpen`) → data-state=open, aria-expanded=true,
  -- aria-controls present, content visible.
  collapsibleCell i s = preset s $
    HH.slot_ _collapsible i Collapsible.component
      (Collapsible.defaultInput
        { defaultOpen = true
        , style =
            { root: cn s.root
            , trigger: cn s.trigger
            , content: cn s.content
            }
        , trigger = [ HH.text "Trigger" ]
        , content = [ HH.text "Content 1" ]
        })
