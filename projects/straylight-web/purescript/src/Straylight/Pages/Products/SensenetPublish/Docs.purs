-- | sensenet//publish Documentation
-- | Complete docs for scope-graph documentation, CLI, and API
module Straylight.Pages.Products.SensenetPublish.Docs 
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
            [ sidebarLink "/sensenet/publish/docs" "Overview" currentPath
            , sidebarLink "/sensenet/publish/docs/quickstart" "Quick Start" currentPath
            , sidebarLink "/sensenet/publish/docs/installation" "Installation" currentPath
            ]
        , sidebarSection "Core Concepts"
            [ sidebarLink "/sensenet/publish/docs/scope-graphs" "Scope Graphs" currentPath
            , sidebarLink "/sensenet/publish/docs/references" "Reference Resolution" currentPath
            , sidebarLink "/sensenet/publish/docs/languages" "Languages" currentPath
            , sidebarLink "/sensenet/publish/docs/output-formats" "Output Formats" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/sensenet/publish/docs/cli" "CLI Reference" currentPath
            , sidebarLink "/sensenet/publish/docs/api" "REST API" currentPath
            , sidebarLink "/sensenet/publish/docs/config" "Configuration" currentPath
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
                  then "bg-teal-400/10 text-teal-400 font-medium" 
                  else "text-muted-foreground hover:text-text hover:bg-card"
              ]
        ]
        [ HH.text label ]
    ]

-- ============================================================
-- STATIC RENDER (for SSG)
-- ============================================================

-- | Render a docs page for static site generation
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
  "/sensenet/publish/docs" -> overviewContent
  "/sensenet/publish/docs/quickstart" -> quickstartContent
  "/sensenet/publish/docs/installation" -> installationContent
  "/sensenet/publish/docs/scope-graphs" -> scopeGraphsContent
  "/sensenet/publish/docs/references" -> referencesContent
  "/sensenet/publish/docs/languages" -> languagesContent
  "/sensenet/publish/docs/output-formats" -> outputFormatsContent
  "/sensenet/publish/docs/cli" -> cliContent
  "/sensenet/publish/docs/api" -> apiContent
  "/sensenet/publish/docs/config" -> configContent
  _ -> overviewContent

-- ============================================================
-- OVERVIEW
-- ============================================================

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  article
    [ h1 "Documentation"
    , p "Everything you need to build scope-graph documentation that actually resolves."
    
    -- Quick links
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 my-8" ] ]
        [ docCard "/sensenet/publish/docs/quickstart" "Quick Start" "Get up and running in under a minute."
        , docCard "/sensenet/publish/docs/scope-graphs" "Scope Graphs" "Understand how semantic analysis works."
        , docCard "/sensenet/publish/docs/ci" "CI Integration" "Add reference checking to your pipeline."
        , docCard "/sensenet/publish/docs/cli" "CLI Reference" "Full command documentation."
        ]
    
    , h2 "What is sensenet//publish?"
    , p "sensenet//publish generates documentation using scope-graph analysis. Unlike traditional doc generators that parse comments and hope for the best, we build a complete semantic model of your codebase. Every reference is verified. Every link resolves or the build fails."
    
    , h2 "Core Concepts"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Scope Graphs - Complete semantic model of bindings and references"
        , li' "Reference Resolution - Every cross-reference verified at build time"
        , li' "Cross-Language - Unified representation across Rust, Haskell, TypeScript, and more"
        , li' "Machine-Readable - JSON-LD, OpenAPI, and custom output formats"
        ]
    
    , h2 "How it works"
    , HH.ol
        [ cls [ "list-decimal list-inside space-y-2 text-muted-foreground mb-6" ] ]
        [ HH.li_ [ HH.text "Parse your source code into a scope graph" ]
        , HH.li_ [ HH.text "Extract documentation comments and markdown" ]
        , HH.li_ [ HH.text "Resolve all references against the scope graph" ]
        , HH.li_ [ HH.text "Generate output in your chosen format" ]
        ]
    
    , h2 "Quick example"
    , codeBlock
        [ codeLine "$ " "sensenet-publish init"
        , codeLine "$ " "sensenet-publish build"
        , codeLine "$ " "sensenet-publish check --strict"
        ]
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  article
    [ h1 "Quick Start"
    , p "Get sensenet//publish working in under a minute."
    
    , h2 "1. Install the CLI"
    , codeBlock
        [ codeLine "# " "Using Nix (recommended)"
        , codeLine "$ " "nix profile install github:straylight-software/sensenet-publish"
        , HH.text "\n"
        , codeLine "# " "Or via curl"
        , codeLine "$ " "curl -fsSL https://publish.sensenet.dev/install.sh | sh"
        ]
    
    , h2 "2. Initialize your project"
    , codeBlock
        [ codeLine "$ " "cd your-project"
        , codeLine "$ " "sensenet-publish init"
        , codeLine "" "Created sensenet-publish.toml"
        , codeLine "" "Detected languages: rust, typescript"
        ]
    
    , h2 "3. Build the scope graph"
    , codeBlock
        [ codeLine "$ " "sensenet-publish build"
        , codeLine "" "Parsing source files..."
        , codeLine "" "Building scope graph..."
        , codeLine "" "Resolving references..."
        , codeLine "" "Generating output..."
        , codeLine "" "Done! Output written to ./docs/build"
        ]
    
    , h2 "4. Check references (CI mode)"
    , codeBlock
        [ codeLine "$ " "sensenet-publish check --strict"
        , codeLine "" "Checking 247 references..."
        , codeLine "" "All references resolved"
        ]
    
    , h2 "Next steps"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground" ] ]
        [ li link "/sensenet/publish/docs/scope-graphs" "Understand scope graphs"
        , li link "/sensenet/publish/docs/ci" "Set up CI integration"
        , li link "/sensenet/publish/docs/cli" "Explore the CLI"
        ]
    ]

