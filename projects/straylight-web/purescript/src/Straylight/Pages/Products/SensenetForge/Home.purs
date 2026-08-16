-- | sensenet//forge Home Page
-- | Code hosting + review. Stacked diffs, not PRs. jujutsu first-class. Agent-era design.
module Straylight.Pages.Products.SensenetForge.Home 
  ( homePage
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
    , features
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-rose-400/10 border border-rose-400/20 rounded-full text-rose-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-rose-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
          
          -- Headline
        , HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Code review for"
            , HH.br_
            , HH.text "the "
            , HH.span [ cls [ "text-rose-400" ] ] [ HH.text "agent era" ]
            ]
          
          -- Subheadline
        , HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Stacked diffs, not PRs. jujutsu first-class. Agent-native review workflows. Attestation-backed merge. Built for teams shipping with AI." ]
          
          -- CTAs
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/forge/pricing" "Get started"
            , secondaryButton "/sensenet/forge/docs" "Read the docs"
            ]
          
          -- Install options
        , HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-3" ] ]
            [ HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "curl -fsSL forge.sensenet.dev | sh"
                    ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:sensenet/forge"
                    ]
                ]
            ]
          
          -- Social proof
        , HH.p
            [ cls [ "mt-12 text-sm text-muted-foreground" ] ]
            [ HH.text "Replaces GitHub, Gerrit, Phabricator" ]
        ]
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
                [ HH.text "Why sensenet//forge?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built for teams who ship fast with AI agents and want review workflows that don't fight them." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "||" "Stacked diffs" 
                "Review changes in logical units, not massive PRs. Dependent changes stack cleanly. Rebase propagates automatically."
            , featureCard "@" "jujutsu native"
                "First-class jj support. Anonymous branches. Operation log. Conflict-free rebasing. Git compatibility when you need it."
            , featureCard "[]" "Agent-aware review"
                "AI-generated changes get dedicated review flows. Attestation shows provenance. Humans review intent, not boilerplate."
            , featureCard "~" "Attestation"
                "Every commit cryptographically signed. Agent identity verified. Post-quantum signatures. Audit trail from prompt to production."
            , featureCard "?" "Semantic code search"
                "Search by meaning, not just text. Find all error handlers. Locate similar patterns. Understand impact before merge."
            , featureCard "/" "Branch-free workflow"
                "No feature branches to manage. Work directly on changes. Stack, split, squash without ceremony. Ship when ready."
            ]
        ]
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
                [ HH.text "Code review that scales" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others force you into PR-shaped boxes. We built review workflows for how modern teams actually ship." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-rose-400 font-bold" ] ] [ HH.text "sensenet//forge" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "GitHub" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Gerrit" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "GitLab" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Review model" "Stacked diffs" "PRs" "Patchsets" "MRs"
                    , comparisonRow "jujutsu support" "Native" "no" "no" "no"
                    , comparisonRow "Agent provenance" "Attestation" "no" "no" "no"
                    , comparisonRow "Semantic search" "Built-in" "no" "no" "no"
                    , comparisonRow "Stack rebasing" "Automatic" "manual" "manual" "manual"
                    , comparisonRow "Self-hosted" "Yes" "Enterprise" "Yes" "Yes"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Feature comparison as of 2026." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us github gerrit gitlab =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-rose-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell github ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell gerrit ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell gitlab ]
    ]

compCell :: forall w i. String -> HH.HTML w i
compCell value =
  HH.span
    [ cls [ case value of
              "no" -> "text-muted-foreground/50"
              _ -> "text-muted-foreground"
          ]
    ]
    [ HH.text value ]

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
                [ HH.text "Get started in 30 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Install the CLI"
            , codeLine "$ " "nix run github:sensenet/forge -- init"
            , HH.text "\n"
            , codeLine "# " "Create a stacked diff"
            , codeLine "$ " "jj new -m 'Add feature X'"
            , codeLine "$ " "forge diff create"
            , HH.text "\n"
            , codeLine "# " "Stack another change"
            , codeLine "$ " "jj new -m 'Add feature Y'"
            , codeLine "$ " "forge diff create"
            , HH.text "\n"
            , codeLine "# " "Submit for review"
            , codeLine "$ " "forge stack submit"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/forge/docs"
                , cls [ "text-rose-400 hover:text-rose-400/80 transition-colors" ]
                ]
                [ HH.text "Full quickstart guide ->" ]
            ]
        ]
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
            [ HH.text "Ready to ship faster?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Free tier includes unlimited public repos. No credit card required." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/forge/dashboard" "Create free account"
            , secondaryButton "/sensenet/forge/pricing" "See all plans"
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-rose-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-rose-400 mb-4 font-mono" ] ]
        [ HH.text icon ]
    , HH.h3
        [ cls [ "text-text text-lg font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]

primaryButton :: forall w i. String -> String -> HH.HTML w i
primaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-8 py-4 bg-rose-400 text-background font-medium rounded-md hover:bg-rose-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
