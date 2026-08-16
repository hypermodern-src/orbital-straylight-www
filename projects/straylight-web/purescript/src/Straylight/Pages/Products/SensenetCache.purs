-- | sensenet//cache Product Page
-- | Attestation-aware binary cache & artifact store
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.SensenetCache where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

sensenetCachePage :: forall q i o m. H.Component q i o m
sensenetCachePage = H.mkComponent
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-cyan-400/10 border border-cyan-400/20 rounded-full text-cyan-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-cyan-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Binary cache"
            , HH.br_
            , HH.text "that "
            , HH.span [ cls [ "text-cyan-400" ] ] [ HH.text "proves" ]
            , HH.text " integrity"
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Content-addressed artifact store with attestation-aware distribution. Blake3 hashing. Post-quantum signatures. io_uring lookups. Not another S3 bucket with a CDN." ]
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
                    , HH.text "curl -fsSL cache.sensenet.dev | sh"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#22d3ee] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:straylight-software/sensenet-cache"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#22d3ee] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-cyan-400/60" ] ] [ HH.text "replaces " ]
            , HH.text "Cachix, S3 artifact buckets"
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
                [ HH.text "Why sensenet//cache?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built for teams who need cryptographic proof that their artifacts haven't been tampered with." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "#" "Content-addressed storage"
                "Every artifact identified by its cryptographic hash. Immutable by construction. No version conflicts. No stale cache."
            , featureCard "⚡" "Blake3 hashing"
                "7GB/s single-threaded. 128-bit security. Tree structure enables verified streaming. Faster than SHA-256 by 14x."
            , featureCard "◎" "Distributed sharing"
                "Peer-to-peer artifact distribution across your fleet. Edge nodes cache intelligently. Bandwidth scales with your team."
            , featureCard "❄" "Nix binary cache"
                "Drop-in replacement for cache.nixos.org. Full NAR support. Realisation signatures. Works with any Nix version."
            , featureCard "⌘" "Merkle proof invalidation"
                "Surgical cache invalidation via DAG traversal. Only rebuild what actually changed. No more nuke-and-rebuild."
            , featureCard "∿" "io_uring lookups"
                "Zero-copy async I/O. 2.1M lookups/sec per core. Sub-millisecond P99. Your cache won't be the bottleneck."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-cyan-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-cyan-400 mb-4 font-mono" ] ]
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
                [ HH.text "The complete artifact platform" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others give you a bucket with optimistic caching. We give you cryptographic certainty." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-cyan-400 font-bold" ] ] [ HH.text "sensenet//cache" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Cachix" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Attic" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "S3 direct" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Local" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Content-addressed" "Blake3" "NAR hash" "NAR hash" "no" "NAR hash"
                    , comparisonRow "Attestation" "post-quantum" "no" "no" "no" "no"
                    , comparisonRow "P2P distribution" "yes" "no" "no" "no" "no"
                    , comparisonRow "Merkle invalidation" "yes" "no" "partial" "no" "no"
                    , comparisonRow "lookups/sec" "2.1M" "~10k" "~50k" "~100k" "~500k"
                    , comparisonRow "Hash algorithm" "Blake3" "SHA-256" "SHA-256" "MD5/SHA-256" "SHA-256"
                    , comparisonRow "Zero-copy I/O" "io_uring" "no" "no" "no" "no"
                    , comparisonRow "Self-hostable" "yes" "no" "yes" "yes" "yes"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Benchmarks on Linux x86_64, NVMe storage, 32 cores. External services measured via public APIs." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us cachix attic s3 local =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-cyan-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell cachix ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell attic ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell s3 ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell local ]
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
            [ codeLine "# " "Install sensenet//cache"
            , codeLine "$ " "nix profile install github:straylight-software/sensenet-cache"
            , HH.text "\n"
            , codeLine "# " "Or via curl"
            , codeLine "$ " "curl -fsSL https://cache.sensenet.dev/install.sh | sh"
            , HH.text "\n"
            , codeLine "# " "Configure as Nix substituter"
            , codeLine "$ " "sensenet-cache config --substituter"
            , HH.text "\n"
            , codeLine "# " "Push your first artifact"
            , codeLine "$ " "nix build .#mypackage && sensenet-cache push ./result"
            , HH.text "\n"
            , codeLine "# " "Verify attestation"
            , codeLine "$ " "sensenet-cache verify ./result --show-proof"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/cache/docs"
                , cls [ "text-cyan-400 hover:text-cyan-400/80 transition-colors" ]
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
            [ HH.text "Ready for artifacts you can trust?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "sensenet//cache is in private beta. Join the waitlist for early access." ]
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-cyan-400 text-background font-medium rounded-md hover:bg-cyan-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
