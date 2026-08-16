-- | omega//work Documentation
-- | User guide: quickstart, workspaces, integrations, sharing, api
module Straylight.Pages.Products.OmegaWork.Docs 
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

import Straylight.UI (cls)

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
            [ sidebarLink "/omega/work/docs" "Overview" currentPath
            , sidebarLink "/omega/work/docs/quickstart" "Quickstart" currentPath
            , sidebarLink "/omega/work/docs/installation" "Installation" currentPath
            ]
        , sidebarSection "Team Features"
            [ sidebarLink "/omega/work/docs/workspaces" "Workspaces" currentPath
            , sidebarLink "/omega/work/docs/sharing" "Sharing" currentPath
            , sidebarLink "/omega/work/docs/integrations" "Integrations" currentPath
            ]
        , sidebarSection "Using the App"
            [ sidebarLink "/omega/work/docs/interface" "Interface Guide" currentPath
            , sidebarLink "/omega/work/docs/conversations" "Conversations" currentPath
            , sidebarLink "/omega/work/docs/files" "Working with Files" currentPath
            , sidebarLink "/omega/work/docs/keyboard" "Keyboard Shortcuts" currentPath
            ]
        , sidebarSection "Developer"
            [ sidebarLink "/omega/work/docs/api" "API Reference" currentPath
            , sidebarLink "/omega/work/docs/webhooks" "Webhooks" currentPath
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
                  then "bg-indigo-400/10 text-indigo-400 font-medium" 
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
  "/omega/work/docs" -> overviewContent
  "/omega/work/docs/quickstart" -> quickstartContent
  "/omega/work/docs/installation" -> installationContent
  "/omega/work/docs/workspaces" -> workspacesContent
  "/omega/work/docs/sharing" -> sharingContent
  "/omega/work/docs/integrations" -> integrationsContent
  "/omega/work/docs/interface" -> interfaceContent
  "/omega/work/docs/conversations" -> conversationsContent
  "/omega/work/docs/files" -> filesContent
  "/omega/work/docs/keyboard" -> keyboardContent
  "/omega/work/docs/api" -> apiContent
  "/omega/work/docs/webhooks" -> webhooksContent
  _ -> overviewContent

-- ============================================================
-- OVERVIEW
-- ============================================================

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  article
    [ h1 "omega//work Documentation"
    , p "Welcome to omega//work, the desktop AI assistant built for teams. This guide covers everything from getting started to advanced team features."
    
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 my-8" ] ]
        [ docCard "/omega/work/docs/quickstart" "Quickstart" "Get your team up and running in 5 minutes."
        , docCard "/omega/work/docs/workspaces" "Workspaces" "Organize your team with shared workspaces."
        , docCard "/omega/work/docs/integrations" "Integrations" "Connect Slack, Notion, and more."
        , docCard "/omega/work/docs/api" "API Reference" "Build custom integrations."
        ]
    
    , h2 "What is omega//work?"
    , p "omega//work is a native desktop application that brings AI assistance to every member of your team - PMs, designers, analysts, and ops. No coding required, no terminal needed."
    
    , h2 "Key Concepts"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Workspaces - Shared spaces for teams to collaborate with AI"
        , li' "Conversations - Chat threads that can be shared and searched"
        , li' "Context - Files and information shared with the AI"
        , li' "Integrations - Connections to your existing tools"
        ]
    
    , h2 "Getting Help"
    , p "Need help? Check our FAQ, join the community Discord, or email support@straylight.software for priority support (Team and Enterprise plans)."
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  article
    [ h1 "Quickstart"
    , p "Get your team up and running with omega//work in under 5 minutes."
    
    , h2 "1. Download and install"
    , p "Download omega//work for your platform. Run the installer - no dependencies required."
    , HH.div
        [ cls [ "flex gap-4 my-4" ] ]
        [ downloadButton "macOS"
        , downloadButton "Windows"
        , downloadButton "Linux"
        ]
    
    , h2 "2. Create your account"
    , p "Sign up with your work email. If your organization already uses omega//work, you'll be automatically added to your team workspace."
    
    , h2 "3. Join or create a workspace"
    , p "For teams: Accept the workspace invitation from your admin. For individuals: Create a personal workspace to get started."
    
    , h2 "4. Start your first conversation"
    , p "Click 'New Conversation' and describe what you need help with. Try something like:"
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-4 my-4 text-muted-foreground" ] ]
        [ HH.text "\"Help me write a project brief for our new mobile app feature. It should include goals, timeline, and success metrics.\"" ]
    
    , h2 "5. Share with your team"
    , p "Found something useful? Click 'Share' to make the conversation available to your team or copy a link to send directly."
    
    , h2 "Next steps"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground" ] ]
        [ li' "Set up integrations with Slack, Notion, and more"
        , li' "Learn keyboard shortcuts to work faster"
        , li' "Invite your team members to your workspace"
        ]
    ]

downloadButton :: forall w i. String -> HH.HTML w i
downloadButton platform =
  HH.a
    [ HP.href "/omega/work/dashboard"
    , cls [ "px-4 py-2 bg-indigo-400/10 text-indigo-400 text-sm font-medium rounded-md hover:bg-indigo-400/20 transition-colors" ]
    ]
    [ HH.text platform ]

-- ============================================================
-- INSTALLATION
-- ============================================================

installationContent :: forall w i. HH.HTML w i
installationContent =
  article
    [ h1 "Installation"
    , p "omega//work is available for macOS, Windows, and Linux."
    
    , h2 "macOS"
    , p "Download the .dmg file, open it, and drag omega//work to your Applications folder. Works on both Intel and Apple Silicon Macs (macOS 12+)."
    
    , h2 "Windows"
    , p "Download the .exe installer and run it. Follow the installation wizard. Requires Windows 10 or later."
    
    , h2 "Linux"
    , p "Download the .AppImage file. Make it executable (chmod +x) and run it. Works on Ubuntu 20.04+, Fedora 35+, and most modern distributions."
    
    , h2 "System Requirements"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "4GB RAM minimum (8GB recommended)"
        , li' "500MB disk space"
        , li' "Internet connection for AI features"
        ]
    
    , h2 "Enterprise Deployment"
    , p "For IT teams deploying to many machines: We provide MSI installers for Windows, PKG for macOS, and .deb/.rpm packages for Linux. Contact your account manager for details."
    ]

