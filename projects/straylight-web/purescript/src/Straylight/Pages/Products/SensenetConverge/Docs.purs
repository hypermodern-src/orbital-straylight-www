-- | sensenet//converge Documentation
-- | Complete docs for infrastructure convergence
module Straylight.Pages.Products.SensenetConverge.Docs 
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
            [ sidebarLink "/sensenet/converge/docs" "Overview" currentPath
            , sidebarLink "/sensenet/converge/docs/quickstart" "Quick Start" currentPath
            , sidebarLink "/sensenet/converge/docs/installation" "Installation" currentPath
            ]
        , sidebarSection "Guides"
            [ sidebarLink "/sensenet/converge/docs/resources" "Defining Resources" currentPath
            , sidebarLink "/sensenet/converge/docs/types" "Type System" currentPath
            , sidebarLink "/sensenet/converge/docs/drift" "Drift Detection" currentPath
            , sidebarLink "/sensenet/converge/docs/migration" "Migrate from Terraform" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/sensenet/converge/docs/cli" "CLI Reference" currentPath
            , sidebarLink "/sensenet/converge/docs/api" "REST API" currentPath
            , sidebarLink "/sensenet/converge/docs/config" "Configuration" currentPath
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
                  then "bg-purple-400/10 text-purple-400 font-medium" 
                  else "text-muted-foreground hover:text-text hover:bg-card"
              ]
        ]
        [ HH.text label ]
    ]

-- ============================================================
-- STATIC RENDER (for SSG)
-- ============================================================

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
  "/sensenet/converge/docs" -> overviewContent
  "/sensenet/converge/docs/quickstart" -> quickstartContent
  "/sensenet/converge/docs/installation" -> installationContent
  "/sensenet/converge/docs/resources" -> resourcesContent
  "/sensenet/converge/docs/types" -> typesContent
  "/sensenet/converge/docs/drift" -> driftContent
  "/sensenet/converge/docs/migration" -> migrationContent
  "/sensenet/converge/docs/cli" -> cliContent
  "/sensenet/converge/docs/api" -> apiContent
  "/sensenet/converge/docs/config" -> configContent
  _ -> overviewContent

-- ============================================================
-- OVERVIEW
-- ============================================================

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  article
    [ h1 "Documentation"
    , p "Everything you need to start using sensenet//converge for typed infrastructure-as-code with desired-state convergence."
    
    -- Quick links
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 my-8" ] ]
        [ docCard "/sensenet/converge/docs/quickstart" "Quick Start" "Get up and running in under a minute."
        , docCard "/sensenet/converge/docs/migration" "Migrate from Terraform" "Import your existing infrastructure."
        , docCard "/sensenet/converge/docs/resources" "Defining Resources" "Learn the converge DSL."
        , docCard "/sensenet/converge/docs/cli" "CLI Reference" "Full command documentation."
        ]
    
    , h2 "What is sensenet//converge?"
    , p "sensenet//converge is a typed infrastructure-as-code platform with desired-state convergence. Unlike traditional IaC tools that require manual plan/apply cycles and manage state files, converge continuously reconciles your infrastructure to match your declared intent."
    
    , h2 "Core Concepts"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Desired State - Declare what you want, not how to get there"
        , li' "Convergence - System automatically reconciles reality to match intent"
        , li' "Live State - No state files; infrastructure is queried directly"
        , li' "Drift Detection - Real-time monitoring for unauthorized changes"
        ]
    
    , h2 "Quick example"
    , codeBlock
        [ codeLine "$ " "converge init my-infra && cd my-infra"
        , codeLine "$ " "converge up"
        , codeLine "$ " "converge watch  # continuous drift detection"
        ]
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  article
    [ h1 "Quick Start"
    , p "Get sensenet//converge working in under a minute."
    
    , h2 "1. Install converge"
    , codeBlock
        [ codeLine "# " "Using Nix (recommended)"
        , codeLine "$ " "nix profile install github:straylight-software/converge"
        , HH.text "\n"
        , codeLine "# " "Or via curl"
        , codeLine "$ " "curl -fsSL https://converge.straylight.software/install.sh | sh"
        ]
    
    , h2 "2. Initialize a project"
    , codeBlock
        [ codeLine "$ " "converge init my-infra"
        , codeLine "$ " "cd my-infra"
        ]
    
    , h2 "3. Define your infrastructure"
    , codeBlock
        [ codeLine "# " "infra.cvg"
        , HH.span [ cls [ "text-purple-400" ] ] [ HH.text "resource" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text " aws.ec2.Instance web {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  ami          = \"ami-0c55b159cbfafe1f0\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  instanceType = \"t3.micro\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  tags         = { Name = \"web-server\" }" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
        ]
    
    , h2 "4. Converge to desired state"
    , codeBlock
        [ codeLine "$ " "converge up"
        , codeLine "" "Converging 1 resource..."
        , codeLine "" "  + aws.ec2.Instance.web"
        , codeLine "" "    ami          = \"ami-0c55b159cbfafe1f0\""
        , codeLine "" "    instanceType = \"t3.micro\""
        , codeLine "" ""
        , codeLine "" "Converged in 23s"
        ]
    
    , h2 "5. Watch for drift"
    , codeBlock
        [ codeLine "$ " "converge watch"
        , codeLine "" "Watching 1 resource for drift..."
        , codeLine "" "[12:34:56] All resources in sync"
        ]
    
    , h2 "Next steps"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground" ] ]
        [ li link "/sensenet/converge/docs/resources" "Learn to define resources"
        , li link "/sensenet/converge/docs/types" "Explore the type system"
        , li link "/sensenet/converge/docs/drift" "Configure drift detection"
        ]
    ]

-- ============================================================
-- INSTALLATION
-- ============================================================

installationContent :: forall w i. HH.HTML w i
installationContent =
  article
    [ h1 "Installation"
    , p "Multiple ways to install the converge CLI."
    
    , h2 "Nix (recommended)"
    , codeBlock
        [ codeLine "# " "Add to your flake inputs"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "inputs.converge.url = \"github:straylight-software/converge\";" ]
        , HH.text "\n\n"
        , codeLine "# " "Or install directly"
        , codeLine "$ " "nix profile install github:straylight-software/converge"
        ]
    
    , h2 "Shell script"
    , codeBlock
        [ codeLine "$ " "curl -fsSL https://converge.straylight.software/install.sh | sh"
        ]
    
    , h2 "Homebrew (macOS)"
    , codeBlock
        [ codeLine "$ " "brew install straylight/tap/converge" ]
    
    , h2 "Verify installation"
    , codeBlock
        [ codeLine "$ " "converge --version"
        , codeLine "" "converge 0.1.0 (sensenet//converge)"
        ]
    ]

