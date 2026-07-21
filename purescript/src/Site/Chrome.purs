-- | The deck chrome: nav, section-index overlay, footer, rails, ambient
-- | layers. Transcribed from the golden mock; state-dependent classes and
-- | text are computed from Site.Types.State.
module Site.Chrome
  ( amb
  , nav
  , overlay
  , footer
  , vrail
  , shint
  ) where

import Prelude

import Data.Array ((!!))
import Data.Int as Int
import Data.Maybe (fromMaybe)
import Data.String.CodeUnits as SCU
import Halogen.HTML as HH
import Halogen.HTML.Core (AttrName(..))
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Site.Svg (monogram, moon, sun)
import Site.Types (Action(..), State, darkPanels, panelCount, sectionNames)

cls :: forall r i. String -> HH.IProp (class :: String | r) i
cls = HP.class_ <<< HH.ClassName

style :: forall r i. String -> HH.IProp r i
style = HP.attr (AttrName "style")

dAttr :: forall r i. String -> String -> HH.IProp r i
dAttr n = HP.attr (AttrName n)

pad2 :: Int -> String
pad2 n =
  let s = show (n + 1)
  in if SCU.length s < 2 then "0" <> s else s

dk :: State -> String -> String
dk state base = if darkPanels state.page then base <> " dk" else base

amb :: forall w i. HH.HTML w i
amb = HH.div [ cls "amb", dAttr "aria-hidden" "true" ] [ HH.div_ [], HH.div_ [], HH.div_ [] ]

-- ============================================================
-- NAV
-- ============================================================

navEntries :: Array { p :: Int, name :: String }
navEntries =
  [ { p: 0, name: "Home" }
  , { p: 1, name: "Thesis" }
  , { p: 2, name: "Practices" }
  , { p: 3, name: "Record" }
  ]

navEntries' :: Array { p :: Int, name :: String }
navEntries' =
  [ { p: 4, name: "Method" }
  , { p: 5, name: "Principles" }
  , { p: 6, name: "Inquiries" }
  ]

nav :: forall w. State -> HH.HTML w Action
nav state =
  HH.nav [ cls (dk state "nav"), HP.id "nav" ]
    [ HH.div [ cls "nm", dAttr "data-p" "0", HE.onClick \_ -> Go 0 ] [ HH.text "Hypermodern" ]
    , HH.ul [ cls "nl" ]
        ( map navBtn navEntries
            <> [ HH.li_
                   [ HH.a [ HP.href "../straylight-website-final/Archive.html" ]
                       [ HH.text "Publications ", HH.span [ cls "ext" ] [ HH.text "↗" ] ]
                   ]
               ]
            <> map navBtn navEntries'
            <> [ HH.li_ [ HH.span [ cls "nav-div" ] [] ]
               , HH.li_
                   [ HH.button
                       [ cls "theme-tog"
                       , dAttr "aria-label" "Toggle theme"
                       , HP.title (if state.dark then "Ono-sendai — dark" else "Toggle Ono-sendai")
                       , HE.onClick \_ -> ToggleTheme
                       ]
                       [ if state.dark then moon else sun ]
                   ]
               ]
        )
    , HH.button [ cls "menu-btn", HP.id "menuBtn", dAttr "aria-label" "Open section index", HE.onClick \_ -> OpenOverlay ]
        [ HH.span [ cls "mcount", HP.id "mcount" ] [ HH.text (pad2 state.page <> " / " <> pad2 (panelCount - 1)) ]
        , HH.span [ cls "mbars" ] [ HH.i_ [], HH.i_ [], HH.i_ [] ]
        ]
    ]
  where
  navBtn e =
    HH.li_
      [ HH.button
          [ dAttr "data-p" (show e.p)
          , HP.class_ (HH.ClassName (activeCls e.p))
          , HE.onClick \_ -> Go e.p
          ]
          [ HH.text e.name ]
      ]
  activeCls p = if p == state.page then "active" else ""

-- ============================================================
-- OVERLAY
-- ============================================================

