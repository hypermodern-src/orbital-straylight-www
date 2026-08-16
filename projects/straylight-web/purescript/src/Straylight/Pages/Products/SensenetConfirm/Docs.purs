-- | sensenet//confirm Documentation Page
-- | CI with proof obligations - docs portal
module Straylight.Pages.Products.SensenetConfirm.Docs 
  ( docsPage
  , renderContent
  , sidebar
  , renderStatic
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

type Input = { path :: String }

data Action = Receive Input

docsPage :: forall q o m. H.Component q Input o m
docsPage = H.mkComponent
  { initialState: \input -> { path: input.path }
  , render
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction
      , receive = Just <<< Receive
      }
  }

handleAction :: forall o m. Action -> H.HalogenM { path :: String } Action () o m Unit
handleAction (Receive input) = H.modify_ _ { path = input.path }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall m. { path :: String } -> H.ComponentHTML Action () m
render state =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-12" ] ]
    [ HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-12" ] ]
        [ sidebar state.path
        , renderContent state.path
        ]
    ]

-- ============================================================
-- SIDEBAR
-- ============================================================

sidebar :: forall w i. String -> HH.HTML w i
sidebar currentPath =
  HH.nav
    [ cls [ "lg:sticky lg:top-24 lg:self-start" ] ]
    [ HH.div
        [ cls [ "space-y-6" ] ]
        [ sidebarSection "Getting Started"
            [ sidebarLink "/sensenet/confirm/docs" "Overview" currentPath
            , sidebarLink "/sensenet/confirm/docs/quickstart" "Quick Start" currentPath
            , sidebarLink "/sensenet/confirm/docs/installation" "Installation" currentPath
            ]
        , sidebarSection "Core Concepts"
            [ sidebarLink "/sensenet/confirm/docs/pipelines" "Dhall Pipelines" currentPath
            , sidebarLink "/sensenet/confirm/docs/proofs" "Proof Obligations" currentPath
            , sidebarLink "/sensenet/confirm/docs/agents" "Agent Review" currentPath
            , sidebarLink "/sensenet/confirm/docs/attestation" "Attestation" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/sensenet/confirm/docs/cli" "CLI Reference" currentPath
            , sidebarLink "/sensenet/confirm/docs/api" "REST API" currentPath
            , sidebarLink "/sensenet/confirm/docs/config" "Configuration" currentPath
            ]
        ]
    ]

sidebarSection :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
sidebarSection title children =
  HH.div_
    [ HH.h3
        [ cls [ "text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3" ] ]
        [ HH.text title ]
    , HH.ul
        [ cls [ "space-y-1" ] ]
        children
    ]

sidebarLink :: forall w i. String -> String -> String -> HH.HTML w i
sidebarLink href label currentPath =
  HH.li_
    [ HH.a
        [ HP.href href
        , cls [ "block py-1.5 px-3 rounded text-sm transition-colors"
              , if href == currentPath
                  then "bg-amber-400/10 text-amber-400 font-medium" 
                  else "text-muted-foreground hover:text-text hover:bg-card"
              ]
        ]
        [ HH.text label ]
    ]

-- ============================================================
-- STATIC RENDER
-- ============================================================

renderStatic :: forall w i. String -> HH.HTML w i
renderStatic path =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-12" ] ]
    [ HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-12" ] ]
        [ sidebar path
        , renderContent path
        ]
    ]

-- ============================================================
-- CONTENT ROUTER
-- ============================================================

renderContent :: forall w i. String -> HH.HTML w i
renderContent path = case path of
  "/sensenet/confirm/docs" -> overviewContent
  "/sensenet/confirm/docs/quickstart" -> quickstartContent
  "/sensenet/confirm/docs/installation" -> installationContent
  "/sensenet/confirm/docs/pipelines" -> pipelinesContent
  "/sensenet/confirm/docs/proofs" -> proofsContent
  "/sensenet/confirm/docs/agents" -> agentsContent
  "/sensenet/confirm/docs/attestation" -> attestationContent
  "/sensenet/confirm/docs/cli" -> cliContent
  "/sensenet/confirm/docs/api" -> apiContent
  "/sensenet/confirm/docs/config" -> configContent
  _ -> overviewContent

