{- |
Module      : Straylight.Cms.Store.Postgres
Description : Bounded PostgreSQL store with transaction-local guardrails.

The small pool boundary is adapted from Hypermodern LLC house code in Looking
Local. CMS-specific queries and transaction functions are new Straylight work.
-}
module Straylight.Cms.Store.Postgres (
    PostgresStore,
    closePostgresStore,
    newPostgresStore,
    pingPostgresStore,
    postgresStore,
) where

import Control.Exception (IOException, catch)
import Control.Monad (void)
import Data.Aeson (Value, eitherDecodeStrict', encode)
import Data.ByteString (ByteString)
import Data.ByteString.Lazy qualified as LBS
import Data.Pool (Pool, defaultPoolConfig, destroyAllResources, newPool, setNumStripes, withResource)
import Data.Text (Text)
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import Data.Time (UTCTime)
import Data.UUID (UUID)
import Database.PostgreSQL.Simple (
    Connection,
    Only (Only),
    SqlError (..),
    close,
    connectPostgreSQL,
    execute_,
    query,
    query_,
    withTransaction,
 )

import Straylight.Cms.Domain (
    AppendRevision (..),
    CreateDocument (..),
    Defect (..),
    DocumentKind,
    TransitionDocument (..),
    documentKindText,
    revisionValue,
    workflowStateText,
 )
import Straylight.Cms.Store (EditorialQuery (..), PublicationQuery (..), Store (..), StoreError (..))

newtype PostgresStore = PostgresStore (Pool Connection)

newPostgresStore :: ByteString -> Int -> IO PostgresStore
newPostgresStore connectionString poolSize = do
    pool <- newPool configuration
    pure (PostgresStore pool)
  where
    configuration =
        setNumStripes (Just 1) $ defaultPoolConfig (connectPostgreSQL connectionString) close 60.0 poolSize

closePostgresStore :: PostgresStore -> IO ()
closePostgresStore (PostgresStore pool) = destroyAllResources pool

pingPostgresStore :: PostgresStore -> IO (Either StoreError ())
pingPostgresStore database = runDatabase database $ \connection -> do
    rows <- query_ connection "select to_regprocedure('cms.document_json(uuid,integer,boolean)') is not null" :: IO [Only Bool]
    case rows of
        [Only True] -> pure (Right ())
        _ -> pure (Left (StoreUnavailable "cms schema is not migrated"))

postgresStore :: PostgresStore -> Store
postgresStore database =
    Store
        { storeListEditorialDocuments = listEditorialDocuments database
        , storeListPublications = listPublications database
        , storeGetPublication = getPublication database
        , storeGetEditorialDocument = getEditorialDocument database
        , storeGetReadiness = getReadiness database
        , storeCreateDocument = createDocument database
        , storeAppendRevision = appendDocumentRevision database
        , storeTransitionDocument = transitionDocument database
        }

listEditorialDocuments :: PostgresStore -> EditorialQuery -> IO (Either StoreError [Value])
listEditorialDocuments database EditorialQuery{..} =
    runDatabase database $ \connection -> do
        rows <-
            query
                connection
                "select (cms.document_json(d.id, d.current_revision, true) - 'body' - 'assets')::text \
                \from cms.documents d \
                \join cms.channels c on c.id = d.channel_id \
                \where c.slug = ? \
                \and (?::text is null or d.kind::text = ?::text) \
                \and (?::text is null or d.state::text = ?::text) \
                \order by d.updated_at desc, d.id \
                \limit ? offset ?"
                ( editorialChannel
                , documentKindText <$> editorialKind
                , documentKindText <$> editorialKind
                , workflowStateText <$> editorialState
                , workflowStateText <$> editorialState
                , editorialLimit
                , editorialOffset
                ) ::
                IO [Only Text]
        pure (traverse (decodeStoredJson . fromOnly) rows)

listPublications :: PostgresStore -> PublicationQuery -> IO (Either StoreError [Value])
listPublications database PublicationQuery{..} =
    runDatabase database $ \connection -> do
        rows <-
            query
                connection
                "select (cms.document_json(d.id, d.published_revision, false) - 'body' - 'assets')::text \
                \from cms.documents d \
                \join cms.channels c on c.id = d.channel_id \
                \where d.published_revision is not null and d.state <> 'archived' \
                \and c.slug = ? \
                \and (?::text is null or d.kind::text = ?::text) \
                \order by d.last_published_at desc, d.id \
                \limit ? offset ?"
                ( publicationChannel
                , documentKindText <$> publicationKind
                , documentKindText <$> publicationKind
                , publicationLimit
                , publicationOffset
                ) ::
                IO [Only Text]
        pure (traverse (decodeStoredJson . fromOnly) rows)

getPublication :: PostgresStore -> Text -> Text -> IO (Either StoreError Value)
getPublication database channel slug =
    oneJson database $ \connection ->
        query
            connection
            "select cms.document_json(d.id, d.published_revision, false)::text \
            \from cms.documents d \
            \join cms.channels c on c.id = d.channel_id \
            \where d.published_revision is not null and d.state <> 'archived' \
            \and c.slug = ? and d.slug = ?"
            (channel, slug)

getEditorialDocument :: PostgresStore -> UUID -> IO (Either StoreError Value)
getEditorialDocument database documentId =
    oneJson database $ \connection ->
        query
            connection
            "select cms.document_json(id, current_revision, true)::text \
            \from cms.documents where id = ?"
            (Only documentId)

getReadiness :: PostgresStore -> UUID -> Int -> IO (Either StoreError [Defect])
getReadiness database documentId revision =
    runDatabase database $ \connection -> do
        exists <-
            query
                connection
                "select exists (select 1 from cms.document_revisions where document_id = ? and revision = ?)"
                (documentId, revision) ::
                IO [Only Bool]
        case exists of
            [Only True] -> do
                rows <-
                    query
                        connection
                        "select code, message from cms.publication_defects(?, ?)"
                        (documentId, revision) ::
                        IO [(Text, Text)]
                pure (Right (fmap (uncurry Defect) rows))
            _ -> pure (Left StoreNotFound)

createDocument :: PostgresStore -> Text -> CreateDocument -> IO (Either StoreError Value)
createDocument database actor CreateDocument{..} =
    oneJson database $ \connection ->
        query
            connection
            "select cms.create_document(?, ?::cms.document_kind, ?, ?, ?::jsonb)::text"
            (createChannel, documentKindText createKind, createSlug, actor, jsonText (revisionValue createRevision))

appendDocumentRevision :: PostgresStore -> Text -> UUID -> DocumentKind -> AppendRevision -> IO (Either StoreError Value)
appendDocumentRevision database actor documentId _kind AppendRevision{..} =
    oneJson database $ \connection ->
        query
            connection
            "select cms.append_revision(?, ?, ?, ?::jsonb)::text"
            (documentId, appendExpectedRevision, actor, jsonText (revisionValue appendRevision))

transitionDocument :: PostgresStore -> Text -> UUID -> TransitionDocument -> IO (Either StoreError Value)
transitionDocument database actor documentId TransitionDocument{..} =
    oneJson database $ \connection ->
        query
            connection
            "select cms.transition_document(?, ?, ?::cms.document_state, ?, ?)::text"
            ( documentId
            , transitionExpectedRevision
            , workflowStateText transitionTarget
            , actor
            , transitionScheduledFor :: Maybe UTCTime
            )

oneJson :: PostgresStore -> (Connection -> IO [Only Text]) -> IO (Either StoreError Value)
oneJson database action =
    runDatabase database $ \connection -> do
        rows <- action connection
        pure $ case rows of
            [] -> Left StoreNotFound
            [Only value] -> decodeStoredJson value
            _ -> Left (StoreUnavailable "store returned more than one document")

runDatabase :: PostgresStore -> (Connection -> IO (Either StoreError result)) -> IO (Either StoreError result)
runDatabase (PostgresStore pool) action =
    ( withResource pool $ \connection ->
        withTransaction connection $ do
            void $
                execute_
                    connection
                    "set local statement_timeout = '15s'; \
                    \set local idle_in_transaction_session_timeout = '10s'"
            action connection
    )
        `catch` handleSqlError
        `catch` handleIoError

handleSqlError :: SqlError -> IO (Either StoreError result)
handleSqlError errorValue = pure (Left (classifySqlError errorValue))

handleIoError :: IOException -> IO (Either StoreError result)
handleIoError _ = pure (Left (StoreUnavailable "database connection failed"))

classifySqlError :: SqlError -> StoreError
classifySqlError SqlError{sqlState, sqlErrorMsg, sqlErrorDetail}
    | sqlState == "23505" = StoreConflict "resource_already_exists"
    | sqlState == "P0002" = StoreNotFound
    | sqlState == "P0001" = classifyRaised (decodeUtf8 sqlErrorMsg) sqlErrorDetail
    | otherwise = StoreUnavailable "database operation failed"

classifyRaised :: Text -> ByteString -> StoreError
classifyRaised "revision_conflict" _ = StoreConflict "revision_conflict"
classifyRaised "publication_incomplete" detail =
    StoreInvalid "publication_incomplete" (decodeDetail detail)
classifyRaised code _ = StoreInvalid code Nothing

decodeDetail :: ByteString -> Maybe Value
decodeDetail bytes
    | nullBytes bytes = Nothing
    | otherwise = either (const Nothing) Just (eitherDecodeStrict' bytes)
  where
    nullBytes value = value == ""

decodeStoredJson :: Text -> Either StoreError Value
decodeStoredJson value =
    either (const (Left (StoreUnavailable "store returned invalid JSON"))) Right (eitherDecodeStrict' (encodeUtf8 value))

jsonText :: Value -> Text
jsonText = decodeUtf8 . LBS.toStrict . encode

fromOnly :: Only value -> value
fromOnly (Only value) = value
