-- | sensenet//cache Features Page
-- | Attestation-aware binary cache & artifact store - complete feature showcase
module Straylight.Pages.Products.SensenetCache.Features 
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
    , contentAddressed
    , postQuantum
    , attestation
    , performance
    , nixIntegration
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
            [ HH.text "Built for"
            , HH.br_
            , HH.text "cryptographic certainty"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Content-addressed storage. Post-quantum signatures. Attestation-aware distribution. Every feature designed for supply chain security." ]
        ]
    ]

-- ============================================================
-- CONTENT-ADDRESSED STORAGE
-- ============================================================

contentAddressed :: forall w i. HH.HTML w i
contentAddressed =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ HH.div_
                [ badge "Content-Addressed Storage"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Immutable by construction" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Every artifact is identified by its Blake3 cryptographic hash. Same content, same address. Different content, different address. No version conflicts. No stale cache. Mathematical certainty." ]
                , featureList
                    [ "Blake3 hashing - 7GB/s single-threaded"
                    , "128-bit security level"
                    , "Tree structure for verified streaming"
                    , "Chunk-level deduplication"
                    , "Automatic integrity verification"
                    ]
                ]
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ codeBlock
                    [ codeLine "# " "Same content = same hash, always"
                    , codeLine "" "blake3://abc123def456..."
                    , HH.text "\n"
                    , codeLine "# " "Verify any artifact"
                    , codeLine "$ " "sensenet-cache verify ./result"
                    , codeLine "" "Hash verified against blake3://abc123..."
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- POST-QUANTUM SIGNATURES
-- ============================================================

postQuantum :: forall w i. HH.HTML w i
postQuantum =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ HH.div
                    [ cls [ "grid grid-cols-2 gap-4" ] ]
                    [ cryptoBadge "SPHINCS+" "Post-quantum"
                    , cryptoBadge "Ed25519" "Classical"
                    , cryptoBadge "Blake3" "Hash"
                    , cryptoBadge "NIST Level 3" "Security"
                    ]
                ]
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Post-Quantum Signatures"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Future-proof your supply chain" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "SPHINCS+ signatures resist both classical and quantum attacks. When large-scale quantum computers arrive, your artifact signatures remain secure. Ed25519 hybrid mode for backward compatibility." ]
                , featureList
                    [ "SPHINCS+ post-quantum signatures"
                    , "Ed25519 hybrid for compatibility"
                    , "NIST Level 3 security (192-bit)"
                    , "Hardware security module support"
                    , "Key rotation automation"
                    ]
                ]
            ]
        ]
    ]

cryptoBadge :: forall w i. String -> String -> HH.HTML w i
cryptoBadge title subtitle =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center hover:border-cyan-400/30 transition-colors" ] ]
    [ HH.p [ cls [ "text-xl font-bold text-cyan-400 mb-1" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text subtitle ]
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
            [ HH.div_
                [ badge "Attestation-Aware"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Know where your artifacts came from" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Every artifact carries provenance metadata. Who built it. When. From what source. On which system. Cryptographically signed and verifiable. SLSA Level 3 compliance out of the box." ]
                , featureList
                    [ "Full provenance chain"
                    , "SLSA Level 3 compliance"
                    , "Signed build attestations"
                    , "Source-to-binary mapping"
                    , "Reproducibility verification"
                    ]
                ]
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ codeBlock
                    [ codeLine "# " "View attestation"
                    , codeLine "$ " "sensenet-cache attest ./result"
                    , HH.text "\n"
                    , codeLine "" "Builder: ci.example.com"
                    , codeLine "" "Source:  github.com/org/repo@abc123"
                    , codeLine "" "Time:    2026-02-24T10:30:00Z"
                    , codeLine "" "Signed:  SPHINCS+-256s"
                    , codeLine "" "SLSA:    Level 3"
                    ]
                ]
            ]
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
            [ cls [ "text-center mb-16" ] ]
            [ badge "Performance"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Built for speed" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Security doesn't mean slow. io_uring async I/O, zero-copy transfers, and intelligent caching make sensenet//cache faster than alternatives." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6" ] ]
            [ perfCard "2.1M" "lookups/sec" "per core"
            , perfCard "<1ms" "P99 latency" "local cache"
            , perfCard "7GB/s" "Blake3" "single-threaded"
            , perfCard "0" "copies" "io_uring zero-copy"
            ]
        ]
    ]

perfCard :: forall w i. String -> String -> String -> HH.HTML w i
perfCard value label sublabel =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center" ] ]
    [ HH.p [ cls [ "text-3xl font-bold text-cyan-400 mb-1" ] ] [ HH.text value ]
    , HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text label ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text sublabel ]
    ]

-- ============================================================
-- NIX INTEGRATION
-- ============================================================

nixIntegration :: forall w i. HH.HTML w i
nixIntegration =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ codeBlock
                    [ codeLine "# " "flake.nix"
                    , codeLine "" "nixConfig = {"
                    , codeLine "" "  extra-substituters = ["
                    , codeLine "" "    \"https://cache.sensenet.dev/your-org\""
                    , codeLine "" "  ];"
                    , codeLine "" "  extra-trusted-public-keys = ["
                    , codeLine "" "    \"your-org.cache.sensenet.dev:abc123...\""
                    , codeLine "" "  ];"
                    , codeLine "" "};"
                    ]
                ]
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Nix Binary Cache"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Drop-in Nix replacement" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Full NAR format support. Realisation signatures. Works with any Nix version. Configure once, cache everywhere. No changes to your build process." ]
                , featureList
                    [ "Full NAR format support"
                    , "Realisation signatures"
                    , "Flake-native configuration"
                    , "Backward compatible with Nix 2.0+"
                    , "Multi-cache fallback"
                    ]
                ]
            ]
        ]
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
            [ badge "Security"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Enterprise-grade security" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Built for teams with compliance requirements. SOC 2 Type II. SAML SSO. Audit logs. Fine-grained RBAC." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ secCard "SOC 2 Type II" "Annual audit by independent third party"
            , secCard "SAML/OIDC SSO" "Integrate with your identity provider"
            , secCard "RBAC" "Fine-grained role-based access control"
            , secCard "Audit logs" "90-day retention, export to SIEM"
            , secCard "Private caches" "Complete network isolation"
            , secCard "Self-hostable" "Deploy on your own infrastructure"
            ]
        ]
    ]

secCard :: forall w i. String -> String -> HH.HTML w i
secCard title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 hover:border-cyan-400/30 transition-colors" ] ]
    [ HH.h3 [ cls [ "text-text font-semibold mb-2" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text description ]
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
            [ HH.text "Start free. No credit card required." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/sensenet/cache/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-cyan-400 text-background font-medium rounded-md hover:bg-cyan-400/90 transition-colors" ]
                ]
                [ HH.text "Get started free" ]
            , HH.a
                [ HP.href "/sensenet/cache/docs"
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
    [ cls [ "inline-block px-3 py-1 bg-cyan-400/10 border border-cyan-400/20 rounded-full text-cyan-400 text-sm font-medium mb-4" ] ]
    [ HH.text label ]

featureList :: forall w i. Array String -> HH.HTML w i
featureList items =
  HH.ul
    [ cls [ "space-y-3" ] ]
    (map featureItem items)

featureItem :: forall w i. String -> HH.HTML w i
featureItem txt =
  HH.li
    [ cls [ "flex items-start gap-3" ] ]
    [ HH.span [ cls [ "text-cyan-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text txt ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
