-- | sensenet//publish Dashboard Page
-- | Documentation builds, reference status, broken links
module Straylight.Pages.Products.SensenetPublish.Dashboard where

import Prelude
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Straylight.UI (cls)

type State = { activeTab :: String }
data Action = SetTab String

dashboardPage :: forall q i o m. H.Component q i o m
dashboardPage = H.mkComponent
  { initialState: const { activeTab: "overview" }, render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction } }

handleAction :: forall o m. Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetTab tab -> H.modify_ _ { activeTab = tab }

render :: forall m. State -> H.ComponentHTML Action () m
render state = HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-8" ] ] [ header, tabs state, content state ]

header :: forall w i. HH.HTML w i
header = HH.div [ cls [ "mb-8" ] ]
    [ HH.h1 [ cls [ "text-2xl font-bold text-text mb-2" ] ] [ HH.text "sensenet//publish Dashboard" ]
    , HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text "Documentation builds, reference status, and scope-graph analytics." ] ]

tabs :: forall m. State -> H.ComponentHTML Action () m
tabs state = HH.div [ cls [ "flex gap-1 mb-8 border-b border-border" ] ]
    [ tabButton state "overview" "Overview"
    , tabButton state "builds" "Builds"
    , tabButton state "references" "References"
    , tabButton state "projects" "Projects" ]

tabButton :: forall m. State -> String -> String -> H.ComponentHTML Action () m
tabButton state value label = HH.button
    [ cls [ "px-4 py-2 text-sm font-medium transition-colors -mb-px cursor-pointer"
          , if state.activeTab == value then "text-teal-400 border-b-2 border-teal-400" else "text-muted-foreground hover:text-text" ]
    , HP.type_ HP.ButtonButton
    , HE.onClick \_ -> SetTab value ] [ HH.text label ]

content :: forall m. State -> H.ComponentHTML Action () m
content state = case state.activeTab of
  "overview" -> overviewTab
  "builds" -> buildsTab
  "references" -> referencesTab
  "projects" -> projectsTab
  _ -> overviewTab

overviewTab :: forall w i. HH.HTML w i
overviewTab = HH.div_
    [ HH.div [ cls [ "grid grid-cols-1 md:grid-cols-4 gap-4 mb-8" ] ]
        [ statCard "Projects" "8" "active"
        , statCard "Builds" "247" "this month"
        , statCard "References" "12,847" "resolved"
        , statCard "Broken Links" "0" "in production" ]
    , HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-6" ] ]
        [ recentBuildsCard
        , referenceHealthCard
        ]
    ]

