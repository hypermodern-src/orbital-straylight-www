-- | omega//work Product Page
-- | Desktop AI Coding Agent for Teams
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.OmegaWork where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

omegaWorkPage :: forall q i o m. H.Component q i o m
omegaWorkPage = H.mkComponent
  { initialState: const unit
  , render: const render
  , eval: H.mkEval H.defaultEval
  }

-- ============================================================
-- RENDER (armory shape)
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-green-400/10 border border-green-400/20 rounded-full text-green-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-green-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "AI coding agent"
            , HH.br_
            , HH.text "built for "
            , HH.span [ cls [ "text-green-400" ] ] [ HH.text "teams" ]
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Native desktop app. Shared sessions. Visual diffs. Same evring core, SIGIL protocol, Lean4 proofs. Finally, an AI coding agent your whole team can use together." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/waitlist" "Request team access"
            , secondaryButton "/docs/work" "View documentation"
            ]
        , -- Download options
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-3" ] ]
            [ HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.span
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.text "Download for macOS" ]
                , HH.span
                    [ cls [ "text-green-400 text-xs shrink-0" ] ]
                    [ HH.text "Apple Silicon" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.span
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.text "Download for Linux" ]
                , HH.span
                    [ cls [ "text-green-400 text-xs shrink-0" ] ]
                    [ HH.text "x86_64 / ARM64" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-green-400/60" ] ] [ HH.text "replaces " ]
            , HH.text "VS Code Copilot, JetBrains AI, GitHub Copilot Workspace"
            ]
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
                [ HH.text "Why omega//work?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "The same proven omega core, wrapped in a native desktop experience designed for team collaboration." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "⎔" "Native desktop"
                "Not Electron. Native GPU-accelerated UI. Visual diff views, project navigation, integrated terminal. Sub-millisecond response."
            , featureCard "⇄" "Shared sessions"
                "Multiple engineers on one session. See teammate cursors and selections in real-time. Hand off context seamlessly."
            , featureCard "⊕" "Team context"
                "Shared knowledge base across your org. Institutional memory that persists across projects and team members."
            , featureCard "⊙" "Audit logs"
                "Complete history of every AI action. Who prompted what, which files changed, full attestation chain. Compliance-ready."
            , featureCard "⟠" "SSO & RBAC"
                "SAML, OIDC, Okta, Azure AD. Role-based permissions. Control who can approve AI changes to production code."
            , featureCard "⬡" "On-prem deploy"
                "Air-gapped deployment. Your models, your infrastructure. No code leaves your network. SOC2 Type II ready."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-green-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-green-400 mb-4 font-mono" ] ]
        [ HH.text icon ]
    , HH.h3
        [ cls [ "text-text text-lg font-semibold mb-2" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
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
                [ HH.text "Built for teams, not individuals" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Other tools bolt on \"collaboration\" as an afterthought. omega//work was designed from day one for multi-engineer workflows." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-green-400 font-bold" ] ] [ HH.text "omega//work" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "VS Code Copilot" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "JetBrains AI" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Copilot Workspace" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Runtime" "Native binary" "Electron" "JVM + Electron" "Web"
                    , comparisonRow "Shared sessions" "real-time" "no" "no" "async only"
                    , comparisonRow "Team context" "persistent" "no" "no" "limited"
                    , comparisonRow "Audit logs" "full chain" "no" "no" "basic"
                    , comparisonRow "SSO/SAML" "yes" "Enterprise" "Enterprise" "Enterprise"
                    , comparisonRow "On-prem" "yes" "no" "no" "no"
                    , comparisonRow "Protocol proofs" "18 Lean4" "no" "no" "no"
                    , comparisonRow "Visual diffs" "native" "extension" "built-in" "web-based"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Feature comparison as of January 2025. Enterprise features may vary by plan." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us vscode jetbrains workspace =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-green-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell vscode ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell jetbrains ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell workspace ]
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
                [ HH.text "Get your team started" ]
            ]
        , codeBlock
            [ codeLine "# " "Download the desktop app"
            , codeLine "$ " "curl -fsSL https://omega.straylight.software/work/install.sh | sh"
            , HH.text "\n"
            , codeLine "# " "Or install via Nix"
            , codeLine "$ " "nix profile install github:straylight-software/omega-work"
            , HH.text "\n"
            , codeLine "# " "Connect to your team workspace"
            , codeLine "$ " "omega-work auth --team your-org"
            , HH.text "\n"
            , codeLine "# " "Launch the desktop app"
            , codeLine "$ " "omega-work"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/omega/work/docs"
                , cls [ "text-green-400 hover:text-green-400/80 transition-colors" ]
                ]
                [ HH.text "Full team setup guide →" ]
            ]
        ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
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
            [ HH.text "Ready to upgrade your team's workflow?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "omega//work is in private beta. Request access for your team and get onboarded in days, not months." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/waitlist" "Request team access"
            , secondaryButton "/team" "Talk to sales"
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-green-400 text-background font-medium rounded-md hover:bg-green-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
