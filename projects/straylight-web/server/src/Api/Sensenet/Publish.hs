-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                     // straylight-api // sensenet // publish
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- sensenet//publish API
-- Scope-graph documentation. References resolve or the build fails.
--
-- Features:
--   * Scope-graph semantic analysis
--   * Cross-language reference resolution
--   * Build-time reference validation
--   * Machine-readable output (JSON-LD, OpenAPI)
--   * Semantic code search
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Sensenet.Publish
    ( -- * API
      PublishAPI
    
      -- * Types
    , Project (..)
    , Document (..)
    , Symbol (..)
    , Reference (..)
    , ScopeGraph (..)
    , DocBuildJob (..)
    , ValidationResult (..)
    ) where

import Data.Aeson
import Data.OpenApi (ToSchema (..), ToParamSchema (..))
import Data.Text (Text)
import GHC.Generics
import Servant
import Web.HttpApiData (FromHttpApiData (..), ToHttpApiData (..))

import Api.Types


-- ═══════════════════════════════════════════════════════════════════════════
-- // types //
-- ═══════════════════════════════════════════════════════════════════════════

newtype ProjectId = ProjectId { unProjectId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema ProjectId

newtype DocId = DocId { unDocId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema DocId

newtype SymbolId = SymbolId { unSymbolId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema SymbolId

newtype JobId = JobId { unJobId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema JobId

-- | Symbol kind
data SymbolKind
    = Function
    | TypeDef
    | Variable
    | Module
    | Class
    | Interface
    | Constant
    | Field
    deriving (Eq, Show, Generic)

instance ToJSON SymbolKind
instance FromJSON SymbolKind
instance ToSchema SymbolKind

instance ToHttpApiData SymbolKind where
    toUrlPiece Function = "function"
    toUrlPiece TypeDef = "type"
    toUrlPiece Variable = "variable"
    toUrlPiece Module = "module"
    toUrlPiece Class = "class"
    toUrlPiece Interface = "interface"
    toUrlPiece Constant = "constant"
    toUrlPiece Field = "field"

instance FromHttpApiData SymbolKind where
    parseUrlPiece "function" = Right Function
    parseUrlPiece "type" = Right TypeDef
    parseUrlPiece "variable" = Right Variable
    parseUrlPiece "module" = Right Module
    parseUrlPiece "class" = Right Class
    parseUrlPiece "interface" = Right Interface
    parseUrlPiece "constant" = Right Constant
    parseUrlPiece "field" = Right Field
    parseUrlPiece _ = Left "Invalid symbol kind"

instance ToParamSchema SymbolKind

-- | Build status
data BuildStatus
    = Pending
    | Building
    | Succeeded
    | BuildFailed
    deriving (Eq, Show, Generic)

instance ToJSON BuildStatus where
    toJSON Pending = "pending"
    toJSON Building = "building"
    toJSON Succeeded = "succeeded"
    toJSON BuildFailed = "failed"

instance FromJSON BuildStatus where
    parseJSON = withText "BuildStatus" $ \case
        "pending" -> pure Pending
        "building" -> pure Building
        "succeeded" -> pure Succeeded
        "failed" -> pure BuildFailed
        _ -> fail "Invalid build status"

instance ToSchema BuildStatus

-- | Documentation project
data Project = Project
    { projectId :: ProjectId
    , name :: Text
    , repository :: Text
    , languages :: [Text]         -- ^ ["rust", "haskell", "typescript"]
    , outputFormat :: Text        -- ^ "html" | "json-ld" | "openapi"
    , strictMode :: Bool          -- ^ Fail on broken references
    , createdAt :: Timestamp
    , updatedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Project
instance FromJSON Project
instance ToSchema Project

-- | Symbol definition
data Symbol = Symbol
    { symbolId :: SymbolId
    , projectId :: ProjectId
    , name :: Text
    , qualifiedName :: Text
    , kind :: SymbolKind
    , language :: Text
    , file :: Text
    , line :: Int
    , column :: Int
    , signature :: Maybe Text     -- ^ Type signature
    , documentation :: Maybe Text
    , visibility :: Text          -- ^ "public" | "private" | "internal"
    }
    deriving (Eq, Show, Generic)

instance ToJSON Symbol
instance FromJSON Symbol
instance ToSchema Symbol

-- | Reference between symbols
data Reference = Reference
    { referenceId :: Text
    , fromSymbol :: SymbolId
    , toSymbol :: SymbolId
    , referenceType :: Text       -- ^ "call" | "type" | "import" | "inherit"
    , file :: Text
    , line :: Int
    , resolved :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON Reference
instance FromJSON Reference
instance ToSchema Reference

-- | Scope graph
data ScopeGraph = ScopeGraph
    { projectId :: ProjectId
    , symbols :: [Symbol]
    , references :: [Reference]
    , scopes :: [Value]           -- ^ Scope tree structure
    , builtAt :: Timestamp
    , hash :: Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON ScopeGraph
instance FromJSON ScopeGraph
instance ToSchema ScopeGraph

-- | Generated document
data Document = Document
    { docId :: DocId
    , projectId :: ProjectId
    , path :: Text
    , title :: Text
    , content :: Text
    , format :: Text              -- ^ "html" | "markdown" | "json-ld"
    , symbols :: [SymbolId]       -- ^ Symbols documented in this page
    , version :: Text
    , generatedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Document
instance FromJSON Document
instance ToSchema Document

-- | Validation result
data ValidationResult = ValidationResult
    { valid :: Bool
    , brokenReferences :: [Reference]
    , unresolvedSymbols :: [Text]
    , warnings :: [Text]
    , validatedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON ValidationResult
instance FromJSON ValidationResult
instance ToSchema ValidationResult

-- | Documentation build job
data DocBuildJob = DocBuildJob
    { jobId :: JobId
    , projectId :: ProjectId
    , status :: BuildStatus
    , startedAt :: Maybe Timestamp
    , completedAt :: Maybe Timestamp
    , documentsGenerated :: Int
    , symbolsIndexed :: Int
    , referencesResolved :: Int
    , validation :: Maybe ValidationResult
    , outputUrl :: Maybe Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON DocBuildJob
instance FromJSON DocBuildJob
instance ToSchema DocBuildJob

-- | Build request
data BuildRequest = BuildRequest
    { branch :: Maybe Text
    , commitSha :: Maybe Text
    , strictMode :: Maybe Bool
    , outputFormat :: Maybe Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON BuildRequest
instance FromJSON BuildRequest
instance ToSchema BuildRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type PublishAPI =
    "sensenet" :> "publish" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- Projects
          :<|> "project" :> AuthHeader :> Get '[JSON] [Project]
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> Get '[JSON] Project
          :<|> "project" :> AuthHeader :> ReqBody '[JSON] Project :> Post '[JSON] Project
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> ReqBody '[JSON] Project :> Put '[JSON] Project
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> Delete '[JSON] SuccessResponse
          
          -- Builds
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> "build" :> ReqBody '[JSON] BuildRequest :> Post '[JSON] DocBuildJob
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> "build" :> Get '[JSON] [DocBuildJob]
          :<|> "build" :> AuthHeader :> Capture "jobId" JobId :> Get '[JSON] DocBuildJob
          :<|> "build" :> AuthHeader :> Capture "jobId" JobId :> "logs" :> Get '[PlainText] Text
          
          -- Scope graph
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> "scope-graph" :> Get '[JSON] ScopeGraph
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> "symbol" :> QueryParam "q" Text :> QueryParam "kind" SymbolKind :> Get '[JSON] [Symbol]
          :<|> "symbol" :> AuthHeader :> Capture "symbolId" SymbolId :> Get '[JSON] Symbol
          :<|> "symbol" :> AuthHeader :> Capture "symbolId" SymbolId :> "references" :> Get '[JSON] [Reference]
          :<|> "symbol" :> AuthHeader :> Capture "symbolId" SymbolId :> "callers" :> Get '[JSON] [Reference]
          
          -- Documents
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> "doc" :> Get '[JSON] [Document]
          :<|> "doc" :> AuthHeader :> Capture "docId" DocId :> Get '[JSON] Document
          :<|> "doc" :> AuthHeader :> Capture "docId" DocId :> "html" :> Get '[PlainText] Text
          :<|> "doc" :> AuthHeader :> Capture "docId" DocId :> "json-ld" :> Get '[JSON] Value
          
          -- Validation
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> "validate" :> Post '[JSON] ValidationResult
          
          -- Search
          :<|> "project" :> AuthHeader :> Capture "projectId" ProjectId :> "search" :> QueryParam "q" Text :> QueryParam "type" Text :> Get '[JSON] [Symbol]
        )