-- ============================================================
-- OVERVIEW
-- ============================================================

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  article
    [ h1 "Documentation"
    , p "Everything you need to start using sensenet//confirm for provable CI."
    
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 my-8" ] ]
        [ docCard "/sensenet/confirm/docs/quickstart" "Quick Start" "Get up and running in 60 seconds."
        , docCard "/sensenet/confirm/docs/pipelines" "Dhall Pipelines" "Learn the typed pipeline language."
        , docCard "/sensenet/confirm/docs/proofs" "Proof Obligations" "Add correctness guarantees to your builds."
        , docCard "/sensenet/confirm/docs/cli" "CLI Reference" "Full command documentation."
        ]
    
    , h2 "What is sensenet//confirm?"
    , p "sensenet//confirm is a CI system built around proof obligations and typed pipelines. Unlike traditional CI that runs scripts and hopes they work, confirm verifies correctness before deployment."
    
    , h2 "Core Features"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Typed Dhall Pipelines — No YAML. Compile-time type checking."
        , li' "Proof Obligations — Preconditions and postconditions on every step."
        , li' "Agent Code Review — Higher review burden for AI-generated code."
        , li' "Cryptographic Attestation — Signed builds with post-quantum algorithms."
        ]
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  article
    [ h1 "Quick Start"
    , p "Get sensenet//confirm working in 60 seconds."
    
    , h2 "1. Install the CLI"
    , codeBlock
        [ codeLine "# " "Using Nix (recommended)"
        , codeLine "$ " "nix profile install github:straylight-software/sensenet-confirm"
        , HH.text "\n"
        , codeLine "# " "Or via curl"
        , codeLine "$ " "curl -fsSL https://confirm.straylight.software/install.sh | sh"
        ]
    
    , h2 "2. Initialize your project"
    , codeBlock
        [ codeLine "$ " "cd your-project"
        , codeLine "$ " "confirm init"
        , codeLine "" "Creating pipeline.dhall..."
        , codeLine "" "Creating types.dhall..."
        , codeLine "" "Done! Run 'confirm run' to execute your pipeline."
        ]
    
    , h2 "3. Define your pipeline"
    , codeBlock
        [ codeLine "-- " "pipeline.dhall"
        , codeLine "" "let Pipeline = ./types.dhall"
        , codeLine "" ""
        , codeLine "" "in Pipeline.build {"
        , codeLine "" "  steps = ["
        , codeLine "" "    Pipeline.step { name = \"test\", run = \"cargo test\" },"
        , codeLine "" "    Pipeline.step { name = \"build\", run = \"cargo build --release\" }"
        , codeLine "" "  ],"
        , codeLine "" "  proofs = [ Pipeline.proof.testsPass ]"
        , codeLine "" "}"
        ]
    
    , h2 "4. Run your pipeline"
    , codeBlock
        [ codeLine "$ " "confirm run"
        , codeLine "" "[step: test] Running cargo test..."
        , codeLine "" "[step: test] All tests passed"
        , codeLine "" "[step: build] Running cargo build --release..."
        , codeLine "" "[step: build] Build complete"
        , codeLine "" "[proof: testsPass] Verified"
        , codeLine "" "Pipeline complete. All proofs satisfied."
        ]
    
    , h2 "Next steps"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground" ] ]
        [ li link "/sensenet/confirm/docs/pipelines" "Learn Dhall pipelines"
        , li link "/sensenet/confirm/docs/proofs" "Add proof obligations"
        , li link "/sensenet/confirm/docs/cli" "Explore the CLI"
        ]
    ]

-- ============================================================
-- INSTALLATION
-- ============================================================

installationContent :: forall w i. HH.HTML w i
installationContent =
  article
    [ h1 "Installation"
    , p "Multiple ways to install sensenet//confirm."
    
    , h2 "Nix (recommended)"
    , codeBlock
        [ codeLine "# " "Add to your flake inputs"
        , codeLine "" "inputs.confirm.url = \"github:straylight-software/sensenet-confirm\";"
        , HH.text "\n"
        , codeLine "# " "Or install directly"
        , codeLine "$ " "nix profile install github:straylight-software/sensenet-confirm"
        ]
    
    , h2 "Binary download"
    , codeBlock
        [ codeLine "# " "Linux x86_64"
        , codeLine "$ " "curl -fsSL https://confirm.straylight.software/install.sh | sh"
        , HH.text "\n"
        , codeLine "# " "macOS arm64"
        , codeLine "$ " "curl -fsSL https://confirm.straylight.software/install.sh | sh"
        ]
    
    , h2 "Verify installation"
    , codeBlock
        [ codeLine "$ " "confirm --version"
        , codeLine "" "sensenet-confirm 0.1.0"
        ]
    ]

