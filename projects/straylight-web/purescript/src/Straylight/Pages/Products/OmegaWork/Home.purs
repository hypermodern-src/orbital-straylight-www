-- | omega//work Landing Page
-- | Desktop AI for Teams - Electron app for non-coders with team collaboration
module Straylight.Pages.Products.OmegaWork.Home 
  ( homePage
  , render
  ) where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

-- ============================================================
-- COMPONENT
-- ============================================================

homePage :: forall q i o m. H.Component q i o m
homePage = H.mkComponent
  { initialState: const unit
  , render: const render
  , eval: H.mkEval H.defaultEval
  }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall w i. HH.HTML w i
render =
  HH.div_
    [ hero
    , audience
    , features
    , teamFeatures
    , comparison
    , quickstart
    , cta
    ]

-- ============================================================
-- HERO
-- ============================================================

hero :: forall w i. HH.HTML w i
hero =
  HH.section
    [ cls [ "py-24 md:py-32" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6 text-center" ] ]
        [ -- Badge
          HH.div
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-indigo-400/10 border border-indigo-400/20 rounded-full text-indigo-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-indigo-400 rounded-full animate-pulse" ] ] []
            , HH.text "Desktop AI for Teams"
            ]
          
          -- Headline
        , HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "AI assistance for"
            , HH.br_
            , HH.span [ cls [ "text-indigo-400" ] ] [ HH.text "everyone" ]
            , HH.text " on your team"
            ]
          
          -- Subheadline
        , HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "omega//work brings enterprise-grade AI to PMs, designers, analysts, and ops teams. Same powerful engine as omega//code, wrapped in a beautiful desktop app your whole team can use." ]
          
          -- CTAs
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/omega/work/pricing" "Start free trial"
            , secondaryButton "/omega/work/features" "See how it works"
            ]
          
          -- Platform badges
        , HH.div
            [ cls [ "mt-12 flex items-center justify-center gap-6 text-muted-foreground text-sm" ] ]
            [ platformBadge "macOS"
            , platformBadge "Windows"
            , platformBadge "Linux"
            ]
          
          -- Social proof
        , HH.p
            [ cls [ "mt-8 text-sm text-muted-foreground" ] ]
            [ HH.text "Replaces ChatGPT desktop and Claude desktop for teams" ]
        ]
    ]

platformBadge :: forall w i. String -> HH.HTML w i
platformBadge platform =
  HH.span
    [ cls [ "flex items-center gap-2" ] ]
    [ HH.span [ cls [ "w-1.5 h-1.5 bg-indigo-400/50 rounded-full" ] ] []
    , HH.text platform
    ]

-- ============================================================
-- AUDIENCE
-- ============================================================

audience :: forall w i. HH.HTML w i
audience =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Built for the rest of your team" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Not everyone codes. omega//work gives every team member access to AI assistance." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-6" ] ]
            [ audienceCard "Product Managers" "Write PRDs, analyze feedback, plan roadmaps"
            , audienceCard "Designers" "Generate copy, document systems, iterate faster"
            , audienceCard "Analysts" "Query data, build reports, automate workflows"
            , audienceCard "Operations" "Draft processes, manage docs, streamline tasks"
            ]
        ]
    ]

audienceCard :: forall w i. String -> String -> HH.HTML w i
audienceCard title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg text-center hover:border-indigo-400/30 transition-colors" ] ]
    [ HH.h3
        [ cls [ "text-text font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- FEATURES
-- ============================================================

features :: forall w i. HH.HTML w i
features =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Why omega//work?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "A friendly interface backed by serious AI. No terminal, no learning curve." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard ">" "Point-and-click interface"
                "Drag files, click to share context, visual previews. Designed for how you already work."
            , featureCard "{}" "Same powerful engine"
                "Powered by the same SIGIL protocol as omega//code. Battle-tested reliability, now in a GUI."
            , featureCard "!" "Native desktop app"
                "Electron + Rust core. Fast, responsive, works offline. No browser tabs required."
            , featureCard "++" "Team workspaces"
                "Shared spaces for your team. Collaborate on conversations, share context, work together."
            , featureCard "=" "Shared conversation history"
                "Find what your team has already solved. Search across all team conversations."
            , featureCard "$" "Enterprise integrations"
                "Connect Slack, Notion, Google Workspace. AI that fits into your existing tools."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-indigo-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-indigo-400 mb-4 font-mono" ] ]
        [ HH.text icon ]
    , HH.h3
        [ cls [ "text-text text-lg font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- TEAM FEATURES
-- ============================================================

teamFeatures :: forall w i. HH.HTML w i
teamFeatures =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ HH.span
                    [ cls [ "inline-block px-3 py-1 bg-indigo-400/10 border border-indigo-400/20 rounded-full text-indigo-400 text-sm font-medium mb-4" ] ]
                    [ HH.text "Team Collaboration" ]
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Work together, not in silos" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "omega//work is built for teams from day one. Share workspaces, learn from each other's conversations, and build collective knowledge." ]
                , HH.ul
                    [ cls [ "space-y-3" ] ]
                    [ teamFeatureItem "Shared workspaces for projects and teams"
                    , teamFeatureItem "Conversation history visible to team members"
                    , teamFeatureItem "Role-based permissions and access control"
                    , teamFeatureItem "Usage analytics and admin dashboard"
                    , teamFeatureItem "SSO/SAML for enterprise security"
                    ]
                ]
              -- Right: visual placeholder
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6 aspect-video flex items-center justify-center" ] ]
                [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "[Team Workspace Preview]" ] ]
            ]
        ]
    ]

