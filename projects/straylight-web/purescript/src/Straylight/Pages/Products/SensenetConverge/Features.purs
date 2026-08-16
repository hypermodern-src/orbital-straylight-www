-- | sensenet//converge Features Page
-- | The complete infrastructure platform showcase
module Straylight.Pages.Products.SensenetConverge.Features 
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
    , convergence
    , typeSystem
    , driftDetection
    , multiCloud
    , security
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
            [ HH.text "Everything infrastructure,"
            , HH.br_
            , HH.text "one platform"
            ]
        , HH.p
            [ cls [ "text-xl text-muted-foreground max-w-2xl mx-auto" ] ]
            [ HH.text "Typed configs. Desired-state convergence. Real-time drift detection. Multi-cloud support. All without state files." ]
        ]
    ]

-- ============================================================
-- CONVERGENCE
-- ============================================================

convergence :: forall w i. HH.HTML w i
convergence =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Desired-State Convergence"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "No more plan/apply dance" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Traditional IaC tools require manual plan/apply cycles. Converge runs continuously, automatically reconciling your infrastructure to match your declared intent. Drift is fixed before you even notice it." ]
                , featureList
                    [ "Continuous convergence loop"
                    , "Automatic drift remediation"
                    , "Declarative intent, not imperative scripts"
                    , "Transactions for multi-resource changes"
                    , "Rollback on failure"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-4" ] ]
                    [ convergenceStep "1" "Declare" "Define your desired state in typed configs"
                    , convergenceStep "2" "Converge" "System automatically reconciles reality"
                    , convergenceStep "3" "Monitor" "Continuous drift detection and alerts"
                    , convergenceStep "4" "Repeat" "Changes trigger automatic convergence"
                    ]
                ]
            ]
        ]
    ]

convergenceStep :: forall w i. String -> String -> String -> HH.HTML w i
convergenceStep num title desc =
  HH.div
    [ cls [ "flex items-start gap-4" ] ]
    [ HH.div
        [ cls [ "w-8 h-8 rounded-full bg-purple-400/20 text-purple-400 flex items-center justify-center text-sm font-bold shrink-0" ] ]
        [ HH.text num ]
    , HH.div_
        [ HH.p [ cls [ "text-text font-medium" ] ] [ HH.text title ]
        , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text desc ]
        ]
    ]

-- ============================================================
-- TYPE SYSTEM
-- ============================================================

typeSystem :: forall w i. HH.HTML w i
typeSystem =
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
                    [ codeLine "# " "Typed resource definitions"
                    , HH.text "\n"
                    , HH.span [ cls [ "text-purple-400" ] ] [ HH.text "resource" ]
                    , HH.span [ cls [ "text-text" ] ] [ HH.text " aws.ec2.Instance web {" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  ami          : Ami = \"ami-0c55b159cbfafe1f0\"" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  instanceType : InstanceType = \"t3.micro\"" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  tags         : Map String String = {" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "    Name = \"web-server\"" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "  }" ]
                    , HH.text "\n"
                    , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
                    , HH.text "\n\n"
                    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# IDE catches errors at compile time" ]
                    ]
                ]
              -- Right: content
            , HH.div
                [ cls [ "order-1 lg:order-2" ] ]
                [ badge "Type System"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Catch misconfigs at compile time" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "No more YAML typos discovered in production. Converge's type system catches invalid AMIs, wrong instance types, and missing required fields before you ever run `converge up`." ]
                , featureList
                    [ "Full static type checking"
                    , "IDE autocompletion for all resources"
                    , "Type-safe references between resources"
                    , "Custom type definitions"
                    , "Compile-time validation"
                    ]
                ]
            ]
        ]
    ]

-- ============================================================
-- DRIFT DETECTION
-- ============================================================

driftDetection :: forall w i. HH.HTML w i
driftDetection =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Drift Detection"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Know instantly when reality diverges" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "Someone changed a security group in the console? A cronjob modified a config? Converge detects drift in real-time and can auto-remediate or alert your team." ]
                , featureList
                    [ "Real-time drift detection"
                    , "Configurable remediation policies"
                    , "Slack, PagerDuty, webhook integrations"
                    , "Drift history and audit log"
                    , "Per-resource drift tolerance"
                    ]
                ]
              -- Right: visual
            , HH.div
                [ cls [ "bg-card border border-border rounded-lg p-6" ] ]
                [ HH.div
                    [ cls [ "space-y-3" ] ]
                    [ driftItem "aws.ec2.Instance.web" "in sync" true
                    , driftItem "aws.ec2.SecurityGroup.web-sg" "drifted" false
                    , driftItem "aws.rds.Instance.db" "in sync" true
                    , driftItem "aws.s3.Bucket.assets" "in sync" true
                    ]
                , HH.div
                    [ cls [ "mt-4 pt-4 border-t border-border" ] ]
                    [ HH.p [ cls [ "text-xs text-muted-foreground" ] ] 
                        [ HH.text "1 resource drifted - auto-remediation in 30s" ]
                    ]
                ]
            ]
        ]
    ]

driftItem :: forall w i. String -> String -> Boolean -> HH.HTML w i
driftItem name status synced =
  HH.div
    [ cls [ "flex items-center justify-between p-3 bg-background rounded" ] ]
    [ HH.span [ cls [ "text-sm font-mono text-text" ] ] [ HH.text name ]
    , HH.span 
        [ cls [ "text-xs px-2 py-1 rounded"
              , if synced then "bg-purple-400/20 text-purple-400" else "bg-yellow-500/20 text-yellow-500"
              ] 
        ] 
        [ HH.text status ]
    ]

