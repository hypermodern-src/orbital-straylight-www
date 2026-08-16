-- | sensenet//watch Product Page
-- | Build Observability and Monitoring
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.SensenetWatch where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

sensenetWatchPage :: forall q i o m. H.Component q i o m
sensenetWatchPage = H.mkComponent
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-indigo-400/10 border border-indigo-400/20 rounded-full text-indigo-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-indigo-400 rounded-full animate-pulse" ] ] []
            , HH.text "Now available"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Build observability"
            , HH.br_
            , HH.text "that actually "
            , HH.span [ cls [ "text-indigo-400" ] ] [ HH.text "helps" ]
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Real-time build tracing. Flaky test detection. Resource monitoring. OpenTelemetry native. Know exactly why your builds fail before your engineers rage-quit." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/signup" "Start free trial"
            , secondaryButton "https://github.com/straylight-software/sensenet-watch" "View source"
            ]
        , -- install options
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-3" ] ]
            [ HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "curl -fsSL watch.straylight.software | sh"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#a5b4fc] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:straylight-software/sensenet-watch"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-[#a5b4fc] transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-indigo-400/60" ] ] [ HH.text "replaces " ]
            , HH.text "Datadog CI, Honeycomb, Grafana dashboards, BuildKite Analytics"
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
                [ HH.text "Why sensenet//watch?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built for engineers who need to debug CI failures at 2am and don't have time for dashboard archaeology." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "◎" "Real-time build tracing"
                "Sub-millisecond span ingestion with distributed trace correlation. See exactly which step failed and why, with full context propagation across parallel jobs."
            , featureCard "⚡" "Performance analytics"
                "Track build duration trends, identify regression patterns, and get actionable recommendations. Know when your 5-minute build became 45 minutes."
            , featureCard "⚠" "Flaky test detection"
                "ML-powered flakiness scoring with automatic quarantine suggestions. Stop wasting CI cycles on tests that fail randomly 3% of the time."
            , featureCard "▣" "Resource monitoring"
                "CPU, memory, disk I/O, network - all correlated with build stages. Find the step that's eating 32GB of RAM before it OOMs your runner."
            , featureCard "◈" "Alert integration"
                "Native PagerDuty, Slack, OpsGenie, and webhook support. Get notified when builds break SLOs, not just when they fail."
            , featureCard "⬡" "OpenTelemetry native"
                "OTLP ingestion with zero config. Works with your existing OTel setup. Export to any backend. No vendor lock-in, ever."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-indigo-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-indigo-400 mb-4 font-mono" ] ]
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
                [ HH.text "Build observability, not dashboard sprawl" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others charge per host and give you generic APM. We give you build-native insights at a flat rate." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[800px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-indigo-400 font-bold" ] ] [ HH.text "sensenet//watch" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Datadog" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Honeycomb" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Grafana" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "BuildKite Analytics" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "Build-native tracing" "yes" "partial" "generic" "manual" "yes"
                    , comparisonRow "OpenTelemetry" "native OTLP" "adapter" "native" "plugin" "no"
                    , comparisonRow "Flaky test detection" "ML-powered" "no" "no" "no" "basic"
                    , comparisonRow "Resource correlation" "automatic" "separate product" "manual" "manual" "no"
                    , comparisonRow "Alert integrations" "15+ native" "yes" "yes" "yes" "Slack only"
                    , comparisonRow "Retention" "90 days" "15 days" "60 days" "varies" "30 days"
                    , comparisonRow "Pricing model" "flat rate" "per host" "per event" "per metric" "per seat"
                    , comparisonRow "Self-hostable" "yes" "no" "no" "yes" "no"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Comparison based on publicly available documentation as of 2024. Features may vary by plan tier." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us datadog honeycomb grafana buildkite =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-indigo-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell datadog ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell honeycomb ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell grafana ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell buildkite ]
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
                [ HH.text "Instrument your builds in 60 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Install the CLI"
            , codeLine "$ " "curl -fsSL https://watch.straylight.software/install.sh | sh"
            , HH.text "\n"
            , codeLine "# " "Or via Nix"
            , codeLine "$ " "nix profile install github:straylight-software/sensenet-watch"
            , HH.text "\n"
            , codeLine "# " "Authenticate with your workspace"
            , codeLine "$ " "sensenet-watch auth login"
            , HH.text "\n"
            , codeLine "# " "Initialize in your repo"
            , codeLine "$ " "sensenet-watch init"
            , HH.text "\n"
            , codeLine "# " "Wrap your build command"
            , codeLine "$ " "sensenet-watch exec -- make build"
            , HH.text "\n"
            , codeLine "# " "Or configure via environment (CI-friendly)"
            , codeLine "$ " "export SENSENET_WATCH_TOKEN=\"sw_....\""
            , codeLine "$ " "export OTEL_EXPORTER_OTLP_ENDPOINT=\"https://ingest.watch.straylight.software\""
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/confirm/docs"
                , cls [ "text-indigo-400 hover:text-indigo-400/80 transition-colors" ]
                ]
                [ HH.text "Full quickstart guide →" ]
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
            [ HH.text "Stop guessing why builds fail" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "sensenet//watch gives you the visibility you need to ship faster. Free for open source, flat-rate for teams." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/signup" "Start free trial"
            , secondaryButton "/pricing" "View pricing"
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-indigo-400 text-background font-medium rounded-md hover:bg-indigo-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
