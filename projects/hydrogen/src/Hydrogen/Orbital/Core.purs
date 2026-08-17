-- | ORBITAL core primitives over the canonical class contract.
-- |
-- | Components are pure Halogen render functions with closed visual variants
-- | and an `attrs` escape hatch for ids, data attributes, and event handlers.
module Hydrogen.Orbital.Core
  ( ButtonVariant(..)
  , ButtonInput
  , defaultButton
  , button
  , LinkButtonInput
  , defaultLinkButton
  , linkButton
  , LinkCTAInput
  , defaultLinkCTA
  , linkCTA
  , BadgeInput
  , defaultBadge
  , badge
  , tag
  , StatusInput
  , defaultStatus
  , statusDot
  , Orientation(..)
  , SeparatorInput
  , defaultSeparator
  , separator
  , SpinnerInput
  , defaultSpinner
  , spinner
  , ProgressInput
  , defaultProgress
  , progress
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLa, HTMLbutton, HTMLdiv, HTMLspan)
import Data.Maybe (Maybe(..))
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Orbital.Foundation (ComponentSize(..), Tone(..), classNames, sizeClass, toneClass)

data ButtonVariant = DefaultButton | PrimaryButton | GhostButton

derive instance eqButtonVariant :: Eq ButtonVariant

buttonVariantClass :: ButtonVariant -> String
buttonVariantClass DefaultButton = ""
buttonVariantClass PrimaryButton = "primary"
buttonVariantClass GhostButton = "ghost"

type ButtonInput i =
  { variant :: ButtonVariant
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLbutton i)
  }

defaultButton :: forall i. ButtonInput i
defaultButton = { variant: DefaultButton, class_: "", attrs: [] }

button :: forall w i. ButtonInput i -> Array (HH.HTML w i) -> HH.HTML w i
button o =
  HH.button
    ( [ HP.class_ (HH.ClassName (classNames [ "btn", buttonVariantClass o.variant, o.class_ ]))
      , HP.type_ HP.ButtonButton
      ] <> o.attrs
    )

type LinkButtonInput i =
  { href :: String
  , variant :: ButtonVariant
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLa i)
  }

defaultLinkButton :: forall i. LinkButtonInput i
defaultLinkButton = { href: "#", variant: DefaultButton, class_: "", attrs: [] }

linkButton :: forall w i. LinkButtonInput i -> Array (HH.HTML w i) -> HH.HTML w i
linkButton o =
  HH.a
    ( [ HP.href o.href
      , HP.class_ (HH.ClassName (classNames [ "btn", buttonVariantClass o.variant, o.class_ ]))
      ] <> o.attrs
    )

type LinkCTAInput i =
  { href :: String
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLa i)
  }

defaultLinkCTA :: forall i. LinkCTAInput i
defaultLinkCTA = { href: "#", class_: "", attrs: [] }

linkCTA :: forall w i. LinkCTAInput i -> Array (HH.HTML w i) -> HH.HTML w i
linkCTA o =
  HH.a
    ( [ HP.href o.href
      , HP.class_ (HH.ClassName (classNames [ "link-cta", o.class_ ]))
      ] <> o.attrs
    )

type BadgeInput i =
  { tone :: Tone
  , dot :: Boolean
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLspan i)
  }

defaultBadge :: forall i. BadgeInput i
defaultBadge = { tone: Neutral, dot: true, class_: "", attrs: [] }

badge :: forall w i. BadgeInput i -> Array (HH.HTML w i) -> HH.HTML w i
badge o children =
  HH.span
    ( [ HP.class_ (HH.ClassName (classNames [ "badge2", toneClass o.tone, o.class_ ])) ] <> o.attrs )
    (dot <> children)
  where
  dot = if o.dot then
    [ HH.span
        [ HP.class_ (HH.ClassName "badge2-dot"), HP.attr (HH.AttrName "aria-hidden") "true" ]
        []
    ]
  else []

tag :: forall w i. Array (HH.IProp HTMLspan i) -> Array (HH.HTML w i) -> HH.HTML w i
tag attrs = HH.span ([ HP.class_ (HH.ClassName "tag") ] <> attrs)

type StatusInput i =
  { tone :: Tone
  , pulse :: Boolean
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLspan i)
  }

defaultStatus :: forall i. StatusInput i
defaultStatus = { tone: Neutral, pulse: false, class_: "", attrs: [] }

