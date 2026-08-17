-- | A visual reference assembled only from native Hydrogen.Orbital renderers.
module Orbital.Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Hydrogen.Orbital.Brand (MarkSize(..), MarkVariant(..), defaultBrandmark, defaultMonotile, defaultWatermark, brandmark, monotile, watermarkField)
import Hydrogen.Orbital.Core (ButtonVariant(..), defaultBadge, defaultButton, defaultLinkButton, defaultProgress, defaultSpinner, defaultStatus, badge, button, linkButton, progress, spinner, statusDot, tag)
import Hydrogen.Orbital.Foundation (ComponentSize(..), Tone(..))
import Hydrogen.Orbital.Surface (TerminalLine(..), defaultGlassCard, defaultSectionHead, defaultTerminal, glassCard, metaList, sectionHead, statBand, terminal)
import Hydrogen.Orbital.Typography (body, defaultPullQuote, display, eyebrow, prose, pullQuote)

main :: Effect Unit
main = HA.runHalogenAff do
  root <- HA.awaitBody
  void $ runUI app unit root

app :: forall q i o. H.Component q i o Aff
app =
  H.mkComponent
    { initialState: const unit
    , render: const page
    , eval: H.mkEval H.defaultEval
    }

page :: forall w i. HH.HTML w i
page =
  HH.div [ HP.class_ (HH.ClassName "orbital-reference") ]
    [ HH.header [ HP.class_ (HH.ClassName "reference-bar") ]
        [ brandmark (defaultBrandmark { product = Just "system" })
        , HH.span [ HP.class_ (HH.ClassName "reference-theme") ] [ HH.text "Light / Ono-sendai" ]
        ]
    , HH.main [ HP.class_ (HH.ClassName "reference-main") ]
        [ hero
        , sectionHead (defaultSectionHead { number = Just "01", note = [ HH.text "One hue. One accent. Native PureScript." ] }) [ HH.text "Core signals" ]
        , coreSignals
        , sectionHead (defaultSectionHead { number = Just "02", note = [ HH.text "Hairlines carry structure. Glass carries depth." ] }) [ HH.text "Composed surfaces" ]
        , surfaces
        , sectionHead (defaultSectionHead { number = Just "03", note = [ HH.text "Serif begins only when reading becomes the task." ] }) [ HH.text "Publishing" ]
        , publishing
        ]
    ]

hero :: forall w i. HH.HTML w i
hero =
  HH.section [ HP.class_ (HH.ClassName "reference-hero") ]
    [ HH.div [ HP.class_ (HH.ClassName "reference-copy") ]
        [ eyebrow [] [ HH.text "ORBITAL // INFER" ]
        , display [] [ HH.text "Fast inference. Pure native." ]
        , body [] [ HH.text "LLM and diffusion inference over a custom binary protocol. No Python runtime in the serving path." ]
        , HH.div [ HP.class_ (HH.ClassName "reference-actions") ]
            [ button (defaultButton { variant = PrimaryButton }) [ HH.text "Request access" ]
            , linkButton (defaultLinkButton { href = "#surfaces" }) [ HH.text "Read the system" ]
            ]
        ]
    , watermarkField defaultWatermark
        [ HH.div [ HP.style "display: flex; flex-direction: column; align-items: center; gap: .8rem;" ]
            [ monotile (defaultMonotile { size = LargeMark, variant = StrokeMark })
            , HH.span_ [ HH.text "The monotile is the only mark." ]
            ]
        ]
    ]

coreSignals :: forall w i. HH.HTML w i
coreSignals =
  HH.section [ HP.class_ (HH.ClassName "reference-stack") ]
    [ HH.div [ HP.class_ (HH.ClassName "reference-row") ]
        [ badge (defaultBadge { tone = Accent }) [ HH.text "Measured" ]
        , badge (defaultBadge { tone = Success }) [ HH.text "Verified" ]
        , badge (defaultBadge { tone = Warning }) [ HH.text "Target" ]
        , badge (defaultBadge { tone = Error }) [ HH.text "Failed" ]
        , tag [] [ HH.text "Native" ]
        ]
    , HH.div [ HP.class_ (HH.ClassName "reference-row") ]
        [ statusDot (defaultStatus { tone = Success, pulse = true }) [ HH.text "Serving" ]
        , spinner (defaultSpinner { size = Small, label = "Compiling" })
        ]
    , HH.div [ HP.class_ (HH.ClassName "reference-progress") ]
        [ progress (defaultProgress { value = 72, label = Just "Model residency" }) ]
    ]

surfaces :: forall w i. HH.HTML w i
surfaces =
  HH.section [ HP.id "surfaces", HP.class_ (HH.ClassName "reference-stack") ]
    [ HH.div [ HP.class_ (HH.ClassName "reference-grid") ]
        [ feature "01" "Direct" "A custom binary protocol removes the general-purpose serving layer."
        , feature "02" "Native" "The hot path is compiled, typed, and built for the hardware it runs on."
        , feature "03" "Measured" "Claims remain TBD until a repeatable benchmark and its basis are published."
        ]
    , statBand []
        [ { value: [ HH.text "TBD" ], label: "Tokens / second" }
        , { value: [ HH.text "TBD" ], label: "Image latency" }
        , { value: [ HH.text "TBD" ], label: "Cost / request" }
        , { value: [ HH.text "1" ], label: "Protocol" }
        ]
    , terminal defaultTerminal
        [ Comment "# native serving path"
        , Prompt "orb infer serve model.orb"
        , Output "loading weights"
        , Emphasis "protocol: orbital/1"
        , Okay "ready"
        ]
    ]
  where
  feature kicker title copy =
    glassCard defaultGlassCard
      { kicker: [ HH.text kicker ]
      , title: [ HH.text title ]
      , body: [ HH.text copy ]
      , footer: []
      }

publishing :: forall w i. HH.HTML w i
publishing =
  HH.section [ HP.class_ (HH.ClassName "reference-paper") ]
    [ metaList []
        [ { key: "Type", value: [ HH.text "Research paper" ] }
        , { key: "Status", value: [ HH.text "Working draft" ] }
        , { key: "Basis", value: [ HH.text "Reproducible benchmark" ] }
        ]
    , HH.div [ HP.class_ (HH.ClassName "reference-stack") ]
        [ prose []
            [ HH.p_ [ HH.text "Cormorant appears here because the reader has settled into sustained prose. Structure, metadata, navigation, and every control remain mono." ]
            , HH.p_ [ HH.text "This boundary is semantic. It is not a decorative alternation between two equal typefaces." ]
            ]
        , pullQuote (defaultPullQuote { cite = "Orbital design guide" })
            [ HH.text "Infrastructure that proves itself." ]
        ]
    ]