teamFeatureItem :: forall w i. String -> HH.HTML w i
teamFeatureItem text =
  HH.li
    [ cls [ "flex items-start gap-3" ] ]
    [ HH.span [ cls [ "text-indigo-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

-- ============================================================
-- COMPARISON
-- ============================================================

comparison :: forall w i. HH.HTML w i
comparison =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "omega//work vs alternatives" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Built for teams who need more than a chat interface." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[600px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-indigo-400 font-bold" ] ] [ HH.text "omega//work" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "ChatGPT / Claude" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Team workspaces" "Built-in" "Not available"
                    , comparisonRow "Shared history" "Yes, searchable" "Individual only"
                    , comparisonRow "File handling" "Visual, drag-drop" "Upload only"
                    , comparisonRow "SSO/SAML" "Included" "Enterprise add-on"
                    , comparisonRow "Admin controls" "Full dashboard" "Limited"
                    , comparisonRow "Integrations" "Slack, Notion, more" "Limited"
                    , comparisonRow "Agent engine" "SIGIL (proven)" "Proprietary"
                    , comparisonRow "Platforms" "macOS, Windows, Linux" "Varies"
                    ]
                ]
            ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> HH.HTML w i
comparisonRow feature work other =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-indigo-400 font-semibold" ] ] [ HH.text work ]
    , HH.td [ cls [ "py-3 text-center text-muted-foreground" ] ] [ HH.text other ]
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstart :: forall w i. HH.HTML w i
quickstart =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-12" ] ]
            [ HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Get your team started in minutes" ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-8" ] ]
            [ stepCard "1" "Download" "Get the app for macOS, Windows, or Linux. One installer, no dependencies."
            , stepCard "2" "Create team" "Set up your team workspace and invite members. SSO available for enterprise."
            , stepCard "3" "Start working" "Share context, collaborate on conversations, get things done together."
            ]
        , HH.div
            [ cls [ "mt-12 text-center" ] ]
            [ HH.a
                [ HP.href "/omega/work/docs"
                , cls [ "text-indigo-400 hover:text-indigo-400/80 transition-colors" ]
                ]
                [ HH.text "Read the documentation ->" ]
            ]
        ]
    ]

stepCard :: forall w i. String -> String -> String -> HH.HTML w i
stepCard number title description =
  HH.div
    [ cls [ "text-center" ] ]
    [ HH.div
        [ cls [ "w-10 h-10 rounded-full bg-indigo-400/10 border border-indigo-400/20 text-indigo-400 font-bold flex items-center justify-center mx-auto mb-4" ] ]
        [ HH.text number ]
    , HH.h3
        [ cls [ "text-text font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- CTA
-- ============================================================

cta :: forall w i. HH.HTML w i
cta =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[800px] mx-auto px-6 text-center" ] ]
        [ HH.h2
            [ cls [ "text-3xl font-bold text-text mb-4" ] ]
            [ HH.text "Ready to empower your whole team?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Start with a free trial. No credit card required. Upgrade when you're ready." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/omega/work/pricing" "Start free trial"
            , secondaryButton "/omega/work/pricing" "See pricing"
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

primaryButton :: forall w i. String -> String -> HH.HTML w i
primaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-indigo-400 text-background font-medium rounded-md hover:bg-indigo-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
