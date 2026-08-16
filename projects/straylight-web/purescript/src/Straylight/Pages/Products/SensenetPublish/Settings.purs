-- | sensenet//publish Settings Page
-- | Project settings, language configs, output options
module Straylight.Pages.Products.SensenetPublish.Settings where

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
  { initialState: const { activeTab: "project" }, render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction } }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

render :: forall m. State -> H.ComponentHTML Action () m
render state = HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ]
    [ HH.div [ cls [ "mb-8" ] ] [ HH.h1 [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text "Settings" ] ]
    , HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-[200px_1fr] gap-8" ] ] [ sidebar state, content state ] ]

sidebar :: forall m. State -> H.ComponentHTML Action () m
sidebar state = HH.nav [ cls [ "space-y-1" ] ]
    [ sidebarLink state "project" "Project"
    , sidebarLink state "languages" "Languages"
    , sidebarLink state "output" "Output"
    , sidebarLink state "api" "API Keys"
    , sidebarLink state "team" "Team" ]

sidebarLink :: forall m. State -> String -> String -> H.ComponentHTML Action () m
sidebarLink state value label = HH.button
    [ cls [ "block w-full text-left px-3 py-2 rounded text-sm transition-colors cursor-pointer"
          , if state.activeTab == value then "bg-teal-400/10 text-teal-400 font-medium" else "text-muted-foreground hover:text-text hover:bg-card" ]
    , HP.type_ HP.ButtonButton, HE.onClick \_ -> SetTab value ] [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "project" -> projectSettings
  "languages" -> languageSettings
  "output" -> outputSettings
  "api" -> apiSettings
  "team" -> teamSettings
  _ -> projectSettings

projectSettings :: forall w i. HH.HTML w i
projectSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsSection "Project Settings"
        [ formField "Project Name" "text" "api-docs"
        , formField "Repository" "text" "github.com/org/repo"
        , formField "Default Branch" "text" "main"
        , toggleField "Strict Mode" "Fail builds on any unresolved reference" true
        , toggleField "Incremental Builds" "Use cached scope graphs for unchanged files" true
        ]
    , settingsSection "Build Triggers"
        [ toggleField "Build on Push" "Automatically build when commits are pushed" true
        , toggleField "Build on PR" "Build and comment on pull requests" true
        , toggleField "Build on Tag" "Build when version tags are created" false
        ]
    ]

languageSettings :: forall w i. HH.HTML w i
languageSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsSection "Language Configuration"
        [ HH.div [ cls [ "space-y-4" ] ]
            [ langConfigRow "Rust" true "edition = \"2021\""
            , langConfigRow "TypeScript" true "tsconfig = \"./tsconfig.json\""
            , langConfigRow "Python" false "Not configured"
            , langConfigRow "Haskell" false "Not configured"
            ]
        ]
    , settingsSection "Add Language"
        [ HH.div [ cls [ "flex gap-2" ] ]
            [ HH.select [ cls [ "flex-1 px-3 py-2 bg-muted border border-border rounded-md text-text" ] ]
                [ HH.option_ [ HH.text "Select language..." ]
                , HH.option_ [ HH.text "C++" ]
                , HH.option_ [ HH.text "Go" ]
                , HH.option_ [ HH.text "Python" ]
                ]
            , HH.button [ cls [ "px-4 py-2 bg-teal-400 text-background rounded-md text-sm font-medium" ] ]
                [ HH.text "Add" ]
            ]
        ]
    ]

outputSettings :: forall w i. HH.HTML w i
outputSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsSection "Output Formats"
        [ toggleField "HTML" "Static HTML documentation" true
        , toggleField "JSON-LD" "Linked data with schema.org vocabulary" true
        , toggleField "OpenAPI" "OpenAPI 3.1 spec for REST endpoints" false
        , toggleField "Scope Graph" "Raw scope graph export" false
        ]
    , settingsSection "Output Options"
        [ formField "Output Directory" "text" "./docs/build"
        , formField "Base URL" "text" "https://docs.example.com"
        , toggleField "Minify HTML" "Minify HTML output for production" true
        , toggleField "Include Source Maps" "Include source maps in JSON output" false
        ]
    ]