-- ============================================================
-- INSTALLATION
-- ============================================================

installationContent :: forall w i. HH.HTML w i
installationContent =
  article
    [ h1 "Installation"
    , p "Multiple ways to install sensenet//publish."
    
    , h2 "Nix (recommended)"
    , codeBlock
        [ codeLine "# " "Add to your flake inputs"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "inputs.sensenet-publish.url = \"github:straylight-software/sensenet-publish\";" ]
        , HH.text "\n\n"
        , codeLine "# " "Or install directly"
        , codeLine "$ " "nix profile install github:straylight-software/sensenet-publish"
        ]
    
    , h2 "Curl installer"
    , codeBlock
        [ codeLine "$ " "curl -fsSL https://publish.sensenet.dev/install.sh | sh"
        ]
    
    , h2 "Binary download"
    , p "Pre-built binaries for Linux and macOS:"
    , codeBlock
        [ codeLine "# " "Linux x86_64"
        , codeLine "$ " "curl -L https://publish.sensenet.dev/dl/sensenet-publish-linux-x64 -o sensenet-publish"
        , codeLine "$ " "chmod +x sensenet-publish && sudo mv sensenet-publish /usr/local/bin/"
        , HH.text "\n"
        , codeLine "# " "macOS arm64"
        , codeLine "$ " "curl -L https://publish.sensenet.dev/dl/sensenet-publish-darwin-arm64 -o sensenet-publish"
        , codeLine "$ " "chmod +x sensenet-publish && sudo mv sensenet-publish /usr/local/bin/"
        ]
    
    , h2 "Verify installation"
    , codeBlock
        [ codeLine "$ " "sensenet-publish --version"
        , codeLine "" "sensenet-publish 0.1.0"
        ]
    ]

-- ============================================================
-- SCOPE GRAPHS
-- ============================================================

