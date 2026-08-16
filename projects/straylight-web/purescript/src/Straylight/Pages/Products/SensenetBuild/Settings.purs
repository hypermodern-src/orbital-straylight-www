-- | sensenet//build Settings Page
module Straylight.Pages.Products.SensenetBuild.Settings where

import Prelude
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Straylight.UI (cls)

type State = { activeTab :: String }
data Action = SetTab String

settingsPage :: forall q i o m. H.Component q i o m
settingsPage = H.mkComponent
  { initialState: const { activeTab: "build" }, render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction } }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

render :: forall m. State -> H.ComponentHTML Action () m
render state = HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ HH.div [ cls [ "mb-8" ] ] 
        [ HH.h1 [ cls [ "text-2xl font-bold text-text mb-2" ] ] [ HH.text "Settings" ]
        , HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text "Configure sensenet//build for your project." ]
        ]
    , HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-[200px_1fr] gap-8" ] ] [ sidebar state, content state ] ]

sidebar :: forall m. State -> H.ComponentHTML Action () m
sidebar state = HH.nav [ cls [ "space-y-1" ] ]
    [ sidebarLink state "build" "Build Settings"
    , sidebarLink state "verification" "Proof Verification"
    , sidebarLink state "cache" "Cache"
    , sidebarLink state "remote" "Remote Execution"
    , sidebarLink state "integrations" "Integrations"
    , sidebarLink state "account" "Account"
    ]

sidebarLink :: forall m. State -> String -> String -> H.ComponentHTML Action () m
sidebarLink state value label = HH.button
    [ cls [ "block w-full text-left px-3 py-2 rounded text-sm transition-colors cursor-pointer"
          , if state.activeTab == value then "bg-green-400/10 text-green-400 font-medium" else "text-muted-foreground hover:text-text hover:bg-card" ]
    , HP.type_ HP.ButtonButton, HE.onClick \_ -> SetTab value ] [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "build" -> buildSettings
  "verification" -> verificationSettings
  "cache" -> cacheSettings
  "remote" -> remoteSettings
  "integrations" -> integrationsSettings
  "account" -> accountSettings
  _ -> buildSettings

-- ============================================================
-- BUILD SETTINGS
-- ============================================================

buildSettings :: forall w i. HH.HTML w i
buildSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Build Configuration"
        [ settingRow "Default target" "//..." "Build target when none specified"
        , settingRow "Parallelism" "auto" "Number of concurrent build jobs"
        , settingRow "Sandbox mode" "strict" "Hermetic isolation level"
        ]
    , settingsCard "Dhall Configuration"
        [ settingRow "Config path" "./build.dhall" "Root Dhall configuration file"
        , settingRow "Type checking" "strict" "Dhall type checking mode"
        , settingRow "Import resolution" "cached" "How imports are resolved"
        ]
    , settingsCard "Output"
        [ settingRow "Output directory" "./dist" "Build artifact destination"
        , settingRow "Content addressing" "enabled" "SHA256 content-addressed outputs"
        , settingRow "Attestation" "enabled" "Generate cryptographic attestations"
        ]
    ]

-- ============================================================
-- VERIFICATION SETTINGS
-- ============================================================

verificationSettings :: forall w i. HH.HTML w i
verificationSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Proof Verification Level"
        [ HH.div [ cls [ "space-y-3" ] ]
            [ verificationLevel "Full" "Verify all 47 theorems on every build" true
            , verificationLevel "Standard" "Verify core derivation properties" false
            , verificationLevel "Minimal" "Verify critical proofs only" false
            , verificationLevel "Off" "Skip verification (not recommended)" false
            ]
        ]
    , settingsCard "Lean4 Integration"
        [ settingRow "Lean4 version" "v4.3.0" "Lean4 toolchain version"
        , settingRow "Proof cache" "enabled" "Cache verified proofs"
        , settingRow "Proof timeout" "30s" "Maximum time per proof"
        ]
    , settingsCard "Verification Reporting"
        [ settingToggle "Generate proof reports" true
        , settingToggle "Include in build logs" true
        , settingToggle "Fail build on unverified" true
        ]
    ]

verificationLevel :: forall w i. String -> String -> Boolean -> HH.HTML w i
verificationLevel name desc selected =
  HH.div [ cls [ "flex items-start gap-3 p-3 rounded-lg border transition-colors"
               , if selected then "border-green-400 bg-green-400/5" else "border-border hover:border-border/80" ] ]
    [ HH.div [ cls [ "w-4 h-4 rounded-full border-2 mt-0.5 flex items-center justify-center"
                   , if selected then "border-green-400" else "border-muted-foreground" ] ]
        [ if selected 
            then HH.div [ cls [ "w-2 h-2 rounded-full bg-green-400" ] ] []
            else HH.text ""
        ]
    , HH.div_
        [ HH.p [ cls [ "text-sm font-medium text-text" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text desc ]
        ]
    ]

-- ============================================================
-- CACHE SETTINGS
-- ============================================================

cacheSettings :: forall w i. HH.HTML w i
cacheSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Local Cache"
        [ settingRow "Cache directory" "~/.cache/sensenet" "Local cache location"
        , settingRow "Max size" "10 GB" "Maximum cache size"
        , settingRow "TTL" "30 days" "Cache entry expiration"
        ]
    , settingsCard "Remote Cache"
        [ settingToggle "Enable remote cache" true
        , settingRow "Cache URL" "cache.sensenet.dev" "Remote cache endpoint"
        , settingRow "Auth method" "API key" "Authentication method"
        ]
    , settingsCard "Cache Policy"
        [ settingToggle "Cache intermediate artifacts" true
        , settingToggle "Cache test results" false
        , settingToggle "Share cache across branches" true
        ]
    ]