-- ============================================================
-- RESOURCES
-- ============================================================

resourcesContent :: forall w i. HH.HTML w i
resourcesContent =
  article
    [ h1 "Defining Resources"
    , p "Learn how to define infrastructure resources in converge."
    
    , h2 "Basic syntax"
    , codeBlock
        [ HH.span [ cls [ "text-purple-400" ] ] [ HH.text "resource" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text " <provider>.<type> <name> {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  <attribute> = <value>" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
        ]
    
    , h2 "Example: EC2 instance"
    , codeBlock
        [ HH.span [ cls [ "text-purple-400" ] ] [ HH.text "resource" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text " aws.ec2.Instance web {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  ami          = \"ami-0c55b159cbfafe1f0\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  instanceType = \"t3.micro\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  subnetId     = aws.vpc.Subnet.main.id" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
        ]
    
    , h2 "References"
    , p "Resources can reference other resources using dot notation:"
    , codeBlock
        [ HH.span [ cls [ "text-purple-400" ] ] [ HH.text "resource" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text " aws.ec2.SecurityGroup web_sg {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  vpcId = aws.vpc.Vpc.main.id" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  ingress = [{ port = 80, cidr = \"0.0.0.0/0\" }]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
        ]
    ]

-- ============================================================
-- TYPES
-- ============================================================

typesContent :: forall w i. HH.HTML w i
typesContent =
  article
    [ h1 "Type System"
    , p "Converge's type system catches misconfigurations at compile time."
    
    , h2 "Typed attributes"
    , p "Every resource attribute has a type. The compiler validates values:"
    , codeBlock
        [ HH.span [ cls [ "text-purple-400" ] ] [ HH.text "resource" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text " aws.ec2.Instance web {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  instanceType : InstanceType = \"t3.micro\"  " ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# valid" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  instanceType : InstanceType = \"invalid\"   " ]
        , HH.span [ cls [ "text-danger" ] ] [ HH.text "# compile error!" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
        ]
    
    , h2 "Custom types"
    , codeBlock
        [ HH.span [ cls [ "text-purple-400" ] ] [ HH.text "type" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text " Environment = \"dev\" | \"staging\" | \"prod\"" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-purple-400" ] ] [ HH.text "resource" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text " aws.ec2.Instance web {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  tags = { env : Environment = \"prod\" }" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
        ]
    ]

-- ============================================================
-- DRIFT
-- ============================================================

driftContent :: forall w i. HH.HTML w i
driftContent =
  article
    [ h1 "Drift Detection"
    , p "Configure how converge detects and responds to infrastructure drift."
    
    , h2 "Watching for drift"
    , codeBlock
        [ codeLine "$ " "converge watch"
        , codeLine "" "Watching 15 resources for drift..."
        , codeLine "" "[12:34:56] aws.ec2.SecurityGroup.web_sg drifted"
        , codeLine "" "  - ingress[0].cidr: \"10.0.0.0/8\" -> \"0.0.0.0/0\""
        , codeLine "" "[12:34:57] Auto-remediating..."
        , codeLine "" "[12:34:59] aws.ec2.SecurityGroup.web_sg converged"
        ]
    
    , h2 "Drift policies"
    , codeBlock
        [ HH.span [ cls [ "text-purple-400" ] ] [ HH.text "resource" ]
        , HH.span [ cls [ "text-text" ] ] [ HH.text " aws.ec2.Instance web {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  # ..." ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  drift {" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "    policy = \"auto-remediate\"  " ]
        , HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text "# or \"alert\", \"ignore\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "    notify = [\"slack://alerts\"]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "  }" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "}" ]
        ]
    ]

-- ============================================================
-- MIGRATION
-- ============================================================

migrationContent :: forall w i. HH.HTML w i
migrationContent =
  article
    [ h1 "Migrate from Terraform"
    , p "Import your existing Terraform infrastructure into converge."
    
    , h2 "Import Terraform state"
    , codeBlock
        [ codeLine "$ " "converge import terraform ./terraform.tfstate"
        , codeLine "" "Importing 47 resources..."
        , codeLine "" "  aws.ec2.Instance.web"
        , codeLine "" "  aws.ec2.SecurityGroup.web_sg"
        , codeLine "" "  ..."
        , codeLine "" ""
        , codeLine "" "Generated infra.cvg with 47 resources"
        ]
    
    , h2 "Verify import"
    , codeBlock
        [ codeLine "$ " "converge plan"
        , codeLine "" "No changes. Infrastructure matches desired state."
        ]
    
    , h2 "Start watching"
    , codeBlock
        [ codeLine "$ " "converge watch"
        , codeLine "" "Watching 47 resources for drift..."
        ]
    ]

-- ============================================================
-- CLI
-- ============================================================

cliContent :: forall w i. HH.HTML w i
cliContent =
  article
    [ h1 "CLI Reference"
    , p "Complete reference for the converge command-line interface."
    
    , h2 "converge init"
    , p "Initialize a new converge project."
    , codeBlock
        [ codeLine "$ " "converge init <name>" ]
    
    , h2 "converge up"
    , p "Converge infrastructure to desired state."
    , codeBlock
        [ codeLine "$ " "converge up [--auto-approve]" ]
    
    , h2 "converge plan"
    , p "Preview changes without applying."
    , codeBlock
        [ codeLine "$ " "converge plan" ]
    
    , h2 "converge watch"
    , p "Watch for drift and optionally auto-remediate."
    , codeBlock
        [ codeLine "$ " "converge watch [--interval 30s]" ]
    
    , h2 "converge import"
    , p "Import existing infrastructure."
    , codeBlock
        [ codeLine "$ " "converge import terraform <state-file>"
        , codeLine "$ " "converge import aws <resource-id>"
        ]
    ]

-- ============================================================
-- API
-- ============================================================

apiContent :: forall w i. HH.HTML w i
apiContent =
  article
    [ h1 "REST API"
    , p "Programmatic access to sensenet//converge."
    
    , h2 "Authentication"
    , codeBlock
        [ codeLine "" "Authorization: Bearer <API_TOKEN>" ]
    
    , h2 "Base URL"
    , codeBlock
        [ codeLine "" "https://api.converge.straylight.software/v1" ]
    
    , h2 "Trigger convergence"
    , codeBlock
        [ codeLine "" "POST /projects/{id}/converge"
        , codeLine "" ""
        , codeLine "" "Response: 202 Accepted"
        , codeLine "" "{ \"job_id\": \"...\", \"status\": \"running\" }"
        ]
    
    , h2 "Get drift status"
    , codeBlock
        [ codeLine "" "GET /projects/{id}/drift"
        , codeLine "" ""
        , codeLine "" "Response:"
        , codeLine "" "{ \"drifted\": 1, \"in_sync\": 46, \"resources\": [...] }"
        ]
    ]

-- ============================================================
-- CONFIG
-- ============================================================

configContent :: forall w i. HH.HTML w i
configContent =
  article
    [ h1 "Configuration"
    , p "Configure converge behavior."
    
    , h2 "Config file"
    , codeBlock
        [ codeLine "# " "converge.toml"
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[project]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "name = \"my-infra\"" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[drift]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "interval = \"30s\"" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "policy = \"auto-remediate\"" ]
        , HH.text "\n\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "[notifications]" ]
        , HH.text "\n"
        , HH.span [ cls [ "text-text" ] ] [ HH.text "slack = \"https://hooks.slack.com/...\"" ]
        ]
    
    , h2 "Environment variables"
    , codeBlock
        [ codeLine "" "CONVERGE_API_TOKEN    # API token"
        , codeLine "" "CONVERGE_PROJECT      # Default project"
        , codeLine "" "AWS_PROFILE           # AWS credentials"
        ]
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
    , cls [ "text-purple-400 hover:text-purple-400/80" ]
    ] 
    [ HH.text text ]

docCard :: forall w i. String -> String -> String -> HH.HTML w i
docCard href title description =
  HH.a
    [ HP.href href
    , cls [ "block p-4 bg-card border border-border rounded-lg hover:border-purple-400/50 transition-colors" ]
    ]
    [ HH.h3
        [ cls [ "text-text font-medium mb-1" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prompt content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prompt ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
