-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                       // straylight-api // sensenet // build
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- sensenet//build API
-- Typed build system. Dhall configurations. Lean4 proofs.
--
-- Features:
--   * Dhall-typed build configurations
--   * Lean4 formal verification of build semantics
--   * Hermetic builds with content-addressed caching
--   * Remote execution on distributed clusters
--   * Multi-language support (Rust, Go, Haskell, etc.)
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Sensenet.Build
    ( -- * API
      BuildAPI
    
      -- * Types
    , BuildTarget (..)
    , BuildConfig (..)
    , BuildJob (..)
    , BuildStatus (..)
    , BuildOutput (..)
    , BuildProof (..)
    , ProofStatus (..)
    , Toolchain (..)
    , DhallConfig (..)
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

-- | Build target identifier
newtype TargetId = TargetId { unTargetId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema TargetId

-- | Build job identifier
newtype JobId = JobId { unJobId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema JobId

-- | Build status
data BuildStatus
    = Pending
    | Running
    | Succeeded
    | Failed
    | Cancelled
    deriving (Eq, Show, Generic)

instance ToJSON BuildStatus where
    toJSON Pending = "pending"
    toJSON Running = "running"
    toJSON Succeeded = "success"
    toJSON Failed = "failed"
    toJSON Cancelled = "cancelled"

instance FromJSON BuildStatus where
    parseJSON = withText "BuildStatus" $ \case
        "pending" -> pure Pending
        "running" -> pure Running
        "success" -> pure Succeeded
        "failed" -> pure Failed
        "cancelled" -> pure Cancelled
        _ -> fail "Invalid build status"

instance ToSchema BuildStatus

instance ToHttpApiData BuildStatus where
    toUrlPiece Pending = "pending"
    toUrlPiece Running = "running"
    toUrlPiece Succeeded = "success"
    toUrlPiece Failed = "failed"
    toUrlPiece Cancelled = "cancelled"

instance FromHttpApiData BuildStatus where
    parseUrlPiece "pending" = Right Pending
    parseUrlPiece "running" = Right Running
    parseUrlPiece "success" = Right Succeeded
    parseUrlPiece "failed" = Right Failed
    parseUrlPiece "cancelled" = Right Cancelled
    parseUrlPiece _ = Left "Invalid build status"

instance ToParamSchema BuildStatus

-- | Proof verification status
data ProofStatus
    = Verified
    | Unverified
    | ProofFailed
    | ProofPending
    deriving (Eq, Show, Generic)

instance ToJSON ProofStatus where
    toJSON Verified = "verified"
    toJSON Unverified = "unverified"
    toJSON ProofFailed = "failed"
    toJSON ProofPending = "pending"

instance FromJSON ProofStatus where
    parseJSON = withText "ProofStatus" $ \case
        "verified" -> pure Verified
        "unverified" -> pure Unverified
        "failed" -> pure ProofFailed
        "pending" -> pure ProofPending
        _ -> fail "Invalid proof status"

instance ToSchema ProofStatus

-- | Toolchain configuration
data Toolchain = Toolchain
    { name :: Text
    , version :: Text
    , compiler :: Text
    , compilerVersion :: Text
    , system :: Text
    , nixDerivation :: Maybe Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON Toolchain
instance FromJSON Toolchain
instance ToSchema Toolchain

-- | Dhall configuration
data DhallConfig = DhallConfig
    { source :: Text              -- ^ Dhall source code
    , typeChecked :: Bool
    , normalized :: Maybe Text    -- ^ Normalized Dhall
    , hash :: Maybe Text          -- ^ Semantic hash
    }
    deriving (Eq, Show, Generic)

instance ToJSON DhallConfig
instance FromJSON DhallConfig
instance ToSchema DhallConfig

-- | Build target definition
data BuildTarget = BuildTarget
    { targetId :: TargetId
    , name :: Text
    , targetType :: Text          -- ^ "binary" | "library" | "test"
    , language :: Text            -- ^ "rust" | "go" | "haskell" | "cpp" | etc
    , sources :: [Text]
    , dependencies :: [TargetId]
    , toolchain :: Toolchain
    , config :: DhallConfig
    }
    deriving (Eq, Show, Generic)

instance ToJSON BuildTarget
instance FromJSON BuildTarget
instance ToSchema BuildTarget

-- | Build configuration for a project
data BuildConfig = BuildConfig
    { configId :: Text
    , projectPath :: Text
    , targets :: [BuildTarget]
    , defaultTarget :: Maybe TargetId
    , remoteExecution :: Bool
    , cachingEnabled :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON BuildConfig
instance FromJSON BuildConfig
instance ToSchema BuildConfig

-- | Build proof (Lean4 verification)
data BuildProof = BuildProof
    { proofId :: Text
    , targetId :: TargetId
    , theorem :: Text             -- ^ Lean4 theorem name
    , status :: ProofStatus
    , proofHash :: Maybe Text     -- ^ Hash of the proof term
    , verifiedAt :: Maybe Timestamp
    , leanVersion :: Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON BuildProof
instance FromJSON BuildProof
instance ToSchema BuildProof

-- | Build output artifact
data BuildOutput = BuildOutput
    { outputId :: Text
    , jobId :: JobId
    , path :: Text
    , hash :: Text
    , size :: Integer
    , outputType :: Text          -- ^ "binary" | "library" | "log"
    }
    deriving (Eq, Show, Generic)

instance ToJSON BuildOutput
instance FromJSON BuildOutput
instance ToSchema BuildOutput

-- | Build job
data BuildJob = BuildJob
    { jobId :: JobId
    , targetId :: TargetId
    , status :: BuildStatus
    , startedAt :: Maybe Timestamp
    , completedAt :: Maybe Timestamp
    , duration :: Maybe Double    -- ^ Seconds
    , outputs :: [BuildOutput]
    , proof :: Maybe BuildProof
    , remote :: Bool
    , cached :: Bool
    , logs :: Maybe Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON BuildJob
instance FromJSON BuildJob
instance ToSchema BuildJob

-- | Build request
data BuildRequest = BuildRequest
    { target :: TargetId
    , clean :: Bool
    , remote :: Bool
    , verify :: Bool              -- ^ Run Lean4 proof verification
    }
    deriving (Eq, Show, Generic)

instance ToJSON BuildRequest
instance FromJSON BuildRequest
instance ToSchema BuildRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type BuildAPI =
    "sensenet" :> "build" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- Targets
          :<|> "target" :> AuthHeader :> QueryParam "project" Text :> Get '[JSON] [BuildTarget]
          :<|> "target" :> AuthHeader :> Capture "targetId" TargetId :> Get '[JSON] BuildTarget
          :<|> "target" :> AuthHeader :> ReqBody '[JSON] BuildTarget :> Post '[JSON] BuildTarget
          :<|> "target" :> AuthHeader :> Capture "targetId" TargetId :> ReqBody '[JSON] BuildTarget :> Put '[JSON] BuildTarget
          :<|> "target" :> AuthHeader :> Capture "targetId" TargetId :> Delete '[JSON] SuccessResponse
          
          -- Configuration
          :<|> "config" :> AuthHeader :> QueryParam "project" Text :> Get '[JSON] BuildConfig
          :<|> "config" :> AuthHeader :> ReqBody '[JSON] BuildConfig :> Put '[JSON] BuildConfig
          :<|> "config" :> "validate" :> AuthHeader :> ReqBody '[JSON] DhallConfig :> Post '[JSON] DhallConfig
          
          -- Build jobs
          :<|> "build" :> AuthHeader :> ReqBody '[JSON] BuildRequest :> Post '[JSON] BuildJob
          :<|> "build" :> AuthHeader :> QueryParam "status" BuildStatus :> QueryParam "limit" Int :> Get '[JSON] [BuildJob]
          :<|> "build" :> AuthHeader :> Capture "jobId" JobId :> Get '[JSON] BuildJob
          :<|> "build" :> AuthHeader :> Capture "jobId" JobId :> "cancel" :> Post '[JSON] BuildJob
          :<|> "build" :> AuthHeader :> Capture "jobId" JobId :> "logs" :> Get '[PlainText] Text
          
          -- Outputs
          :<|> "build" :> AuthHeader :> Capture "jobId" JobId :> "output" :> Get '[JSON] [BuildOutput]
          :<|> "build" :> AuthHeader :> Capture "jobId" JobId :> "output" :> Capture "outputId" Text :> Get '[OctetStream] Text
          
          -- Proofs
          :<|> "proof" :> AuthHeader :> Capture "targetId" TargetId :> Get '[JSON] [BuildProof]
          :<|> "proof" :> AuthHeader :> Capture "targetId" TargetId :> "verify" :> Post '[JSON] BuildProof
          
          -- Toolchains
          :<|> "toolchain" :> AuthHeader :> Get '[JSON] [Toolchain]
          :<|> "toolchain" :> AuthHeader :> Capture "name" Text :> Get '[JSON] Toolchain
        )
