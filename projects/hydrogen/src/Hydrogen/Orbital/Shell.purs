-- | Viewport-owned application chrome for ORBITAL tools such as Forge.
module Hydrogen.Orbital.Shell
  ( AppShellInput
  , defaultAppShell
  , appShell
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLdiv)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Orbital.Foundation (classNames)

type AppShellInput w i =
  { header :: Array (HH.HTML w i)
  , main :: Array (HH.HTML w i)
  , statusLeft :: Array (HH.HTML w i)
  , statusRight :: Array (HH.HTML w i)
  , sourceMode :: Boolean
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

defaultAppShell :: forall w i. AppShellInput w i
defaultAppShell =
  { header: []
  , main: []
  , statusLeft: []
  , statusRight: []
  , sourceMode: false
  , class_: ""
  , attrs: []
  }

-- | A `100dvh` grid whose middle row owns scrolling. Source mode keeps the
-- | middle row fixed so split panes can own their independent overflow.
appShell :: forall w i. AppShellInput w i -> HH.HTML w i
appShell o =
  HH.div
    ( [ HP.class_
          ( HH.ClassName
              ( classNames
                  [ "orbital-app-shell"
                  , if o.sourceMode then "is-source" else ""
                  , o.class_
                  ]
              )
          )
      ] <> o.attrs
    )
    [ HH.header [ HP.class_ (HH.ClassName "orbital-app-shell-header") ] o.header
    , HH.main [ HP.class_ (HH.ClassName "orbital-app-shell-main") ] o.main
    , HH.footer [ HP.class_ (HH.ClassName "orbital-app-shell-status") ]
        [ HH.div [ HP.class_ (HH.ClassName "orbital-app-shell-status-left") ] o.statusLeft
        , HH.div [ HP.class_ (HH.ClassName "orbital-app-shell-status-right") ] o.statusRight
        ]
    ]
