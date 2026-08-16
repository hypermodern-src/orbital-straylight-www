-- | omega//code Features Page
-- | Complete feature showcase for the native terminal AI coding agent
module Straylight.Pages.Products.OmegaCode.Features 
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
    , performance
    , nativeTui
    , sigilProtocol
    , crewOrchestration
    , attestation
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
            [ HH.text "Built different,"
            , HH.br_
            , HH.text "not bolted on"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Native Haskell binary. io_uring event loop. SIGIL protocol with Lean4 proofs. Post-quantum attestation. Every component engineered from first principles." ]
        ]
    ]

-- ============================================================
-- PERFORMANCE
-- ============================================================

performance :: forall w i. HH.HTML w i
performance =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Performance"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "509k requests per second" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "evring-wai beats Warp's 99k req/s by 5x. io_uring share-nothing per-core rings eliminate lock contention. Linear multi-core scaling to 128+ cores." ]
                , featureList
                    [ "io_uring event loop with per-core rings"
                    , "Zero-copy buffer management"
                    , "Share-nothing architecture"
                    , "Linear scaling to 128+ cores"
                    , "Sub-millisecond P99 latency"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-4" ] ]
                    [ perfBar "omega//code" 509 "text-blue-300"
                    , perfBar "Warp (baseline)" 99 "text-muted-foreground"
                    , perfBar "Node.js" 45 "text-muted-foreground"
                    , perfBar "Python/uvicorn" 12 "text-muted-foreground"
                    ]
                , HH.p
                    [ cls [ "text-sm text-muted-foreground mt-6 text-center" ] ]
                    [ HH.text "Requests/sec (thousands), Linux x86_64, 32 cores" ]
                ]
            ]
        ]
    ]

perfBar :: forall w i. String -> Int -> String -> HH.HTML w i
perfBar label value color =
  HH.div_
    [ HH.div
        [ cls [ "flex justify-between text-sm mb-2" ] ]
        [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text label ]
        , HH.span [ cls [ color ] ] [ HH.text $ show value <> "k" ]
        ]
    , HH.div
        [ cls [ "h-4 bg-muted rounded-full overflow-hidden" ] ]
        [ HH.div
            [ cls [ "h-full rounded-full transition-all duration-1000"
                  , if value > 200 then "bg-blue-300" else "bg-muted-foreground/50"
                  ]
            , HP.style $ "width: " <> show (value * 100 / 509) <> "%"
            ]
            []
        ]
    ]

-- ============================================================
-- NATIVE TUI
-- ============================================================

nativeTui :: forall w i. HH.HTML w i
nativeTui =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: code block
              HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ codeBlock
                    [ codeLine "# " "~30MB memory footprint"
                    , codeLine "$ " "ps aux | grep omega"
                    , HH.text "\n"
                    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "omega  2847  0.1  0.3  29848  12456" ]
                    , HH.text "\n\n"
                    , codeLine "# " "Compare to Electron..."
                    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "cursor 2901  8.2  4.1 512304 168924" ]
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Native TUI"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Haskell + Brick" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "No Electron. No React. No Node.js. A real native binary with sub-millisecond rendering. Your terminal is already a perfectly good UI framework." ]
                , featureList
                    [ "Brick TUI framework"
                    , "Sub-millisecond render cycles"
                    , "~30MB memory footprint"
                    , "True terminal colors and Unicode"
                    , "Works over SSH"
                    , "No GPU required"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- SIGIL PROTOCOL
-- ============================================================

sigilProtocol :: forall w i. HH.HTML w i
sigilProtocol =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "SIGIL Protocol"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "18 Lean4 proofs, 0 sorry" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Tool call parsing that's mathematically proven correct. Corrupted parse states cannot propagate to your agent. Not \"should work\" \x2014 proven to work." ]
                , featureList
                    [ "Formally verified protocol semantics"
                    , "Structured streaming with parse guarantees"
                    , "Incremental verification"
                    , "Recovery from malformed input"
                    , "Deterministic behavior under all inputs"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-3" ] ]
                    [ proofItem "StreamWellFormed" "verified"
                    , proofItem "ParseComplete" "verified"
                    , proofItem "NoCorruptionPropagation" "verified"
                    , proofItem "RecoveryTerminates" "verified"
                    , proofItem "IncrementalConsistent" "verified"
                    ]
                , HH.p
                    [ cls [ "text-sm text-muted-foreground mt-6 text-center" ] ]
                    [ HH.text "Extract from SIGIL.Proofs module" ]
                ]
            ]
        ]
    ]