-- ============================================================
-- WORKSPACES
-- ============================================================

workspacesContent :: forall w i. HH.HTML w i
workspacesContent =
  article
    [ h1 "Workspaces"
    , p "Workspaces are shared spaces where your team collaborates with AI. Each workspace has its own conversations, context, and settings."
    
    , h2 "Creating a Workspace"
    , p "Click 'New Workspace' in the sidebar. Give it a name (like 'Marketing' or 'Q1 Planning') and invite team members."
    
    , h2 "Workspace Types"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Personal - Private to you, included in Free plan"
        , li' "Team - Shared with your team, requires Team plan"
        , li' "Organization - Visible to everyone in your org, Enterprise only"
        ]
    
    , h2 "Managing Members"
    , p "Workspace admins can invite members, set roles, and manage permissions. Go to Workspace Settings > Members to manage your team."
    
    , h2 "Roles"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Admin - Full control over workspace settings and members"
        , li' "Member - Can create and share conversations"
        , li' "Viewer - Can view shared conversations but not create new ones"
        ]
    
    , h2 "Workspace Context"
    , p "Set default context for your workspace - files, guidelines, or reference material that should be available in all conversations."
    ]

-- ============================================================
-- SHARING
-- ============================================================

sharingContent :: forall w i. HH.HTML w i
sharingContent =
  article
    [ h1 "Sharing"
    , p "Share your AI conversations with team members, make them searchable, or keep them private."
    
    , h2 "Sharing a Conversation"
    , p "Click the 'Share' button in any conversation. Choose who can see it:"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Private - Only you can see it"
        , li' "Workspace - Everyone in the workspace can find and view it"
        , li' "Link - Anyone with the link can view (great for external sharing)"
        ]
    
    , h2 "Finding Shared Conversations"
    , p "Use the search bar to find conversations across your workspaces. Search by content, date, or participant."
    
    , h2 "Conversation History"
    , p "All shared conversations are saved and searchable. This builds your team's knowledge base over time - no need to ask the same questions twice."
    
    , h2 "Exporting"
    , p "Export conversations to Markdown, PDF, or plain text. Useful for documentation, reports, or sharing with people outside your team."
    
    , h2 "Privacy Controls"
    , p "Workspace admins can set default sharing settings and restrict external sharing if needed. Go to Workspace Settings > Privacy."
    ]

-- ============================================================
-- INTEGRATIONS
-- ============================================================