-- ============================================================
-- REMOTE EXECUTION SETTINGS
-- ============================================================

remoteSettings :: forall w i. HH.HTML w i
remoteSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Remote Execution"
        [ settingToggle "Enable remote builds" true
        , settingRow "Cluster endpoint" "build.sensenet.dev" "Remote build cluster"
        , settingRow "Max workers" "16" "Maximum concurrent remote workers"
        ]
    , settingsCard "Execution Policy"
        [ settingRow "Strategy" "hybrid" "local, remote, or hybrid"
        , settingRow "Fallback" "enabled" "Fall back to local on remote failure"
        , settingRow "Priority" "normal" "Job queue priority"
        ]
    , settingsCard "Resource Limits"
        [ settingRow "CPU limit" "4 cores" "Per-job CPU limit"
        , settingRow "Memory limit" "8 GB" "Per-job memory limit"
        , settingRow "Timeout" "30 min" "Maximum job duration"
        ]
    ]

-- ============================================================
-- INTEGRATIONS SETTINGS
-- ============================================================

integrationsSettings :: forall w i. HH.HTML w i
integrationsSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Version Control"
        [ integrationRow "GitHub" "Connected" true
        , integrationRow "GitLab" "Not connected" false
        , integrationRow "Bitbucket" "Not connected" false
        ]
    , settingsCard "CI/CD"
        [ integrationRow "GitHub Actions" "Connected" true
        , integrationRow "CircleCI" "Not connected" false
        , integrationRow "Jenkins" "Not connected" false
        ]
    , settingsCard "Notifications"
        [ integrationRow "Slack" "Connected" true
        , integrationRow "Discord" "Not connected" false
        , integrationRow "Email" "Connected" true
        ]
    , settingsCard "Package Registries"
        [ integrationRow "Crates.io" "Connected" true
        , integrationRow "npm" "Not connected" false
        , integrationRow "PyPI" "Not connected" false
        ]
    ]

integrationRow :: forall w i. String -> String -> Boolean -> HH.HTML w i
integrationRow name status connected =
  HH.div [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text name ]
    , HH.div [ cls [ "flex items-center gap-3" ] ]
        [ HH.span [ cls [ "text-xs"
                        , if connected then "text-green-400" else "text-muted-foreground" ] ] 
            [ HH.text status ]
        , HH.button [ cls [ "text-xs px-3 py-1 rounded border border-border text-muted-foreground hover:text-text hover:bg-card transition-colors" ] ]
            [ HH.text $ if connected then "Configure" else "Connect" ]
        ]
    ]

-- ============================================================
-- ACCOUNT SETTINGS
-- ============================================================

accountSettings :: forall w i. HH.HTML w i
accountSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsCard "Profile"
        [ settingRow "Email" "user@example.com" "Account email"
        , settingRow "Organization" "Acme Corp" "Team organization"
        , settingRow "Plan" "Pro" "$49/month"
        ]
    , settingsCard "API Access"
        [ settingRow "API Key" "snb_••••••••••••" "For programmatic access"
        , HH.div [ cls [ "pt-2" ] ]
            [ HH.button [ cls [ "text-sm px-4 py-2 rounded border border-border text-muted-foreground hover:text-text hover:bg-card transition-colors" ] ]
                [ HH.text "Regenerate API Key" ]
            ]
        ]
    , settingsCard "Danger Zone"
        [ HH.div [ cls [ "flex items-center justify-between" ] ]
            [ HH.div_
                [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text "Delete account" ]
                , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text "Permanently delete your account and all data" ]
                ]
            , HH.button [ cls [ "text-sm px-4 py-2 rounded bg-red-400/10 text-red-400 hover:bg-red-400/20 transition-colors" ] ]
                [ HH.text "Delete Account" ]
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

settingsCard :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
settingsCard title children =
  HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text title ]
    , HH.div [ cls [ "space-y-4" ] ] children
    ]

settingRow :: forall w i. String -> String -> String -> HH.HTML w i
settingRow label value description =
  HH.div [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.span [ cls [ "text-sm text-muted-foreground font-mono" ] ] [ HH.text value ]
    ]

settingToggle :: forall w i. String -> Boolean -> HH.HTML w i
settingToggle label enabled =
  HH.div [ cls [ "flex items-center justify-between py-2" ] ]
    [ HH.span [ cls [ "text-sm text-text" ] ] [ HH.text label ]
    , HH.div [ cls [ "w-10 h-5 rounded-full relative cursor-pointer transition-colors"
                   , if enabled then "bg-green-400" else "bg-muted" ] ]
        [ HH.div [ cls [ "absolute top-0.5 w-4 h-4 rounded-full bg-white transition-transform"
                       , if enabled then "left-5" else "left-0.5" ] ] []
        ]
    ]
