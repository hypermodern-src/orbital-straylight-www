-- | sensenet//forge Documentation Page
-- | Code hosting + review. Stacked diffs, not PRs. jujutsu first-class. Agent-era design.
module Straylight.Pages.Products.SensenetForge.Docs 
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
            [ sidebarLink "/sensenet/forge/docs" "Overview" currentPath
            , sidebarLink "/sensenet/forge/docs/quickstart" "Quick Start" currentPath
            , sidebarLink "/sensenet/forge/docs/installation" "Installation" currentPath
            ]
        , sidebarSection "Core Concepts"
            [ sidebarLink "/sensenet/forge/docs/stacked-diffs" "Stacked Diffs" currentPath
            , sidebarLink "/sensenet/forge/docs/jujutsu" "jujutsu Integration" currentPath
            , sidebarLink "/sensenet/forge/docs/attestation" "Attestation" currentPath
            ]
        , sidebarSection "Guides"
            [ sidebarLink "/sensenet/forge/docs/git-migration" "Migrating from Git" currentPath
            , sidebarLink "/sensenet/forge/docs/agent-workflows" "Agent Workflows" currentPath
            , sidebarLink "/sensenet/forge/docs/ci-integration" "CI Integration" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/sensenet/forge/docs/cli" "CLI Reference" currentPath
            , sidebarLink "/sensenet/forge/docs/api" "REST API" currentPath
            , sidebarLink "/sensenet/forge/docs/config" "Configuration" currentPath
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
                  then "bg-rose-400/10 text-rose-400 font-medium" 
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
  "/sensenet/forge/docs" -> overviewContent
  "/sensenet/forge/docs/quickstart" -> quickstartContent
  "/sensenet/forge/docs/installation" -> installationContent
  "/sensenet/forge/docs/stacked-diffs" -> stackedDiffsContent
  "/sensenet/forge/docs/jujutsu" -> jujutsuContent
  "/sensenet/forge/docs/attestation" -> attestationContent
  "/sensenet/forge/docs/cli" -> cliContent
  "/sensenet/forge/docs/api" -> apiContent
  _ -> overviewContent

-- ============================================================
-- OVERVIEW
-- ============================================================

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  article
    [ h1 "Documentation"
    , p "Everything you need to start using sensenet//forge for code hosting and review."
    
    -- Quick links
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 my-8" ] ]
        [ docCard "/sensenet/forge/docs/quickstart" "Quick Start" "Get up and running in under a minute."
        , docCard "/sensenet/forge/docs/stacked-diffs" "Stacked Diffs" "Learn the core review model."
        , docCard "/sensenet/forge/docs/jujutsu" "jujutsu Integration" "First-class jj support."
        , docCard "/sensenet/forge/docs/cli" "CLI Reference" "Full command documentation."
        ]
    
    , h2 "What is sensenet//forge?"
    , p "sensenet//forge is a code hosting and review platform built for the agent era. Unlike traditional PR-based workflows, forge uses stacked diffs — small, focused changes that build on each other. Native jujutsu support. Cryptographic attestation for AI-generated code."
    
    , h2 "Core Features"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Stacked Diffs — Review changes in logical units, not massive PRs"
        , li' "jujutsu Native — First-class support for the modern VCS"
        , li' "Agent Attestation — Cryptographic proof of AI-generated code"
        , li' "Semantic Search — Find code by what it does, not what it's called"
        ]
    
    , h2 "How it works"
    , HH.ol
        [ cls [ "list-decimal list-inside space-y-2 text-muted-foreground mb-6" ] ]
        [ HH.li_ [ HH.text "Create changes with jj (or git)" ]
        , HH.li_ [ HH.text "Stack related changes together" ]
        , HH.li_ [ HH.text "Submit for review with forge" ]
        , HH.li_ [ HH.text "Land when approved — rebasing handled automatically" ]
        ]
    
    , h2 "Quick example"
    , codeBlock
        [ codeLine "$ " "jj new -m 'Add user authentication'"
        , codeLine "$ " "forge diff create"
        , codeLine "$ " "jj new -m 'Add OAuth support'"
        , codeLine "$ " "forge diff create"
        , codeLine "$ " "forge stack submit"
        ]
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  article
    [ h1 "Quick Start"
    , p "Get sensenet//forge working in under a minute."
    
    , h2 "1. Install the CLI"
    , codeBlock
        [ codeLine "# " "Using Nix (recommended)"
        , codeLine "$ " "nix run github:sensenet/forge"
        , HH.text "\n"
        , codeLine "# " "Or via curl"
        , codeLine "$ " "curl -fsSL https://forge.sensenet.dev/install.sh | sh"
        ]
    
    , h2 "2. Initialize your repo"
    , codeBlock
        [ codeLine "$ " "cd your-project"
        , codeLine "$ " "forge init"
        , codeLine "" "✓ Initialized forge in /path/to/your-project"
        , codeLine "" "✓ Remote: https://forge.sensenet.dev/yourname/your-project"
        ]
    
    , h2 "3. Create your first diff"
    , codeBlock
        [ codeLine "# " "Make some changes..."
        , codeLine "$ " "jj new -m 'Add feature X'"
        , codeLine "$ " "forge diff create"
        , codeLine "" "Created diff D001: Add feature X"
        , codeLine "" "https://forge.sensenet.dev/yourname/your-project/D001"
        ]
    
    , h2 "4. Stack more changes"
    , codeBlock
        [ codeLine "# " "Create a dependent change"
        , codeLine "$ " "jj new -m 'Add feature Y (depends on X)'"
        , codeLine "$ " "forge diff create"
        , codeLine "" "Created diff D002: Add feature Y"
        , codeLine "" "Stack: D001 → D002"
        ]
    
    , h2 "5. Submit for review"
    , codeBlock
        [ codeLine "$ " "forge stack submit"
        , codeLine "" "Submitted stack for review:"
        , codeLine "" "  D001: Add feature X [needs review]"
        , codeLine "" "  D002: Add feature Y [needs review]"
        ]
    
    , h2 "Next steps"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground" ] ]
        [ li link "/sensenet/forge/docs/stacked-diffs" "Learn about stacked diffs"
        , li link "/sensenet/forge/docs/jujutsu" "Explore jujutsu integration"
        , li link "/sensenet/forge/docs/cli" "CLI reference"
        ]
    ]

-- ============================================================
-- INSTALLATION
-- ============================================================

installationContent :: forall w i. HH.HTML w i
installationContent =
  article
    [ h1 "Installation"
    , p "Multiple ways to install the sensenet//forge CLI."
    
    , h2 "Nix (recommended)"
    , codeBlock
        [ codeLine "# " "Run directly"
        , codeLine "$ " "nix run github:sensenet/forge"
        , HH.text "\n"
        , codeLine "# " "Or add to your flake"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "inputs.forge.url = \"github:sensenet/forge\";" ]
        ]
    
    , h2 "Shell script"
    , codeBlock
        [ codeLine "$ " "curl -fsSL https://forge.sensenet.dev/install.sh | sh" ]
    
    , h2 "Homebrew (macOS)"
    , codeBlock
        [ codeLine "$ " "brew install sensenet/tap/forge" ]
    
    , h2 "Cargo"
    , codeBlock
        [ codeLine "$ " "cargo install forge-cli" ]
    
    , h2 "Verify installation"
    , codeBlock
        [ codeLine "$ " "forge --version"
        , codeLine "" "forge 0.1.0 (sensenet//forge CLI)"
        ]
    ]

