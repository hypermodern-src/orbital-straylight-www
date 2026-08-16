-- | sensenet//build Documentation
module Straylight.Pages.Products.SensenetBuild.Docs 
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
            [ sidebarLink "/sensenet/build/docs" "Overview" currentPath
            , sidebarLink "/sensenet/build/docs/quickstart" "Quick Start" currentPath
            ]
        , sidebarSection "Guides"
            [ sidebarLink "/sensenet/build/docs/dhall" "Dhall Configuration" currentPath
            , sidebarLink "/sensenet/build/docs/lean4" "Lean4 Proofs" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/sensenet/build/docs/cli" "CLI Reference" currentPath
            , sidebarLink "/sensenet/build/docs/api" "API Reference" currentPath
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
              , if href == currentPath then "bg-green-400/10 text-green-400 font-medium" else "text-muted-foreground hover:text-text hover:bg-card" ] ]
        [ HH.text label ] ]

renderStatic :: forall w i. String -> HH.HTML w i
renderStatic path = HH.div [ cls [ "max-w-[1100px] mx-auto px-6 py-12" ] ]
    [ HH.div [ cls [ "grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-12" ] ] [ sidebar path, renderContent path ] ]

renderContent :: forall w i. String -> HH.HTML w i
renderContent path
  | path == "/sensenet/build/docs" = overviewContent
  | path == "/sensenet/build/docs/quickstart" = quickstartContent
  | path == "/sensenet/build/docs/dhall" = dhallContent
  | path == "/sensenet/build/docs/lean4" = lean4Content
  | path == "/sensenet/build/docs/cli" = cliContent
  | path == "/sensenet/build/docs/api" = apiContent
  | otherwise = overviewContent

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "sensenet//build Documentation" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "Typed build system with formal verification. Dhall configs. Lean4-proven derivations." ]
    , codeBlock [ HH.text "# Build with proofs\nsensenet-build --verify ./derivation.dhall" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-12 mb-4" ] ] [ HH.text "Why sensenet//build?" ]
    , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2 mb-8" ] ]
        [ HH.li_ [ HH.text "Type-safe build configurations with Dhall" ]
        , HH.li_ [ HH.text "Lean4 proofs for derivation correctness" ]
        , HH.li_ [ HH.text "Content-addressed artifacts with attestations" ]
        , HH.li_ [ HH.text "Hermetic builds by default" ]
        ]
    ]

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Quick Start" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "Get started with sensenet//build in 5 minutes." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Installation" ]
    , codeBlock [ HH.text "# Install via nix\nnix profile install github:straylight-software/sensenet-build\n\n# Or use the binary cache\nnix run github:straylight-software/sensenet-build -- --help" ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Create your first build" ]
    , codeBlock [ HH.text "# Initialize a new project\nsensenet-build init my-project\ncd my-project\n\n# Build with verification\nsensenet-build --verify" ]
    ]

dhallContent :: forall w i. HH.HTML w i
dhallContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Dhall Configuration" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "sensenet//build uses Dhall for type-safe, programmable build configurations." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Basic derivation" ]
    , codeBlock [ HH.text "let Build = https://build.sensenet.dev/schemas/v1.dhall\n\nin Build.derivation {\n  name = \"my-package\",\n  version = \"1.0.0\",\n  src = ./src,\n  builder = Build.builders.cargo\n}" ]
    ]

lean4Content :: forall w i. HH.HTML w i
lean4Content =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Lean4 Proofs" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "Prove properties about your builds using Lean4." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Proof obligations" ]
    , codeBlock [ HH.text "-- Prove that output hash is deterministic\ntheorem hash_deterministic (d : Derivation) :\n  build d = build d := by\n  rfl" ]
    ]

cliContent :: forall w i. HH.HTML w i
cliContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "CLI Reference" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "Complete reference for the sensenet-build command-line interface." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Commands" ]
    , codeBlock [ HH.text "sensenet-build [OPTIONS] [COMMAND]\n\nCommands:\n  init      Initialize a new project\n  build     Build the project\n  verify    Verify build proofs\n  clean     Clean build artifacts\n  publish   Publish to cache" ]
    ]

apiContent :: forall w i. HH.HTML w i
apiContent =
  HH.article [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "API Reference" ]
    , HH.p [ cls [ "text-muted-foreground mb-8" ] ] [ HH.text "HTTP API for programmatic access to sensenet//build." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Endpoints" ]
    , codeBlock [ HH.text "POST /api/v1/build\nGET  /api/v1/derivation/:hash\nGET  /api/v1/attestation/:hash\nPOST /api/v1/verify" ]
    ]