buildsTab :: forall w i. HH.HTML w i
buildsTab = HH.div_
    [ HH.div [ cls [ "bg-card border border-border rounded-lg" ] ]
        [ HH.div [ cls [ "p-4 border-b border-border" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Recent Builds" ] ]
        , HH.div [ cls [ "divide-y divide-border" ] ]
            [ buildRow "api-docs" "main" "success" "2 min ago" "247 refs"
            , buildRow "sdk-reference" "v2.1.0" "success" "15 min ago" "1,203 refs"
            , buildRow "internal-docs" "feature/auth" "failed" "32 min ago" "3 broken"
            , buildRow "api-docs" "main" "success" "1 hour ago" "247 refs"
            , buildRow "guides" "main" "success" "2 hours ago" "89 refs"
            ]
        ]
    ]

referencesTab :: forall w i. HH.HTML w i
referencesTab = HH.div_
    [ HH.div [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-4 mb-6" ] ]
        [ statCard "Total References" "12,847" "across all projects"
        , statCard "Resolution Rate" "100%" "all refs resolve"
        , statCard "Cross-Language" "342" "cross-lang refs"
        ]
    , HH.div [ cls [ "bg-card border border-border rounded-lg" ] ]
        [ HH.div [ cls [ "p-4 border-b border-border" ] ]
            [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Reference Status by Project" ] ]
        , HH.div [ cls [ "divide-y divide-border" ] ]
            [ refProjectRow "api-docs" 3247 3247 0
            , refProjectRow "sdk-reference" 8156 8156 0
            , refProjectRow "internal-docs" 1444 1441 3
            ]
        ]
    ]

projectsTab :: forall w i. HH.HTML w i
projectsTab = HH.div_
    [ HH.div [ cls [ "flex justify-between items-center mb-6" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Projects" ]
        , HH.button [ cls [ "px-4 py-2 bg-teal-400 text-background rounded-md text-sm font-medium hover:bg-teal-400/90 transition-colors" ] ]
            [ HH.text "New Project" ]
        ]
    , HH.div [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4" ] ]
        [ projectCard "api-docs" "Rust, TypeScript" "2 min ago"
        , projectCard "sdk-reference" "Rust" "15 min ago"
        , projectCard "internal-docs" "TypeScript, Python" "32 min ago"
        , projectCard "guides" "Markdown" "2 hours ago"
        ]
    ]

statCard :: forall w i. String -> String -> String -> HH.HTML w i
statCard label value subtitle = HH.div [ cls [ "bg-card border border-border rounded-lg p-4" ] ]
    [ HH.p [ cls [ "text-sm text-muted-foreground mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-2xl font-bold text-text" ] ] [ HH.text value ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text subtitle ] ]

recentBuildsCard :: forall w i. HH.HTML w i
recentBuildsCard = HH.div [ cls [ "bg-card border border-border rounded-lg" ] ]
    [ HH.div [ cls [ "p-4 border-b border-border" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Recent Builds" ] ]
    , HH.div [ cls [ "divide-y divide-border" ] ]
        [ buildRow "api-docs" "main" "success" "2 min ago" "247 refs"
        , buildRow "sdk-reference" "v2.1.0" "success" "15 min ago" "1,203 refs"
        , buildRow "internal-docs" "feature/auth" "failed" "32 min ago" "3 broken"
        ]
    ]

referenceHealthCard :: forall w i. HH.HTML w i
referenceHealthCard = HH.div [ cls [ "bg-card border border-border rounded-lg" ] ]
    [ HH.div [ cls [ "p-4 border-b border-border" ] ]
        [ HH.h3 [ cls [ "text-lg font-semibold text-text" ] ] [ HH.text "Reference Health" ] ]
    , HH.div [ cls [ "p-4 space-y-4" ] ]
        [ refHealthRow "api-docs" 100
        , refHealthRow "sdk-reference" 100
        , refHealthRow "internal-docs" 97
        , refHealthRow "guides" 100
        ]
    ]

buildRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
buildRow project branch status time refs = HH.div [ cls [ "p-4 flex items-center justify-between" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text project ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text branch ]
        ]
    , HH.div [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text refs ]
        , HH.span [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text time ]
        , HH.span [ cls [ "px-2 py-1 rounded text-xs font-medium"
              , if status == "success" then "bg-green-400/10 text-green-400" else "bg-red-400/10 text-red-400" ] ]
            [ HH.text status ]
        ]
    ]

refHealthRow :: forall w i. String -> Int -> HH.HTML w i
refHealthRow project pct = HH.div_
    [ HH.div [ cls [ "flex justify-between text-sm mb-1" ] ]
        [ HH.span [ cls [ "text-text" ] ] [ HH.text project ]
        , HH.span [ cls [ if pct == 100 then "text-green-400" else "text-yellow-400" ] ] 
            [ HH.text (show pct <> "%") ]
        ]
    , HH.div [ cls [ "h-2 bg-muted rounded-full overflow-hidden" ] ]
        [ HH.div [ cls [ "h-full rounded-full", if pct == 100 then "bg-green-400" else "bg-yellow-400" ]
                 , HP.style ("width: " <> show pct <> "%") ] [] ]
    ]

refProjectRow :: forall w i. String -> Int -> Int -> Int -> HH.HTML w i
refProjectRow project total resolved broken = HH.div [ cls [ "p-4 flex items-center justify-between" ] ]
    [ HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text project ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text (show total <> " total references") ]
        ]
    , HH.div [ cls [ "flex items-center gap-4" ] ]
        [ HH.span [ cls [ "text-sm text-green-400" ] ] [ HH.text (show resolved <> " resolved") ]
        , if broken > 0
            then HH.span [ cls [ "text-sm text-red-400" ] ] [ HH.text (show broken <> " broken") ]
            else HH.text ""
        ]
    ]

projectCard :: forall w i. String -> String -> String -> HH.HTML w i
projectCard name langs lastBuild = HH.div [ cls [ "bg-card border border-border rounded-lg p-4 hover:border-teal-400/50 transition-colors" ] ]
    [ HH.h4 [ cls [ "text-text font-medium mb-2" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-sm text-muted-foreground mb-3" ] ] [ HH.text langs ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text ("Last build: " <> lastBuild) ]
    ]
