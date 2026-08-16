-- | omega//proxy Documentation
module Straylight.Pages.Products.OmegaProxy.Docs 
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

sidebar :: forall w i. String -> HH.HTML w i
sidebar currentPath =
  HH.nav
    [ cls [ "lg:sticky lg:top-24 lg:self-start" ] ]
    [ HH.div
        [ cls [ "space-y-6" ] ]
        [ sidebarSection "Getting Started"
            [ sidebarLink "/omega/proxy/docs" "Overview" currentPath
            , sidebarLink "/omega/proxy/docs/quickstart" "Quick Start" currentPath
            , sidebarLink "/omega/proxy/docs/installation" "Installation" currentPath
            ]
        , sidebarSection "Core Concepts"
            [ sidebarLink "/omega/proxy/docs/sigil-protocol" "SIGIL Protocol" currentPath
            , sidebarLink "/omega/proxy/docs/sse-translation" "SSE Translation" currentPath
            , sidebarLink "/omega/proxy/docs/reset-on-ambiguity" "Reset-on-Ambiguity" currentPath
            , sidebarLink "/omega/proxy/docs/tool-call-repair" "Tool Call Repair" currentPath
            ]
        , sidebarSection "Providers"
            [ sidebarLink "/omega/proxy/docs/providers" "Provider Setup" currentPath
            , sidebarLink "/omega/proxy/docs/providers/openai" "OpenAI" currentPath
            , sidebarLink "/omega/proxy/docs/providers/anthropic" "Anthropic" currentPath
            , sidebarLink "/omega/proxy/docs/providers/ollama" "Ollama (Local)" currentPath
            ]
        , sidebarSection "Deployment"
            [ sidebarLink "/omega/proxy/docs/deployment" "Deployment Guide" currentPath
            , sidebarLink "/omega/proxy/docs/deployment/docker" "Docker" currentPath
            , sidebarLink "/omega/proxy/docs/deployment/kubernetes" "Kubernetes" currentPath
            , sidebarLink "/omega/proxy/docs/deployment/zeromq" "ZeroMQ Setup" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/omega/proxy/docs/api" "API Reference" currentPath
            , sidebarLink "/omega/proxy/docs/cli" "CLI Reference" currentPath
            , sidebarLink "/omega/proxy/docs/config" "Configuration" currentPath
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
                  then "bg-orange-400/10 text-orange-400 font-medium" 
                  else "text-muted-foreground hover:text-text hover:bg-card"
              ]
        ]
        [ HH.text label ]
    ]

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