proofItem :: forall w i. String -> String -> HH.HTML w i
proofItem name status =
  HH.div
    [ cls [ "flex items-center justify-between py-2 border-b border-border last:border-0" ] ]
    [ HH.span [ cls [ "font-mono text-sm text-text" ] ] [ HH.text name ]
    , HH.span 
        [ cls [ "text-xs px-2 py-0.5 rounded bg-blue-300/20 text-blue-300" ] ] 
        [ HH.text status ]
    ]

-- ============================================================
-- CREW ORCHESTRATION
-- ============================================================

crewOrchestration :: forall w i. HH.HTML w i
crewOrchestration =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Crew Mode"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Parallel competing agents" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Spawn multiple agents working on the same problem. CoW filesystem isolation via bubblewrap. Best result wins. Attestation on merge." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-3 gap-6" ] ]
            [ crewCard "1" "Spawn" "Launch N agents with isolated CoW filesystems. Each works independently on your task."
            , crewCard "2" "Compete" "Agents race to complete. Real-time visibility into each agent's progress and approach."
            , crewCard "3" "Merge" "Select best result or combine approaches. Cryptographic attestation anchors the merge."
            ]
        ]
    ]

crewCard :: forall w i. String -> String -> String -> HH.HTML w i
crewCard num title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3 mb-4" ] ]
        [ HH.span 
            [ cls [ "w-8 h-8 rounded-full bg-blue-300/20 text-blue-300 flex items-center justify-center text-sm font-bold" ] ] 
            [ HH.text num ]
        , HH.h3 [ cls [ "text-text font-semibold" ] ] [ HH.text title ]
        ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
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
            [ -- Left: content
              HH.div_
                [ badge "Attestation"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Post-quantum signatures" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Every change cryptographically anchored. Hybrid signatures combine classical and post-quantum algorithms. Continuity kernel ensures verifiable history." ]
                , featureList
                    [ "ML-DSA + Ed25519 hybrid signatures"
                    , "Cryptographic anchoring of all changes"
                    , "Continuity kernel for verifiable history"
                    , "Tamper-evident audit logs"
                    , "Zero-knowledge provenance proofs"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "grid grid-cols-2 gap-4" ] ]
                [ trustBadge "ML-DSA" "Post-Quantum"
                , trustBadge "Ed25519" "Classical"
                , trustBadge "SHA-3" "Hash"
                , trustBadge "0" "Backdoors"
                ]
            ]
        ]
    ]

trustBadge :: forall w i. String -> String -> HH.HTML w i
trustBadge title subtitle =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center" ] ]
    [ HH.p [ cls [ "text-2xl font-bold text-blue-300 mb-1" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text subtitle ]
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
                [ HH.text "Built for humans" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "We're developers too. We built the DX we wanted." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ dxCard ">" "Native CLI"
                "Tab completion, progress bars, human-readable errors. Pipe-friendly for scripting."
            , dxCard "{}" "95 API endpoints"
                "Sessions, messages, files, PTY terminals, SSE streaming, sandboxed execution."
            , dxCard "!" "221 property tests"
                "Every endpoint covered. QuickCheck ensures correct behavior under all inputs."
            , dxCard "=" "Nix-native"
                "First-class Nix support. Reproducible builds. Declarative configuration."
            , dxCard "++" "SSE streaming"
                "Real-time token streaming. No polling. Instant feedback."
            , dxCard "$" "MIT licensed"
                "Open source. Self-host if you want. No vendor lock-in."
            ]
        ]
    ]

dxCard :: forall w i. String -> String -> String -> HH.HTML w i
dxCard icon title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 hover:border-blue-300/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3 mb-3" ] ]
        [ HH.span [ cls [ "text-blue-300 font-mono text-xl" ] ] [ HH.text icon ]
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
            [ HH.text "Ready to try something different?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "omega//code is in private beta. Join the waitlist for early access." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/omega/code/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-blue-300 text-background font-medium rounded-md hover:bg-blue-300/90 transition-colors" ]
                ]
                [ HH.text "Join the waitlist" ]
            , HH.a
                [ HP.href "/omega/code/docs"
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
    [ cls [ "inline-block px-3 py-1 bg-blue-300/10 border border-blue-300/20 rounded-full text-blue-300 text-sm font-medium mb-4" ] ]
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
    [ HH.span [ cls [ "text-blue-300 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