-- ============================================================
-- STACKED DIFFS
-- ============================================================

stackedDiffsContent :: forall w i. HH.HTML w i
stackedDiffsContent =
  article
    [ h1 "Stacked Diffs"
    , p "The core review model in sensenet//forge."
    
    , h2 "What are stacked diffs?"
    , p "Instead of creating one large PR with all your changes, you create a stack of small, focused diffs. Each diff builds on the previous one. Reviewers see logical units of change."
    
    , h2 "Why stacked diffs?"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Smaller changes are easier to review"
        , li' "Dependent changes are explicit"
        , li' "Rebasing propagates automatically"
        , li' "Land changes independently"
        ]
    
    , h2 "Creating a stack"
    , codeBlock
        [ codeLine "# " "First change"
        , codeLine "$ " "jj new -m 'Refactor auth module'"
        , codeLine "$ " "forge diff create"
        , HH.text "\n"
        , codeLine "# " "Second change (depends on first)"
        , codeLine "$ " "jj new -m 'Add OAuth support'"
        , codeLine "$ " "forge diff create"
        , HH.text "\n"
        , codeLine "# " "Third change (depends on second)"
        , codeLine "$ " "jj new -m 'Add Google provider'"
        , codeLine "$ " "forge diff create"
        ]
    
    , h2 "Viewing your stack"
    , codeBlock
        [ codeLine "$ " "forge stack show"
        , codeLine "" "D003: Add Google provider [draft]"
        , codeLine "" "  ↑"
        , codeLine "" "D002: Add OAuth support [draft]"
        , codeLine "" "  ↑"
        , codeLine "" "D001: Refactor auth module [draft]"
        ]
    
    , h2 "Rebasing"
    , p "When the base branch updates, forge automatically rebases your entire stack:"
    , codeBlock
        [ codeLine "$ " "forge stack rebase"
        , codeLine "" "Rebasing 3 diffs onto main..."
        , codeLine "" "✓ D001: Refactor auth module"
        , codeLine "" "✓ D002: Add OAuth support"
        , codeLine "" "✓ D003: Add Google provider"
        ]
    ]