-- ============================================================
-- PIPELINES
-- ============================================================

pipelinesContent :: forall w i. HH.HTML w i
pipelinesContent =
  article
    [ h1 "Dhall Pipelines"
    , p "sensenet//confirm uses Dhall for pipeline definitions. Dhall is a typed configuration language that catches errors at compile time."
    
    , h2 "Why Dhall?"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Type safety — Errors caught before execution"
        , li' "No string interpolation — No injection vulnerabilities"
        , li' "Composable — Import and reuse pipeline fragments"
        , li' "IDE support — LSP for autocompletion and errors"
        ]
    
    , h2 "Basic structure"
    , codeBlock
        [ codeLine "" "let Pipeline = ./types.dhall"
        , codeLine "" ""
        , codeLine "" "let testStep = Pipeline.step {"
        , codeLine "" "  name = \"test\","
        , codeLine "" "  run = \"cargo test\""
        , codeLine "" "}"
        , codeLine "" ""
        , codeLine "" "in Pipeline.build {"
        , codeLine "" "  steps = [ testStep ]"
        , codeLine "" "}"
        ]
    
    , h2 "Step dependencies"
    , codeBlock
        [ codeLine "" "let buildStep = Pipeline.step {"
        , codeLine "" "  name = \"build\","
        , codeLine "" "  run = \"cargo build --release\","
        , codeLine "" "  needs = [ testStep ]  -- runs after testStep"
        , codeLine "" "}"
        ]
    ]

-- ============================================================
-- PROOFS
-- ============================================================

proofsContent :: forall w i. HH.HTML w i
proofsContent =
  article
    [ h1 "Proof Obligations"
    , p "Proof obligations are preconditions and postconditions that must be satisfied before a pipeline completes."
    
    , h2 "Built-in proofs"
    , codeBlock
        [ codeLine "" "Pipeline.proof.testsPass      -- all tests passed"
        , codeLine "" "Pipeline.proof.noWarnings     -- zero compiler warnings"
        , codeLine "" "Pipeline.proof.coverageMin 80 -- 80% test coverage"
        , codeLine "" "Pipeline.proof.noSecrets      -- no secrets in code"
        ]
    
    , h2 "Step-level proofs"
    , codeBlock
        [ codeLine "" "Pipeline.step {"
        , codeLine "" "  name = \"deploy\","
        , codeLine "" "  run = \"kubectl apply -f manifests/\","
        , codeLine "" "  requires = [ Pipeline.proof.testsPass ],"
        , codeLine "" "  ensures = [ Pipeline.proof.healthCheckPasses ]"
        , codeLine "" "}"
        ]
    
    , h2 "Custom proofs"
    , codeBlock
        [ codeLine "" "let myProof = Pipeline.customProof {"
        , codeLine "" "  name = \"no-todos\","
        , codeLine "" "  check = \"! grep -r TODO src/\""
        , codeLine "" "}"
        ]
    ]

-- ============================================================
-- AGENTS
-- ============================================================

agentsContent :: forall w i. HH.HTML w i
agentsContent =
  article
    [ h1 "Agent Code Review"
    , p "sensenet//confirm automatically detects AI-generated code and applies stricter review requirements."
    
    , h2 "How it works"
    , p "Commits are analyzed for markers indicating AI generation (Copilot metadata, common patterns). Agent-generated code faces higher proof thresholds."
    
    , h2 "Configuration"
    , codeBlock
        [ codeLine "" "# confirm.toml"
        , codeLine "" "[agent_review]"
        , codeLine "" "enabled = true"
        , codeLine "" "human_approvals = 2"
        , codeLine "" "agent_approvals = 4"
        , codeLine "" "require_security_review = true"
        ]
    
    , h2 "Taint tracking"
    , p "Code provenance is tracked through the system. If tainted code touches critical paths, additional review is required."
    ]

-- ============================================================
-- ATTESTATION
-- ============================================================

attestationContent :: forall w i. HH.HTML w i
attestationContent =
  article
    [ h1 "Cryptographic Attestation"
    , p "Every build produces a signed attestation with post-quantum algorithms."
    
    , h2 "What is attested"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Source code hash"
        , li' "Build environment hash"
        , li' "Output artifact hashes"
        , li' "Proof obligation results"
        , li' "Timestamp"
        ]
    
    , h2 "Verifying attestations"
    , codeBlock
        [ codeLine "$ " "confirm verify artifact.tar.gz"
        , codeLine "" "Signature: valid (Dilithium3)"
        , codeLine "" "Source: abc123..."
        , codeLine "" "Proofs: testsPass, noWarnings"
        , codeLine "" "Built: 2026-02-24T10:30:00Z"
        ]
    ]

