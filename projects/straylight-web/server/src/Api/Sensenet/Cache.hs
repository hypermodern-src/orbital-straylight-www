-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                       // straylight-api // sensenet // cache
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- sensenet//cache API
-- Attestation-aware binary cache & artifact store
--
-- Features:
--   * Content-addressed storage with Blake3 hashing
--   * Post-quantum signatures (SPHINCS+)
--   * Attestation metadata for provenance
--   * Nix binary cache protocol compatibility
--   * io_uring async I/O for high throughput
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Sensenet.Cache
    ( -- * API
      CacheAPI
    
      -- * Types
    , Artifact (..)
    , ArtifactUpload (..)
    , ArtifactMetadata (..)
    , Attestation (..)
    , AttestationVerify (..)
    , SignatureType (..)
    , HashInfo (..)
    , NarInfo (..)
    , CacheStats (..)
    , StorePath (..)
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

-- | Content hash using Blake3
newtype ContentHash = ContentHash { unContentHash :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema ContentHash

-- | Store path (Nix-compatible)
newtype StorePath = StorePath { unStorePath :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData)

instance ToSchema StorePath

-- | Signature algorithm
data SignatureType 
    = Ed25519
    | SPHINCSPlus     -- Post-quantum
    | Hybrid          -- Ed25519 + SPHINCS+
    deriving (Eq, Show, Generic)

instance ToJSON SignatureType where
    toJSON Ed25519 = "ed25519"
    toJSON SPHINCSPlus = "sphincs+"
    toJSON Hybrid = "hybrid"

instance FromJSON SignatureType where
    parseJSON = withText "SignatureType" $ \case
        "ed25519" -> pure Ed25519
        "sphincs+" -> pure SPHINCSPlus
        "hybrid" -> pure Hybrid
        _ -> fail "Invalid signature type"

instance ToSchema SignatureType

-- | Hash information
data HashInfo = HashInfo
    { algorithm :: Text        -- ^ "blake3" | "sha256"
    , digest :: Text           -- ^ Hex-encoded hash
    , size :: Integer          -- ^ Size in bytes
    }
    deriving (Eq, Show, Generic)

instance ToJSON HashInfo
instance FromJSON HashInfo
instance ToSchema HashInfo

-- | Attestation for provenance tracking
data Attestation = Attestation
    { attestationId :: Text
    , artifactHash :: ContentHash
    , builderIdentity :: Text
    , buildTimestamp :: Timestamp
    , signatureType :: SignatureType
    , signature :: Text
    , reproducible :: Bool
    , buildInputs :: [ContentHash]
    , metadata :: Maybe Value
    }
    deriving (Eq, Show, Generic)

instance ToJSON Attestation
instance FromJSON Attestation
instance ToSchema Attestation

-- | Attestation verification result
data AttestationVerify = AttestationVerify
    { valid :: Bool
    , attestation :: Maybe Attestation
    , verifiedAt :: Timestamp
    , trustedBuilder :: Bool
    , chainValid :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON AttestationVerify
instance FromJSON AttestationVerify
instance ToSchema AttestationVerify

-- | Artifact metadata
data ArtifactMetadata = ArtifactMetadata
    { contentType :: Maybe Text
    , compression :: Maybe Text     -- ^ "none" | "zstd" | "xz"
    , deriver :: Maybe StorePath
    , references :: [StorePath]
    , system :: Maybe Text          -- ^ "x86_64-linux" etc
    }
    deriving (Eq, Show, Generic)

instance ToJSON ArtifactMetadata
instance FromJSON ArtifactMetadata
instance ToSchema ArtifactMetadata

-- | Artifact record
data Artifact = Artifact
    { artifactId :: Text
    , hash :: HashInfo
    , storePath :: Maybe StorePath
    , metadata :: ArtifactMetadata
    , attestation :: Maybe Attestation
    , createdAt :: Timestamp
    , accessedAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Artifact
instance FromJSON Artifact
instance ToSchema Artifact

-- | Artifact upload request
data ArtifactUpload = ArtifactUpload
    { expectedHash :: Maybe ContentHash
    , storePath :: Maybe StorePath
    , metadata :: ArtifactMetadata
    , attestation :: Maybe Attestation
    }
    deriving (Eq, Show, Generic)

instance ToJSON ArtifactUpload
instance FromJSON ArtifactUpload
instance ToSchema ArtifactUpload

-- | Nix NAR info (binary cache protocol)
data NarInfo = NarInfo
    { storePath :: StorePath
    , url :: Text
    , compression :: Text
    , fileHash :: Text
    , fileSize :: Integer
    , narHash :: Text
    , narSize :: Integer
    , references :: [StorePath]
    , deriver :: Maybe StorePath
    , sig :: [Text]
    }
    deriving (Eq, Show, Generic)

instance ToJSON NarInfo
instance FromJSON NarInfo
instance ToSchema NarInfo

-- | Cache statistics
data CacheStats = CacheStats
    { totalArtifacts :: Integer
    , totalSize :: Integer
    , hitRate :: Double
    , lookupsPerSecond :: Double
    , attestedArtifacts :: Integer
    , postQuantumSigned :: Integer
    }
    deriving (Eq, Show, Generic)

instance ToJSON CacheStats
instance FromJSON CacheStats
instance ToSchema CacheStats


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type CacheAPI =
    "sensenet" :> "cache" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- Artifacts
          :<|> "artifact" :> AuthHeader :> QueryParam "limit" Int :> QueryParam "offset" Int :> Get '[JSON] (PaginatedResponse Artifact)
          :<|> "artifact" :> AuthHeader :> Capture "hash" ContentHash :> Get '[JSON] Artifact
          :<|> "artifact" :> AuthHeader :> ReqBody '[JSON] ArtifactUpload :> Post '[JSON] Artifact
          :<|> "artifact" :> AuthHeader :> Capture "hash" ContentHash :> Delete '[JSON] SuccessResponse
          
          -- Artifact content
          :<|> "artifact" :> Capture "hash" ContentHash :> "content" :> Get '[OctetStream] ByteString
          :<|> "artifact" :> AuthHeader :> Capture "hash" ContentHash :> "content" :> ReqBody '[OctetStream] ByteString :> Put '[JSON] Artifact
          
          -- Attestation
          :<|> "attestation" :> AuthHeader :> Capture "hash" ContentHash :> Get '[JSON] Attestation
          :<|> "attestation" :> AuthHeader :> Capture "hash" ContentHash :> "verify" :> Post '[JSON] AttestationVerify
          :<|> "attestation" :> AuthHeader :> ReqBody '[JSON] Attestation :> Post '[JSON] Attestation
          
          -- Nix binary cache protocol
          :<|> "nix-cache-info" :> Get '[PlainText] Text
          :<|> Capture "hash" Text :> "narinfo" :> Get '[PlainText] Text
          :<|> "nar" :> Capture "hash" Text :> Get '[OctetStream] ByteString
          
          -- Stats
          :<|> "stats" :> AuthHeader :> Get '[JSON] CacheStats
        )

-- ByteString for binary content
type ByteString = Text  -- Placeholder, actual impl uses Data.ByteString
