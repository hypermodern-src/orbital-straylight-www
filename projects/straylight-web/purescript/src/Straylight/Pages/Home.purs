-- | Product Landing Page
-- | Two product families. Ten external products. One attestation layer.
module Straylight.Pages.Home where

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
    , productMap
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
        [ cls [ "text-center" ] ]
        [ -- Badge
          badge "Q1 2026 · February – March"
        , HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Product Map" ]
        , HH.p
            [ cls [ "text-xl text-primary max-w-2xl mx-auto" ] ]
            [ HH.text "Two product families. Ten external products. One attestation layer." ]
        ]
    ]

-- ============================================================
-- PRODUCT MAP (Two columns)
-- ============================================================

productMap :: forall w i. HH.HTML w i
productMap =
  HH.section
    [ cls [ "py-16 border-t border-border" ] ]
    [ HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-12" ] ]
        [ -- SENSE//NET column
          HH.div_
            [ brandHeader "SENSE // NET" "Build infrastructure" true
            , HH.div
                [ cls [ "flex flex-col gap-3" ] ]
                [ productCardLink true "Cache" 
                    "Attestation-aware binary cache & artifact store. Content-addressed. Post-quantum signatures."
                    "Cachix, S3 artifact buckets"
                    "/sensenet/cache"
                , productCardLink true "Build"
                    "Typed build system with formal verification. Dhall configs. Lean4-proven derivations."
                    "Bazel, Buck2, Nix expressions"
                    "/sensenet/build"
                , productCardLink true "Converge"
                    "Typed infrastructure-as-code. Desired-state convergence. No state files, no drift."
                    "Terraform, Pulumi, Ansible"
                    "/sensenet/converge"
                , productCardLink true "Confirm"
                    "CI with proof obligations. Typed Dhall pipelines. Agent code faces higher review burden."
                    "GitHub Actions, CircleCI, Jenkins"
                    "/sensenet/confirm"
                , productCardLink true "Forge"
                    "Code hosting + review. Stacked diffs, not PRs. jujutsu first-class. Agent-era design."
                    "GitHub, Graphite, Phabricator"
                    "/sensenet/forge"
                , productCardLink true "Publish"
                    "Scope-graph documentation. References resolve or the build fails. Cross-language. Machine-readable."
                    "rustdoc, Haddock, typedoc, Doxygen"
                    "/sensenet/publish"
                ]
            ]
        , -- OMEGA column
          HH.div_
            [ brandHeader "// Ω //" "Agent infrastructure" false
            , HH.div
                [ cls [ "flex flex-col gap-3" ] ]
                [ productCardLink false "code"
                    "Native terminal AI coding agent. Haskell + Brick TUI. io_uring event loop. 509k req/s. SIGIL-native."
                    "Claude Code, Cursor, Windsurf, Aider"
                    "/omega/code"
                , productCardLink false "work"
                    "Electron desktop app for non-coders. Same agent engine, GUI surface. For PMs, designers, analysts, ops."
                    "ChatGPT desktop, Claude desktop (for teams)"
                    "/omega/work"
                , productCardLink false "proxy"
                    "Verified inference proxy. jaylene-slide ingress: SSE → SIGIL over ZeroMQ. Reset-on-ambiguity. 200–600% wire compression."
                    "LiteLLM, raw OpenAI SDK, broken tool calls"
                    "/omega/proxy"
                , productCardLink false "boost"
                    "Managed inference co-located with BYOK vendor. evring HTTP/1.1+2+3 stack. Custom CUTLASS 3.x sm_120 kernels."
                    "Self-hosted vLLM, raw provider APIs"
                    "/omega/boost"
                ]
            , -- Shared architecture box
              sharedArchitecture
            ]
        ]
    ]

brandHeader :: forall w i. String -> String -> Boolean -> HH.HTML w i
brandHeader name desc isSense =
  HH.div
    [ cls [ "flex items-baseline gap-3 mb-5" ] ]
    [ HH.span
        [ cls [ "font-mono font-bold text-sm tracking-wide"
              , if isSense then "text-primary" else "text-blue-300" 
              ] 
        ]
        [ HH.text name ]
    , HH.span
        [ cls [ "text-sm text-muted-foreground italic" ] ]
        [ HH.text desc ]
    ]

