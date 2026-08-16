-- | omega//code Documentation
-- | Complete docs for the native terminal AI coding agent
module Straylight.Pages.Products.OmegaCode.Docs 
  ( docsPage
  , renderContent
  , sidebar
  -- For SSG
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
            [ sidebarLink "/omega/code/docs" "Overview" currentPath
            , sidebarLink "/omega/code/docs/quickstart" "Quick Start" currentPath
            , sidebarLink "/omega/code/docs/installation" "Installation" currentPath
            ]
        , sidebarSection "Guides"
            [ sidebarLink "/omega/code/docs/configuration" "Configuration" currentPath
            , sidebarLink "/omega/code/docs/providers" "Providers" currentPath
            , sidebarLink "/omega/code/docs/crew-mode" "Crew Mode" currentPath
            , sidebarLink "/omega/code/docs/sigil" "SIGIL Protocol" currentPath
            , sidebarLink "/omega/code/docs/attestation" "Attestation" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/omega/code/docs/cli" "CLI Reference" currentPath
            , sidebarLink "/omega/code/docs/api" "API Reference" currentPath
            , sidebarLink "/omega/code/docs/keybindings" "Keybindings" currentPath
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
                  then "bg-blue-300/10 text-blue-300 font-medium" 
                  else "text-muted-foreground hover:text-text hover:bg-card"
              ]
        ]
        [ HH.text label ]
    ]

-- ============================================================
-- STATIC RENDER (for SSG)
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
  "/omega/code/docs" -> overviewContent
  "/omega/code/docs/quickstart" -> quickstartContent
  "/omega/code/docs/installation" -> installationContent
  "/omega/code/docs/configuration" -> configurationContent
  "/omega/code/docs/providers" -> providersContent
  "/omega/code/docs/crew-mode" -> crewModeContent
  "/omega/code/docs/sigil" -> sigilContent
  "/omega/code/docs/attestation" -> attestationContent
  "/omega/code/docs/cli" -> cliContent
  "/omega/code/docs/api" -> apiContent
  "/omega/code/docs/keybindings" -> keybindingsContent
  _ -> overviewContent

-- ============================================================
-- OVERVIEW
-- ============================================================

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  article
    [ h1 "Documentation"
    , p "Everything you need to start using omega//code, the native terminal AI coding agent."
    
    -- Quick links
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 my-8" ] ]
        [ docCard "/omega/code/docs/quickstart" "Quick Start" "Get up and running in under a minute."
        , docCard "/omega/code/docs/crew-mode" "Crew Mode" "Run parallel competing agents."
        , docCard "/omega/code/docs/sigil" "SIGIL Protocol" "Understand the verified tool call protocol."
        , docCard "/omega/code/docs/cli" "CLI Reference" "Full command documentation."
        ]
    
    , h2 "What is omega//code?"
    , p "omega//code is a native terminal AI coding agent built in Haskell. Unlike Electron-based tools, it's a real binary with sub-millisecond response times, ~30MB memory footprint, and works over SSH."
    
    , h2 "Core Features"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Native TUI \x2014 Haskell + Brick, no Electron"
        , li' "509k req/s \x2014 io_uring event loop"
        , li' "SIGIL-native \x2014 18 Lean4 proofs for tool call parsing"
        , li' "Crew Mode \x2014 Parallel competing agents with CoW isolation"
        , li' "Attestation \x2014 Post-quantum cryptographic anchoring"
        ]
    
    , h2 "Quick example"
    , codeBlock
        [ codeLine "$ " "omega auth login"
        , codeLine "$ " "omega"
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# You're now in the omega//code TUI" ]
        ]
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  article
    [ h1 "Quick Start"
    , p "Get omega//code running in under a minute."
    
    , h2 "1. Install"
    , codeBlock
        [ codeLine "# " "Using Nix (recommended)"
        , codeLine "$ " "nix profile install github:straylight-software/omega-code"
        , HH.text "\n"
        , codeLine "# " "Or via curl"
        , codeLine "$ " "curl -fsSL https://omega.straylight.software/install.sh | sh"
        ]
    
    , h2 "2. Authenticate"
    , codeBlock
        [ codeLine "$ " "omega auth login"
        , codeLine "" "Opening browser for authentication..."
        , codeLine "" "\x2713 Authenticated as you@example.com"
        ]
    
    , h2 "3. Start coding"
    , codeBlock
        [ codeLine "$ " "omega"
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# The TUI launches. Start typing your request." ]
        ]
    
    , h2 "4. Basic usage"
    , codeBlock
        [ codeLine "" "> Fix the type error in src/Main.hs"
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# omega//code reads your codebase, proposes changes," ]
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# and applies them with your approval." ]
        ]
    
    , h2 "Next steps"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground" ] ]
        [ li link "/omega/code/docs/configuration" "Configure omega//code"
        , li link "/omega/code/docs/crew-mode" "Try Crew Mode"
        , li link "/omega/code/docs/keybindings" "Learn keybindings"
        ]
    ]

