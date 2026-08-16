-- | sensenet//forge Features Page
-- | Code hosting + review. Stacked diffs, not PRs. jujutsu first-class. Agent-era design.
module Straylight.Pages.Products.SensenetForge.Features 
  ( featuresPage
  , render
  ) where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

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
    , stackedDiffs
    , jujutsuNative
    , agentReview
    , attestation
    , semanticSearch
    , developer
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
            [ HH.text "Code review,"
            , HH.br_
            , HH.text "reimagined"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Stacked diffs. jujutsu native. Agent-aware review. Cryptographic attestation. Built for how teams actually ship software." ]
        ]
    ]

-- ============================================================
-- STACKED DIFFS
-- ============================================================

stackedDiffs :: forall w i. HH.HTML w i
stackedDiffs =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Stacked Diffs"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Review changes, not branches" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "PRs force you to review massive changesets or manage complex branch hierarchies. Stacked diffs let you review logical units — each change builds on the last, and rebasing propagates automatically." ]
                , featureList
                    [ "Review small, focused changes"
                    , "Dependent changes stack cleanly"
                    , "Automatic rebase propagation"
                    , "Land any change in the stack"
                    , "No branch management overhead"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-3" ] ]
                    [ stackItem "3" "Add error handling" "Ready to land" true
                    , stackItem "2" "Implement feature X" "Approved" true
                    , stackItem "1" "Refactor utils" "Landed" false
                    ]
                ]
            ]
        ]
    ]

stackItem :: forall w i. String -> String -> String -> Boolean -> HH.HTML w i
stackItem num title status active =
  HH.div
    [ cls [ "flex items-center gap-4 p-3 rounded-lg"
          , if active then "bg-rose-400/10 border border-rose-400/20" else "bg-muted/30"
          ]
    ]
    [ HH.span
        [ cls [ "w-8 h-8 rounded-full flex items-center justify-center text-sm font-mono"
              , if active then "bg-rose-400 text-background" else "bg-muted text-muted-foreground"
              ]
        ]
        [ HH.text num ]
    , HH.div [ cls [ "flex-1" ] ]
        [ HH.p [ cls [ "text-text text-sm font-medium" ] ] [ HH.text title ]
        , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text status ]
        ]
    ]

-- ============================================================
-- JUJUTSU NATIVE
-- ============================================================

jujutsuNative :: forall w i. HH.HTML w i
jujutsuNative =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual (code)
              HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ codeBlock
                    [ codeLine "# " "Work on a change"
                    , codeLine "$ " "jj new -m 'Add user authentication'"
                    , HH.text "\n"
                    , codeLine "# " "Stack another change"
                    , codeLine "$ " "jj new -m 'Add OAuth providers'"
                    , HH.text "\n"
                    , codeLine "# " "Submit the stack"
                    , codeLine "$ " "forge stack submit"
                    , HH.text "\n"
                    , codeLine "# " "Rebase entire stack"
                    , codeLine "$ " "jj rebase -d main"
                    , codeLine "" "Automatically rebased 2 changes"
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "jujutsu Native"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "First-class jj support" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "jujutsu is the future of version control. Anonymous branches, operation log, conflict-free rebasing. We built forge around jj from day one — not bolted on as an afterthought." ]
                , featureList
                    [ "Anonymous branches by default"
                    , "Operation log for time travel"
                    , "Conflict-free rebasing"
                    , "Git compatibility layer"
                    , "Native working copy management"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- AGENT REVIEW
-- ============================================================

agentReview :: forall w i. HH.HTML w i
agentReview =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Agent-Aware Review"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Review intent, not boilerplate" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "AI agents generate code differently than humans. They're consistent, verbose, and follow patterns exactly. Our review UI adapts — showing you the intent and letting you focus on what matters." ]
                , featureList
                    [ "Dedicated agent review workflows"
                    , "Intent summary from prompts"
                    , "Diff compression for generated code"
                    , "Pattern verification"
                    , "Human-in-the-loop approval"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg overflow-hidden" ] ]
                [ HH.div
                    [ cls [ "p-4 border-b border-border bg-muted/30" ] ]
                    [ HH.div
                        [ cls [ "flex items-center gap-2" ] ]
                        [ HH.span [ cls [ "text-xs px-2 py-0.5 rounded bg-rose-400/20 text-rose-400" ] ] [ HH.text "Agent" ]
                        , HH.span [ cls [ "text-sm text-text" ] ] [ HH.text "claude-opus-4" ]
                        ]
                    ]
                , HH.div
                    [ cls [ "p-4 space-y-3" ] ]
                    [ HH.div_
                        [ HH.p [ cls [ "text-xs text-muted-foreground mb-1" ] ] [ HH.text "Intent" ]
                        , HH.p [ cls [ "text-sm text-text" ] ] [ HH.text "Add rate limiting to API endpoints" ]
                        ]
                    , HH.div_
                        [ HH.p [ cls [ "text-xs text-muted-foreground mb-1" ] ] [ HH.text "Changes" ]
                        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text "12 files, 847 lines (compressed view)" ]
                        ]
                    , HH.div_
                        [ HH.p [ cls [ "text-xs text-muted-foreground mb-1" ] ] [ HH.text "Attestation" ]
                        , HH.p [ cls [ "text-sm font-mono text-green-400" ] ] [ HH.text "Verified" ]
                        ]
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- ATTESTATION
-- ============================================================

attestation :: forall w i. HH.HTML w i
attestation =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual
              HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ HH.div
                    [ cls [ "grid grid-cols-2 gap-4" ] ]
                    [ trustBadge "PQ-Sig" "Post-Quantum"
                    , trustBadge "SLSA" "Level 3"
                    , trustBadge "SBOM" "Auto-generated"
                    , trustBadge "Provenance" "Verified"
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Attestation"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Cryptographic proof of origin" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Every commit is cryptographically signed with verified identity. Agent commits include provenance — which model, which prompt, which version. Audit trail from intent to production." ]
                , featureList
                    [ "Ed25519 and post-quantum signatures"
                    , "Agent identity verification"
                    , "SLSA Level 3 compliance"
                    , "Auto-generated SBOMs"
                    , "Tamper-evident audit log"
                    ]
                ]
            ]
        ]
    ]

