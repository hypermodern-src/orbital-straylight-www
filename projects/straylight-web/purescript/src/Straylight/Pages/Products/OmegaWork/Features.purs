-- | omega//work Features Page
-- | Desktop AI for Teams - GUI, workspaces, integrations, file handling
module Straylight.Pages.Products.OmegaWork.Features 
  ( featuresPage
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

featuresPage :: forall q i o m. H.Component q i o m
featuresPage = H.mkComponent
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
    , visualInterface
    , teamWorkspaces
    , sharedContexts
    , fileHandling
    , integrations
    , security
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
        [ HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Powerful AI,"
            , HH.br_
            , HH.text "friendly interface"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "omega//work brings enterprise AI to every team member. The same reliable engine developers trust, wrapped in an interface anyone can use." ]
        ]
    ]

-- ============================================================
-- VISUAL INTERFACE
-- ============================================================

visualInterface :: forall w i. HH.HTML w i
visualInterface =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "GUI Interface"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Point, click, done" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "No command line, no learning curve. omega//work is designed for PMs, designers, analysts, and ops teams who want AI assistance without becoming developers." ]
                , featureList
                    [ "Intuitive drag-and-drop interface"
                    , "Visual file browser with preview"
                    , "Rich text formatting in conversations"
                    , "One-click actions for common tasks"
                    , "Dark and light theme support"
                    ]
                ]
              -- Right: visual placeholder
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6 aspect-video flex items-center justify-center" ] ]
                [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "[Interface Preview]" ] ]
            ]
        ]
    ]

-- ============================================================
-- TEAM WORKSPACES
-- ============================================================

teamWorkspaces :: forall w i. HH.HTML w i
teamWorkspaces =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual
              HH.div
                [ cls [ "order-2 lg:order-1 bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-4" ] ]
                    [ workspaceStat "Marketing" "12 members" "Active"
                    , workspaceStat "Product" "8 members" "Active"
                    , workspaceStat "Design" "5 members" "Active"
                    , workspaceStat "Operations" "6 members" "Active"
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Team Workspaces"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Organize by team" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Create workspaces for each team or project. Keep conversations organized, control access, and let teams work independently while sharing what matters." ]
                , featureList
                    [ "Unlimited workspaces per organization"
                    , "Role-based access control"
                    , "Per-workspace settings and defaults"
                    , "Cross-workspace search for admins"
                    , "Workspace templates for quick setup"
                    ]
                ]
            ]
        ]
    ]

workspaceStat :: forall w i. String -> String -> String -> HH.HTML w i
workspaceStat name members status =
  HH.div
    [ cls [ "flex items-center justify-between py-3 border-b border-border last:border-0" ] ]
    [ HH.div_
        [ HH.span [ cls [ "text-text font-medium" ] ] [ HH.text name ]
        , HH.span [ cls [ "text-muted-foreground text-sm ml-2" ] ] [ HH.text members ]
        ]
    , HH.span [ cls [ "text-indigo-400 text-sm font-medium" ] ] [ HH.text status ]
    ]

-- ============================================================
-- SHARED CONTEXTS
-- ============================================================

sharedContexts :: forall w i. HH.HTML w i
sharedContexts =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Shared Contexts"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Learn from each other" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Conversations are searchable and shareable. Find what your team has already solved, build on past work, and avoid repeating questions." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
            [ projectCard ">" "Shared history" 
                "Every conversation is saved and searchable. Find answers from past team interactions."
            , projectCard "{}" "Context inheritance"
                "Start new conversations with shared context. No need to re-explain your project."
            , projectCard "!" "Conversation sharing"
                "Share specific conversations with team members or make them available to everyone."
            ]
        ]
    ]

