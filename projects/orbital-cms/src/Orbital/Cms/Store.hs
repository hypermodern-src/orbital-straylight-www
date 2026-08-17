module Orbital.Cms.Store (
    EditorialQuery (..),
    PublicationQuery (..),
    Store (..),
    StoreError (..),
) where

import Data.Aeson (Value)
import Data.Text (Text)
import Data.UUID (UUID)

import Orbital.Cms.Domain (
    AppendRevision,
    AssetInput,
    CreateDocument,
    Defect,
    DocumentKind,
    TransitionDocument,
    WorkflowState,
 )

data EditorialQuery = EditorialQuery
    { editorialChannel :: Text
    , editorialKind :: Maybe DocumentKind
    , editorialState :: Maybe WorkflowState
    , editorialLimit :: Int
    , editorialOffset :: Int
    }
    deriving stock (Eq, Show)

data PublicationQuery = PublicationQuery
    { publicationChannel :: Text
    , publicationKind :: Maybe DocumentKind
    , publicationLimit :: Int
    , publicationOffset :: Int
    }
    deriving stock (Eq, Show)

data StoreError
    = StoreNotFound
    | StoreConflict Text
    | StoreInvalid Text (Maybe Value)
    | StoreUnavailable Text
    deriving stock (Eq, Show)

data Store = Store
    { storeRegisterAsset :: Text -> AssetInput -> IO (Either StoreError Value)
    , storeListEditorialDocuments :: EditorialQuery -> IO (Either StoreError [Value])
    , storeListPublications :: PublicationQuery -> IO (Either StoreError [Value])
    , storeGetPublication :: Text -> Text -> IO (Either StoreError Value)
    , storeGetEditorialDocument :: UUID -> IO (Either StoreError Value)
    , storeGetReadiness :: UUID -> Int -> IO (Either StoreError [Defect])
    , storeCreateDocument :: Text -> CreateDocument -> IO (Either StoreError Value)
    , storeAppendRevision :: Text -> UUID -> DocumentKind -> AppendRevision -> IO (Either StoreError Value)
    , storeTransitionDocument :: Text -> UUID -> TransitionDocument -> IO (Either StoreError Value)
    }