apiSettings :: forall w i. HH.HTML w i
apiSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsSection "API Keys"
        [ HH.div [ cls [ "space-y-4" ] ]
            [ apiKeyRow "Production" "snp_prod_****7f3a" "Created Feb 10, 2026"
            , apiKeyRow "Development" "snp_dev_****2b1c" "Created Jan 28, 2026"
            ]
        , HH.button [ cls [ "mt-4 px-4 py-2 border border-border text-text rounded-md text-sm font-medium hover:bg-card transition-colors" ] ]
            [ HH.text "Generate New Key" ]
        ]
    , settingsSection "Webhooks"
        [ formField "Webhook URL" "text" "https://example.com/webhook"
        , toggleField "Build Complete" "Notify when builds complete" true
        , toggleField "Reference Errors" "Notify when references fail to resolve" true
        ]
    ]

teamSettings :: forall w i. HH.HTML w i
teamSettings = HH.div [ cls [ "space-y-6" ] ]
    [ settingsSection "Team Members"
        [ HH.div [ cls [ "space-y-4" ] ]
            [ teamMemberRow "alice@example.com" "Owner"
            , teamMemberRow "bob@example.com" "Admin"
            , teamMemberRow "carol@example.com" "Member"
            ]
        , HH.button [ cls [ "mt-4 px-4 py-2 border border-border text-text rounded-md text-sm font-medium hover:bg-card transition-colors" ] ]
            [ HH.text "Invite Member" ]
        ]
    ]

settingsSection :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
settingsSection title children = HH.div [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.h3 [ cls [ "text-lg font-semibold text-text mb-4" ] ] [ HH.text title ]
    , HH.div [ cls [ "space-y-4" ] ] children
    ]

formField :: forall w i. String -> String -> String -> HH.HTML w i
formField label inputType placeholder = HH.div_
    [ HH.label [ cls [ "block text-sm font-medium text-text mb-1" ] ] [ HH.text label ]
    , HH.input [ HP.type_ (if inputType == "text" then HP.InputText else HP.InputText)
               , HP.placeholder placeholder
               , HP.value placeholder
               , cls [ "w-full px-3 py-2 bg-muted border border-border rounded-md text-text" ] ]
    ]

toggleField :: forall w i. String -> String -> Boolean -> HH.HTML w i
toggleField label description enabled = HH.div [ cls [ "flex items-center justify-between" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm font-medium text-text" ] ] [ HH.text label ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
        ]
    , HH.div [ cls [ "w-10 h-6 rounded-full relative cursor-pointer transition-colors"
                   , if enabled then "bg-teal-400" else "bg-muted" ] ]
        [ HH.div [ cls [ "absolute top-1 w-4 h-4 bg-white rounded-full transition-transform"
                       , if enabled then "left-5" else "left-1" ] ] []
        ]
    ]

langConfigRow :: forall w i. String -> Boolean -> String -> HH.HTML w i
langConfigRow lang enabled config = HH.div [ cls [ "flex items-center justify-between p-3 bg-muted rounded-md" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm font-medium text-text" ] ] [ HH.text lang ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text config ]
        ]
    , HH.span [ cls [ "px-2 py-1 rounded text-xs font-medium"
                    , if enabled then "bg-teal-400/10 text-teal-400" else "bg-muted-foreground/10 text-muted-foreground" ] ]
        [ HH.text (if enabled then "Enabled" else "Disabled") ]
    ]

apiKeyRow :: forall w i. String -> String -> String -> HH.HTML w i
apiKeyRow name key created = HH.div [ cls [ "flex items-center justify-between p-3 bg-muted rounded-md" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-sm font-medium text-text" ] ] [ HH.text name ]
        , HH.p [ cls [ "text-xs text-muted-foreground font-mono" ] ] [ HH.text key ]
        ]
    , HH.span [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text created ]
    ]

teamMemberRow :: forall w i. String -> String -> HH.HTML w i
teamMemberRow email role = HH.div [ cls [ "flex items-center justify-between p-3 bg-muted rounded-md" ] ]
    [ HH.p [ cls [ "text-sm text-text" ] ] [ HH.text email ]
    , HH.span [ cls [ "px-2 py-1 rounded text-xs font-medium bg-teal-400/10 text-teal-400" ] ] [ HH.text role ]
    ]