-- ============================================================
-- INSTALLATION
-- ============================================================

installationContent :: forall w i. HH.HTML w i
installationContent =
  article
    [ h1 "Installation"
    , p "Multiple ways to install omega//code."
    
    , h2 "Nix (recommended)"
    , codeBlock
        [ codeLine "# " "Add to your flake inputs"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "inputs.omega.url = \"github:straylight-software/omega-code\";" ]
        , HH.text "\n\n"
        , codeLine "# " "Or install directly"
        , codeLine "$ " "nix profile install github:straylight-software/omega-code"
        ]
    
    , h2 "Curl installer"
    , codeBlock
        [ codeLine "$ " "curl -fsSL https://omega.straylight.software/install.sh | sh"
        ]
    
    , h2 "Binary download"
    , p "Pre-built binaries for Linux and macOS:"
    , codeBlock
        [ codeLine "# " "Linux x86_64"
        , codeLine "$ " "curl -L https://omega.straylight.software/dl/omega-linux-x64 -o omega"
        , codeLine "$ " "chmod +x omega && sudo mv omega /usr/local/bin/"
        , HH.text "\n"
        , codeLine "# " "macOS arm64"
        , codeLine "$ " "curl -L https://omega.straylight.software/dl/omega-darwin-arm64 -o omega"
        , codeLine "$ " "chmod +x omega && sudo mv omega /usr/local/bin/"
        ]
    
    , h2 "Verify installation"
    , codeBlock
        [ codeLine "$ " "omega --version"
        , codeLine "" "omega//code 0.1.0 (straylight-software)"
        ]
    ]

-- ============================================================
-- CONFIGURATION
-- ============================================================

