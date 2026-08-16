-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                           // straylight-api // omega // work
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- omega//work API
-- Desktop AI for Teams. Electron app for non-coders with team collaboration.
--
-- Features:
--   * Team workspaces with shared context
--   * Conversation history and search
--   * Enterprise integrations (Slack, Notion, Google)
--   * SSO/SAML authentication
--   * Admin controls and usage analytics
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Omega.Work
    ( -- * API
      WorkAPI
    
      -- * Types
    , Workspace (..)
    , Conversation (..)
    , WorkMessage (..)
    , TeamMember (..)
    , Integration (..)
    , UsageStats (..)
    ) where

import Data.Aeson
import Data.OpenApi (ToSchema (..), ToParamSchema (..))
import Data.Text (Text)
import GHC.Generics
import Servant

import Api.Types


-- ═══════════════════════════════════════════════════════════════════════════
-- // types //
-- ═══════════════════════════════════════════════════════════════════════════

newtype WorkspaceId = WorkspaceId { unWorkspaceId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema WorkspaceId

newtype ConversationId = ConversationId { unConversationId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema ConversationId

newtype MemberId = MemberId { unMemberId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema MemberId

newtype IntegrationId = IntegrationId { unIntegrationId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema IntegrationId

-- | Member role
data MemberRole
    = Owner
    | Admin
    | Member
    | Viewer
    deriving (Eq, Show, Generic)

instance ToJSON MemberRole
instance FromJSON MemberRole
instance ToSchema MemberRole

-- | Team member
data TeamMember = TeamMember
    { memberId :: MemberId
    , userId :: Text
    , email :: Text
    , name :: Text
    , role :: MemberRole
    , joinedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON TeamMember
instance FromJSON TeamMember
instance ToSchema TeamMember

-- | Workspace
data Workspace = Workspace
    { workspaceId :: WorkspaceId
    , name :: Text
    , description :: Maybe Text
    , organizationId :: Maybe Text
    , members :: [TeamMember]
    , ssoEnabled :: Bool
    , createdAt :: Timestamp
    , updatedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Workspace
instance FromJSON Workspace
instance ToSchema Workspace

-- | Work message (simpler than code messages)
data WorkMessage = WorkMessage
    { messageId :: Text
    , conversationId :: ConversationId
    , role :: Text                -- ^ "user" | "assistant"
    , content :: Text
    , attachments :: [Value]      -- ^ File references
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON WorkMessage
instance FromJSON WorkMessage
instance ToSchema WorkMessage

-- | Conversation
data Conversation = Conversation
    { conversationId :: ConversationId
    , workspaceId :: WorkspaceId
    , title :: Text
    , createdBy :: MemberId
    , sharedWith :: [MemberId]
    , messageCount :: Int
    , createdAt :: Timestamp
    , updatedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Conversation
instance FromJSON Conversation
instance ToSchema Conversation

-- | Integration
data Integration = Integration
    { integrationId :: IntegrationId
    , workspaceId :: WorkspaceId
    , integrationType :: Text     -- ^ "slack" | "notion" | "google" | "github"
    , name :: Text
    , enabled :: Bool
    , config :: Value
    , connectedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Integration
instance FromJSON Integration
instance ToSchema Integration

-- | Usage statistics
data UsageStats = UsageStats
    { workspaceId :: WorkspaceId
    , period :: Text              -- ^ "day" | "week" | "month"
    , startDate :: Timestamp
    , endDate :: Timestamp
    , totalConversations :: Int
    , totalMessages :: Int
    , activeUsers :: Int
    , tokensUsed :: Int
    , cost :: Double
    }
    deriving (Eq, Show, Generic)

instance ToJSON UsageStats
instance FromJSON UsageStats
instance ToSchema UsageStats

-- | Create conversation request
data CreateConversationRequest = CreateConversationRequest
    { title :: Maybe Text
    , initialMessage :: Maybe Text
    , sharedWith :: Maybe [MemberId]
    }
    deriving (Eq, Show, Generic)

instance ToJSON CreateConversationRequest
instance FromJSON CreateConversationRequest
instance ToSchema CreateConversationRequest

-- | Send message request
data SendMessageRequest = SendMessageRequest
    { content :: Text
    , attachments :: Maybe [Text]
    }
    deriving (Eq, Show, Generic)

instance ToJSON SendMessageRequest
instance FromJSON SendMessageRequest
instance ToSchema SendMessageRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type WorkAPI =
    "omega" :> "work" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- Workspaces
          :<|> "workspace" :> AuthHeader :> Get '[JSON] [Workspace]
          :<|> "workspace" :> AuthHeader :> ReqBody '[JSON] Workspace :> Post '[JSON] Workspace
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> Get '[JSON] Workspace
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> ReqBody '[JSON] Workspace :> Put '[JSON] Workspace
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> Delete '[JSON] SuccessResponse
          
          -- Members
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "member" :> Get '[JSON] [TeamMember]
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "member" :> ReqBody '[JSON] TeamMember :> Post '[JSON] TeamMember
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "member" :> Capture "memberId" MemberId :> Delete '[JSON] SuccessResponse
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "member" :> Capture "memberId" MemberId :> "role" :> ReqBody '[JSON] Value :> Put '[JSON] TeamMember
          
          -- Conversations
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "conversation" :> QueryParam "search" Text :> QueryParam "limit" Int :> Get '[JSON] [Conversation]
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "conversation" :> ReqBody '[JSON] CreateConversationRequest :> Post '[JSON] Conversation
          :<|> "conversation" :> AuthHeader :> Capture "conversationId" ConversationId :> Get '[JSON] Conversation
          :<|> "conversation" :> AuthHeader :> Capture "conversationId" ConversationId :> Delete '[JSON] SuccessResponse
          :<|> "conversation" :> AuthHeader :> Capture "conversationId" ConversationId :> "share" :> ReqBody '[JSON] Value :> Post '[JSON] Conversation
          
          -- Messages
          :<|> "conversation" :> AuthHeader :> Capture "conversationId" ConversationId :> "message" :> Get '[JSON] [WorkMessage]
          :<|> "conversation" :> AuthHeader :> Capture "conversationId" ConversationId :> "message" :> ReqBody '[JSON] SendMessageRequest :> Post '[JSON] WorkMessage
          :<|> "conversation" :> AuthHeader :> Capture "conversationId" ConversationId :> "stream" :> Raw  -- SSE
          
          -- Search
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "search" :> QueryParam "q" Text :> Get '[JSON] [Conversation]
          
          -- Integrations
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "integration" :> Get '[JSON] [Integration]
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "integration" :> ReqBody '[JSON] Integration :> Post '[JSON] Integration
          :<|> "integration" :> AuthHeader :> Capture "integrationId" IntegrationId :> Get '[JSON] Integration
          :<|> "integration" :> AuthHeader :> Capture "integrationId" IntegrationId :> ReqBody '[JSON] Integration :> Put '[JSON] Integration
          :<|> "integration" :> AuthHeader :> Capture "integrationId" IntegrationId :> Delete '[JSON] SuccessResponse
          
          -- Admin & Stats
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "stats" :> QueryParam "period" Text :> Get '[JSON] UsageStats
          :<|> "workspace" :> AuthHeader :> Capture "workspaceId" WorkspaceId :> "audit" :> QueryParam "limit" Int :> Get '[JSON] [Value]
        )