ovEntries :: Array { num :: String, name :: String, meta :: String, p :: Int }
ovEntries =
  [ { num: "01", name: "Home", meta: "Consulting for the technically serious", p: 0 }
  , { num: "02", name: "Thesis", meta: "Constraint is the insight", p: 1 }
  , { num: "03", name: "Practices", meta: "Six disciplines", p: 2 }
  , { num: "04", name: "Record", meta: "Twenty years of systems at scale", p: 3 }
  ]

ovEntries' :: Array { num :: String, name :: String, meta :: String, p :: Int }
ovEntries' =
  [ { num: "05", name: "Method", meta: "CDR — Claude, DeepSeek, Reesman", p: 4 }
  , { num: "06", name: "Principles", meta: "Nullius in verba", p: 5 }
  , { num: "07", name: "Inquiries", meta: "Begin a conversation", p: 6 }
  ]

overlay :: forall w. State -> HH.HTML w Action
overlay state =
  HH.div [ HP.class_ (HH.ClassName ("overlay" <> if state.overlayOpen then " open" else "")), HP.id "overlay" ]
    [ HH.div [ cls "overlay-top" ]
        [ HH.div [ cls "nm", dAttr "data-p" "0", HE.onClick \_ -> Go 0 ] [ HH.text "Hypermodern" ]
        , HH.button [ cls "ov-close", HP.id "ovClose", HE.onClick \_ -> CloseOverlay ]
            [ HH.span_ [ HH.text "Close" ], HH.span [ cls "x" ] [] ]
        ]
    , HH.ul [ HP.id "ovList" ]
        ( map ovBtn ovEntries
            <> [ HH.li_
                   [ HH.a [ HP.href "../straylight-website-final/Archive.html" ]
                       [ HH.span [ cls "ov-num" ] [ HH.text "↗" ]
                       , HH.span [ cls "ov-name" ] [ HH.text "Publications" ]
                       , HH.span [ cls "ov-meta" ] [ HH.text "Read the archive ↗" ]
                       ]
                   ]
               ]
            <> map ovBtn ovEntries'
        )
    ]
  where
  ovBtn e =
    HH.li_
      [ HH.button
          [ dAttr "data-p" (show e.p)
          , HP.class_ (HH.ClassName (if e.p == state.page then "active" else ""))
          , HE.onClick \_ -> Go e.p
          ]
          [ HH.span [ cls "ov-num" ] [ HH.text e.num ]
          , HH.span [ cls "ov-name" ] [ HH.text e.name ]
          , HH.span [ cls "ov-meta" ] [ HH.text e.meta ]
          ]
      ]

-- ============================================================
-- FOOTER
-- ============================================================

footer :: forall w. State -> HH.HTML w Action
footer state =
  HH.div [ cls (dk state "ft"), HP.id "ft" ]
    [ HH.div [ cls "ft-l" ]
        [ HH.span [ cls "mono-i", style "width:12px;height:9px;opacity:.4" ] [ monogram "currentColor" ]
        , HH.span [ cls "lbl" ] [ HH.text "Hypermodern LLC" ]
        ]
    , HH.div [ cls "ft-c" ]
        [ HH.span [ cls "ft-sec", HP.id "ftSec" ] [ HH.text sectionName ]
        , HH.div [ cls "ind", HP.id "ind", HE.onClick Scrub ]
            [ HH.div [ cls "ind-glow", HP.id "indGlow", style ("left:" <> glowLeft <> "%") ] [] ]
        ]
    , HH.div [ cls "ft-r" ] [ HH.text "© 2026" ]
    ]
  where
  sectionName = fromMaybe "Home" (sectionNames !! state.page)
  -- thumb is 12.5% wide -> travel range is (100 - 12.5)%
  glowLeft = show (Int.toNumber state.page / Int.toNumber (panelCount - 1) * 87.5)

-- ============================================================
-- RAILS
-- ============================================================

vrail :: forall w i. HH.HTML w i
vrail =
  HH.div [ cls "vrail", HP.id "vrail" ]
    [ HH.div [ cls "vrail-track" ] [], HH.div [ cls "vrail-thumb", HP.id "vthumb" ] [] ]

shint :: forall w i. HH.HTML w i
shint =
  HH.div [ cls "shint", HP.id "shint" ]
    [ HH.span_ [ HH.text "Scroll" ], HH.span [ cls "chev" ] [] ]