integrationsContent :: forall w i. HH.HTML w i
integrationsContent =
  article
    [ h1 "Integrations"
    , p "Connect omega//work to the tools your team already uses."
    
    , h2 "Available Integrations"
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 my-6" ] ]
        [ integrationItem "Slack" "Share conversations to channels, get notifications"
        , integrationItem "Notion" "Import pages as context, export results to docs"
        , integrationItem "Google Workspace" "Access Drive files, export to Docs"
        , integrationItem "Linear" "Create issues from conversations"
        , integrationItem "Jira" "Link conversations to tickets"
        , integrationItem "GitHub" "Access repo files as context"
        , integrationItem "Figma" "Import designs for discussion"
        , integrationItem "Confluence" "Sync with your wiki"
        ]
    
    , h2 "Setting Up Integrations"
    , p "Go to Settings > Integrations. Click 'Connect' next to the service you want. You'll be redirected to authorize omega//work."
    
    , h2 "Using Integrations"
    , p "Once connected, integrations appear in your conversation toolbar. Click to pull in context from connected services or push results back."
    
    , h2 "Custom Integrations"
    , p "Enterprise plans can request custom integrations with internal tools. Contact your account manager to discuss requirements."
    ]

integrationItem :: forall w i. String -> String -> HH.HTML w i
integrationItem name description =
  HH.div
    [ cls [ "p-4 bg-card border border-border rounded-lg" ] ]
    [ HH.h4 [ cls [ "text-text font-medium mb-1" ] ] [ HH.text name ]
    , HH.p [ cls [ "text-muted-foreground text-sm" ] ] [ HH.text description ]
    ]

-- ============================================================
-- INTERFACE
-- ============================================================

interfaceContent :: forall w i. HH.HTML w i
interfaceContent =
  article
    [ h1 "Interface Guide"
    , p "omega//work has a clean, focused interface designed for productivity."
    
    , h2 "Main Areas"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Sidebar - Workspace navigation, recent conversations, search"
        , li' "Conversation Panel - Chat with AI, view responses"
        , li' "Context Panel - Files and references shared with AI"
        , li' "Preview Panel - View files and proposed changes"
        ]
    
    , h2 "Conversation Panel"
    , p "The conversation panel is where you interact with the AI. Type messages, ask questions, and request help. The AI responds with explanations and suggestions."
    
    , h2 "Context Panel"
    , p "Drag files here to share them with the AI. The AI can read and reference these files in the conversation. Remove context when you're done."
    
    , h2 "Preview Panel"
    , p "When viewing files or AI suggestions, they appear in the preview panel. For documents, you'll see a formatted view. For changes, you'll see a diff."
    ]

-- ============================================================
-- CONVERSATIONS
-- ============================================================

conversationsContent :: forall w i. HH.HTML w i
conversationsContent =
  article
    [ h1 "Conversations"
    , p "Conversations are how you interact with the AI and collaborate with your team."
    
    , h2 "Starting a Conversation"
    , p "Click 'New Conversation' or press Cmd/Ctrl+N. Type your request and press Enter."
    
    , h2 "Adding Context"
    , p "Drag files into the conversation or click the attachment button. The AI will reference these files when responding."
    
    , h2 "Conversation Tips"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Be specific about what you need"
        , li' "Provide relevant context and examples"
        , li' "Break complex requests into steps"
        , li' "Ask follow-up questions to refine results"
        ]
    
    , h2 "Conversation History"
    , p "All conversations are saved automatically. Find past conversations in the sidebar or use search."
    ]

-- ============================================================
-- FILES
-- ============================================================

filesContent :: forall w i. HH.HTML w i
filesContent =
  article
    [ h1 "Working with Files"
    , p "omega//work can read and help you work with many file types."
    
    , h2 "Supported File Types"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Documents - .docx, .pdf, .txt, .md"
        , li' "Spreadsheets - .xlsx, .csv"
        , li' "Images - .png, .jpg, .svg"
        , li' "Data - .json, .xml, .yaml"
        ]
    
    , h2 "Sharing Files"
    , p "Drag files from your desktop into the conversation. Files are processed locally - only relevant content is sent to the AI."
    
    , h2 "File Previews"
    , p "Click any shared file to preview it. Documents show formatted content, spreadsheets show data tables, images display inline."
    
    , h2 "Exporting Results"
    , p "Export AI-generated content to files. Click 'Export' in any conversation to save as Markdown, PDF, or plain text."
    ]

-- ============================================================
-- KEYBOARD
-- ============================================================

