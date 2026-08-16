module Orbital.Pages.Infer (content) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

content :: forall w i. HH.HTML w i
content =
  HH.element (HH.ElemName "main")
    [ cls "wrap narrow" ]
    [ hero
    , sectionHeader "01" "Native all the way down"
    , HH.div
        [ cls "infer-features"
        , attr "data-reveal-stagger" "70"
        ]
        [ feature "01" "No Python runtime"
            "A compiled native service starts, loads, schedules, and serves the model. There is no interpreter, environment, or dependency maze in production."
        , feature "02" "Binary on the wire"
            "A purpose-built, versioned binary protocol moves inference requests without turning the hot path into generic HTTP and JSON plumbing."
        , feature "03" "Own the hot path"
            "The native runtime controls request handling, batching, memory, and scheduling as one system instead of a stack of wrappers around wrappers."
        ]
    , sectionHeader "02" "Language and diffusion, one engine"
    , HH.div
        [ cls "infer-workloads"
        , attr "data-reveal-stagger" "80"
        ]
        [ workload "LLM"
            "Language models"
            "Serve language-model workloads through a transport built for streaming model output, without making every response pay a text-serialization tax."
            "Latency and throughput targets publish per supported model and accelerator."
        , workload "DIFF"
            "Diffusion models"
            "Run diffusion workloads on the same native runtime and binary protocol, with the serving path designed around generated media rather than retrofitted from a chat API."
            "Image-generation targets publish with model, resolution, steps, and hardware pinned."
        ]
    , sectionHeader "03" "Built for the benchmark"
    , HH.div [ cls "metalist", attr "data-reveal" "" ]
        [ metaRow "Latency"
            "Target: minimize time to first output and end-to-end generation time on supported workloads."
        , metaRow "Throughput"
            "Target: maximize useful model output per accelerator-dollar, not requests detached from their actual work."
        , metaRow "Protocol"
            "Design: versioned binary messages from client to scheduler, with no JSON in the inference hot path."
        , metaRow "Method"
            "Every result will name the model, weights, quantization, hardware, driver, workload, concurrency, and comparison baseline, with raw logs published."
        ]
    , HH.div [ cls "statband", attr "data-reveal" "" ]
        [ stat "TBD" "Time to first output"
        , stat "TBD" "Language throughput"
        , stat "TBD" "Diffusion throughput"
        , stat "TBD" "Cost per output"
        ]
    , HH.p [ cls "infer-benchmark-note", attr "data-reveal" "" ]
        [ HH.text "The performance target is the best latency, throughput, and economics money can buy for supported workloads. Results stay blank until the measurements and their basis are public." ]
    , sectionHeader "04" "The shortest serving path we can build"
    , HH.div [ cls "infer-flow", attr "data-reveal" "" ]
        [ flowStep "01" "Client"
        , flowArrow
        , flowStep "02" "Binary protocol"
        , flowArrow
        , flowStep "03" "Native scheduler"
        , flowArrow
        , flowStep "04" "Accelerator"
        ]
    , HH.div [ cls "infer-principle glass", attr "data-reveal" "" ]
        [ HH.span [ cls "infer-principle-key" ] [ HH.text "Operating principle" ]
        , HH.p_
            [ HH.text "Every layer in the serving path must justify its latency, memory, and operational cost. If it does not help the model produce useful output, it does not belong there." ]
        ]
    , callToAction
    ]

hero :: forall w i. HH.HTML w i
hero =
  HH.element (HH.ElemName "header") [ cls "phero infer-hero" ]
    [ HH.div [ cls "phero-head" ]
        [ HH.div [ cls "eyebrow", attr "data-reveal" "" ]
            [ HH.span [ cls "ns" ] [ HH.text "ORBITAL" ]
            , HH.span [ cls "sep" ] [ HH.text "//" ]
            , HH.span [ cls "nm" ] [ HH.text "infer" ]
            , HH.span [ cls "badge2 is-warn", attr "data-orbital" "badge" ]
                [ HH.span [ cls "badge2-dot" ] []
                , HH.text "in development"
                ]
            ]
        , HH.h1 [ attr "data-reveal" "" ]
            [ HH.text "Inference without the interpreter tax." ]
        ]
    , HH.div_
        [ HH.p [ cls "sub", attr "data-reveal" "", HP.style "margin-top:0" ]
            [ HH.b_ [ HH.text "INFER" ]
            , HH.text " is a native inference engine for language and diffusion models. No Python runtime. No JSON in the hot path. A custom binary protocol carries requests from client to scheduler."
            ]
        , waitlist
        , HH.p [ cls "hero-note", attr "data-reveal" "" ]
            [ HH.text "Performance target: the best latency and throughput per dollar available for supported workloads. Benchmarks publish before release." ]
        , HH.div [ cls "meta", attr "data-reveal" "" ]
            [ HH.span_ [ HH.b_ [ HH.text "Runtime" ], HH.text " native" ]
            , HH.span_ [ HH.b_ [ HH.text "Protocol" ], HH.text " binary" ]
            , HH.span_ [ HH.b_ [ HH.text "Workloads" ], HH.text " language + diffusion" ]
            ]
        ]
    , HH.div [ cls "hero-visual", attr "data-reveal" "" ]
        [ HH.div [ cls "term" ]
            [ HH.div [ cls "term-bar" ]
                [ HH.i_ []
                , HH.i_ []
                , HH.i_ []
                , HH.span [ cls "tt" ] [ HH.text "orbital infer / native runtime" ]
                ]
            , HH.element (HH.ElemName "pre") []
                [ HH.text "$ orbital infer serve model.orb\n"
                , HH.span [ cls "ok" ] [ HH.text "✓ native runtime ready\n" ]
                , HH.span [ cls "ok" ] [ HH.text "✓ binary transport ready\n" ]
                , HH.span [ cls "ok" ] [ HH.text "✓ model resident\n" ]
                , HH.span [ cls "ac" ] [ HH.text "→ accepting inference requests " ]
                , HH.span [ cls "cur" ] []
                ]
            ]
        , HH.div [ cls "claim-slot" ]
            [ HH.div [ cls "ck" ] [ HH.text "Benchmark status" ]
            , HH.p_
                [ HH.text "Numbers are withheld until the hardware, models, workloads, baselines, and raw results are pinned and public." ]
            ]
        ]
    ]