projectCard :: forall w i. String -> String -> String -> HH.HTML w i
projectCard icon title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 hover:border-indigo-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3 mb-3" ] ]
        [ HH.span [ cls [ "text-indigo-400 font-mono text-xl" ] ] [ HH.text icon ]
        , HH.h3 [ cls [ "text-text font-semibold" ] ] [ HH.text title ]
        ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

-- ============================================================
-- FILE HANDLING
-- ============================================================

fileHandling :: forall w i. HH.HTML w i
fileHandling =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "File Handling"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Work with any file" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Drag documents, spreadsheets, images, and more into conversations. omega//work understands context from your files and can help you work with them." ]
                , featureList
                    [ "Drag-and-drop from desktop or Finder"
                    , "Preview files inline in conversations"
                    , "Extract data from PDFs and images"
                    , "Edit documents with AI assistance"
                    , "Export results in multiple formats"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-3" ] ]
                    [ fileTypeRow ".docx" "Word documents"
                    , fileTypeRow ".xlsx" "Spreadsheets"
                    , fileTypeRow ".pdf" "PDF documents"
                    , fileTypeRow ".png/.jpg" "Images"
                    , fileTypeRow ".md" "Markdown files"
                    , fileTypeRow ".csv" "Data files"
                    ]
                ]
            ]
        ]
    ]

fileTypeRow :: forall w i. String -> String -> HH.HTML w i
fileTypeRow ext description =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "text-indigo-400 font-mono text-sm" ] ] [ HH.text ext ]
    , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text description ]
    ]

-- ============================================================
-- INTEGRATIONS
-- ============================================================

integrations :: forall w i. HH.HTML w i
integrations =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Integrations"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Connect your tools" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "omega//work integrates with the tools your team already uses. Pull in context from anywhere, push results where they belong." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ integrationCard "Slack" "Share to channels"
            , integrationCard "Notion" "Sync documents"
            , integrationCard "Google Workspace" "Drive & Docs"
            , integrationCard "Linear" "Create issues"
            , integrationCard "Figma" "Export designs"
            , integrationCard "Confluence" "Wiki integration"
            , integrationCard "Jira" "Track work"
            , integrationCard "GitHub" "Access repos"
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-sm mt-8" ] ]
            [ HH.text "More integrations coming soon. Request yours in Settings." ]
        ]
    ]

integrationCard :: forall w i. String -> String -> HH.HTML w i
integrationCard name description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4 text-center hover:border-indigo-400/30 transition-colors" ] ]
    [ HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text description ]
    ]

-- ============================================================
-- SECURITY
-- ============================================================

security :: forall w i. HH.HTML w i
security =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Enterprise Security"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Built for enterprise" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "omega//work meets the security requirements of modern enterprises. SSO, audit logs, and compliance features built-in." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-4" ] ]
            [ securityBadge "SSO/SAML" "Enterprise identity"
            , securityBadge "SOC 2 Type II" "Compliance ready"
            , securityBadge "E2E encryption" "Data in transit"
            , securityBadge "Audit logs" "Full visibility"
            ]
        ]
    ]

securityBadge :: forall w i. String -> String -> HH.HTML w i
securityBadge title subtitle =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4 text-center" ] ]
    [ HH.p [ cls [ "text-indigo-400 font-semibold mb-1" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text subtitle ]
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
            [ HH.text "Ready to empower your team?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Start with a free trial for individuals, or contact us for team pricing." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/omega/work/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-indigo-400 text-background font-medium rounded-md hover:bg-indigo-400/90 transition-colors" ]
                ]
                [ HH.text "Start free trial" ]
            , HH.a
                [ HP.href "/omega/work/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
                ]
                [ HH.text "View pricing" ]
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

badge :: forall w i. String -> HH.HTML w i
badge label =
  HH.span
    [ cls [ "inline-block px-3 py-1 bg-indigo-400/10 border border-indigo-400/20 rounded-full text-indigo-400 text-sm font-medium mb-4" ] ]
    [ HH.text label ]

featureList :: forall w i. Array String -> HH.HTML w i
featureList items =
  HH.ul
    [ cls [ "space-y-3" ] ]
    (map featureItem items)

featureItem :: forall w i. String -> HH.HTML w i
featureItem text =
  HH.li
    [ cls [ "flex items-start gap-3" ] ]
    [ HH.span [ cls [ "text-indigo-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]