configurationContent :: forall w i. HH.HTML w i
configurationContent =
  article
    [ h1 "Configuration"
    , p "Configure omega//code to match your workflow."
    
    , h2 "Config file location"
    , codeBlock
        [ codeLine "" "~/.config/omega/config.toml"
        ]
    
    , h2 "Basic configuration"
    , codeBlock
        [ HH.span [ cls [ "text-text" ] ] [ HH.text "[llm]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "provider = \"anthropic\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "model = \"claude-sonnet-4-20250514\"" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[ui]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "theme = \"dark\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "show_tokens = true" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[crew]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "default_agents = 3" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "timeout = 300" ]
        ]
    
    , h2 "Environment variables"
    , codeBlock
        [ codeLine "" "OMEGA_API_KEY       # API key for cloud features"
        , codeLine "" "OMEGA_LLM_PROVIDER  # Override LLM provider"
        , codeLine "" "OMEGA_LLM_MODEL     # Override model"
        , codeLine "" "OMEGA_CONFIG        # Custom config path"
        ]
    ]

-- ============================================================
-- PROVIDERS
-- ============================================================

providersContent :: forall w i. HH.HTML w i
providersContent =
  article
    [ h1 "Providers"
    , p "omega//code supports multiple LLM providers. Use your own API keys (BYOK) or managed inference with Pro."
    
    , h2 "Supported Providers"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Anthropic \x2014 Claude Sonnet, Claude Opus"
        , li' "OpenAI \x2014 GPT-4, GPT-4o, GPT-4 Turbo"
        , li' "OpenRouter \x2014 Multi-provider gateway"
        , li' "Groq \x2014 Fast inference for Llama, Mixtral"
        , li' "Together AI \x2014 Open source models"
        , li' "Ollama \x2014 Local models on your machine"
        ]
    
    , h2 "Configuration"
    , codeBlock
        [ HH.span [ cls [ "text-text" ] ] [ HH.text "[llm]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "provider = \"anthropic\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "model = \"claude-sonnet-4-20250514\"" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# Or use OpenRouter for access to many models" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "provider = \"openrouter\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "model = \"anthropic/claude-sonnet-4-20250514\"" ]
        ]
    
    , h2 "Environment Variables"
    , codeBlock
        [ codeLine "" "# Anthropic"
        , codeLine "" "export ANTHROPIC_API_KEY=\"sk-ant-...\""
        , HH.text "\n"
        , codeLine "" "# OpenAI"
        , codeLine "" "export OPENAI_API_KEY=\"sk-...\""
        , HH.text "\n"
        , codeLine "" "# OpenRouter"
        , codeLine "" "export OPENROUTER_API_KEY=\"sk-or-...\""
        , HH.text "\n"
        , codeLine "" "# Groq"
        , codeLine "" "export GROQ_API_KEY=\"gsk_...\""
        ]
    
    , h2 "Local Models with Ollama"
    , codeBlock
        [ codeLine "# " "Start Ollama"
        , codeLine "$ " "ollama serve"
        , HH.text "\n"
        , codeLine "# " "Pull a model"
        , codeLine "$ " "ollama pull codellama:34b"
        , HH.text "\n"
        , codeLine "# " "Configure omega//code"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "provider = \"ollama\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "model = \"codellama:34b\"" ]
        ]
    
    , h2 "Custom Endpoints"
    , p "Any OpenAI-compatible API can be used:"
    , codeBlock
        [ HH.span [ cls [ "text-text" ] ] [ HH.text "[llm]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "provider = \"custom\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "base_url = \"https://your-endpoint.example.com/v1\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "model = \"your-model-name\"" ]
        ]
    ]

-- ============================================================
-- CREW MODE
-- ============================================================

crewModeContent :: forall w i. HH.HTML w i
crewModeContent =
  article
    [ h1 "Crew Mode"
    , p "Run parallel competing agents to explore multiple approaches simultaneously."
    
    , h2 "How it works"
    , HH.ol
        [ cls [ "list-decimal list-inside space-y-2 text-muted-foreground mb-6" ] ]
        [ HH.li_ [ HH.text "Spawn N agents with isolated CoW (copy-on-write) filesystems" ]
        , HH.li_ [ HH.text "Each agent works independently on your task" ]
        , HH.li_ [ HH.text "Compare results and select the best approach" ]
        , HH.li_ [ HH.text "Merge with cryptographic attestation" ]
        ]
    
    , h2 "Start a crew"
    , codeBlock
        [ codeLine "$ " "omega crew -n 3 \"Refactor the auth module\""
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# Spawns 3 agents working in parallel" ]
        ]
    
    , h2 "Watch progress"
    , codeBlock
        [ codeLine "" "[Agent 1] Reading src/Auth.hs..."
        , codeLine "" "[Agent 2] Analyzing dependencies..."
        , codeLine "" "[Agent 3] Checking type signatures..."
        ]
    
    , h2 "Select and merge"
    , codeBlock
        [ codeLine "" "Agent 1: 12 files changed, 3 tests added"
        , codeLine "" "Agent 2: 8 files changed, cleaner approach"
        , codeLine "" "Agent 3: 15 files changed, most comprehensive"
        , HH.text "\n"
        , codeLine "" "Select agent to merge [1/2/3/diff]: "
        ]
    ]