-- ============================================================
-- JUJUTSU
-- ============================================================

jujutsuContent :: forall w i. HH.HTML w i
jujutsuContent =
  article
    [ h1 "jujutsu Integration"
    , p "sensenet//forge is built around jujutsu from day one."
    
    , h2 "Why jujutsu?"
    , p "jujutsu (jj) is a modern version control system that improves on Git in every way: anonymous branches, operation log, conflict-free rebasing, first-class undo. forge embraces these features."
    
    , h2 "Key concepts"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Changes — not commits. Each change has a stable ID across rebases."
        , li' "Anonymous branches — no need to name branches. Just create changes."
        , li' "Operation log — time travel through your repository history."
        , li' "Working copy — always on a real change, not a floating state."
        ]
    
    , h2 "Workflow example"
    , codeBlock
        [ codeLine "# " "Create a new change"
        , codeLine "$ " "jj new -m 'Add feature'"
        , HH.text "\n"
        , codeLine "# " "Edit files normally..."
        , HH.text "\n"
        , codeLine "# " "Create a forge diff"
        , codeLine "$ " "forge diff create"
        , HH.text "\n"
        , codeLine "# " "Need to make changes? Just edit."
        , codeLine "$ " "jj squash  # include changes in current diff"
        , codeLine "$ " "forge diff update"
        ]
    
    , h2 "Git compatibility"
    , p "forge supports Git repositories too. You can push from Git and pull to Git. Your team can migrate gradually."
    , codeBlock
        [ codeLine "# " "Clone a Git repo"
        , codeLine "$ " "jj git clone https://github.com/your/repo"
        , HH.text "\n"
        , codeLine "# " "Push to Git remote"
        , codeLine "$ " "jj git push"
        ]
    ]

-- ============================================================
-- ATTESTATION
-- ============================================================

attestationContent :: forall w i. HH.HTML w i
attestationContent =
  article
    [ h1 "Attestation"
    , p "Cryptographic proof of code origin."
    
    , h2 "What is attestation?"
    , p "Every change in forge is cryptographically signed. For AI-generated code, attestation includes the model, version, and a hash of the prompt. Reviewers know exactly where code came from."
    
    , h2 "Human changes"
    , p "Human-authored changes are signed with your SSH key or GPG key:"
    , codeBlock
        [ codeLine "" "Author: alice@example.com"
        , codeLine "" "Signed-by: ssh-ed25519 AAAA..."
        , codeLine "" "Timestamp: 2026-02-24T10:30:00Z"
        ]
    
    , h2 "Agent changes"
    , p "AI-generated changes include provenance metadata:"
    , codeBlock
        [ codeLine "" "Author: claude-opus-4"
        , codeLine "" "Model: anthropic/claude-opus-4"
        , codeLine "" "Version: 2026-02-01"
        , codeLine "" "Prompt-Hash: sha256:abc123..."
        , codeLine "" "Signed-by: attestation.sensenet.dev"
        ]
    
    , h2 "Verification"
    , codeBlock
        [ codeLine "$ " "forge verify D001"
        , codeLine "" "D001: Add rate limiting"
        , codeLine "" "  Author: claude-opus-4 (agent)"
        , codeLine "" "  Model: anthropic/claude-opus-4"
        , codeLine "" "  Signature: ✓ Valid"
        , codeLine "" "  Attestation: ✓ Verified by sensenet.dev"
        ]
    
    , h2 "Policy enforcement"
    , p "Configure policies for your organization:"
    , codeBlock
        [ codeLine "# " "forge.toml"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[policy]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "require_attestation = true" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "allowed_agents = [\"claude-*\", \"gpt-4*\"]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "require_human_review = true" ]
        ]
    ]

-- ============================================================
-- CLI REFERENCE
-- ============================================================

