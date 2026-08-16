-- | sensenet//converge Product Page
-- | Typed Infrastructure-as-Code with Desired-State Convergence
-- | Full product marketing page (armory shape)
module Straylight.Pages.Products.SensenetConverge where

import Prelude

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls, codeBlock)

-- ============================================================
-- COMPONENT
-- ============================================================

sensenetConvergePage :: forall q i o m. H.Component q i o m
sensenetConvergePage = H.mkComponent
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
            [ cls [ "inline-flex items-center gap-2 px-3 py-1 bg-emerald-400/10 border border-emerald-400/20 rounded-full text-emerald-400 text-sm mb-8" ] ]
            [ HH.span [ cls [ "w-2 h-2 bg-emerald-400 rounded-full animate-pulse" ] ] []
            , HH.text "Private beta"
            ]
        , -- Headline
          HH.h1
            [ cls [ "text-4xl md:text-6xl font-bold text-text mb-6 leading-tight" ] ]
            [ HH.text "Infrastructure that"
            , HH.br_
            , HH.span [ cls [ "text-emerald-400" ] ] [ HH.text "converges" ]
            , HH.text ", not drifts"
            ]
        , -- Subheadline
          HH.p
            [ cls [ "text-xl text-muted-foreground mb-10 max-w-2xl mx-auto" ] ]
            [ HH.text "Typed infrastructure-as-code. Desired-state convergence. No state files to corrupt. No drift to detect. Your infra is always what your code says it is." ]
        , -- CTAs
          HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/waitlist" "Join the waitlist"
            , secondaryButton "https://github.com/straylight-software" "View source"
            ]
        , -- install options
          HH.div
            [ cls [ "mt-12 flex flex-col sm:flex-row items-center justify-center gap-3" ] ]
            [ HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "curl -fsSL converge.straylight.software | sh"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-emerald-400 transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            , HH.span [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text "or" ]
            , HH.div
                [ cls [ "bg-[#0a0c0f] border border-[#2a3038] rounded-lg px-5 py-3 font-mono text-sm flex items-center gap-6" ] ]
                [ HH.code
                    [ cls [ "text-[#dde6f0] whitespace-nowrap" ] ]
                    [ HH.span [ cls [ "text-[#596775]" ] ] [ HH.text "$ " ]
                    , HH.text "nix run github:straylight-software/converge"
                    ]
                , HH.button
                    [ cls [ "text-[#596775] hover:text-emerald-400 transition-colors text-xs shrink-0" ] ]
                    [ HH.text "copy" ]
                ]
            ]
        , -- Social proof
          HH.p
            [ cls [ "mt-8 font-mono text-sm text-muted-foreground" ] ]
            [ HH.span [ cls [ "text-emerald-400/60" ] ] [ HH.text "replaces " ]
            , HH.text "Terraform, Pulumi, Ansible, CloudFormation"
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
    [ cls [ "p-6 bg-card border border-border rounded-lg hover:border-emerald-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "text-2xl text-emerald-400 mb-4 font-mono" ] ]
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
                        , HH.th [ cls [ "py-4 text-center text-emerald-400 font-bold" ] ] [ HH.text "converge" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Terraform" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Pulumi" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "Ansible" ]
                        , HH.th [ cls [ "py-4 text-center text-muted-foreground font-medium" ] ] [ HH.text "CloudFormation" ]
                        ]
                    ]
                , HH.tbody_
                    [ comparisonRow "State management" "Live query" "State file" "State file" "No state" "CloudFormation"
                    , comparisonRow "Drift detection" "Real-time" "Manual" "Manual" "No" "Drift detection"
                    , comparisonRow "Type system" "Full types" "HCL" "Language types" "YAML" "YAML"
                    , comparisonRow "Convergence" "Continuous" "Plan/Apply" "Plan/Apply" "Playbook" "Stack update"
                    , comparisonRow "Idempotency" "Proven" "Best effort" "Best effort" "Module-dependent" "Best effort"
                    , comparisonRow "Multi-cloud" "Native" "Providers" "Providers" "Modules" "AWS only"
                    , comparisonRow "State locking" "Not needed" "Required" "Required" "Not needed" "Managed"
                    , comparisonRow "Rollback" "Instant" "Manual" "Manual" "Rerun" "Stack rollback"
                    ]
                ]
            ]
        , HH.p
            [ cls [ "text-center text-muted-foreground text-xs mt-6" ] ]
            [ HH.text "Comparison based on default configurations. Some features may require additional setup in other tools." ]
        ]
    ]

comparisonRow :: forall w i. String -> String -> String -> String -> String -> String -> HH.HTML w i
comparisonRow feature us terraform pulumi ansible cloudformation =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-3 text-muted-foreground font-medium" ] ] [ HH.text feature ]
    , HH.td [ cls [ "py-3 text-center text-emerald-400 font-semibold" ] ] [ HH.text us ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell terraform ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell pulumi ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell ansible ]
    , HH.td [ cls [ "py-3 text-center" ] ] [ compCell cloudformation ]
    ]

compCell :: forall w i. String -> HH.HTML w i
compCell value =
  HH.span
    [ cls [ case value of
              "No" -> "text-muted-foreground/50"
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
                [ HH.text "Get started in 30 seconds" ]
            ]
        , codeBlock
            [ codeLine "# " "Install (Nix)"
            , codeLine "$ " "nix profile install github:straylight-software/converge"
            , HH.text "\n"
            , codeLine "# " "Or via curl"
            , codeLine "$ " "curl -fsSL https://converge.straylight.software/install.sh | sh"
            , HH.text "\n"
            , codeLine "# " "Initialize a new project"
            , codeLine "$ " "converge init my-infra"
            , codeLine "$ " "cd my-infra"
            , HH.text "\n"
            , codeLine "# " "Define your infrastructure (infra.cvg)"
            , codeLine "" "resource aws.ec2.Instance web {"
            , codeLine "" "  ami          = \"ami-0c55b159cbfafe1f0\""
            , codeLine "" "  instanceType = \"t3.micro\""
            , codeLine "" "  tags         = { Name = \"web-server\" }"
            , codeLine "" "}"
            , HH.text "\n"
            , codeLine "# " "Converge to desired state"
            , codeLine "$ " "converge up"
            , HH.text "\n"
            , codeLine "# " "Watch for drift (runs continuously)"
            , codeLine "$ " "converge watch"
            ]
        , HH.div
            [ cls [ "mt-8 text-center" ] ]
            [ HH.a
                [ HP.href "/sensenet/converge/docs"
                , cls [ "text-emerald-400 hover:text-emerald-400/80 transition-colors" ]
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
            [ HH.text "sensenet//converge is in private beta. Join the waitlist for early access." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ primaryButton "/waitlist" "Join the waitlist"
            , secondaryButton "/team" "Meet the team"
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
    , cls [ "inline-flex items-center justify-center px-6 py-3 bg-emerald-400 text-background font-medium rounded-md hover:bg-emerald-400/90 transition-colors" ]
    ]
    [ HH.text label ]

secondaryButton :: forall w i. String -> String -> HH.HTML w i
secondaryButton href label =
  HH.a
    [ HP.href href
    , cls [ "inline-flex items-center justify-center px-6 py-3 border border-border text-text font-medium rounded-md hover:bg-card transition-colors" ]
    ]
    [ HH.text label ]
