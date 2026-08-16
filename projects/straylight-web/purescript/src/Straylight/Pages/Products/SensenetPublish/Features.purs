-- | sensenet//publish Features Page
-- | The complete scope-graph documentation platform showcase
module Straylight.Pages.Products.SensenetPublish.Features 
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
    , scopeGraphs
    , referenceResolution
    , crossLanguage
    , machineReadable
    , ciIntegration
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
            [ HH.text "Semantic documentation,"
            , HH.br_
            , HH.text "not string matching"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Scope-graph analysis. Reference resolution. Cross-language support. Build integration. Everything you need for documentation that actually works." ]
        ]
    ]

-- ============================================================
-- SCOPE GRAPHS
-- ============================================================

scopeGraphs :: forall w i. HH.HTML w i
scopeGraphs =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Scope Graphs"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Full semantic understanding" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Traditional doc generators parse comments and hope for the best. We build a complete scope graph of your codebase - every binding, every reference, every scope boundary. The same technology used in compilers and language servers." ]
                , featureList
                    [ "Complete name resolution across modules"
                    , "Handles shadowing, imports, and re-exports"
                    , "Works with macros and generated code"
                    , "Language-agnostic core representation"
                    , "Query definitions, usages, and relationships"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "font-mono text-sm" ] ]
                    [ HH.div [ cls [ "text-muted-foreground mb-2" ] ] [ HH.text "// Scope graph for:" ]
                    , HH.div [ cls [ "text-text mb-4" ] ] [ HH.text "fn process(data: &Data) -> Result<Output>" ]
                    , HH.div [ cls [ "border-l-2 border-teal-400/50 pl-4 space-y-2" ] ]
                        [ HH.div_ [ HH.span [ cls [ "text-teal-400" ] ] [ HH.text "def" ], HH.text " process @ line 42" ]
                        , HH.div_ [ HH.span [ cls [ "text-green-400" ] ] [ HH.text "ref" ], HH.text " Data -> types.rs:15" ]
                        , HH.div_ [ HH.span [ cls [ "text-green-400" ] ] [ HH.text "ref" ], HH.text " Result -> std::result" ]
                        , HH.div_ [ HH.span [ cls [ "text-green-400" ] ] [ HH.text "ref" ], HH.text " Output -> output.rs:8" ]
                        ]
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- REFERENCE RESOLUTION
-- ============================================================

referenceResolution :: forall w i. HH.HTML w i
referenceResolution =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual (code)
              HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ codeBlock
                    [ codeLine "# " "Build with strict reference checking"
                    , codeLine "$ " "sensenet-publish build --strict"
                    , HH.text "\n"
                    , HH.span [ cls [ "text-red-400" ] ] [ HH.text "ERROR" ]
                    , HH.span [ cls [ "text-text" ] ] [ HH.text ": Unresolved reference in docs/api.md:47" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "  See [`process_data`] for details." ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "       ^^^^^^^^^^^^^^^" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "  Did you mean: `process` (lib.rs:42)" ]
                    , HH.text "\n\n"
                    , HH.span [ cls [ "text-yellow-400" ] ] [ HH.text "1 error, 0 warnings" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-red-400" ] ] [ HH.text "Build failed" ]
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Reference Resolution"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Broken links fail the build" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Every cross-reference in your documentation is verified against the scope graph at build time. Rename a function? The build fails until you update the docs. Delete a type? You'll know immediately which docs need fixing." ]
                , featureList
                    [ "Catches typos and renames automatically"
                    , "Suggests corrections for common mistakes"
                    , "Version-aware - pin refs to specific releases"
                    , "Works with doc comments and markdown"
                    , "CI integration for pull request checks"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- CROSS-LANGUAGE
-- ============================================================

crossLanguage :: forall w i. HH.HTML w i
crossLanguage =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Cross-Language"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "One tool for your whole stack" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Your codebase isn't monolingual. Neither is sensenet//publish. We build scope graphs for Rust, Haskell, TypeScript, Python, C++, and more - then link them together. Reference a Rust function from your TypeScript FFI bindings? We'll track it." ]
                , featureList
                    [ "Unified scope-graph representation"
                    , "Cross-language reference tracking"
                    , "Consistent output format across languages"
                    , "Language-specific idioms respected"
                    , "Extensible via tree-sitter grammars"
                    ]
                ]
              -- Right: visual (language grid)
            , HH.div
                [ cls [ "grid grid-cols-3 gap-4" ] ]
                [ langCard "Rust" "Full support"
                , langCard "Haskell" "Full support"
                , langCard "TypeScript" "Full support"
                , langCard "Python" "Full support"
                , langCard "C++" "Beta"
                , langCard "Go" "Beta"
                ]
            ]
        ]
    ]

