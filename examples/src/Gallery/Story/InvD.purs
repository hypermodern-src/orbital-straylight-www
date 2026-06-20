-- | Multi-component behavioral-invariance subject (STR-383, wave D). Renders several
-- | primitives, each in a `[data-invariance="<Component>"]` group containing four
-- | `[data-preset]` variants (unstyled · themes · shadcn · daisy) that differ ONLY in
-- | their Style class lists. The invariance gate (invariance.mjs) proves, per group,
-- | that the behavioral DOM (role=toolbar/group, tabindex roving, input type,
-- | data-radix-otp-input, aria-*) is byte-identical across all four presets.
-- |
-- | The SAME Input is fed to all four skins — only the per-part class lists vary, so
-- | the behavioral surface stays identical.
-- |
-- | NOT a pixel story — excluded from the gallery manifest.
module Gallery.Story.InvD (story) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Data.Void (Void)
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Behavior.Direction (Dir(..))
import Hydrogen.Radix.Foundation.Style (Orientation(..), cn)
import Hydrogen.Radix.OneTimePasswordField as OTP
import Hydrogen.Radix.PasswordToggleField as PasswordToggle
import Hydrogen.Radix.Toolbar as Toolbar
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "inv-d", component }

type Slots =
  ( toolbar :: Toolbar.Slot Int
  , otp :: OTP.Slot Int
  , passwordToggle :: PasswordToggle.Slot Int
  )

_toolbar :: Proxy "toolbar"
_toolbar = Proxy

_otp :: Proxy "otp"
_otp = Proxy

_passwordToggle :: Proxy "passwordToggle"
_passwordToggle = Proxy

-- | Four skins, each a different class vocabulary on whatever parts a component has.
-- | `a` is the primary/root part, `b`..`d` secondary parts. The strings are
-- | deliberately unrelated design systems — invariance must hold regardless.
type Skin =
  { name :: String, a :: String, b :: String, c :: String, d :: String }

skins :: Array Skin
skins =
  [ { name: "unstyled", a: "", b: "", c: "", d: "" }
  , { name: "themes", a: "rt-reset rt-BaseButton", b: "rt-Item", c: "rt-Separator", d: "rt-Input" }
  , { name: "shadcn", a: "flex items-center gap-1", b: "inline-flex h-8 items-center rounded-md px-2", c: "mx-1 h-4 w-px bg-border", d: "h-9 w-9 rounded-md border text-center" }
  , { name: "daisy", a: "join", b: "btn join-item", c: "divider divider-horizontal", d: "input input-bordered w-10" }
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
    [ group "Toolbar" (mapWithIndex toolbarCell skins)
    , group "OneTimePasswordField" (mapWithIndex otpCell skins)
    , group "PasswordToggleField" (mapWithIndex passwordToggleCell skins)
    ]
  where
  group name kids = HH.div [ HP.attr (HH.AttrName "data-invariance") name ] kids

  preset s kid = HH.div [ HP.attr (HH.AttrName "data-preset") s.name ] [ kid ]

  -- Toolbar: a small fixed heterogeneous item set (button · separator · button ·
  -- single-mode toggle-group). Same items + orientation/dir/loop/label across skins;
  -- only the per-part class lists differ. At rest: role=toolbar, every item tabindex=-1.
  toolbarCell i s = preset s $
    HH.slot_ _toolbar i Toolbar.component
      (Toolbar.defaultInput
        { items =
            [ Toolbar.Button { value: "bold", label: [ HH.text "B" ], disabled: false }
            , Toolbar.Sep
            , Toolbar.Link { value: "help", label: [ HH.text "Help" ], href: "#help", disabled: false }
            , Toolbar.ToggleGroup
                { items:
                    [ { value: "left", label: [ HH.text "L" ], disabled: false }
                    , { value: "center", label: [ HH.text "C" ], disabled: false }
                    ]
                , single: true
                , defaultValue: [ "left" ]
                , ariaLabel: Just "Alignment"
                }
            ]
        , orientation = Horizontal
        , dir = LTR
        , loop = true
        , ariaLabel = Just "Formatting"
        , style =
            { root: cn s.a
            , button: cn s.b
            , link: cn s.b
            , separator: cn s.c
            , toggleGroup: cn s.a
            , toggleItem: cn s.b
            }
        })

  -- OneTimePasswordField: a fixed 4-slot numeric field, uncontrolled and empty at rest.
  -- role=group; slot 0 carries autocomplete=one-time-code; the rest carry the ignore
  -- attrs; data-radix-otp-input on every slot. Same Input across skins.
  otpCell i s = preset s $
    HH.slot_ _otp i OTP.component
      (OTP.defaultInput
        { length = 4
        , validation = OTP.Numeric
        , name = Just "code"
        , style = { root: cn s.a, input: cn s.d }
        })

  -- PasswordToggleField: at rest hidden (type=password), with text Show/Hide toggle
  -- content (so aria-label is omitted — the accessible name comes from the text).
  -- Fixed inputId so the upstream id-on-both-nodes quirk is constant across skins.
  passwordToggleCell i s = preset s $
    HH.slot_ _passwordToggle i PasswordToggle.component
      (PasswordToggle.defaultInput
        { inputId = Just "inv-d-password"
        , toggleVisible = [ HH.text "Hide" ]
        , toggleHidden = [ HH.text "Show" ]
        , style = { input: cn s.d, toggle: cn s.b }
        })
