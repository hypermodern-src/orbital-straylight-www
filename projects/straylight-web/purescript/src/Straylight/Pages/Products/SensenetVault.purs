-- | sensenet//vault Product Page
-- | Secrets Management for Build Infrastructure
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.SensenetVault where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

sensenetVaultPage :: forall q i o m. H.Component q i o m
sensenetVaultPage = H.mkComponent
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-amber-400/10 border border-amber-400/20 rounded-full text-amber-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-amber-400 rounded-full animate-pulse" ] ] []
            , HH.text "Production ready"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Secrets management"
            , HH.br_
            , HH.text "that doesn't "
            , HH.span [ cls [ "text-amber-400" ] ] [ HH.text "leak" ]
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Hardware-backed keys. Build-time injection. Auto-rotating credentials. Post-quantum encryption. Not another YAML file with base64-encoded API keys." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/docs/vault" "Read the docs"
            , secondaryButton "https://github.com/straylight-software/sensenet-vault" "View source"
            ]
        , -- install options
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-3" ] ]
            [ HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "curl -fsSL vault.straylight.software | sh"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#fbbf24] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:straylight-software/vault"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#fbbf24] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-amber-400/60" ] ] [ HH.text "replaces " ]
            , HH.text "HashiCorp Vault, AWS Secrets Manager, SOPS, age, dotenv"
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
                [ HH.text "Why sensenet//vault?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built for CI/CD pipelines by engineers who've cleaned up too many leaked credentials." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "[]" "Hardware-backed keys"
                "TPM 2.0 and HSM integration. Keys never leave the secure enclave. FIPS 140-3 compliant. No plaintext ever touches disk."
            , featureCard "{}" "Build-time injection"
                "Secrets injected at build time via tmpfs. Zero persistence. Automatic cleanup. Works with any build system."
            , featureCard "<>" "Auto-rotating credentials"
                "Configurable rotation schedules. Automatic renewal before expiry. Zero-downtime rotation. Revocation propagates instantly."
            , featureCard "!!" "Audit logging"
                "Every access logged with attestation. Tamper-evident append-only logs. SOC 2 and HIPAA compliant. Export to SIEM."
            , featureCard "**" "Post-quantum ready"
                "ML-KEM-768 + X25519 hybrid encryption. Future-proof against quantum attacks. Backwards compatible with existing keys."
            , featureCard "=>" "CI/CD native"
                "First-class GitHub Actions, GitLab CI, Jenkins, CircleCI support. OIDC federation. No static tokens in your pipelines."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-amber-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-amber-400 mb-4 font-mono" ] ]
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
                [ HH.text "The complete secrets platform" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others ship complexity or compromise on security. We ship a single binary with hardware-backed encryption." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[800px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-44" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-amber-400 font-bold" ] ] [ HH.text "sensenet//vault" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "HashiCorp Vault" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "AWS Secrets Mgr" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "SOPS" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "age" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Hardware keys" "TPM/HSM" "HSM (enterprise)" "CloudHSM ($)" "no" "no"
                    , comparisonRow "Build injection" "native" "plugin" "SDK" "manual" "manual"
                    , comparisonRow "Auto-rotation" "built-in" "enterprise" "built-in" "no" "no"
                    , comparisonRow "Audit logging" "attestation" "enterprise" "CloudTrail" "no" "no"
                    , comparisonRow "Post-quantum" "ML-KEM hybrid" "no" "no" "no" "no"
                    , comparisonRow "CI/CD OIDC" "native" "plugin" "native" "no" "no"
                    , comparisonRow "Complexity" "single binary" "cluster" "managed" "CLI" "CLI"
                    , comparisonRow "Open source" "MIT" "BSL 1.1" "no" "Apache" "BSD"
                    , comparisonRow "Self-hosted" "yes" "yes" "no" "yes" "yes"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Comparison based on default configurations. Enterprise features may vary." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us hashicorp aws sops age =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-amber-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell hashicorp ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell aws ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell sops ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell age ]
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
                [ HH.text "Get started in 60 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Install (Nix)"
            , codeLine "$ " "nix profile install github:straylight-software/sensenet-vault"
            , HH.text "\n"
            , codeLine "# " "Or via curl"
            , codeLine "$ " "curl -fsSL https://vault.straylight.software/install.sh | sh"
            , HH.text "\n"
            , codeLine "# " "Initialize vault with TPM backing"
            , codeLine "$ " "vault init --backend=tpm"
            , HH.text "\n"
            , codeLine "# " "Store a secret"
            , codeLine "$ " "vault set production/db/password --value=\"$(op read ...)\" "
            , HH.text "\n"
            , codeLine "# " "Inject into build"
            , codeLine "$ " "vault exec -- make build"
            , HH.text "\n"
            , codeLine "# " "Configure rotation (optional)"
            , codeLine "$ " "vault rotate production/db/password --interval=7d"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/cache/docs"
                , cls [ "text-amber-400 hover:text-amber-400/80 transition-colors" ]
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
            [ HH.text "Ready to stop leaking secrets?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "sensenet//vault is production ready and MIT licensed. Deploy today." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/docs/vault" "Read the docs"
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-amber-400 text-background font-medium rounded-md hover:bg-amber-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