productCard :: forall w i. Boolean -> String -> String -> String -> HH.HTML w i
productCard isSense name desc replaces =
  HH.div
    [ cls [ "p-4 bg-card border border-border rounded-md transition-all hover:border-opacity-50 group"
          , if isSense then "hover:border-primary" else "hover:border-blue-300"
          ]
    ]
    [ HH.div
        [ cls [ "flex items-baseline gap-2 mb-2" ] ]
        [ HH.span 
            [ cls [ "font-mono font-bold text-sm"
                  , if isSense then "text-primary" else "text-blue-300"
                  ] 
            ] 
            [ HH.text "//" ]
        , HH.span 
            [ cls [ "font-semibold text-text" ] ] 
            [ HH.text name ]
        ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground leading-relaxed mb-2" ] ]
        [ HH.text desc ]
    , HH.p
        [ cls [ "font-mono text-[10px] text-muted-foreground/60" ] ]
        [ HH.span 
            [ cls [ if isSense then "text-primary/50" else "text-blue-300/50" ] ] 
            [ HH.text "replaces " ]
        , HH.text replaces
        ]
    ]

productCardLink :: forall w i. Boolean -> String -> String -> String -> String -> HH.HTML w i
productCardLink isSense name desc replaces href =
  HH.a
    [ HP.href href
    , cls [ "block p-4 bg-card border border-border rounded-md transition-all group"
          , if isSense then "hover:border-primary hover:bg-primary/5" else "hover:border-blue-300 hover:bg-blue-300/5"
          ]
    ]
    [ HH.div
        [ cls [ "flex items-baseline gap-2 mb-2" ] ]
        [ HH.span 
            [ cls [ "font-mono font-bold text-sm"
                  , if isSense then "text-primary" else "text-blue-300"
                  ] 
            ] 
            [ HH.text "//" ]
        , HH.span 
            [ cls [ "font-semibold text-text group-hover:text-primary transition-colors"
                  , if isSense then "group-hover:text-primary" else "group-hover:text-blue-300"
                  ] 
            ] 
            [ HH.text name ]
        , HH.span
            [ cls [ "ml-auto text-xs text-muted-foreground group-hover:text-text transition-colors" ] ]
            [ HH.text "→" ]
        ]
    , HH.p
        [ cls [ "text-sm text-muted-foreground leading-relaxed mb-2" ] ]
        [ HH.text desc ]
    , HH.p
        [ cls [ "font-mono text-[10px] text-muted-foreground/60" ] ]
        [ HH.span 
            [ cls [ if isSense then "text-primary/50" else "text-blue-300/50" ] ] 
            [ HH.text "replaces " ]
        , HH.text replaces
        ]
    ]

sharedArchitecture :: forall w i. HH.HTML w i
sharedArchitecture =
  HH.div
    [ cls [ "mt-6 p-5 border border-border rounded-md bg-card" ] ]
    [ HH.div
        [ cls [ "font-mono text-[10px] text-muted-foreground text-center mb-4 tracking-widest" ] ]
        [ HH.text "SHARED ARCHITECTURE" ]
    , HH.div
        [ cls [ "flex justify-center items-center gap-2 font-mono text-xs" ] ]
        [ archPill "code" "TUI"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "╲" ]
        , HH.span [ cls [ "text-text px-4 py-2 border border-primary rounded-md bg-primary/10 font-medium" ] ] 
            [ HH.text "Agent Engine" ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "╱" ]
        , archPill "work" "Electron"
        ]
    , HH.div
        [ cls [ "text-center mt-4 font-mono text-[9px] text-muted-foreground" ] ]
        [ HH.text "weapon-server · 95 endpoints · 221 property tests · SIGIL protocol" ]
    ]

archPill :: forall w i. String -> String -> HH.HTML w i
archPill name label =
  HH.span 
    [ cls [ "text-blue-300 px-3 py-1.5 border border-border rounded-md" ] ] 
    [ HH.text $ name <> " "
    , HH.span [ cls [ "text-muted-foreground text-[9px]" ] ] [ HH.text label ] 
    ]

-- ============================================================
-- CTA
-- ============================================================

cta :: forall w i. HH.HTML w i
cta =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "text-center" ] ]
        [ HH.h2
            [ cls [ "text-3xl font-bold text-text mb-4" ] ]
            [ HH.text "Ready to ship?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8 max-w-xl mx-auto" ] ]
            [ HH.text "omega//code is in private beta. Join the waitlist or check out our open source work." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/omega/code" "Learn about omega//code"
            , secondaryButton "https://github.com/straylight-software" "GitHub"
            ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

badge :: forall w i. String -> HH.HTML w i
badge label =
  HH.span
    [ cls [ "inline-block px-3 py-1 bg-primary/10 border border-primary/20 rounded-full text-primary text-sm font-medium mb-6" ] ]
    [ HH.text label ]

primaryButton :: forall w i. String -> String -> HH.HTML w i
primaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-primary text-background font-medium rounded-md hover:bg-primary/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , HP.target "_blank"
    , HP.rel "noopener noreferrer"
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