-- ============================================================
-- CLI
-- ============================================================

cliContent :: forall w i. HH.HTML w i
cliContent =
  article
    [ h1 "CLI Reference"
    , p "Complete reference for the confirm command-line interface."
    
    , h2 "confirm init"
    , p "Initialize a new pipeline in the current directory."
    , codeBlock
        [ codeLine "$ " "confirm init"
        ]
    
    , h2 "confirm run"
    , p "Execute the pipeline."
    , codeBlock
        [ codeLine "$ " "confirm run [--verify] [--parallel N]"
        ]
    
    , h2 "confirm check"
    , p "Type-check the pipeline without running."
    , codeBlock
        [ codeLine "$ " "confirm check"
        ]
    
    , h2 "confirm verify"
    , p "Verify a build attestation."
    , codeBlock
        [ codeLine "$ " "confirm verify <artifact>"
        ]
    ]

-- ============================================================
-- API
-- ============================================================

apiContent :: forall w i. HH.HTML w i
apiContent =
  article
    [ h1 "REST API"
    , p "Programmatic access to sensenet//confirm."
    
    , h2 "Authentication"
    , codeBlock
        [ codeLine "" "Authorization: Bearer <API_TOKEN>"
        ]
    
    , h2 "Trigger build"
    , codeBlock
        [ codeLine "" "POST /api/v1/builds"
        , codeLine "" "{"
        , codeLine "" "  \"repo\": \"github.com/org/repo\","
        , codeLine "" "  \"ref\": \"main\""
        , codeLine "" "}"
        ]
    
    , h2 "Get build status"
    , codeBlock
        [ codeLine "" "GET /api/v1/builds/{id}"
        ]
    ]

-- ============================================================
-- CONFIG
-- ============================================================

configContent :: forall w i. HH.HTML w i
configContent =
  article
    [ h1 "Configuration"
    , p "Configuration options for sensenet//confirm."
    
    , h2 "confirm.toml"
    , codeBlock
        [ codeLine "" "[project]"
        , codeLine "" "name = \"my-project\""
        , codeLine "" ""
        , codeLine "" "[build]"
        , codeLine "" "parallel = 4"
        , codeLine "" "timeout = \"30m\""
        , codeLine "" ""
        , codeLine "" "[proofs]"
        , codeLine "" "strict = true"
        , codeLine "" ""
        , codeLine "" "[agent_review]"
        , codeLine "" "enabled = true"
        ]
    
    , h2 "Environment variables"
    , codeBlock
        [ codeLine "" "CONFIRM_TOKEN    # API token"
        , codeLine "" "CONFIRM_PARALLEL # Parallelism level"
        , codeLine "" "CONFIRM_VERBOSE  # Verbose output"
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

article :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
article = HH.article [ cls [ "prose prose-invert max-w-none" ] ]

h1 :: forall w i. String -> HH.HTML w i
h1 text = HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text text ]

h2 :: forall w i. String -> HH.HTML w i
h2 text = HH.h2 [ cls [ "text-2xl font-semibold text-text mt-12 mb-4" ] ] [ HH.text text ]

p :: forall w i. String -> HH.HTML w i
p text = HH.p [ cls [ "text-muted-foreground mb-4" ] ] [ HH.text text ]

li' :: forall w i. String -> HH.HTML w i
li' text = HH.li [ cls [ "text-muted-foreground" ] ] [ HH.text text ]

li :: forall w i. (forall w' i'. String -> String -> HH.HTML w' i') -> String -> String -> HH.HTML w i
li f href text = HH.li_ [ f href text ]

link :: forall w i. String -> String -> HH.HTML w i
link href text = 
  HH.a 
    [ HP.href href
    , cls [ "text-amber-400 hover:text-amber-400/80" ]
    ] 
    [ HH.text text ]

docCard :: forall w i. String -> String -> String -> HH.HTML w i
docCard href title description =
  HH.a
    [ HP.href href
    , cls [ "block p-4 bg-card border border-border rounded-lg hover:border-amber-400/50 transition-colors" ]
    ]
    [ HH.h3
        [ cls [ "text-text font-medium mb-1" ] ]
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
