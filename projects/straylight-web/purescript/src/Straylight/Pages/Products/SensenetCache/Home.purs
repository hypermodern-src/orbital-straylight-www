-- | sensenet//cache Home Page
-- | Attestation-aware binary cache & artifact store
module Straylight.Pages.Products.SensenetCache.Home 
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-cyan-400/10 border border-cyan-400/20 rounded-full text-cyan-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-cyan-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
          
          -- Headline
        , HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Binary cache"
            , HH.br_
            , HH.text "that "
            , HH.span [ cls [ "text-cyan-400" ] ] [ HH.text "proves" ]
            , HH.text " integrity"
            ]
          
          -- Subheadline
        , HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Content-addressed artifact store with attestation-aware distribution. Blake3 hashing. Post-quantum signatures. io_uring lookups. Not another S3 bucket with a CDN." ]
          
          -- CTAs
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/cache/pricing" "Get started"
            , secondaryButton "/sensenet/cache/docs" "Read the docs"
            ]
          
          -- Social proof
        , HH.p
            [ cls [ "mt-12 text-sm text-muted-foreground" ] ]
            [ HH.text "Securing supply chains for teams who refuse to trust blindly" ]
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
            [ featureCard "#" "Content-addressed" 
                "Every artifact identified by its cryptographic hash. Immutable by construction. No version conflicts."
            , featureCard "Q" "Post-quantum signatures"
                "SPHINCS+ signatures resist quantum attacks. Future-proof your supply chain security today."
            , featureCard ">" "Blake3 hashing"
                "7GB/s single-threaded. 128-bit security. Tree structure enables verified streaming."
            , featureCard "{}" "Attestation-aware"
                "Artifacts carry provenance metadata. Know exactly where your binaries came from."
            , featureCard "=" "Nix binary cache"
                "Drop-in replacement for cache.nixos.org. Full NAR support. Works with any Nix version."
            , featureCard "!" "io_uring I/O"
                "Zero-copy async I/O. 2.1M lookups/sec per core. Your cache won't be the bottleneck."
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
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "S3 bucket" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Content-addressed" "Blake3" "NAR hash" "NAR hash" "no"
                    , comparisonRow "Post-quantum sigs" "SPHINCS+" "no" "no" "no"
                    , comparisonRow "Attestation" "full" "no" "no" "no"
                    , comparisonRow "Merkle proofs" "yes" "no" "partial" "no"
                    , comparisonRow "lookups/sec" "2.1M" "~10k" "~50k" "~100k"
                    , comparisonRow "Zero-copy I/O" "io_uring" "no" "no" "no"
                    , comparisonRow "Self-hostable" "yes" "no" "yes" "yes"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Benchmarks on Linux x86_64, NVMe storage, 32 cores." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us cachix attic s3 =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ cell us true ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ cell cachix false ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ cell attic false ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ cell s3 false ]
    ]

cell :: forall w i. String -> Boolean -> HH.HTML w i
cell value isUs = 
  HH.span
    [ cls [ if isUs then "text-cyan-400 font-semibold" else textColor ] ]
    [ HH.text value ]
  where
  textColor = case value of
    "yes" -> "text-text"
    "no" -> "text-muted-foreground/50"
    _ -> "text-muted-foreground"

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
            , codeLine "$ " "nix profile install github:straylight-software/sensenet-cache"
            , HH.text "\n"
            , codeLine "# " "Authenticate"
            , codeLine "$ " "sensenet-cache login"
            , HH.text "\n"
            , codeLine "# " "Push your first artifact"
            , codeLine "$ " "nix build .#mypackage && sensenet-cache push ./result"
            , HH.text "\n"
            , codeLine "# " "Configure as substituter"
            , codeLine "$ " "sensenet-cache config --substituter"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/cache/docs/quickstart"
                , cls [ "text-cyan-400 hover:text-cyan-400/80 transition-colors" ]
                ]
                [ HH.text "Full quickstart guide ->" ]
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
            [ HH.text "Free tier includes 5GB storage and 50GB transfer. No credit card required." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/cache/pricing" "Start for free"
            , secondaryButton "/sensenet/cache/pricing" "See all plans"
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
    , cls [ "inline-flex items-center justify-center px-8 py-4 bg-cyan-400 text-background font-medium rounded-md hover:bg-cyan-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
