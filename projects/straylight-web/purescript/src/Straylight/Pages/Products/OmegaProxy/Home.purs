-- | omega//proxy Home Page
-- | Landing page for the verified inference proxy
module Straylight.Pages.Products.OmegaProxy.Home 
  ( homePage
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

homePage :: forall q i o m. H.Component q i o m
homePage = H.mkComponent
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-orange-400/10 border border-orange-400/20 rounded-full text-orange-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-orange-400 rounded-full animate-pulse" ] ] []
            , HH.text "Verified Inference Proxy"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Verified inference"
            , HH.br_
            , HH.text "with "
            , HH.span [ cls [ "text-orange-400" ] ] [ HH.text "200-600% compression" ]
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "jaylene-slide ingress: SSE to SIGIL over ZeroMQ. Reset-on-ambiguity prevents hallucination cascades. Fixes broken tool calls. Replaces LiteLLM, raw OpenAI SDK, and custom proxy scripts." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/omega/proxy/docs" "Get started"
            , secondaryButton "https://github.com/straylight-software/omega-proxy" "View source"
            ]
        , -- Install options
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-3" ] ]
            [ HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "docker run -p 8080:8080 straylight/omega-proxy"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-orange-400 transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:straylight-software/omega-proxy"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-orange-400 transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-orange-400/60" ] ] [ HH.text "replaces " ]
            , HH.text "LiteLLM, raw OpenAI SDK, broken tool calls, custom proxy scripts"
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
                [ HH.text "Why omega//proxy?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built for agents that need verified inference, wire compression, and reliable tool calls." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard ">" "SSE to SIGIL"
                "jaylene-slide ingress translates Server-Sent Events to SIGIL frames over ZeroMQ. No intermediate buffering. Real-time verified tokens."
            , featureCard "!" "Reset-on-ambiguity"
                "Prevents hallucination cascades. Automatic state reset on ambiguous responses. No corrupt context propagation. Clean recovery."
            , featureCard "◎" "200-600% Compression"
                "Wire-level compression reduces bandwidth dramatically. SIGIL protocol optimizes token transmission. Lower latency, lower costs."
            , featureCard "⚡" "Fixes Broken Tool Calls"
                "LLM providers often return malformed tool calls. omega//proxy validates, repairs, and ensures structured responses work every time."
            , featureCard "↔" "Multi-Provider"
                "OpenAI, Anthropic, Google, Mistral, local models via Ollama. Single unified API. Hot-swap providers without code changes."
            , featureCard "∴" "Verified Inference"
                "SIGIL protocol ensures structured, verified communication. Every response validated against schema. Tamper-evident audit logs."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-orange-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-orange-400 mb-4 font-mono" ] ]
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
                [ HH.text "The verified inference layer" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others pass through requests and hope for the best. We verify, compress, and fix what the LLM returns." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-orange-400 font-bold" ] ] [ HH.text "omega//proxy" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "LiteLLM" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "OpenRouter" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Direct API" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Wire Compression" "200-600%" "no" "no" "no"
                    , comparisonRow "Fixes Tool Calls" "automatic" "no" "no" "no"
                    , comparisonRow "Reset-on-ambiguity" "automatic" "no" "no" "no"
                    , comparisonRow "SSE to SIGIL" "native" "no" "no" "no"
                    , comparisonRow "ZeroMQ transport" "yes" "no" "no" "no"
                    , comparisonRow "Provider support" "all + local" "all" "most" "one"
                    ]
                ]
            ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us litellm openrouter direct =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-orange-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell litellm ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell openrouter ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell direct ]
    ]

compCell :: forall w i. String -> HH.HTML w i
compCell value =
  HH.span
    [ cls [ case value of
              "no" -> "text-muted-foreground/50"
              "none" -> "text-muted-foreground/50"
              "n/a" -> "text-muted-foreground/50"
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
                [ HH.text "Deploy in 60 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Docker (quickest)"
            , codeLine "$ " "docker run -p 8080:8080 \\"
            , codeLine "    " "-e OPENAI_API_KEY=$OPENAI_API_KEY \\"
            , codeLine "    " "-e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \\"
            , codeLine "    " "straylight/omega-proxy"
            , HH.text "\n"
            , codeLine "# " "Or via Nix"
            , codeLine "$ " "nix run github:straylight-software/omega-proxy"
            , HH.text "\n"
            , codeLine "# " "Connect via ZeroMQ for SIGIL frames"
            , codeLine "$ " "zmq-sub tcp://localhost:5555"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/omega/proxy/docs"
                , cls [ "text-orange-400 hover:text-orange-400/80 transition-colors" ]
                ]
                [ HH.text "Full deployment guide ->" ]
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
            [ HH.text "Ready for verified inference?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "omega//proxy is open source and free to self-host. Managed hosting available for teams." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/omega/proxy/docs" "Deploy now"
            , secondaryButton "/omega/proxy/pricing" "View pricing"
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-orange-400 text-background font-medium rounded-md hover:bg-orange-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