scopeGraphsContent :: forall w i. HH.HTML w i
scopeGraphsContent =
  article
    [ h1 "Scope Graphs"
    , p "Understanding the semantic foundation of sensenet//publish."
    
    , h2 "What is a scope graph?"
    , p "A scope graph is a language-agnostic representation of name binding and resolution. It captures:"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Definitions - Where names are introduced"
        , li' "References - Where names are used"
        , li' "Scopes - Regions where bindings are visible"
        , li' "Edges - Relationships between scopes (imports, inheritance, etc.)"
        ]
    
    , h2 "Why scope graphs?"
    , p "Traditional doc generators use regex or simple AST matching to find references. This breaks on:"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Shadowing - The same name in different scopes"
        , li' "Imports and re-exports"
        , li' "Macros and generated code"
        , li' "Type-level vs value-level names"
        ]
    , p "Scope graphs handle all of these correctly because they model the actual name resolution semantics of the language."
    
    , h2 "Example"
    , codeBlock
        [ codeLine "// " "Rust source"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "mod utils {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "    pub fn process(data: Data) -> Result<Output> { ... }" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
        , HH.text "\n\n"
        , codeLine "// " "Scope graph representation"
        , HH.span [ cls [ "text-teal-400" ] ] [ HH.text "scope:utils" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  def process @ utils.rs:2" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  ref Data -> types::Data" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  ref Result -> std::result::Result" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  ref Output -> output::Output" ]
        ]
    
    , h2 "Querying the scope graph"
    , codeBlock
        [ codeLine "$ " "sensenet-publish query 'callers(utils::process)'"
        , codeLine "$ " "sensenet-publish query 'refs-to(types::Data)'"
        , codeLine "$ " "sensenet-publish query 'scope-of(utils::process)'"
        ]
    ]

-- ============================================================
-- REFERENCES
-- ============================================================

referencesContent :: forall w i. HH.HTML w i
referencesContent =
  article
    [ h1 "Reference Resolution"
    , p "How sensenet//publish verifies every cross-reference in your documentation."
    
    , h2 "The problem"
    , p "Documentation rots. You rename a function, delete a type, or move a module - and links break silently. Readers find dead links. Search indexes point nowhere. Trust erodes."
    
    , h2 "The solution"
    , p "Every reference in your documentation is resolved against the scope graph at build time. If a reference can't be resolved, the build fails with a helpful error message."
    
    , h2 "Reference syntax"
    , p "In doc comments and markdown, use backtick references:"
    , codeBlock
        [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "/// Process the [`Data`] and return an [`Output`]." ]
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "/// See [`utils::process`] for details." ]
        ]
    
    , h2 "Error messages"
    , p "When a reference fails to resolve:"
    , codeBlock
        [ HH.span [ cls [ "text-red-400" ] ] [ HH.text "ERROR" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text ": Unresolved reference in docs/api.md:47" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "  See [`process_data`] for details." ]
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "       ^^^^^^^^^^^^^^^" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "  Did you mean: `process` (lib.rs:42)" ]
        ]
    
    , h2 "Version pinning"
    , p "Pin references to specific versions for stable external links:"
    , codeBlock
        [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "See [`utils::process@v1.2.0`] for the previous API." ]
        ]
    ]

-- ============================================================
-- CROSS-LANGUAGE
-- ============================================================

languagesContent :: forall w i. HH.HTML w i
languagesContent =
  article
    [ h1 "Supported Languages"
    , p "sensenet//publish supports multiple languages with cross-language reference tracking."
    
    , h2 "Full support"
    , HH.div
        [ cls [ "grid grid-cols-2 md:grid-cols-3 gap-4 my-6" ] ]
        [ langBadge "Rust" "Full support"
        , langBadge "Haskell" "Full support"
        , langBadge "TypeScript" "Full support"
        , langBadge "Python" "Full support"
        , langBadge "C++" "Beta"
        , langBadge "Go" "Beta"
        ]
    
    , h2 "How it works"
    , p "Each language has a tree-sitter grammar that produces language-specific scope graph rules. The rules are then merged into a unified scope graph, allowing cross-language reference tracking."
    
    , h2 "Cross-language references"
    , p "Reference symbols from other languages in your documentation:"
    , codeBlock
        [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "/// The TypeScript bindings call [`rust::native::process`]." ]
        , HH.text "\n"
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "/// FFI is handled by [`c::ffi_bridge`]." ]
        ]
    
    , h2 "Adding language support"
    , p "sensenet//publish is extensible via tree-sitter grammars. See the contribution guide for adding new languages."
    ]

-- ============================================================
-- OUTPUT FORMATS
-- ============================================================