cliContent :: forall w i. HH.HTML w i
cliContent =
  article
    [ h1 "CLI Reference"
    , p "Complete reference for the forge command-line interface."
    
    , h2 "Global options"
    , codeBlock
        [ codeLine "" "forge [OPTIONS] <COMMAND>"
        , codeLine "" ""
        , codeLine "" "Options:"
        , codeLine "" "  -v, --verbose    Increase verbosity"
        , codeLine "" "  -q, --quiet      Suppress output"
        , codeLine "" "  --json           Output as JSON"
        , codeLine "" "  -h, --help       Print help"
        , codeLine "" "  -V, --version    Print version"
        ]
    
    , h2 "forge init"
    , p "Initialize forge in a repository."
    , codeBlock
        [ codeLine "$ " "forge init [--remote URL]" ]
    
    , h2 "forge diff"
    , p "Manage diffs."
    , codeBlock
        [ codeLine "$ " "forge diff create    # create a new diff"
        , codeLine "$ " "forge diff update    # update existing diff"
        , codeLine "$ " "forge diff show      # show diff details"
        , codeLine "$ " "forge diff land      # land an approved diff"
        ]
    
    , h2 "forge stack"
    , p "Manage stacks of diffs."
    , codeBlock
        [ codeLine "$ " "forge stack show     # show current stack"
        , codeLine "$ " "forge stack submit   # submit for review"
        , codeLine "$ " "forge stack rebase   # rebase onto base"
        ]
    
    , h2 "forge review"
    , p "Review diffs."
    , codeBlock
        [ codeLine "$ " "forge review D001           # open review UI"
        , codeLine "$ " "forge review approve D001   # approve diff"
        , codeLine "$ " "forge review comment D001   # add comment"
        ]
    
    , h2 "forge search"
    , p "Semantic code search."
    , codeBlock
        [ codeLine "$ " "forge search 'error handling'"
        , codeLine "$ " "forge search --type function 'auth'"
        ]
    ]

-- ============================================================
-- API REFERENCE
-- ============================================================

apiContent :: forall w i. HH.HTML w i
apiContent =
  article
    [ h1 "REST API"
    , p "Programmatic access to sensenet//forge."
    
    , h2 "Authentication"
    , codeBlock
        [ codeLine "" "Authorization: Bearer <API_TOKEN>" ]
    , p "Get your API token from Settings → API Keys."
    
    , h2 "Base URL"
    , codeBlock
        [ codeLine "" "https://api.forge.sensenet.dev/v1" ]
    
    , h2 "Create diff"
    , codeBlock
        [ codeLine "" "POST /repos/{owner}/{repo}/diffs"
        , codeLine "" ""
        , codeLine "" "Request body:"
        , codeLine "" "{"
        , codeLine "" "  \"title\": \"Add feature X\","
        , codeLine "" "  \"change_id\": \"abc123\","
        , codeLine "" "  \"base\": \"main\""
        , codeLine "" "}"
        ]
    
    , h2 "Get diff"
    , codeBlock
        [ codeLine "" "GET /repos/{owner}/{repo}/diffs/{id}"
        , codeLine "" ""
        , codeLine "" "Response:"
        , codeLine "" "{"
        , codeLine "" "  \"id\": \"D001\","
        , codeLine "" "  \"title\": \"Add feature X\","
        , codeLine "" "  \"status\": \"needs_review\","
        , codeLine "" "  \"author\": \"alice\","
        , codeLine "" "  \"attestation\": { ... }"
        , codeLine "" "}"
        ]
    
    , h2 "List stack"
    , codeBlock
        [ codeLine "" "GET /repos/{owner}/{repo}/stacks/{id}"
        , codeLine "" ""
        , codeLine "" "Response:"
        , codeLine "" "{"
        , codeLine "" "  \"diffs\": [\"D001\", \"D002\", \"D003\"],"
        , codeLine "" "  \"base\": \"main\""
        , codeLine "" "}"
        ]
    
    , h2 "Search"
    , codeBlock
        [ codeLine "" "GET /repos/{owner}/{repo}/search?q={query}"
        , codeLine "" ""
        , codeLine "" "Response:"
        , codeLine "" "{"
        , codeLine "" "  \"results\": ["
        , codeLine "" "    { \"file\": \"src/auth.rs\", \"line\": 42, \"score\": 0.94 }"
        , codeLine "" "  ]"
        , codeLine "" "}"
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
    , cls [ "text-rose-400 hover:text-rose-400/80" ]
    ] 
    [ HH.text text ]

docCard :: forall w i. String -> String -> String -> HH.HTML w i
docCard href title description =
  HH.a
    [ HP.href href
    , cls [ "block p-4 bg-card border border-border rounded-lg hover:border-rose-400/50 transition-colors" ]
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