trustBadge :: forall w i. String -> String -> HH.HTML w i
trustBadge title subtitle =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center" ] ]
    [ HH.p [ cls [ "text-2xl font-bold text-rose-400 mb-1" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text subtitle ]
    ]

-- ============================================================
-- SEMANTIC SEARCH
-- ============================================================

semanticSearch :: forall w i. HH.HTML w i
semanticSearch =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Semantic Search"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Search by meaning" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Find code by what it does, not what it's called. Search for 'all error handlers' or 'database queries that might be slow'. Understand impact before you merge." ]
                , featureList
                    [ "Natural language queries"
                    , "Semantic code understanding"
                    , "Impact analysis"
                    , "Similar pattern detection"
                    , "Cross-repo search"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg overflow-hidden" ] ]
                [ HH.div
                    [ cls [ "p-4 border-b border-border" ] ]
                    [ HH.div
                        [ cls [ "flex items-center gap-3 bg-background border border-border rounded-md px-4 py-2" ] ]
                        [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text ">" ]
                        , HH.span [ cls [ "text-text" ] ] [ HH.text "functions that handle auth" ]
                        ]
                    ]
                , HH.div
                    [ cls [ "divide-y divide-border" ] ]
                    [ searchResult "validateToken" "src/auth/jwt.rs" "94%"
                    , searchResult "checkPermissions" "src/auth/rbac.rs" "91%"
                    , searchResult "refreshSession" "src/auth/session.rs" "87%"
                    ]
                ]
            ]
        ]
    ]

searchResult :: forall w i. String -> String -> String -> HH.HTML w i
searchResult name file score =
  HH.div
    [ cls [ "p-4 hover:bg-muted/50 transition-colors" ] ]
    [ HH.div
        [ cls [ "flex items-center justify-between" ] ]
        [ HH.div_
            [ HH.span [ cls [ "text-text font-medium font-mono" ] ] [ HH.text name ]
            , HH.span [ cls [ "text-muted-foreground text-sm ml-2" ] ] [ HH.text file ]
            ]
        , HH.span [ cls [ "text-xs text-rose-400" ] ] [ HH.text $ score <> " match" ]
        ]
    ]

-- ============================================================
-- DEVELOPER EXPERIENCE
-- ============================================================

developer :: forall w i. HH.HTML w i
developer =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Developer Experience"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Built for speed" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Every interaction optimized for developer velocity." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ dxCard ">" "CLI-first" 
                "Everything you need from the terminal. Keyboard shortcuts. Pipe-friendly output."
            , dxCard "{}" "REST + GraphQL API"
                "Full API access for automation. Build your own integrations."
            , dxCard "!" "Real-time updates"
                "Review comments, CI status, merge conflicts — all streamed live."
            , dxCard "=" "Offline mode"
                "Work without network. Sync when you're back online."
            , dxCard "++" "Editor integrations"
                "VS Code, Neovim, Emacs, JetBrains. Review diffs without leaving your editor."
            , dxCard "$" "Self-hostable"
                "Run on your infrastructure. Air-gapped deployments supported."
            ]
        ]
    ]

dxCard :: forall w i. String -> String -> String -> HH.HTML w i
dxCard icon title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 hover:border-rose-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3 mb-3" ] ]
        [ HH.span [ cls [ "text-rose-400 font-mono text-xl" ] ] [ HH.text icon ]
        , HH.h3 [ cls [ "text-text font-semibold" ] ] [ HH.text title ]
        ]
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
            [ HH.text "Ready to modernize code review?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Free for open source. Start shipping faster today." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/sensenet/forge/dashboard"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-rose-400 text-background font-medium rounded-md hover:bg-rose-400/90 transition-colors" ]
                ]
                [ HH.text "Get started free" ]
            , HH.a
                [ HP.href "/sensenet/forge/docs"
                , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
                ]
                [ HH.text "Read the docs" ]
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

badge :: forall w i. String -> HH.HTML w i
badge label =
  HH.span
    [ cls [ "inline-block px-3 py-1 bg-rose-400/10 border border-rose-400/20 rounded-full text-rose-400 text-sm font-medium mb-4" ] ]
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
    [ HH.span [ cls [ "text-rose-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
