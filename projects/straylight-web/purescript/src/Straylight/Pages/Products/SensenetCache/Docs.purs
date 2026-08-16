-- | sensenet//cache Documentation
module Straylight.Pages.Products.SensenetCache.Docs 
  ( docsPage, renderContent, sidebar, renderStatic ) where

import Prelude
import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Straylight.UI (cls, codeBlock)

type Input = { path :: String }
data Action = Receive Input

docsPage :: forall q o m. H.Component q Input o m
docsPage = H.mkComponent
  { initialState: \input -> { path: input.path }
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction, receive = Just <<< Receive }
  }

handleAction :: forall o m. Action -> H.HalogenM { path :: String } Action () o m Unit
handleAction (Receive input) = H.modify_ _ { path = input.path }

render :: forall m. { path :: String } -> H.ComponentHTML Action () m
render state =
  HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-12" ] ]
    [ HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-12" ] ]
        [ sidebar state.path, renderContent state.path ]
    ]

sidebar :: forall w i. String -> HH.HTML w i
sidebar currentPath =
  HH.nav [ cls [ "lg:sticky lg:top-24 lg:self-start" ] ]
    [ HH.div [ cls [ "space-y-6" ] ]
        [ sidebarSection "Getting Started"
            [ sidebarLink "/sensenet/cache/docs" "Overview" currentPath
            , sidebarLink "/sensenet/cache/docs/quickstart" "Quick Start" currentPath
            ]
        , sidebarSection "Guides"
            [ sidebarLink "/sensenet/cache/docs/attestation" "Attestation" currentPath
            , sidebarLink "/sensenet/cache/docs/post-quantum" "Post-Quantum Signatures" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/sensenet/cache/docs/cli" "CLI Reference" currentPath
            , sidebarLink "/sensenet/cache/docs/api" "API Reference" currentPath
            ]
        ]
    ]

sidebarSection :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
sidebarSection title children =
  HH.div_ [ HH.h3 [ cls [ "text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3" ] ] [ HH.text title ]
          , HH.ul [ cls [ "space-y-1" ] ] children ]

sidebarLink :: forall w i. String -> String -> String -> HH.HTML w i
sidebarLink href label currentPath =
  HH.li_ [ HH.a [ HP.href href, cls [ "block py-1.5 px-3 rounded text-sm transition-colors"
              , if href == currentPath then "bg-cyan-400/10 text-cyan-400 font-medium" else "text-muted-foreground hover:text-text hover:bg-card" ] ]
        [ HH.text label ] ]