outputFormatsContent :: forall w i. HH.HTML w i
outputFormatsContent =
  article
    [ h1 "Output Formats"
    , p "sensenet//publish generates machine-readable documentation in multiple formats."
    
    , h2 "HTML"
    , p "Static HTML documentation with full navigation, search, and cross-references. Default format."
    , codeBlock
        [ codeLine "$ " "sensenet-publish build --format html"
        ]
    
    , h2 "JSON-LD"
    , p "Linked data format using schema.org vocabulary. Ideal for knowledge graphs and semantic web integration."
    , codeBlock
        [ codeLine "$ " "sensenet-publish build --format json-ld"
        , HH.text "\n"
        , codeLine "// " "Output includes:"
        , codeLine "" "- @context with schema.org vocabulary"
        , codeLine "" "- Typed definitions (Function, Class, Module)"
        , codeLine "" "- Linked references between entities"
        ]
    
    , h2 "OpenAPI"
    , p "Generate OpenAPI 3.1 specs from annotated REST handlers. Works with Rust (axum, actix), Haskell (servant), and TypeScript (express, fastify)."
    , codeBlock
        [ codeLine "$ " "sensenet-publish build --format openapi"
        ]
    
    , h2 "Raw scope graph"
    , p "Export the scope graph directly for custom tooling."
    , codeBlock
        [ codeLine "$ " "sensenet-publish build --format scope-graph"
        , codeLine "" "Output: JSON representation of nodes and edges"
        ]
    
    , h2 "Multiple formats"
    , p "Generate multiple formats in a single build:"
    , codeBlock
        [ codeLine "$ " "sensenet-publish build --format html,json-ld,openapi"
        ]
    ]

-- ============================================================
-- CLI REFERENCE
-- ============================================================

cliContent :: forall w i. HH.HTML w i
cliContent =
  article
    [ h1 "CLI Reference"
    , p "Complete reference for the sensenet-publish command-line interface."
    
    , h2 "Global options"
    , codeBlock
        [ codeLine "" "sensenet-publish [OPTIONS] <COMMAND>"
        , codeLine "" ""
        , codeLine "" "Options:"
        , codeLine "" "  -v, --verbose    Increase verbosity"
        , codeLine "" "  -q, --quiet      Suppress output"
        , codeLine "" "  --config <PATH>  Config file path"
        , codeLine "" "  -h, --help       Print help"
        , codeLine "" "  -V, --version    Print version"
        ]
    
    , h2 "sensenet-publish init"
    , p "Initialize a new project."
    , codeBlock
        [ codeLine "$ " "sensenet-publish init"
        , codeLine "" "Created sensenet-publish.toml"
        ]
    
    , h2 "sensenet-publish build"
    , p "Build documentation from source."
    , codeBlock
        [ codeLine "$ " "sensenet-publish build"
        , codeLine "$ " "sensenet-publish build --format html"
        , codeLine "$ " "sensenet-publish build --format json-ld"
        , codeLine "$ " "sensenet-publish build --output ./docs/build"
        ]
    
    , h2 "sensenet-publish check"
    , p "Verify all references resolve."
    , codeBlock
        [ codeLine "$ " "sensenet-publish check"
        , codeLine "$ " "sensenet-publish check --strict  # Fail on warnings"
        , codeLine "$ " "sensenet-publish check --format junit > results.xml"
        ]
    
    , h2 "sensenet-publish query"
    , p "Query the scope graph."
    , codeBlock
        [ codeLine "$ " "sensenet-publish query 'callers(process)'"
        , codeLine "$ " "sensenet-publish query 'refs-to(Data)'"
        , codeLine "$ " "sensenet-publish query 'scope-of(utils::process)'"
        ]
    
    , h2 "sensenet-publish serve"
    , p "Start a local development server."
    , codeBlock
        [ codeLine "$ " "sensenet-publish serve"
        , codeLine "$ " "sensenet-publish serve --port 8080"
        , codeLine "$ " "sensenet-publish serve --watch  # Auto-rebuild on changes"
        ]
    ]

-- ============================================================
-- API REFERENCE
-- ============================================================