-- ============================================================
-- SIGIL
-- ============================================================

sigilContent :: forall w i. HH.HTML w i
sigilContent =
  article
    [ h1 "SIGIL Protocol"
    , p "The formally verified tool call protocol that powers omega//code."
    
    , h2 "Why SIGIL?"
    , p "Traditional tool call parsing relies on JSON with \"hope\" that the LLM produces valid output. SIGIL uses Lean4 proofs to guarantee correct parsing and prevent corrupted parse states from propagating."
    
    , h2 "Verified properties"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "StreamWellFormed \x2014 All streams satisfy structural invariants"
        , li' "ParseComplete \x2014 Parsing terminates with definite result"
        , li' "NoCorruptionPropagation \x2014 Malformed input cannot corrupt state"
        , li' "RecoveryTerminates \x2014 Error recovery always completes"
        , li' "IncrementalConsistent \x2014 Partial results are consistent"
        ]
    
    , h2 "Example tool call"
    , codeBlock
        [ HH.span [ cls [ "text-text" ] ] [ HH.text "SIGIL/TOOL_CALL" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  name: write_file" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  params:" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "    path: src/Main.hs" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "    content: |" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "      module Main where" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "      ..." ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "SIGIL/END" ]
        ]
    ]

-- ============================================================
-- ATTESTATION
-- ============================================================

attestationContent :: forall w i. HH.HTML w i
attestationContent =
  article
    [ h1 "Attestation"
    , p "Cryptographic anchoring for every change made by omega//code."
    
    , h2 "Post-quantum signatures"
    , p "omega//code uses hybrid signatures combining ML-DSA (post-quantum) with Ed25519 (classical). This provides security against both current and future quantum attacks."
    
    , h2 "What gets attested"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Every file change"
        , li' "Agent decisions and reasoning"
        , li' "Crew mode merges"
        , li' "Tool call invocations"
        , li' "Session boundaries"
        ]
    
    , h2 "Verify attestation"
    , codeBlock
        [ codeLine "$ " "omega attest verify ./src"
        , codeLine "" "\x2713 All changes verified"
        , codeLine "" "  12 files, 47 attestations"
        , codeLine "" "  Chain root: 0x8f3a..."
        ]
    
    , h2 "Export audit log"
    , codeBlock
        [ codeLine "$ " "omega attest export --format json > audit.json"
        ]
    ]

-- ============================================================
-- CLI REFERENCE
-- ============================================================

cliContent :: forall w i. HH.HTML w i
cliContent =
  article
    [ h1 "CLI Reference"
    , p "Complete reference for the omega command-line interface."
    
    , h2 "Global options"
    , codeBlock
        [ codeLine "" "omega [OPTIONS] <COMMAND>"
        , codeLine "" ""
        , codeLine "" "Options:"
        , codeLine "" "  -v, --verbose    Increase verbosity"
        , codeLine "" "  -q, --quiet      Suppress output"
        , codeLine "" "  --json           Output as JSON"
        , codeLine "" "  -h, --help       Print help"
        , codeLine "" "  -V, --version    Print version"
        ]
    
    , h2 "omega (default)"
    , p "Launch the interactive TUI."
    , codeBlock
        [ codeLine "$ " "omega"
        , codeLine "$ " "omega --model claude-sonnet-4-20250514"
        ]
    
    , h2 "omega auth"
    , p "Manage authentication."
    , codeBlock
        [ codeLine "$ " "omega auth login"
        , codeLine "$ " "omega auth logout"
        , codeLine "$ " "omega auth status"
        ]
    
    , h2 "omega crew"
    , p "Run parallel agents."
    , codeBlock
        [ codeLine "$ " "omega crew -n 3 \"Your task\""
        , codeLine "$ " "omega crew --timeout 600 \"Complex task\""
        ]
    
    , h2 "omega attest"
    , p "Manage attestations."
    , codeBlock
        [ codeLine "$ " "omega attest verify ./path"
        , codeLine "$ " "omega attest export --format json"
        , codeLine "$ " "omega attest show <HASH>"
        ]
    ]

