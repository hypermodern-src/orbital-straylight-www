-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                     // straylight-api // sensenet // confirm
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- sensenet//confirm API
-- CI with proof obligations. Typed Dhall pipelines.
--
-- Features:
--   * Dhall-typed pipeline definitions
--   * Proof obligations checked at merge time
--   * Agent code review with taint tracking
--   * Post-quantum build attestation
--   * Hermetic reproducible builds
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Sensenet.Confirm
    ( -- * API
      ConfirmAPI
    
      -- * Types
    , Pipeline (..)
    , PipelineRun (..)
    , PipelineStep (..)
    , StepResult (..)
    , ProofObligation (..)
    , ProofResult (..)
    , AgentReview (..)
    , BuildAttestation (..)
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

newtype PipelineId = PipelineId { unPipelineId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema PipelineId

newtype RunId = RunId { unRunId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema RunId

-- | Pipeline run status
data RunStatus
    = Queued
    | InProgress
    | Passed
    | RunFailed
    | Skipped
    deriving (Eq, Show, Generic)

instance ToJSON RunStatus where
    toJSON Queued = "queued"
    toJSON InProgress = "in_progress"
    toJSON Passed = "passed"
    toJSON RunFailed = "failed"
    toJSON Skipped = "skipped"

instance FromJSON RunStatus where
    parseJSON = withText "RunStatus" $ \case
        "queued" -> pure Queued
        "in_progress" -> pure InProgress
        "passed" -> pure Passed
        "failed" -> pure RunFailed
        "skipped" -> pure Skipped
        _ -> fail "Invalid run status"

instance ToSchema RunStatus

instance ToHttpApiData RunStatus where
    toUrlPiece Queued = "queued"
    toUrlPiece InProgress = "in_progress"
    toUrlPiece Passed = "passed"
    toUrlPiece RunFailed = "failed"
    toUrlPiece Skipped = "skipped"

instance FromHttpApiData RunStatus where
    parseUrlPiece "queued" = Right Queued
    parseUrlPiece "in_progress" = Right InProgress
    parseUrlPiece "passed" = Right Passed
    parseUrlPiece "failed" = Right RunFailed
    parseUrlPiece "skipped" = Right Skipped
    parseUrlPiece _ = Left "Invalid run status"

instance ToParamSchema RunStatus

-- | Pipeline step
data PipelineStep = PipelineStep
    { stepId :: Text
    , name :: Text
    , run :: Text                 -- ^ Command to execute
    , environment :: Maybe Value  -- ^ Environment variables
    , timeout :: Maybe Int        -- ^ Timeout in seconds
    , condition :: Maybe Text     -- ^ Dhall expression for conditional execution
    , proofRequired :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON PipelineStep
instance FromJSON PipelineStep
instance ToSchema PipelineStep

-- | Proof obligation
data ProofObligation = ProofObligation
    { obligationId :: Text
    , stepId :: Text
    , proofType :: Text           -- ^ "tests_pass" | "type_check" | "coverage" | "custom"
    , expression :: Text          -- ^ Dhall/Lean expression
    , required :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON ProofObligation
instance FromJSON ProofObligation
instance ToSchema ProofObligation

-- | Proof verification result
data ProofResult = ProofResult
    { obligationId :: Text
    , verified :: Bool
    , verifiedAt :: Timestamp
    , proofHash :: Maybe Text
    , error :: Maybe Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON ProofResult
instance FromJSON ProofResult
instance ToSchema ProofResult

-- | Pipeline definition
data Pipeline = Pipeline
    { pipelineId :: PipelineId
    , name :: Text
    , repository :: Text
    , branch :: Maybe Text
    , steps :: [PipelineStep]
    , proofs :: [ProofObligation]
    , dhallSource :: Text
    , dhallHash :: Text
    , agentReviewRequired :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON Pipeline
instance FromJSON Pipeline
instance ToSchema Pipeline

-- | Step execution result
data StepResult = StepResult
    { stepId :: Text
    , status :: RunStatus
    , startedAt :: Maybe Timestamp
    , completedAt :: Maybe Timestamp
    , exitCode :: Maybe Int
    , stdout :: Maybe Text
    , stderr :: Maybe Text
    , proofResult :: Maybe ProofResult
    }
    deriving (Eq, Show, Generic)

instance ToJSON StepResult
instance FromJSON StepResult
instance ToSchema StepResult

-- | Agent review for AI-generated code
data AgentReview = AgentReview
    { reviewId :: Text
    , runId :: RunId
    , agentId :: Text             -- ^ "claude-opus-4" etc
    , promptHash :: Text
    , taintedFiles :: [Text]
    , humanReviewRequired :: Bool
    , reviewStatus :: Text        -- ^ "pending" | "approved" | "rejected"
    , reviewedBy :: Maybe Text
    , reviewedAt :: Maybe Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON AgentReview
instance FromJSON AgentReview
instance ToSchema AgentReview

-- | Build attestation
data BuildAttestation = BuildAttestation
    { attestationId :: Text
    , runId :: RunId
    , builderIdentity :: Text
    , buildTimestamp :: Timestamp
    , inputHash :: Text
    , outputHash :: Text
    , signatureType :: Text       -- ^ "ed25519" | "sphincs+" | "hybrid"
    , signature :: Text
    , reproducible :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON BuildAttestation
instance FromJSON BuildAttestation
instance ToSchema BuildAttestation

-- | Pipeline run
data PipelineRun = PipelineRun
    { runId :: RunId
    , pipelineId :: PipelineId
    , trigger :: Text             -- ^ "push" | "pr" | "manual" | "schedule"
    , commitSha :: Text
    , branch :: Text
    , status :: RunStatus
    , startedAt :: Maybe Timestamp
    , completedAt :: Maybe Timestamp
    , steps :: [StepResult]
    , attestation :: Maybe BuildAttestation
    , agentReview :: Maybe AgentReview
    }
    deriving (Eq, Show, Generic)

instance ToJSON PipelineRun
instance FromJSON PipelineRun
instance ToSchema PipelineRun

-- | Trigger request
data TriggerRequest = TriggerRequest
    { branch :: Maybe Text
    , commitSha :: Maybe Text
    , variables :: Maybe Value
    }
    deriving (Eq, Show, Generic)

instance ToJSON TriggerRequest
instance FromJSON TriggerRequest
instance ToSchema TriggerRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type ConfirmAPI =
    "sensenet" :> "confirm" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- Pipelines
          :<|> "pipeline" :> AuthHeader :> QueryParam "repository" Text :> Get '[JSON] [Pipeline]
          :<|> "pipeline" :> AuthHeader :> Capture "pipelineId" PipelineId :> Get '[JSON] Pipeline
          :<|> "pipeline" :> AuthHeader :> ReqBody '[JSON] Pipeline :> Post '[JSON] Pipeline
          :<|> "pipeline" :> AuthHeader :> Capture "pipelineId" PipelineId :> ReqBody '[JSON] Pipeline :> Put '[JSON] Pipeline
          :<|> "pipeline" :> AuthHeader :> Capture "pipelineId" PipelineId :> Delete '[JSON] SuccessResponse
          :<|> "pipeline" :> "validate" :> AuthHeader :> ReqBody '[JSON] Pipeline :> Post '[JSON] Pipeline
          
          -- Pipeline runs
          :<|> "pipeline" :> AuthHeader :> Capture "pipelineId" PipelineId :> "trigger" :> ReqBody '[JSON] TriggerRequest :> Post '[JSON] PipelineRun
          :<|> "pipeline" :> AuthHeader :> Capture "pipelineId" PipelineId :> "run" :> QueryParam "status" RunStatus :> QueryParam "limit" Int :> Get '[JSON] [PipelineRun]
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> Get '[JSON] PipelineRun
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "cancel" :> Post '[JSON] PipelineRun
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "retry" :> Post '[JSON] PipelineRun
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "logs" :> Get '[PlainText] Text
          
          -- Step logs
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "step" :> Capture "stepId" Text :> "logs" :> Get '[PlainText] Text
          
          -- Proofs
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "proof" :> Get '[JSON] [ProofResult]
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "proof" :> Capture "obligationId" Text :> Get '[JSON] ProofResult
          
          -- Agent review
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "review" :> Get '[JSON] AgentReview
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "review" :> "approve" :> Post '[JSON] AgentReview
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "review" :> "reject" :> Post '[JSON] AgentReview
          
          -- Attestation
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "attestation" :> Get '[JSON] BuildAttestation
          :<|> "run" :> AuthHeader :> Capture "runId" RunId :> "attestation" :> "verify" :> Post '[JSON] SuccessResponse
        )
