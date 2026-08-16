-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                       // straylight-api // sensenet // forge
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- sensenet//forge API
-- Code hosting + review. Stacked diffs, not PRs. jujutsu first-class.
--
-- Features:
--   * Stacked diffs for incremental review
--   * Native jujutsu (jj) support
--   * Agent code attestation
--   * Semantic code search
--   * SSH-based authentication
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Sensenet.Forge
    ( -- * API
      ForgeAPI
    
      -- * Types
    , Repository (..)
    , Diff (..)
    , DiffStack (..)
    , Review (..)
    , Comment (..)
    , Change (..)
    , Attestation (..)
    , SearchResult (..)
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

newtype RepoId = RepoId { unRepoId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema RepoId

newtype DiffId = DiffId { unDiffId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema DiffId

newtype StackId = StackId { unStackId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema StackId

-- | Diff status
data DiffStatus
    = Draft
    | NeedsReview
    | Approved
    | Landed
    | Abandoned
    deriving (Eq, Show, Generic)

instance ToJSON DiffStatus where
    toJSON Draft = "draft"
    toJSON NeedsReview = "needs_review"
    toJSON Approved = "approved"
    toJSON Landed = "landed"
    toJSON Abandoned = "abandoned"

instance FromJSON DiffStatus where
    parseJSON = withText "DiffStatus" $ \case
        "draft" -> pure Draft
        "needs_review" -> pure NeedsReview
        "approved" -> pure Approved
        "landed" -> pure Landed
        "abandoned" -> pure Abandoned
        _ -> fail "Invalid diff status"

instance ToSchema DiffStatus

instance ToHttpApiData DiffStatus where
    toUrlPiece Draft = "draft"
    toUrlPiece NeedsReview = "needs_review"
    toUrlPiece Approved = "approved"
    toUrlPiece Landed = "landed"
    toUrlPiece Abandoned = "abandoned"

instance FromHttpApiData DiffStatus where
    parseUrlPiece "draft" = Right Draft
    parseUrlPiece "needs_review" = Right NeedsReview
    parseUrlPiece "approved" = Right Approved
    parseUrlPiece "landed" = Right Landed
    parseUrlPiece "abandoned" = Right Abandoned
    parseUrlPiece _ = Left "Invalid diff status"

instance ToParamSchema DiffStatus

-- | Repository
data Repository = Repository
    { repoId :: RepoId
    , owner :: Text
    , name :: Text
    , description :: Maybe Text
    , defaultBranch :: Text
    , visibility :: Text          -- ^ "public" | "private"
    , cloneUrl :: Text
    , sshUrl :: Text
    , createdAt :: Timestamp
    , updatedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Repository
instance FromJSON Repository
instance ToSchema Repository

-- | jujutsu change
data Change = Change
    { changeId :: Text            -- ^ jj change ID (stable across rebases)
    , commitId :: Text            -- ^ Git commit ID (changes on rebase)
    , description :: Text
    , author :: Text
    , authorEmail :: Text
    , timestamp :: Timestamp
    , parents :: [Text]
    }
    deriving (Eq, Show, Generic)

instance ToJSON Change
instance FromJSON Change
instance ToSchema Change

-- | Code attestation for AI-generated code
data Attestation = Attestation
    { attestationId :: Text
    , diffId :: DiffId
    , authorType :: Text          -- ^ "human" | "agent"
    , agentId :: Maybe Text       -- ^ "claude-opus-4" etc
    , modelVersion :: Maybe Text
    , promptHash :: Maybe Text
    , signatureType :: Text
    , signature :: Text
    , verifiedAt :: Maybe Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Attestation
instance FromJSON Attestation
instance ToSchema Attestation

-- | Diff (single change in a stack)
data Diff = Diff
    { diffId :: DiffId
    , repoId :: RepoId
    , stackId :: Maybe StackId
    , title :: Text
    , description :: Maybe Text
    , author :: Text
    , status :: DiffStatus
    , change :: Change
    , baseBranch :: Text
    , filesChanged :: Int
    , additions :: Int
    , deletions :: Int
    , attestation :: Maybe Attestation
    , createdAt :: Timestamp
    , updatedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Diff
instance FromJSON Diff
instance ToSchema Diff

-- | Stack of related diffs
data DiffStack = DiffStack
    { stackId :: StackId
    , repoId :: RepoId
    , diffs :: [DiffId]           -- ^ Ordered from base to tip
    , baseBranch :: Text
    , status :: DiffStatus
    , author :: Text
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON DiffStack
instance FromJSON DiffStack
instance ToSchema DiffStack

-- | Review comment
data Comment = Comment
    { commentId :: Text
    , diffId :: DiffId
    , author :: Text
    , body :: Text
    , file :: Maybe Text
    , line :: Maybe Int
    , resolved :: Bool
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Comment
instance FromJSON Comment
instance ToSchema Comment

-- | Review
data Review = Review
    { reviewId :: Text
    , diffId :: DiffId
    , reviewer :: Text
    , verdict :: Text             -- ^ "approve" | "request_changes" | "comment"
    , body :: Maybe Text
    , comments :: [Comment]
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Review
instance FromJSON Review
instance ToSchema Review

-- | Semantic search result
data SearchResult = SearchResult
    { file :: Text
    , line :: Int
    , content :: Text
    , score :: Double
    , symbolType :: Maybe Text    -- ^ "function" | "type" | "variable" etc
    }
    deriving (Eq, Show, Generic)

instance ToJSON SearchResult
instance FromJSON SearchResult
instance ToSchema SearchResult

-- | Create diff request
data CreateDiffRequest = CreateDiffRequest
    { title :: Text
    , description :: Maybe Text
    , changeId :: Text
    , baseBranch :: Maybe Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON CreateDiffRequest
instance FromJSON CreateDiffRequest
instance ToSchema CreateDiffRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type ForgeAPI =
    "sensenet" :> "forge" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- Repositories
          :<|> "repo" :> AuthHeader :> QueryParam "owner" Text :> Get '[JSON] [Repository]
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> Get '[JSON] Repository
          :<|> "repo" :> AuthHeader :> ReqBody '[JSON] Repository :> Post '[JSON] Repository
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> ReqBody '[JSON] Repository :> Put '[JSON] Repository
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> Delete '[JSON] SuccessResponse
          
          -- Diffs
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> "diff" :> QueryParam "status" DiffStatus :> Get '[JSON] [Diff]
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> "diff" :> ReqBody '[JSON] CreateDiffRequest :> Post '[JSON] Diff
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> Get '[JSON] Diff
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> ReqBody '[JSON] Diff :> Put '[JSON] Diff
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> "submit" :> Post '[JSON] Diff
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> "land" :> Post '[JSON] Diff
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> "abandon" :> Post '[JSON] Diff
          
          -- Stacks
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> "stack" :> Get '[JSON] [DiffStack]
          :<|> "stack" :> AuthHeader :> Capture "stackId" StackId :> Get '[JSON] DiffStack
          :<|> "stack" :> AuthHeader :> Capture "stackId" StackId :> "submit" :> Post '[JSON] DiffStack
          :<|> "stack" :> AuthHeader :> Capture "stackId" StackId :> "rebase" :> Post '[JSON] DiffStack
          
          -- Reviews
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> "review" :> Get '[JSON] [Review]
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> "review" :> ReqBody '[JSON] Review :> Post '[JSON] Review
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> "comment" :> ReqBody '[JSON] Comment :> Post '[JSON] Comment
          
          -- Attestation
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> "attestation" :> Get '[JSON] Attestation
          :<|> "diff" :> AuthHeader :> Capture "diffId" DiffId :> "attestation" :> "verify" :> Post '[JSON] SuccessResponse
          
          -- Search
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> "search" :> QueryParam "q" Text :> QueryParam "type" Text :> Get '[JSON] [SearchResult]
          
          -- Browse
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> "browse" :> QueryParam "path" Text :> QueryParam "ref" Text :> Get '[JSON] Value
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> "log" :> QueryParam "ref" Text :> QueryParam "limit" Int :> Get '[JSON] [Change]
          :<|> "repo" :> AuthHeader :> Capture "owner" Text :> Capture "name" Text :> "branch" :> Get '[JSON] [Text]
        )