apiContent :: forall w i. HH.HTML w i
apiContent =
  article
    [ h1 "REST API"
    , p "Programmatic access to sensenet//publish. API access requires a Pro plan or higher."
    
    , h2 "Authentication"
    , codeBlock
        [ codeLine "" "Authorization: Bearer <API_TOKEN>"
        ]
    , p "Get your API token from the dashboard -> Settings -> API Keys."
    
    , h2 "Base URL"
    , codeBlock
        [ codeLine "" "https://api.publish.sensenet.dev/v1"
        ]
    
    , h2 "Build documentation"
    , codeBlock
        [ codeLine "" "POST /projects/{project}/build"
        , codeLine "" ""
        , codeLine "" "Request body:"
        , codeLine "" "{"
        , codeLine "" "  \"ref\": \"main\","
        , codeLine "" "  \"format\": \"html\","
        , codeLine "" "  \"strict\": true"
        , codeLine "" "}"
        ]
    
    , h2 "Check references"
    , codeBlock
        [ codeLine "" "POST /projects/{project}/check"
        , codeLine "" ""
        , codeLine "" "Response:"
        , codeLine "" "{"
        , codeLine "" "  \"status\": \"success\","
        , codeLine "" "  \"references_checked\": 247,"
        , codeLine "" "  \"errors\": [],"
        , codeLine "" "  \"warnings\": []"
        , codeLine "" "}"
        ]
    
    , h2 "Query scope graph"
    , codeBlock
        [ codeLine "" "POST /projects/{project}/query"
        , codeLine "" ""
        , codeLine "" "Request body:"
        , codeLine "" "{"
        , codeLine "" "  \"query\": \"callers(process)\""
        , codeLine "" "}"
        ]
    
    , h2 "Rate limits"
    , p "API requests are rate limited to 100 requests per minute per project."
    ]

-- ============================================================
-- CONFIGURATION
-- ============================================================

configContent :: forall w i. HH.HTML w i
configContent =
  article
    [ h1 "Configuration"
    , p "All configuration options for sensenet//publish."
    
    , h2 "Config file"
    , codeBlock
        [ codeLine "# " "sensenet-publish.toml"
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[project]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "name = \"my-project\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "languages = [\"rust\", \"typescript\"]" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[output]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "format = \"html\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "path = \"./docs/build\"" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[check]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "strict = true" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "ignore = [\"tests/**\"]" ]
        ]
    
    , h2 "Language-specific options"
    , codeBlock
        [ HH.span [ cls [ "text-text" ] ] [ HH.text "[languages.rust]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "edition = \"2021\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "features = [\"full\"]" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[languages.typescript]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "tsconfig = \"./tsconfig.json\"" ]
        ]
    
    , h2 "Environment variables"
    , HH.div
        [ cls [ "overflow-x-auto" ] ]
        [ HH.table
            [ cls [ "w-full text-sm" ] ]
            [ HH.thead_
                [ HH.tr [ cls [ "border-b border-border" ] ]
                    [ HH.th [ cls [ "py-2 text-left text-muted-foreground" ] ] [ HH.text "Variable" ]
                    , HH.th [ cls [ "py-2 text-left text-muted-foreground" ] ] [ HH.text "Description" ]
                    ]
                ]
            , HH.tbody_
                [ envRow "SENSENET_PUBLISH_TOKEN" "API token for hosted service"
                , envRow "SENSENET_PUBLISH_PROJECT" "Default project ID"
                , envRow "SENSENET_PUBLISH_FORMAT" "Default output format"
                , envRow "SENSENET_PUBLISH_STRICT" "Enable strict mode"
                ]
            ]
        ]
    ]

envRow :: forall w i. String -> String -> HH.HTML w i
envRow name desc =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-2 font-mono text-teal-400" ] ] [ HH.text name ]
    , HH.td [ cls [ "py-2 text-muted-foreground" ] ] [ HH.text desc ]
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
    , cls [ "text-teal-400 hover:text-teal-400/80" ]
    ] 
    [ HH.text text ]

docCard :: forall w i. String -> String -> String -> HH.HTML w i
docCard href title description =
  HH.a
    [ HP.href href
    , cls [ "block p-4 bg-card border border-border rounded-lg hover:border-teal-400/50 transition-colors" ]
    ]
    [ HH.h3
        [ cls [ "text-text font-medium mb-1" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

langBadge :: forall w i. String -> String -> HH.HTML w i
langBadge name status =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-3 text-center" ] ]
    [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text status ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
