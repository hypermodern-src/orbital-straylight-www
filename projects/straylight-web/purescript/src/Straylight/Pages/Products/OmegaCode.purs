-- | omega//code Product Page
-- | Native Terminal AI Coding Agent
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.OmegaCode where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock, inlineCode)

-- ============================================================
-- COMPONENT
-- ============================================================

omegaCodePage :: forall q i o m. H.Component q i o m
omegaCodePage = H.mkComponent
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-blue-300/10 border border-blue-300/20 rounded-full text-blue-300 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-blue-300 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "AI coding agent"
            , HH.br_
            , HH.text "that doesn't "
            , HH.span [ cls [ "text-blue-300" ] ] [ HH.text "suck" ]
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "509k req/s. Native Haskell TUI. io_uring event loop. SIGIL protocol with Lean4 proofs. Not another Electron wrapper around the OpenAI SDK." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/waitlist" "Join the waitlist"
            , secondaryButton "https://github.com/straylight-software" "View source"
            ]
        , -- install options
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-3" ] ]
            [ HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "curl -fsSL omega.straylight.software | sh"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#80ccff] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:straylight-software/omega"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#80ccff] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-blue-300/60" ] ] [ HH.text "replaces " ]
            , HH.text "Claude Code, Cursor, Windsurf, Aider, Copilot Workspace"
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
                [ HH.text "Why omega//code?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built by engineers who got tired of slow, bloated, unreliable coding agents." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard ">" "509k req/s"
                "evring-wai vs Warp's 99k. io_uring share-nothing per-core rings. Linear multi-core scaling."
            , featureCard "{}" "Native TUI"
                "Haskell + Brick. No Electron. No React. No Node.js. Sub-millisecond rendering from a real binary."
            , featureCard "∴" "18 Lean4 proofs"
                "SIGIL protocol semantics proven correct. 0 sorry. Corrupted parse cannot propagate to your agent."
            , featureCard "++" "Crew orchestration"
                "Parallel competing agents. CoW filesystem isolation via bwrap. Best result wins. Attestation on merge."
            , featureCard "=" "Full API parity"
                "95 endpoints. Sessions, messages, files, PTY terminals, SSE streaming, sandboxed execution. 221 property tests."
            , featureCard "!" "Attestation-first"
                "Every change cryptographically anchored. Post-quantum hybrid signatures. Continuity kernel."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-blue-300/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-blue-300 mb-4 font-mono" ] ]
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
                [ HH.text "The complete agent platform" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others ship Electron wrappers with broken tool calls. We ship a native binary with proven protocol semantics." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-blue-300 font-bold" ] ] [ HH.text "omega//code" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Claude Code" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Cursor" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Aider" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Runtime" "Native binary" "Node.js" "Electron" "Python"
                    , comparisonRow "req/s" "509k" "~10k" "~5k" "~1k"
                    , comparisonRow "Protocol proofs" "18 Lean4" "no" "no" "no"
                    , comparisonRow "Tool call parsing" "SIGIL (proven)" "JSON (hopeful)" "JSON" "JSON"
                    , comparisonRow "Multi-agent" "Crew (CoW)" "no" "no" "no"
                    , comparisonRow "Attestation" "post-quantum" "no" "no" "no"
                    , comparisonRow "Memory (idle)" "~30MB" "~200MB" "~500MB" "~100MB"
                    , comparisonRow "Open source" "MIT" "no" "no" "Apache"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Benchmarks on Linux x86_64, 32 cores. Claude Code/Cursor measured via public APIs." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us claude cursor aider =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-blue-300 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell claude ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell cursor ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell aider ]
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
            [ codeLine "# " "Install (Nix)"
            , codeLine "$ " "nix profile install github:straylight-software/omega-code"
            , HH.text "\n"
            , codeLine "# " "Or via curl"
            , codeLine "$ " "curl -fsSL https://omega.straylight.software/install.sh | sh"
            , HH.text "\n"
            , codeLine "# " "Authenticate"
            , codeLine "$ " "omega auth login"
            , HH.text "\n"
            , codeLine "# " "Start coding"
            , codeLine "$ " "omega"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/omega/code/docs"
                , cls [ "text-blue-300 hover:text-blue-300/80 transition-colors" ]
                ]
                [ HH.text "Full quickstart guide →" ]
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
            [ HH.text "Ready to stop fighting your tools?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "omega//code is in private beta. Join the waitlist for early access." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/waitlist" "Join the waitlist"
            , secondaryButton "/team" "Meet the team"
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-blue-300 text-background font-medium rounded-md hover:bg-blue-300/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
