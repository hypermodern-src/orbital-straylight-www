-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                           // straylight-api // omega // code
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- omega//code API
-- Native terminal AI coding agent. Haskell + Brick TUI.
--
-- Features:
--   * Session management with persistent storage
--   * LLM integration (Anthropic, OpenRouter, local)
--   * Tool execution (read, write, edit, bash, glob, grep)
--   * PTY terminals with WebSocket bridge
--   * SSE event streaming
--   * Crew mode for parallel agents
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Omega.Code
    ( -- * API
      CodeAPI
    
      -- * Types
    , Session (..)
    , Message (..)
    , MessagePart (..)
    , Tool (..)
    , ToolCall (..)
    , ToolResult (..)
    , Pty (..)
    , CrewJob (..)
    , AgentConfig (..)
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

newtype SessionId = SessionId { unSessionId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema SessionId

newtype MessageId = MessageId { unMessageId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema MessageId

newtype PtyId = PtyId { unPtyId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema PtyId

newtype CrewId = CrewId { unCrewId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema CrewId

-- | Session status
data SessionStatus
    = Idle
    | Streaming
    | ToolExecuting
    | Thinking
    | Stalled
    deriving (Eq, Show, Generic)

instance ToJSON SessionStatus
instance FromJSON SessionStatus
instance ToSchema SessionStatus

-- | Message role
data Role
    = User
    | Assistant
    | System
    deriving (Eq, Show, Generic)

instance ToJSON Role
instance FromJSON Role
instance ToSchema Role

-- | Agent configuration
data AgentConfig = AgentConfig
    { provider :: Text            -- ^ "anthropic" | "openrouter" | "local"
    , model :: Text               -- ^ "claude-opus-4" etc
    , maxTokens :: Int
    , temperature :: Double
    , systemPrompt :: Maybe Text
    , tools :: [Text]             -- ^ Enabled tool names
    }
    deriving (Eq, Show, Generic)

instance ToJSON AgentConfig
instance FromJSON AgentConfig
instance ToSchema AgentConfig

-- | Tool definition
data Tool = Tool
    { name :: Text
    , description :: Text
    , inputSchema :: Value        -- ^ JSON Schema
    , requiresApproval :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON Tool
instance FromJSON Tool
instance ToSchema Tool

-- | Tool call
data ToolCall = ToolCall
    { toolCallId :: Text
    , toolName :: Text
    , input :: Value
    , approved :: Maybe Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON ToolCall
instance FromJSON ToolCall
instance ToSchema ToolCall

-- | Tool execution result
data ToolResult = ToolResult
    { toolCallId :: Text
    , output :: Value
    , success :: Bool
    , duration :: Double          -- ^ Seconds
    }
    deriving (Eq, Show, Generic)

instance ToJSON ToolResult
instance FromJSON ToolResult
instance ToSchema ToolResult

-- | Message part (content block)
data MessagePart = MessagePart
    { partId :: Text
    , partType :: Text            -- ^ "text" | "tool_call" | "tool_result" | "thinking"
    , content :: Value
    }
    deriving (Eq, Show, Generic)

instance ToJSON MessagePart
instance FromJSON MessagePart
instance ToSchema MessagePart

-- | Message
data Message = Message
    { messageId :: MessageId
    , sessionId :: SessionId
    , role :: Role
    , parts :: [MessagePart]
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Message
instance FromJSON Message
instance ToSchema Message

-- | Session
data Session = Session
    { sessionId :: SessionId
    , projectId :: Text
    , directory :: Text
    , title :: Text
    , status :: SessionStatus
    , agentConfig :: AgentConfig
    , parentId :: Maybe SessionId
    , tokensUsed :: Int
    , cost :: Double
    , createdAt :: Timestamp
    , updatedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Session
instance FromJSON Session
instance ToSchema Session

-- | PTY terminal
data Pty = Pty
    { ptyId :: PtyId
    , sessionId :: SessionId
    , name :: Text
    , command :: Text
    , cols :: Int
    , rows :: Int
    , running :: Bool
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Pty
instance FromJSON Pty
instance ToSchema Pty

-- | Crew job (parallel agents)
data CrewJob = CrewJob
    { crewId :: CrewId
    , sessionId :: SessionId
    , agents :: [SessionId]       -- ^ Child agent sessions
    , status :: Text              -- ^ "running" | "completed" | "cancelled"
    , prompt :: Text
    , selectedAgent :: Maybe SessionId
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON CrewJob
instance FromJSON CrewJob
instance ToSchema CrewJob

-- | Create session request
data CreateSessionRequest = CreateSessionRequest
    { directory :: Text
    , title :: Maybe Text
    , agentConfig :: Maybe AgentConfig
    , parentId :: Maybe SessionId
    }
    deriving (Eq, Show, Generic)

instance ToJSON CreateSessionRequest
instance FromJSON CreateSessionRequest
instance ToSchema CreateSessionRequest

-- | Prompt request
data PromptRequest = PromptRequest
    { content :: Text
    , attachments :: Maybe [Text] -- ^ File paths
    }
    deriving (Eq, Show, Generic)

instance ToJSON PromptRequest
instance FromJSON PromptRequest
instance ToSchema PromptRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type CodeAPI =
    "omega" :> "code" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- Sessions
          :<|> "session" :> AuthHeader :> QueryParam "directory" Text :> QueryParam "limit" Int :> Get '[JSON] [Session]
          :<|> "session" :> AuthHeader :> ReqBody '[JSON] CreateSessionRequest :> Post '[JSON] Session
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> Get '[JSON] Session
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> ReqBody '[JSON] Session :> Patch '[JSON] Session
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> Delete '[JSON] SuccessResponse
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "fork" :> Post '[JSON] Session
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "abort" :> Post '[JSON] Session
          
          -- Messages
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "message" :> Get '[JSON] [Message]
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "message" :> ReqBody '[JSON] PromptRequest :> Post '[JSON] Message
          :<|> "message" :> AuthHeader :> Capture "messageId" MessageId :> Get '[JSON] Message
          
          -- Streaming (SSE)
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "stream" :> Raw
          :<|> "global" :> "event" :> AuthHeader :> Raw
          
          -- Tools
          :<|> "tool" :> AuthHeader :> Get '[JSON] [Tool]
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "tool" :> Capture "toolCallId" Text :> "approve" :> Post '[JSON] ToolResult
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "tool" :> Capture "toolCallId" Text :> "reject" :> Post '[JSON] ToolResult
          
          -- PTY
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "pty" :> Get '[JSON] [Pty]
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "pty" :> ReqBody '[JSON] Pty :> Post '[JSON] Pty
          :<|> "pty" :> AuthHeader :> Capture "ptyId" PtyId :> Get '[JSON] Pty
          :<|> "pty" :> AuthHeader :> Capture "ptyId" PtyId :> Delete '[JSON] SuccessResponse
          :<|> "pty" :> AuthHeader :> Capture "ptyId" PtyId :> "connect" :> Raw  -- WebSocket
          :<|> "pty" :> AuthHeader :> Capture "ptyId" PtyId :> "resize" :> ReqBody '[JSON] Value :> Post '[JSON] SuccessResponse
          
          -- Crew mode
          :<|> "session" :> AuthHeader :> Capture "sessionId" SessionId :> "crew" :> ReqBody '[JSON] Value :> Post '[JSON] CrewJob
          :<|> "crew" :> AuthHeader :> Capture "crewId" CrewId :> Get '[JSON] CrewJob
          :<|> "crew" :> AuthHeader :> Capture "crewId" CrewId :> "select" :> Capture "agentId" SessionId :> Post '[JSON] CrewJob
          :<|> "crew" :> AuthHeader :> Capture "crewId" CrewId :> "cancel" :> Post '[JSON] CrewJob
          
          -- Config
          :<|> "config" :> AuthHeader :> Get '[JSON] Value
          :<|> "config" :> AuthHeader :> ReqBody '[JSON] Value :> Patch '[JSON] Value
          :<|> "provider" :> AuthHeader :> Get '[JSON] [Value]
        )
