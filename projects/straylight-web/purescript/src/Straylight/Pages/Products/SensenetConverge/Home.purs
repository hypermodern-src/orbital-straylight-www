-- | sensenet//converge Home Page
-- | Typed infrastructure-as-code. Desired-state convergence.
module Straylight.Pages.Products.SensenetConverge.Home 
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-purple-400/10 border border-purple-400/20 rounded-full text-purple-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-purple-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
          
          -- Headline
        , HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Infrastructure that"
            , HH.br_
            , HH.span [ cls [ "text-purple-400" ] ] [ HH.text "converges" ]
            , HH.text ", not drifts"
            ]
          
          -- Subheadline
        , HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Typed infrastructure-as-code. Desired-state convergence. No state files to corrupt. No drift to detect. Your infra is always what your code says it is." ]
          
          -- CTAs
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/converge/pricing" "Get started"
            , secondaryButton "/sensenet/converge/docs" "Read the docs"
            ]
          
          -- Social proof
        , HH.p
            [ cls [ "mt-12 text-sm text-muted-foreground" ] ]
            [ HH.text "Trusted by teams who got tired of state file corruption" ]
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
                [ HH.text "Why sensenet//converge?" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-xl mx-auto" ] ]
                [ HH.text "Built by engineers who got tired of state file corruption, drift nightmares, and untyped YAML sprawl." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ featureCard "~>" "Desired-state convergence" 
                "Declare what you want. Converge runs continuously until reality matches intent. No plan/apply dance."
            , featureCard "0" "No state files"
                "State is queried live from your infrastructure. No S3 buckets to manage. No locks to break. No corruption."
            , featureCard "=" "Drift detection"
                "Real-time drift detection built-in. Know instantly when reality diverges from intent. Auto-remediate or alert."
            , featureCard "::" "Typed configs"
                "Full type system for infrastructure. Catch misconfigurations at compile time. IDE autocompletion for your cloud."
            , featureCard "!" "Idempotent operations"
                "Every operation is idempotent by construction. Run converge 1000 times, get the same result. Proven correct."
            , featureCard "*" "Cloud-agnostic"
                "AWS, GCP, Azure, Kubernetes, bare metal. One language, one mental model. Portable infrastructure definitions."
            ]
        ]
    ]

featureCard :: forall w i. String -> String -> String -> HH.HTML w i
featureCard icon title description =
  HH.div
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-purple-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-purple-400 mb-4 font-mono" ] ]
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
                [ HH.text "The infrastructure platform that converges" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "Others make you manage state files and pray for no drift. We continuously converge to your declared intent." ]
            ]
        , HH.div
            [ cls [ "overflow-x-auto -mx-6 px-6" ] ]
            [ HH.table
                [ cls [ "w-full min-w-[700px] text-sm" ] ]
                [ HH.thead_
                    [ HH.tr
                        [ cls [ "border-b border-border" ] ]
                        [ HH.th [ cls [ "py-4 text-left text-muted-foreground font-medium w-40" ] ] [ HH.text "" ]
                        , HH.th [ cls [ "py-4 text-center text-purple-400 font-bold" ] ] [ HH.text "converge" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Terraform" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Pulumi" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Ansible" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "State management" "Live query" "State file" "State file" "No state"
                    , comparisonRow "Drift detection" "Real-time" "Manual" "Manual" "No"
                    , comparisonRow "Type system" "Full types" "HCL" "Language types" "YAML"
                    , comparisonRow "Convergence" "Continuous" "Plan/Apply" "Plan/Apply" "Playbook"
                    , comparisonRow "Idempotency" "Proven" "Best effort" "Best effort" "Module-dependent"
                    , comparisonRow "Multi-cloud" "Native" "Providers" "Providers" "Modules"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Comparison based on default configurations." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us terraform pulumi ansible =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-purple-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center text-muted-foreground" ] ] [ HH.text terraform ]
    , HH.td [ cls [ "py-3 text-center text-muted-foreground" ] ] [ HH.text pulumi ]
    , HH.td [ cls [ "py-3 text-center text-muted-foreground" ] ] [ HH.text ansible ]
    ]

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
                [ HH.text "Get started in 30 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Install converge"
            , codeLine "$ " "nix profile install github:straylight-software/converge"
            , HH.text "\n"
            , codeLine "# " "Initialize a project"
            , codeLine "$ " "converge init my-infra && cd my-infra"
            , HH.text "\n"
            , codeLine "# " "Converge to desired state"
            , codeLine "$ " "converge up"
            , HH.text "\n"
            , codeLine "# " "Watch for drift"
            , codeLine "$ " "converge watch"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/converge/docs"
                , cls [ "text-purple-400 hover:text-purple-400/80 transition-colors" ]
                ]
                [ HH.text "Full quickstart guide ->" ]
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
            [ HH.text "Ready to stop managing state files?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Free tier includes 10 resources and unlimited drift detection. No credit card required." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/sensenet/converge/pricing" "Start for free"
            , secondaryButton "/sensenet/converge/features" "See all features"
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
    , cls [ "inline-flex items-center justify-center px-8 py-4 bg-purple-400 text-background font-medium rounded-md hover:bg-purple-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-8 py-4 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