-- ============================================================
-- API REFERENCE
-- ============================================================

apiContent :: forall w i. HH.HTML w i
apiContent =
  article
    [ h1 "API Reference"
    , p "omega//code exposes 95 REST API endpoints for programmatic access."
    
    , h2 "Authentication"
    , codeBlock
        [ codeLine "" "Authorization: Bearer <API_KEY>"
        ]
    
    , h2 "Base URL"
    , codeBlock
        [ codeLine "" "https://api.omega.straylight.software/v1"
        ]
    
    , h2 "Sessions"
    , codeBlock
        [ codeLine "" "POST   /sessions              # Create session"
        , codeLine "" "GET    /sessions/:id          # Get session"
        , codeLine "" "DELETE /sessions/:id          # End session"
        ]
    
    , h2 "Messages"
    , codeBlock
        [ codeLine "" "POST   /sessions/:id/messages # Send message"
        , codeLine "" "GET    /sessions/:id/messages # List messages"
        ]
    
    , h2 "Files"
    , codeBlock
        [ codeLine "" "GET    /sessions/:id/files    # List files"
        , codeLine "" "GET    /sessions/:id/files/:path"
        , codeLine "" "PUT    /sessions/:id/files/:path"
        ]
    
    , h2 "SSE Streaming"
    , codeBlock
        [ codeLine "" "GET /sessions/:id/stream"
        , codeLine "" ""
        , codeLine "" "event: token"
        , codeLine "" "data: {\"content\": \"Hello\"}"
        ]
    ]

-- ============================================================
-- KEYBINDINGS
-- ============================================================

keybindingsContent :: forall w i. HH.HTML w i
keybindingsContent =
  article
    [ h1 "Keybindings"
    , p "Default keybindings for the omega//code TUI."
    
    , h2 "Navigation"
    , HH.div
        [ cls [ "space-y-2 font-mono text-sm" ] ]
        [ keyRow "j / Down" "Move down"
        , keyRow "k / Up" "Move up"
        , keyRow "h / Left" "Move left"
        , keyRow "l / Right" "Move right"
        , keyRow "g g" "Go to top"
        , keyRow "G" "Go to bottom"
        ]
    
    , h2 "Actions"
    , HH.div
        [ cls [ "space-y-2 font-mono text-sm" ] ]
        [ keyRow "Enter" "Submit / Accept"
        , keyRow "Escape" "Cancel / Back"
        , keyRow "Tab" "Next pane"
        , keyRow "Shift+Tab" "Previous pane"
        , keyRow "y" "Accept change"
        , keyRow "n" "Reject change"
        , keyRow "d" "Show diff"
        ]
    
    , h2 "Commands"
    , HH.div
        [ cls [ "space-y-2 font-mono text-sm" ] ]
        [ keyRow ":" "Command mode"
        , keyRow ":q" "Quit"
        , keyRow ":w" "Save"
        , keyRow ":crew N" "Start crew with N agents"
        , keyRow ":attest" "Show attestations"
        ]
    ]

keyRow :: forall w i. String -> String -> HH.HTML w i
keyRow key desc =
  HH.div
    [ cls [ "flex items-center gap-4 py-2 border-b border-border" ] ]
    [ HH.span [ cls [ "text-blue-300 w-32" ] ] [ HH.text key ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text desc ]
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
    , cls [ "text-blue-300 hover:text-blue-300/80" ]
    ] 
    [ HH.text text ]

docCard :: forall w i. String -> String -> String -> HH.HTML w i
docCard href title description =
  HH.a
    [ HP.href href
    , cls [ "block p-4 bg-card border border-border rounded-lg hover:border-blue-300/50 transition-colors" ]
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