renderContent :: forall w i. String -> HH.HTML w i
renderContent path = case path of
  "/omega/proxy/docs" -> overviewContent
  "/omega/proxy/docs/quickstart" -> quickstartContent
  "/omega/proxy/docs/sigil-protocol" -> sigilProtocolContent
  "/omega/proxy/docs/providers" -> providersContent
  "/omega/proxy/docs/deployment" -> deploymentContent
  "/omega/proxy/docs/api" -> apiContent
  _ -> overviewContent

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  HH.article
    [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "omega//proxy Documentation" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] 
        [ HH.text "Verified inference proxy. jaylene-slide ingress: SSE to SIGIL over ZeroMQ. Reset-on-ambiguity. 200-600% wire compression." ]
    , HH.h2 [ cls [ "text-2xl font-semibold text-text mt-12 mb-4" ] ] [ HH.text "What is omega//proxy?" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ] 
        [ HH.text "omega//proxy sits between your LLM provider and your applications, translating Server-Sent Events (SSE) into the SIGIL protocol over ZeroMQ. It provides verified inference with reset-on-ambiguity semantics, fixing broken tool calls automatically." ]
    , HH.h2 [ cls [ "text-2xl font-semibold text-text mt-12 mb-4" ] ] [ HH.text "Key Features" ]
    , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2 mb-6" ] ]
        [ HH.li_ [ HH.span [ cls [ "text-orange-400" ] ] [ HH.text "SSE to SIGIL" ], HH.text " — Real-time translation via jaylene-slide ingress" ]
        , HH.li_ [ HH.span [ cls [ "text-orange-400" ] ] [ HH.text "Reset-on-ambiguity" ], HH.text " — Prevents hallucination cascades" ]
        , HH.li_ [ HH.span [ cls [ "text-orange-400" ] ] [ HH.text "200-600% compression" ], HH.text " — Wire-level SIGIL optimization" ]
        , HH.li_ [ HH.span [ cls [ "text-orange-400" ] ] [ HH.text "Tool call repair" ], HH.text " — Fixes malformed LLM tool responses" ]
        , HH.li_ [ HH.span [ cls [ "text-orange-400" ] ] [ HH.text "Multi-provider" ], HH.text " — OpenAI, Anthropic, Google, Ollama, custom" ]
        ]
    , HH.h2 [ cls [ "text-2xl font-semibold text-text mt-12 mb-4" ] ] [ HH.text "Replaces" ]
    , HH.p [ cls [ "text-muted-foreground" ] ] 
        [ HH.text "LiteLLM, raw OpenAI SDK, broken tool calls, custom proxy scripts." ]
    ]

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  HH.article
    [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Quick Start" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] [ HH.text "Get omega//proxy running in under 60 seconds." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Docker (Recommended)" ]
    , codeBlock
        [ HH.text "docker run -p 8080:8080 -p 5555:5555 \\\n"
        , HH.text "  -e OPENAI_API_KEY=$OPENAI_API_KEY \\\n"
        , HH.text "  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \\\n"
        , HH.text "  straylight/omega-proxy"
        ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Nix" ]
    , codeBlock
        [ HH.text "nix run github:straylight-software/omega-proxy"
        ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Connect via ZeroMQ" ]
    , codeBlock
        [ HH.text "# Subscribe to SIGIL frames\n"
        , HH.text "zmq-sub tcp://localhost:5555\n\n"
        , HH.text "# Or use the HTTP API\n"
        , HH.text "curl http://localhost:8080/v1/chat/completions \\\n"
        , HH.text "  -H \"Content-Type: application/json\" \\\n"
        , HH.text "  -d '{\"model\": \"gpt-4\", \"messages\": [...]}'"
        ]
    ]

sigilProtocolContent :: forall w i. HH.HTML w i
sigilProtocolContent =
  HH.article
    [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "SIGIL Protocol" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] 
        [ HH.text "SIGIL is a wire-optimized protocol for verified LLM inference. It achieves 200-600% compression over raw JSON SSE." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Frame Structure" ]
    , codeBlock
        [ HH.text "(sigil-frame\n"
        , HH.text "  :type token\n"
        , HH.text "  :content \"Hello\"\n"
        , HH.text "  :verified true\n"
        , HH.text "  :confidence 0.97\n"
        , HH.text "  :seq 42)"
        ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Verification" ]
    , HH.p [ cls [ "text-muted-foreground" ] ] 
        [ HH.text "Each frame includes verification metadata. When confidence drops below threshold, reset-on-ambiguity triggers automatic context recovery." ]
    ]

providersContent :: forall w i. HH.HTML w i
providersContent =
  HH.article
    [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Provider Setup" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] 
        [ HH.text "omega//proxy supports all major LLM providers with a unified API." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Supported Providers" ]
    , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2 mb-6" ] ]
        [ HH.li_ [ HH.text "OpenAI (GPT-4, GPT-4o, o1)" ]
        , HH.li_ [ HH.text "Anthropic (Claude 3.5 Sonnet, Opus)" ]
        , HH.li_ [ HH.text "Google (Gemini)" ]
        , HH.li_ [ HH.text "Mistral (Mistral Large)" ]
        , HH.li_ [ HH.text "Ollama (local models)" ]
        , HH.li_ [ HH.text "Custom endpoints" ]
        ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Configuration" ]
    , codeBlock
        [ HH.text "# config.yaml\n"
        , HH.text "providers:\n"
        , HH.text "  openai:\n"
        , HH.text "    api_key: ${OPENAI_API_KEY}\n"
        , HH.text "    models: [gpt-4, gpt-4o]\n"
        , HH.text "  anthropic:\n"
        , HH.text "    api_key: ${ANTHROPIC_API_KEY}\n"
        , HH.text "    models: [claude-3-5-sonnet]"
        ]
    ]

deploymentContent :: forall w i. HH.HTML w i
deploymentContent =
  HH.article
    [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "Deployment Guide" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] 
        [ HH.text "Deploy omega//proxy to production with Docker, Kubernetes, or bare metal." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Production Checklist" ]
    , HH.ul [ cls [ "list-disc list-inside text-muted-foreground space-y-2 mb-6" ] ]
        [ HH.li_ [ HH.text "Configure ZeroMQ bind addresses" ]
        , HH.li_ [ HH.text "Set up provider API keys" ]
        , HH.li_ [ HH.text "Configure reset-on-ambiguity thresholds" ]
        , HH.li_ [ HH.text "Enable TLS for HTTP endpoints" ]
        , HH.li_ [ HH.text "Set up monitoring (Prometheus, Grafana)" ]
        ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "Docker Compose" ]
    , codeBlock
        [ HH.text "version: '3.8'\n"
        , HH.text "services:\n"
        , HH.text "  omega-proxy:\n"
        , HH.text "    image: straylight/omega-proxy:latest\n"
        , HH.text "    ports:\n"
        , HH.text "      - \"8080:8080\"\n"
        , HH.text "      - \"5555:5555\"\n"
        , HH.text "    environment:\n"
        , HH.text "      - OPENAI_API_KEY\n"
        , HH.text "      - ANTHROPIC_API_KEY\n"
        , HH.text "      - OMEGA_AMBIGUITY_THRESHOLD=0.3"
        ]
    ]

apiContent :: forall w i. HH.HTML w i
apiContent =
  HH.article
    [ cls [ "prose prose-invert max-w-none" ] ]
    [ HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text "API Reference" ]
    , HH.p [ cls [ "text-muted-foreground mb-6" ] ] 
        [ HH.text "omega//proxy exposes an OpenAI-compatible HTTP API and SIGIL frames over ZeroMQ." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "HTTP Endpoints" ]
    , HH.h3 [ cls [ "text-lg font-medium text-text mt-6 mb-2" ] ] [ HH.text "POST /v1/chat/completions" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ] [ HH.text "OpenAI-compatible chat completions endpoint with verified inference." ]
    , HH.h3 [ cls [ "text-lg font-medium text-text mt-6 mb-2" ] ] [ HH.text "GET /health" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ] [ HH.text "Health check endpoint for load balancers." ]
    , HH.h3 [ cls [ "text-lg font-medium text-text mt-6 mb-2" ] ] [ HH.text "GET /metrics" ]
    , HH.p [ cls [ "text-muted-foreground mb-4" ] ] [ HH.text "Prometheus metrics endpoint." ]
    , HH.h2 [ cls [ "text-xl font-semibold text-text mt-8 mb-4" ] ] [ HH.text "ZeroMQ Sockets" ]
    , HH.h3 [ cls [ "text-lg font-medium text-text mt-6 mb-2" ] ] [ HH.text "PUB tcp://*:5555" ]
    , HH.p [ cls [ "text-muted-foreground" ] ] [ HH.text "SIGIL frames published for all inference responses. Subscribe to receive verified tokens in real-time." ]
    ]