statusDot :: forall w i. StatusInput i -> Array (HH.HTML w i) -> HH.HTML w i
statusDot o children =
  HH.span
    ( [ HP.class_ (HH.ClassName (classNames [ "statusdot", toneClass o.tone, o.class_ ])) ] <> o.attrs )
    ( [ HH.span
          [ HP.class_ (HH.ClassName (classNames [ "statusdot-dot", if o.pulse then "is-pulse" else "" ]))
          , HP.attr (HH.AttrName "aria-hidden") "true"
          ]
          []
      ] <> children
    )

data Orientation = Horizontal | Vertical

derive instance eqOrientation :: Eq Orientation

type SeparatorInput i =
  { orientation :: Orientation
  , label :: Maybe String
  , decorative :: Boolean
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

defaultSeparator :: forall i. SeparatorInput i
defaultSeparator =
  { orientation: Horizontal
  , label: Nothing
  , decorative: false
  , class_: ""
  , attrs: []
  }

separator :: forall w i. SeparatorInput i -> HH.HTML w i
separator o =
  HH.div
    ( [ HP.class_ (HH.ClassName (classNames [ "separator", orientationClass, o.class_ ]))
      , HP.attr (HH.AttrName "role") (if o.decorative then "none" else "separator")
      ] <> orientationAttr <> o.attrs
    )
    label
  where
  orientationClass = case o.orientation of
    Horizontal -> ""
    Vertical -> "is-vertical"
  orientationAttr = case o.orientation of
    Horizontal -> []
    Vertical -> [ HP.attr (HH.AttrName "aria-orientation") "vertical" ]
  label = case o.label of
    Nothing -> []
    Just value -> [ HH.span [ HP.class_ (HH.ClassName "separator-label") ] [ HH.text value ] ]

type SpinnerInput i =
  { size :: ComponentSize
  , label :: String
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLspan i)
  }

defaultSpinner :: forall i. SpinnerInput i
defaultSpinner = { size: Medium, label: "Loading", class_: "", attrs: [] }

spinner :: forall w i. SpinnerInput i -> HH.HTML w i
spinner o =
  HH.span
    ( [ HP.class_ (HH.ClassName (classNames [ "spinner", sizeClass o.size, o.class_ ]))
      , HP.attr (HH.AttrName "role") "status"
      , HP.attr (HH.AttrName "aria-label") o.label
      ] <> o.attrs
    )
    []

type ProgressInput i =
  { value :: Int
  , label :: Maybe String
  , indeterminate :: Boolean
  , showValue :: Boolean
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

defaultProgress :: forall i. ProgressInput i
defaultProgress =
  { value: 0
  , label: Nothing
  , indeterminate: false
  , showValue: true
  , class_: ""
  , attrs: []
  }

progress :: forall w i. ProgressInput i -> HH.HTML w i
progress o =
  HH.div
    ( [ HP.class_ (HH.ClassName (classNames [ "progress", o.class_ ])) ] <> o.attrs )
    (headRow <> [ track ])
  where
  value = max 0 (min 100 o.value)
  headRow = if o.label == Nothing && not o.showValue then []
    else
      [ HH.div [ HP.class_ (HH.ClassName "progress-head") ]
          [ HH.span_ (case o.label of
              Nothing -> []
              Just label -> [ HH.text label ]
            )
          , HH.span [ HP.class_ (HH.ClassName "progress-val") ]
              (if o.showValue && not o.indeterminate then [ HH.text (show value <> "%") ] else [])
          ]
      ]
  track =
    HH.div
      ( [ HP.class_ (HH.ClassName (classNames [ "progress-track", if o.indeterminate then "is-indeterminate" else "" ]))
        , HP.attr (HH.AttrName "role") "progressbar"
        , HP.attr (HH.AttrName "aria-label") (case o.label of
            Nothing -> "Progress"
            Just label -> label
          )
        , HP.attr (HH.AttrName "aria-valuemin") "0"
        , HP.attr (HH.AttrName "aria-valuemax") "100"
        ] <> valueAttr
      )
      [ HH.div
          [ HP.class_ (HH.ClassName "progress-bar")
          , HP.style (if o.indeterminate then "" else "width: " <> show value <> "%;")
          ]
          []
      ]
  valueAttr = if o.indeterminate then [] else [ HP.attr (HH.AttrName "aria-valuenow") (show value) ]