langCard :: forall w i. String -> String -> HH.HTML w i
langCard name status =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-4 text-center hover:border-teal-400/50 transition-colors" ] ]
    [ HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-xs text-muted-foreground" ] ] [ HH.text status ]
    ]

-- ============================================================
-- MACHINE-READABLE
-- ============================================================

machineReadable :: forall w i. HH.HTML w i
machineReadable =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: visual
              HH.div
                [ cls [ "order-2 lg:order-1" ] ]
                [ codeBlock
                    [ codeLine "// " "Output formats"
                    , codeLine "$ " "sensenet-publish build --format json-ld"
                    , codeLine "$ " "sensenet-publish build --format openapi"
                    , codeLine "$ " "sensenet-publish build --format html"
                    , HH.text "\n"
                    , codeLine "// " "Query the scope graph"
                    , codeLine "$ " "sensenet-publish query 'callers(process)'"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "main.rs:127  handle_request" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "worker.rs:43 batch_process" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "test.rs:15   test_process" ]
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Machine-Readable"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Structured output for tooling" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Documentation shouldn't be a dead end. Export to JSON-LD for knowledge graphs, OpenAPI for API docs, or query the scope graph directly. Build IDE plugins, search indexes, or custom tooling on top of real semantic data." ]
                , featureList
                    [ "JSON-LD with schema.org vocabulary"
                    , "OpenAPI 3.1 for REST API docs"
                    , "GraphQL schema generation"
                    , "Direct scope-graph queries"
                    , "Custom format plugins"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- CI INTEGRATION
-- ============================================================

ciIntegration :: forall w i. HH.HTML w i
ciIntegration =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "CI Integration"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "Works with your pipeline" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "First-class GitHub Actions. Drop-in support for GitLab, Jenkins, and any CI that runs commands. Docs are build artifacts, not afterthoughts." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-6" ] ]
            [ ciCard "GitHub Actions" "Official action"
            , ciCard "GitLab CI" "Config template"
            , ciCard "Jenkins" "Pipeline step"
            , ciCard "Nix" "Flake integration"
            ]
        , HH.div
            [ cls [ "mt-12" ] ]
            [ codeBlock
                [ codeLine "# " ".github/workflows/docs.yml"
                , HH.text "\n"
                , HH.span [ cls [ "text-text" ] ] [ HH.text "- uses: straylight/sensenet-publish-action@v1" ]
                , HH.text "\n"
                , HH.span [ cls [ "text-text" ] ] [ HH.text "  with:" ]
                , HH.text "\n"
                , HH.span [ cls [ "text-text" ] ] [ HH.text "    strict: true" ]
                , HH.text "\n"
                , HH.span [ cls [ "text-text" ] ] [ HH.text "    format: html,json-ld" ]
                , HH.text "\n"
                , HH.span [ cls [ "text-text" ] ] [ HH.text "- uses: actions/upload-pages-artifact@v3" ]
                , HH.text "\n"
                , HH.span [ cls [ "text-text" ] ] [ HH.text "  with:" ]
                , HH.text "\n"
                , HH.span [ cls [ "text-text" ] ] [ HH.text "    path: ./docs/build" ]
                ]
            ]
        ]
    ]

ciCard :: forall w i. String -> String -> HH.HTML w i
ciCard name desc =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center hover:border-teal-400/50 transition-colors" ] ]
    [ HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text desc ]
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
            [ dxCard ">" "Fast incremental builds"
                "Only re-analyze changed files. Scope graph is cached between builds."
            , dxCard "{}" "Watch mode"
                "Live reload during development. See doc changes instantly."
            , dxCard "!" "Clear error messages"
                "Human-readable errors with suggestions and context."
            , dxCard "=" "Zero config start"
                "Sensible defaults. Add a config file when you need it."
            , dxCard "++" "Editor integration"
                "LSP support for doc previews and reference navigation."
            , dxCard "$" "Open source core"
                "MIT licensed. Extend and contribute."
            ]
        ]
    ]

dxCard :: forall w i. String -> String -> String -> HH.HTML w i
dxCard icon title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 hover:border-teal-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3 mb-3" ] ]
        [ HH.span [ cls [ "text-teal-400 font-mono text-xl" ] ] [ HH.text icon ]
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
            [ HH.text "Ready for docs that actually work?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Free for open source. Simple pricing for teams and enterprises." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/sensenet/publish/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-teal-400 text-background font-medium rounded-md hover:bg-teal-400/90 transition-colors" ]
                ]
                [ HH.text "Get started" ]
            , HH.a
                [ HP.href "/sensenet/publish/docs"
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
    [ cls [ "inline-block px-3 py-1 bg-teal-400/10 border border-teal-400/20 rounded-full text-teal-400 text-sm font-medium mb-4" ] ]
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
    [ HH.span [ cls [ "text-teal-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