renderStatic :: forall w i. String -> HH.HTML w i
renderStatic path = HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-12" ] ]
    [ HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-12" ] ] [ sidebar path, renderContent path ] ]

renderContent :: forall w i. String -> HH.HTML w i
renderContent path
  | path == "/sensenet/cache/docs" = overviewContent
  | path == "/sensenet/cache/docs/quickstart" = quickstartContent
  | path == "/sensenet/cache/docs/attestation" = attestationContent
  | path == "/sensenet/cache/docs/post-quantum" = postQuantumContent
  | path == "/sensenet/cache/docs/cli" = cliContent
  | path == "/sensenet/cache/docs/api" = apiContent
  | otherwise = overviewContent

-- ============================================================
-- OVERVIEW
-- ============================================================

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "sensenet//cache Documentation" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] 
        [ HH.text "Attestation-aware binary cache with content-addressed storage and post-quantum signatures. A drop-in replacement for Cachix and S3 artifact buckets." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-12 mb-4" ] ] [ HH.text "What is sensenet//cache?" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ]
        [ HH.text "sensenet//cache is a content-addressed binary cache designed for Nix and other build systems. Every artifact is identified by its Blake3 cryptographic hash and signed with post-quantum SPHINCS+ signatures. Attestation metadata tracks provenance from source to binary." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Key Features" ]
    , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2 mb-8" ] ]
        [ HH.li_ [ HH.text "Content-addressed storage with Blake3 hashing (7GB/s)" ]
        , HH.li_ [ HH.text "Post-quantum SPHINCS+ signatures (NIST Level 3)" ]
        , HH.li_ [ HH.text "Full attestation chain for SLSA Level 3 compliance" ]
        , HH.li_ [ HH.text "Drop-in Nix substituter support" ]
        , HH.li_ [ HH.text "io_uring async I/O for 2.1M lookups/sec" ]
        ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Quick Example" ]
    , codeBlock [ HH.text "# Push an artifact with attestation\nsensenet-cache push --attest ./result\n\n# Verify an artifact's provenance\nsensenet-cache verify blake3://abc123..." ]
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Quick Start" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] 
        [ HH.text "Get started with sensenet//cache in under 5 minutes." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "1. Install the CLI" ]
    , codeBlock [ HH.text "# Install via Nix\nnix profile install github:straylight-software/sensenet-cache\n\n# Or run directly\nnix run github:straylight-software/sensenet-cache -- --help" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "2. Authenticate" ]
    , codeBlock [ HH.text "# Login to your account\nsensenet-cache login\n\n# This opens a browser for OAuth authentication\n# Your credentials are stored in ~/.config/sensenet-cache/auth.json" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "3. Push Your First Artifact" ]
    , codeBlock [ HH.text "# Build something with Nix\nnix build .#mypackage\n\n# Push to your cache with attestation\nsensenet-cache push --attest ./result\n\n# Output:\n# Uploading blake3://7f83b1657ff1fc53...\n# Attestation signed with SPHINCS+-256s\n# Done: https://cache.sensenet.dev/yourorg/7f83b1657ff1fc53" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "4. Configure as Nix Substituter" ]
    , codeBlock [ HH.text "# Add to your flake.nix\nnixConfig = {\n  extra-substituters = [\n    \"https://cache.sensenet.dev/yourorg\"\n  ];\n  extra-trusted-public-keys = [\n    \"yourorg.cache.sensenet.dev:abc123...\"\n  ];\n};" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "5. Verify Downloads" ]
    , codeBlock [ HH.text "# Nix automatically verifies signatures on download\n# For manual verification:\nsensenet-cache verify ./result\n\n# Output:\n# Hash: blake3://7f83b1657ff1fc53...\n# Signature: SPHINCS+-256s (valid)\n# Builder: ci.yourorg.com\n# Source: github.com/yourorg/repo@abc123\n# SLSA Level: 3" ]
    ]

-- ============================================================
-- ATTESTATION GUIDE
-- ============================================================

attestationContent :: forall w i. HH.HTML w i
attestationContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Attestation" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] 
        [ HH.text "Every artifact in sensenet//cache carries cryptographically signed provenance metadata. Know exactly where your binaries came from." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "What is Attestation?" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ]
        [ HH.text "An attestation is a signed statement about an artifact's provenance. It answers: Who built this? When? From what source? On which system? sensenet//cache implements SLSA (Supply-chain Levels for Software Artifacts) attestations." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Attestation Structure" ]
    , codeBlock [ HH.text "{\n  \"subject\": {\n    \"hash\": \"blake3://7f83b1657ff1fc53...\",\n    \"size\": 12847592\n  },\n  \"predicate\": {\n    \"builder\": \"ci.example.com\",\n    \"buildType\": \"nix-build\",\n    \"invocation\": {\n      \"configSource\": \"github.com/org/repo@abc123\"\n    },\n    \"buildConfig\": {\n      \"system\": \"x86_64-linux\",\n      \"nixVersion\": \"2.18.1\"\n    },\n    \"timestamp\": \"2026-02-24T10:30:00Z\"\n  },\n  \"signature\": \"SPHINCS+-256s:...\"\n}" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "SLSA Compliance" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ]
        [ HH.text "sensenet//cache provides SLSA Level 3 compliance out of the box:" ]
    , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2 mb-8" ] ]
        [ HH.li_ [ HH.text "Level 1: Attestation exists and is signed" ]
        , HH.li_ [ HH.text "Level 2: Attestation is generated by a hosted build service" ]
        , HH.li_ [ HH.text "Level 3: Source and build platform are hardened against tampering" ]
        ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Generating Attestations" ]
    , codeBlock [ HH.text "# Push with full attestation (default)\nsensenet-cache push --attest ./result\n\n# Push with custom builder identity\nsensenet-cache push --attest --builder \"my-ci.example.com\" ./result\n\n# Push with source reference\nsensenet-cache push --attest --source \"github.com/org/repo@$(git rev-parse HEAD)\" ./result" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Verifying Attestations" ]
    , codeBlock [ HH.text "# View attestation for an artifact\nsensenet-cache attest show blake3://7f83b1657ff1fc53...\n\n# Verify attestation signature\nsensenet-cache attest verify blake3://7f83b1657ff1fc53...\n\n# Export attestation as JSON\nsensenet-cache attest export --format json blake3://7f83b1657ff1fc53..." ]
    ]

-- ============================================================
-- POST-QUANTUM SIGNATURES
-- ============================================================

postQuantumContent :: forall w i. HH.HTML w i
postQuantumContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Post-Quantum Signatures" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] 
        [ HH.text "sensenet//cache uses SPHINCS+ signatures to protect your artifacts against both classical and quantum computer attacks." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Why Post-Quantum?" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ]
        [ HH.text "Large-scale quantum computers will break RSA, ECDSA, and Ed25519 signatures. Artifacts signed today with classical algorithms will be forgeable in the future. SPHINCS+ is a hash-based signature scheme that remains secure against quantum attacks, standardized by NIST in 2024." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "SPHINCS+ Parameters" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ]
        [ HH.text "sensenet//cache uses SPHINCS+-256s with the following security properties:" ]
    , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2 mb-8" ] ]
        [ HH.li_ [ HH.text "NIST Security Level 3 (192-bit classical, 128-bit quantum)" ]
        , HH.li_ [ HH.text "256-bit hash output (Blake3)" ]
        , HH.li_ [ HH.text "Small signature variant for faster verification" ]
        , HH.li_ [ HH.text "Signature size: ~8KB (vs 64 bytes for Ed25519)" ]
        ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Hybrid Mode" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ]
        [ HH.text "For backward compatibility, sensenet//cache supports hybrid signing that combines Ed25519 with SPHINCS+:" ]
    , codeBlock [ HH.text "# Sign with both Ed25519 and SPHINCS+\nsensenet-cache push --sign hybrid ./result\n\n# Verify requires both signatures to be valid\nsensenet-cache verify --require hybrid blake3://..." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Key Management" ]
    , codeBlock [ HH.text "# Generate a new SPHINCS+ keypair\nsensenet-cache keys generate --algorithm sphincs\n\n# List signing keys\nsensenet-cache keys list\n\n# Rotate keys (signs new artifacts with new key)\nsensenet-cache keys rotate --grace-period 30d\n\n# Export public key for substituter config\nsensenet-cache keys export --public" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "HSM Support" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ]
        [ HH.text "Enterprise plans support Hardware Security Modules for key storage:" ]
    , codeBlock [ HH.text "# Configure HSM backend\nsensenet-cache config set signing.backend hsm\nsensenet-cache config set signing.hsm.slot 1\nsensenet-cache config set signing.hsm.pin-env SENSENET_HSM_PIN" ]
    ]

-- ============================================================
-- CLI REFERENCE
-- ============================================================

cliContent :: forall w i. HH.HTML w i
cliContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "CLI Reference" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] 
        [ HH.text "Complete reference for the sensenet-cache command-line interface." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Global Options" ]
    , codeBlock [ HH.text "sensenet-cache [OPTIONS] <COMMAND>\n\nOptions:\n  --config <PATH>    Config file path (default: ~/.config/sensenet-cache/config.toml)\n  --cache <NAME>     Target cache name (default: from config)\n  --verbose, -v      Increase verbosity (can be repeated)\n  --quiet, -q        Suppress non-error output\n  --help, -h         Show help\n  --version          Show version" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Commands" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "login" ]
    , codeBlock [ HH.text "sensenet-cache login [OPTIONS]\n\nAuthenticate with sensenet//cache.\n\nOptions:\n  --token <TOKEN>    Use API token instead of OAuth\n  --no-browser       Print URL instead of opening browser" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "push" ]
    , codeBlock [ HH.text "sensenet-cache push [OPTIONS] <PATH>...\n\nUpload artifacts to the cache.\n\nOptions:\n  --attest           Generate attestation (default: true)\n  --builder <NAME>   Builder identity for attestation\n  --source <REF>     Source reference (e.g., git commit)\n  --sign <MODE>      Signature mode: sphincs, ed25519, hybrid (default: sphincs)\n  --jobs, -j <N>     Parallel upload jobs (default: 4)" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "verify" ]
    , codeBlock [ HH.text "sensenet-cache verify [OPTIONS] <PATH|HASH>\n\nVerify artifact integrity and attestation.\n\nOptions:\n  --require <MODE>   Required signature mode: sphincs, ed25519, hybrid, any\n  --slsa <LEVEL>     Require minimum SLSA level (1-3)\n  --json             Output verification result as JSON" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "attest" ]
    , codeBlock [ HH.text "sensenet-cache attest <SUBCOMMAND>\n\nSubcommands:\n  show <HASH>        Display attestation for an artifact\n  verify <HASH>      Verify attestation signature\n  export <HASH>      Export attestation (--format json|intoto)" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "config" ]
    , codeBlock [ HH.text "sensenet-cache config <SUBCOMMAND>\n\nSubcommands:\n  get <KEY>          Get config value\n  set <KEY> <VALUE>  Set config value\n  list               List all config values\n  --substituter      Configure as Nix substituter" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "migrate" ]
    , codeBlock [ HH.text "sensenet-cache migrate [OPTIONS]\n\nMigrate from another cache provider.\n\nOptions:\n  --from <PROVIDER>  Source provider: cachix, s3, attic\n  --source <URL>     Source cache URL\n  --dry-run          Show what would be migrated" ]
    ]

-- ============================================================
-- API REFERENCE
-- ============================================================

apiContent :: forall w i. HH.HTML w i
apiContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "API Reference" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] 
        [ HH.text "HTTP API for programmatic access to sensenet//cache." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Authentication" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ]
        [ HH.text "All API requests require authentication via Bearer token:" ]
    , codeBlock [ HH.text "curl -H \"Authorization: Bearer $SENSENET_TOKEN\" \\\n  https://api.cache.sensenet.dev/v1/..." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Endpoints" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "Upload Artifact" ]
    , codeBlock [ HH.text "POST /v1/artifacts\nContent-Type: application/octet-stream\nX-Sensenet-Hash: blake3://<hash>\nX-Sensenet-Attest: true\n\n<binary data>\n\nResponse:\n{\n  \"hash\": \"blake3://7f83b1657ff1fc53...\",\n  \"size\": 12847592,\n  \"attestation\": \"https://api.cache.sensenet.dev/v1/attestations/7f83b1657ff1fc53\"\n}" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "Download Artifact" ]
    , codeBlock [ HH.text "GET /v1/artifacts/:hash\n\nResponse: Binary artifact data\n\nHeaders:\n  X-Sensenet-Signature: <SPHINCS+ signature>\n  X-Sensenet-Attestation: <attestation URL>" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "Get Attestation" ]
    , codeBlock [ HH.text "GET /v1/attestations/:hash\n\nResponse:\n{\n  \"subject\": { \"hash\": \"blake3://...\", \"size\": 12847592 },\n  \"predicate\": {\n    \"builder\": \"ci.example.com\",\n    \"buildType\": \"nix-build\",\n    \"timestamp\": \"2026-02-24T10:30:00Z\"\n  },\n  \"signature\": \"SPHINCS+-256s:...\"\n}" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "Verify Artifact" ]
    , codeBlock [ HH.text "POST /v1/verify\nContent-Type: application/json\n\n{\n  \"hash\": \"blake3://7f83b1657ff1fc53...\",\n  \"require_signature\": \"sphincs\",\n  \"require_slsa\": 3\n}\n\nResponse:\n{\n  \"valid\": true,\n  \"signature\": { \"algorithm\": \"SPHINCS+-256s\", \"valid\": true },\n  \"attestation\": { \"slsa_level\": 3, \"valid\": true }\n}" ]
    , HH.h3 [ cls [ "text-lg font-semibold text-text mt-6 mb-3" ] ] [ HH.text "List Cache Contents" ]
    , codeBlock [ HH.text "GET /v1/caches/:name/artifacts?limit=100&cursor=...\n\nResponse:\n{\n  \"artifacts\": [\n    { \"hash\": \"blake3://...\", \"size\": 12847592, \"uploaded_at\": \"2026-02-24T10:30:00Z\" }\n  ],\n  \"next_cursor\": \"eyJvZmZzZXQiOjEwMH0=\"\n}" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Nix Binary Cache Protocol" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ]
        [ HH.text "sensenet//cache implements the standard Nix binary cache protocol:" ]
    , codeBlock [ HH.text "GET /nix-cache-info\nGET /:hash.narinfo\nGET /nar/:hash.nar.zst" ]
    ]