-- ============================================================
-- MULTI-CLOUD
-- ============================================================

multiCloud :: forall w i. HH.HTML w i
multiCloud =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "text-center mb-16" ] ]
            [ badge "Multi-Cloud"
            , HH.h2
                [ cls [ "text-3xl font-bold text-text mb-4" ] ]
                [ HH.text "One language, every cloud" ]
            , HH.p
                [ cls [ "text-muted-foreground max-w-2xl mx-auto" ] ]
                [ HH.text "AWS, GCP, Azure, Kubernetes, bare metal. Define your infrastructure once, deploy anywhere. No provider-specific syntax to learn." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-2 md:grid-cols-4 gap-6" ] ]
            [ cloudCard "AWS" "Full support"
            , cloudCard "GCP" "Full support"
            , cloudCard "Azure" "Full support"
            , cloudCard "Kubernetes" "Full support"
            ]
        ]
    ]

cloudCard :: forall w i. String -> String -> HH.HTML w i
cloudCard name desc =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center hover:border-purple-400/50 transition-colors" ] ]
    [ HH.p [ cls [ "text-text font-medium mb-1" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text desc ]
    ]

-- ============================================================
-- SECURITY
-- ============================================================

security :: forall w i. HH.HTML w i
security =
  HH.section
    [ cls [ "py-24 border-t border-border" ] ]
    [ HH.div
        [ cls [ "max-w-[1100px] mx-auto px-6" ] ]
        [ HH.div
            [ cls [ "grid grid-cols-1 lg:grid-cols-2 gap-16 items-center" ] ]
            [ -- Left: content
              HH.div_
                [ badge "Security"
                , HH.h2
                    [ cls [ "text-3xl font-bold text-text mb-6" ] ]
                    [ HH.text "Enterprise-grade, actually" ]
                , HH.p
                    [ cls [ "text-muted-foreground mb-6" ] ]
                    [ HH.text "No state files means no secrets in S3. No drift means no unauthorized changes. Full audit log of every change, who made it, and when." ]
                , featureList
                    [ "SOC 2 Type II certified"
                    , "SAML/OIDC SSO"
                    , "Fine-grained RBAC"
                    , "Full audit logging"
                    , "Secrets never stored in state"
                    , "Policy-as-code enforcement"
                    ]
                ]
              -- Right: trust badges
            , HH.div
                [ cls [ "grid grid-cols-2 gap-4" ] ]
                [ trustBadge "SOC 2" "Type II Certified"
                , trustBadge "GDPR" "Compliant"
                , trustBadge "SSO" "SAML + OIDC"
                , trustBadge "99.9%" "SLA Available"
                ]
            ]
        ]
    ]

trustBadge :: forall w i. String -> String -> HH.HTML w i
trustBadge title subtitle =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 text-center" ] ]
    [ HH.p [ cls [ "text-2xl font-bold text-purple-400 mb-1" ] ] [ HH.text title ]
    , HH.p [ cls [ "text-sm text-muted-foreground" ] ] [ HH.text subtitle ]
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
                [ HH.text "We're infrastructure engineers too. We built the DX we wanted." ]
            ]
        , HH.div
            [ cls [ "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" ] ]
            [ dxCard ">" "CLI that doesn't suck" 
                "Tab completion, progress bars, human-readable errors. Pipe-friendly for scripting."
            , dxCard "{}" "REST API for everything"
                "Anything you can do in the CLI, you can do via API. OpenAPI spec included."
            , dxCard "!" "Real-time streaming"
                "Convergence logs, drift events, everything streams. No polling, no spinners."
            , dxCard "::" "IDE integration"
                "VS Code, Neovim, IntelliJ. Full LSP support with go-to-definition and type hints."
            , dxCard "++" "Git-native"
                "Version control your infrastructure. PR reviews, branch-per-environment. GitOps-ready."
            , dxCard "$" "Transparent pricing"
                "Calculator on the site. No 'contact sales' for basic questions."
            ]
        ]
    ]

dxCard :: forall w i. String -> String -> String -> HH.HTML w i
dxCard icon title description =
  HH.div
    [ cls [ "bg-card border border-border rounded-lg p-6 hover:border-purple-400/30 transition-colors" ] ]
    [ HH.div
        [ cls [ "flex items-center gap-3 mb-3" ] ]
        [ HH.span [ cls [ "text-purple-400 font-mono text-xl" ] ] [ HH.text icon ]
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
            [ HH.text "Ready to stop fighting your infrastructure?" ]
        , HH.p
            [ cls [ "text-muted-foreground mb-8" ] ]
            [ HH.text "Start free. No credit card. 10 resources, unlimited drift detection." ]
        , HH.div
            [ cls [ "flex flex-col sm:flex-row items-center justify-center gap-4" ] ]
            [ HH.a
                [ HP.href "/sensenet/converge/pricing"
                , cls [ "inline-flex items-center justify-center px-8 py-4 bg-purple-400 text-background font-medium rounded-md hover:bg-purple-400/90 transition-colors" ]
                ]
                [ HH.text "Get started free" ]
            , HH.a
                [ HP.href "/sensenet/converge/docs"
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
    [ cls [ "inline-block px-3 py-1 bg-purple-400/10 border border-purple-400/20 rounded-full text-purple-400 text-sm font-medium mb-4" ] ]
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
    [ HH.span [ cls [ "text-purple-400 mt-1" ] ] [ HH.text "+" ]
    , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text text ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