waitlist :: forall w i. HH.HTML w i
waitlist =
  HH.form
    [ cls "ea-form"
    , HP.id "early-access"
    , attr "data-waitlist" "infer"
    , attr "data-reveal" ""
    ]
    [ HH.div [ cls "ea-fields" ]
        [ HH.input
            [ attr "type" "email"
            , HP.name "email"
            , attr "autocomplete" "email"
            , attr "inputmode" "email"
            , attr "required" ""
            , HP.placeholder "you@company.com"
            , attr "aria-label" "Work email"
            ]
        , HH.select
            [ HP.name "builds-with"
            , attr "autocomplete" "off"
            , attr "aria-label" "Inference workload"
            ]
            [ HH.option [ HP.value "", attr "disabled" "", attr "selected" "" ]
                [ HH.text "What do you run? (optional)" ]
            , HH.option [ HP.value "Language models" ] [ HH.text "Language models" ]
            , HH.option [ HP.value "Diffusion models" ] [ HH.text "Diffusion models" ]
            , HH.option [ HP.value "Both" ] [ HH.text "Both" ]
            , HH.option [ HP.value "Something else" ] [ HH.text "Something else" ]
            ]
        ]
    , HH.div [ cls "ea-row" ]
        [ HH.button [ attr "type" "submit", cls "btn primary" ] [ HH.text "Get early access" ]
        , HH.a [ cls "link-cta", HP.href "pricing.html" ] [ HH.text "See pricing" ]
        ]
    , HH.p [ cls "ea-hint" ]
        [ HH.text "Tell us the model and hardware after signup. We want the workload that hurts." ]
    , HH.p [ cls "ea-msg", attr "hidden" "" ]
        [ HH.text "That did not go through. Check the address and try again." ]
    , HH.div [ cls "ea-count", attr "data-waitlist-count" "", attr "hidden" "" ]
        [ HH.b_ [], HH.text " signups on the early-access list" ]
    ]

sectionHeader :: forall w i. String -> String -> HH.HTML w i
sectionHeader number title =
  HH.div [ cls "sh", attr "data-reveal" "" ]
    [ HH.span [ cls "n" ] [ HH.text number ]
    , HH.h2_ [ HH.text title ]
    ]

feature :: forall w i. String -> String -> String -> HH.HTML w i
feature number title description =
  HH.div [ cls "glass feat", attr "data-reveal" "" ]
    [ HH.div [ cls "fk" ] [ HH.text number ]
    , HH.h3_ [ HH.text title ]
    , HH.p_ [ HH.text description ]
    ]

workload :: forall w i. String -> String -> String -> String -> HH.HTML w i
workload label title description note =
  HH.div [ cls "glass infer-workload", attr "data-reveal" "" ]
    [ HH.div [ cls "infer-workload-label" ] [ HH.text label ]
    , HH.h3_ [ HH.text title ]
    , HH.p_ [ HH.text description ]
    , HH.div [ cls "infer-workload-note" ] [ HH.text note ]
    ]

metaRow :: forall w i. String -> String -> HH.HTML w i
metaRow label description =
  HH.div [ cls "metarow" ]
    [ HH.span [ cls "my" ] [ HH.text label ]
    , HH.span [ cls "mt" ] [ HH.text description ]
    ]

stat :: forall w i. String -> String -> HH.HTML w i
stat value label =
  HH.div [ cls "st" ]
    [ HH.span [ cls "v" ] [ HH.text value ]
    , HH.span [ cls "k" ] [ HH.text label ]
    ]

flowStep :: forall w i. String -> String -> HH.HTML w i
flowStep number label =
  HH.div [ cls "infer-flow-step" ]
    [ HH.span [ cls "infer-flow-number" ] [ HH.text number ]
    , HH.span [ cls "infer-flow-label" ] [ HH.text label ]
    ]

flowArrow :: forall w i. HH.HTML w i
flowArrow = HH.span [ cls "infer-flow-arrow", attr "aria-hidden" "true" ] [ HH.text "→" ]

callToAction :: forall w i. HH.HTML w i
callToAction =
  HH.div [ cls "ctaband", attr "data-reveal" "" ]
    [ HH.h2_ [ HH.text "Bring the hard workload." ]
    , HH.p_
        [ HH.text "Join early access. We want the model, hardware, and serving problem your current stack cannot make fast enough." ]
    , HH.div [ cls "cta" ]
        [ HH.a [ cls "btn primary", HP.href "#early-access" ] [ HH.text "Get early access" ]
        , HH.a [ cls "btn", HP.href "pricing.html" ] [ HH.text "See pricing" ]
        ]
    ]

cls :: forall r i. String -> HP.IProp (class :: String | r) i
cls = HP.class_ <<< HH.ClassName

attr :: forall r i. String -> String -> HP.IProp r i
attr name = HP.attr (HH.AttrName name)