keyboardContent :: forall w i. HH.HTML w i
keyboardContent =
  article
    [ h1 "Keyboard Shortcuts"
    , p "Speed up your workflow with keyboard shortcuts."
    
    , h2 "General"
    , shortcutTable
        [ { key: "Cmd/Ctrl + N", action: "New conversation" }
        , { key: "Cmd/Ctrl + K", action: "Quick search" }
        , { key: "Cmd/Ctrl + ,", action: "Settings" }
        , { key: "Cmd/Ctrl + 1-9", action: "Switch workspace" }
        ]
    
    , h2 "Conversation"
    , shortcutTable
        [ { key: "Enter", action: "Send message" }
        , { key: "Shift + Enter", action: "New line" }
        , { key: "Cmd/Ctrl + L", action: "Clear conversation" }
        , { key: "Up/Down", action: "Navigate messages" }
        ]
    
    , h2 "Sharing"
    , shortcutTable
        [ { key: "Cmd/Ctrl + S", action: "Share conversation" }
        , { key: "Cmd/Ctrl + E", action: "Export conversation" }
        , { key: "Cmd/Ctrl + C", action: "Copy selected text" }
        ]
    ]

shortcutTable :: forall w i. Array { key :: String, action :: String } -> HH.HTML w i
shortcutTable shortcuts =
  HH.table
    [ cls [ "w-full text-sm mb-6" ] ]
    [ HH.tbody_ (map shortcutRow shortcuts) ]

shortcutRow :: forall w i. { key :: String, action :: String } -> HH.HTML w i
shortcutRow { key, action } =
  HH.tr
    [ cls [ "border-b border-border" ] ]
    [ HH.td [ cls [ "py-2 text-indigo-400 font-mono" ] ] [ HH.text key ]
    , HH.td [ cls [ "py-2 text-muted-foreground" ] ] [ HH.text action ]
    ]

-- ============================================================
-- API
-- ============================================================

apiContent :: forall w i. HH.HTML w i
apiContent =
  article
    [ h1 "API Reference"
    , p "omega//work provides a REST API for building custom integrations (Enterprise plan)."
    
    , h2 "Authentication"
    , p "API requests require a Bearer token. Generate tokens in Settings > API > Create Token."
    , HH.div
        [ cls [ "bg-card border border-border rounded-lg p-4 my-4 font-mono text-sm text-muted-foreground" ] ]
        [ HH.text "Authorization: Bearer your-api-token" ]
    
    , h2 "Endpoints"
    , HH.div
        [ cls [ "space-y-4 my-6" ] ]
        [ apiEndpoint "GET" "/api/v1/workspaces" "List all workspaces"
        , apiEndpoint "GET" "/api/v1/conversations" "List conversations"
        , apiEndpoint "POST" "/api/v1/conversations" "Create a conversation"
        , apiEndpoint "GET" "/api/v1/conversations/:id" "Get conversation details"
        , apiEndpoint "POST" "/api/v1/conversations/:id/messages" "Add a message"
        ]
    
    , h2 "Rate Limits"
    , p "API requests are limited to 1000 per hour per token. Contact support for higher limits."
    
    , h2 "SDKs"
    , p "Official SDKs available for Python, JavaScript, and Go. See the GitHub repo for installation instructions."
    ]

apiEndpoint :: forall w i. String -> String -> String -> HH.HTML w i
apiEndpoint method path description =
  HH.div
    [ cls [ "flex items-center gap-4 p-3 bg-card border border-border rounded-lg" ] ]
    [ HH.span [ cls [ "px-2 py-1 text-xs font-mono font-bold bg-indigo-400/10 text-indigo-400 rounded" ] ] [ HH.text method ]
    , HH.span [ cls [ "font-mono text-sm text-text" ] ] [ HH.text path ]
    , HH.span [ cls [ "text-muted-foreground text-sm ml-auto" ] ] [ HH.text description ]
    ]

-- ============================================================
-- WEBHOOKS
-- ============================================================

webhooksContent :: forall w i. HH.HTML w i
webhooksContent =
  article
    [ h1 "Webhooks"
    , p "Receive real-time notifications when events happen in omega//work (Enterprise plan)."
    
    , h2 "Setting Up Webhooks"
    , p "Go to Settings > API > Webhooks. Click 'Add Webhook' and enter your endpoint URL."
    
    , h2 "Available Events"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "conversation.created - A new conversation was started"
        , li' "conversation.shared - A conversation was shared"
        , li' "message.created - A new message was added"
        , li' "member.joined - A user joined a workspace"
        ]
    
    , h2 "Payload Format"
    , p "Webhooks send JSON payloads with event type, timestamp, and relevant data."
    
    , h2 "Security"
    , p "Webhook requests include a signature header for verification. See our security guide for implementation details."
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

docCard :: forall w i. String -> String -> String -> HH.HTML w i
docCard href title description =
  HH.a
    [ HP.href href
    , cls [ "block p-4 bg-card border border-border rounded-lg hover:border-indigo-400/50 transition-colors" ]
    ]
    [ HH.h3
        [ cls [ "text-text font-medium mb-1" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]
