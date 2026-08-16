module Straylight.Cms.Application (
    AppEnv (..),
    application,
) where

import Data.Aeson (FromJSON, ToJSON, Value (Object, String), eitherDecode, encode, object, toJSON, (.=))
import Data.Aeson.KeyMap qualified as KeyMap
import Data.ByteArray (constEq)
import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as ByteString
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text.Encoding (decodeUtf8', encodeUtf8)
import Data.UUID qualified as UUID
import Network.HTTP.Types (
    Header,
    Status,
    hAuthorization,
    hContentType,
    methodGet,
    methodPost,
    status200,
    status201,
    status304,
    status400,
    status401,
    status404,
    status409,
    status422,
    status503,
 )
import Network.Wai (
    Application,
    Request,
    Response,
    pathInfo,
    queryString,
    requestHeaders,
    requestMethod,
    responseLBS,
    strictRequestBody,
 )
import Text.Read (readMaybe)

import Straylight.Cms.Domain (
    Defect,
    DocumentKind,
    parseDocumentKind,
    parseWorkflowState,
    validateAppendRevision,
    validateCreateDocument,
    validateTransitionDocument,
 )
import Straylight.Cms.Store (EditorialQuery (..), PublicationQuery (..), Store (..), StoreError (..))
import Straylight.Web.Middleware qualified as Web

data AppEnv = AppEnv
    { appStore :: Store
    , appEditorToken :: Maybe ByteString
    , appEditorActor :: Text
    }

application :: AppEnv -> Application
application environment request respond = route environment request >>= respond

route :: AppEnv -> Request -> IO Response
route environment request
    | requestMethod request == methodGet && pathInfo request == ["v1", "publications"] =
        listPublicationsRoute environment request
    | requestMethod request == methodGet
    , ["v1", "publications", channel, slug] <- pathInfo request =
        getPublicationRoute environment request channel slug
    | requestMethod request == methodPost && pathInfo request == ["v1", "editorial", "documents"] =
        editorial environment request (createDocumentRoute environment request)
    | requestMethod request == methodGet && pathInfo request == ["v1", "editorial", "documents"] =
        editorial environment request (listEditorialDocumentsRoute environment request)
    | requestMethod request == methodGet
    , ["v1", "editorial", "documents", rawDocumentId] <- pathInfo request =
        editorial environment request (withDocumentId rawDocumentId (getEditorialRoute environment))
    | requestMethod request == methodGet
    , ["v1", "editorial", "documents", rawDocumentId, "readiness"] <- pathInfo request =
        editorial environment request (withDocumentId rawDocumentId (getReadinessRoute environment request))
    | requestMethod request == methodPost
    , ["v1", "editorial", "documents", rawDocumentId, "revisions"] <- pathInfo request =
        editorial environment request (withDocumentId rawDocumentId (appendRevisionRoute environment request))
    | requestMethod request == methodPost
    , ["v1", "editorial", "documents", rawDocumentId, "transitions"] <- pathInfo request =
        editorial environment request (withDocumentId rawDocumentId (transitionDocumentRoute environment request))
    | otherwise = pure (Web.jsonErrorResponse status404 "not_found" "resource not found")

listEditorialDocumentsRoute :: AppEnv -> Request -> IO Response
listEditorialDocumentsRoute AppEnv{appStore = Store{storeListEditorialDocuments}} request =
    case editorialQuery request of
        Left response -> pure response
        Right editorialQueryValue -> do
            result <- storeListEditorialDocuments editorialQueryValue
            pure $ case result of
                Left storeError -> storeErrorResponse storeError
                Right items ->
                    jsonResponse
                        status200
                        []
                        ( object
                            [ "items" .= items
                            , "limit" .= editorialLimit editorialQueryValue
                            , "offset" .= editorialOffset editorialQueryValue
                            ]
                        )

listPublicationsRoute :: AppEnv -> Request -> IO Response
listPublicationsRoute AppEnv{appStore = Store{storeListPublications}} request =
    case publicationQuery request of
        Left response -> pure response
        Right publicationQueryValue -> do
            result <- storeListPublications publicationQueryValue
            pure $ case result of
                Left storeError -> storeErrorResponse storeError
                Right items ->
                    jsonResponse
                        status200
                        publicListHeaders
                        ( object
                            [ "items" .= items
                            , "limit" .= publicationLimit publicationQueryValue
                            , "offset" .= publicationOffset publicationQueryValue
                            ]
                        )

getPublicationRoute :: AppEnv -> Request -> Text -> Text -> IO Response
getPublicationRoute AppEnv{appStore = Store{storeGetPublication}} request channel slug = do
    result <- storeGetPublication channel slug
    pure $ case result of
        Left storeError -> storeErrorResponse storeError
        Right publication -> publicationResponse request publication

getEditorialRoute :: AppEnv -> UUID.UUID -> IO Response
getEditorialRoute AppEnv{appStore = Store{storeGetEditorialDocument}} documentId =
    storeGetEditorialDocument documentId >>= pure . either storeErrorResponse (jsonResponse status200 [])

getReadinessRoute :: AppEnv -> Request -> UUID.UUID -> IO Response
getReadinessRoute AppEnv{appStore = Store{storeGetReadiness}} request documentId =
    case requiredPositiveQuery "revision" request of
        Left response -> pure response
        Right revision -> do
            result <- storeGetReadiness documentId revision
            pure $ case result of
                Left storeError -> storeErrorResponse storeError
                Right defects ->
                    jsonResponse
                        status200
                        []
                        ( object
                            [ "document_id" .= documentId
                            , "revision" .= revision
                            , "ready" .= null defects
                            , "defects" .= defects
                            ]
                        )

createDocumentRoute :: AppEnv -> Request -> IO Response
createDocumentRoute AppEnv{appStore = Store{storeCreateDocument}, appEditorActor} request = do
    decoded <- decodeBody request
    case decoded of
        Left response -> pure response
        Right input -> case validateCreateDocument input of
            defects@(_ : _) -> pure (inputDefectsResponse defects)
            [] -> do
                result <- storeCreateDocument appEditorActor input
                pure (either storeErrorResponse (jsonResponse status201 []) result)

appendRevisionRoute :: AppEnv -> Request -> UUID.UUID -> IO Response
appendRevisionRoute AppEnv{appStore = store@Store{storeAppendRevision}, appEditorActor} request documentId = do
    decoded <- decodeBody request
    case decoded of
        Left response -> pure response
        Right input -> do
            current <- storeGetEditorialDocument store documentId
            case current of
                Left storeError -> pure (storeErrorResponse storeError)
                Right document -> case documentKind document of
                    Nothing -> pure (storeErrorResponse (StoreUnavailable "document kind is absent"))
                    Just kind -> case validateAppendRevision kind input of
                        defects@(_ : _) -> pure (inputDefectsResponse defects)
                        [] -> do
                            result <- storeAppendRevision appEditorActor documentId kind input
                            pure (either storeErrorResponse (jsonResponse status201 []) result)

transitionDocumentRoute :: AppEnv -> Request -> UUID.UUID -> IO Response
transitionDocumentRoute AppEnv{appStore = Store{storeTransitionDocument}, appEditorActor} request documentId = do
    decoded <- decodeBody request
    case decoded of
        Left response -> pure response
        Right input -> case validateTransitionDocument input of
            defects@(_ : _) -> pure (inputDefectsResponse defects)
            [] -> do
                result <- storeTransitionDocument appEditorActor documentId input
                pure (either storeErrorResponse (jsonResponse status200 []) result)

editorial :: AppEnv -> Request -> IO Response -> IO Response
editorial AppEnv{appEditorToken = Nothing} _ _ =
    pure (Web.jsonErrorResponse status503 "editorial_disabled" "editorial API is not configured")
editorial AppEnv{appEditorToken = Just expected} request action =
    case bearerToken request of
        Just supplied | supplied `constEq` expected -> action
        _ -> pure (Web.jsonErrorResponse status401 "unauthorized" "valid editorial bearer token required")

bearerToken :: Request -> Maybe ByteString
bearerToken request =
    lookup hAuthorization (requestHeaders request) >>= ByteString.stripPrefix "Bearer "

withDocumentId :: Text -> (UUID.UUID -> IO Response) -> IO Response
withDocumentId raw next = case UUID.fromText raw of
    Nothing -> pure (Web.jsonErrorResponse status400 "invalid_document_id" "document ID must be a UUID")
    Just documentId -> next documentId

publicationQuery :: Request -> Either Response PublicationQuery
publicationQuery request = do
    channel <- optionalTextQuery "channel" request
    kindText <- optionalTextQuery "kind" request
    kind <- case kindText of
        Nothing -> Right Nothing
        Just value -> case parseDocumentKind value of
            Nothing -> Left (Web.jsonErrorResponse status400 "invalid_kind" "kind must be post or paper")
            Just parsed -> Right (Just parsed)
    limit <- optionalBoundedIntQuery "limit" 1 100 20 request
    offset <- optionalBoundedIntQuery "offset" 0 1000000 0 request
    pure
        PublicationQuery
            { publicationChannel = fromMaybe "straylight" channel
            , publicationKind = kind
            , publicationLimit = limit
            , publicationOffset = offset
            }

editorialQuery :: Request -> Either Response EditorialQuery
editorialQuery request = do
    channel <- optionalTextQuery "channel" request
    kindText <- optionalTextQuery "kind" request
    kind <- case kindText of
        Nothing -> Right Nothing
        Just value -> case parseDocumentKind value of
            Nothing -> Left (Web.jsonErrorResponse status400 "invalid_kind" "kind must be post or paper")
            Just parsed -> Right (Just parsed)
    stateText <- optionalTextQuery "state" request
    state <- case stateText of
        Nothing -> Right Nothing
        Just value -> case parseWorkflowState value of
            Nothing -> Left (Web.jsonErrorResponse status400 "invalid_state" "state is not a workflow state")
            Just parsed -> Right (Just parsed)
    limit <- optionalBoundedIntQuery "limit" 1 100 20 request
    offset <- optionalBoundedIntQuery "offset" 0 1000000 0 request
    pure
        EditorialQuery
            { editorialChannel = fromMaybe "straylight" channel
            , editorialKind = kind
            , editorialState = state
            , editorialLimit = limit
            , editorialOffset = offset
            }

requiredPositiveQuery :: ByteString -> Request -> Either Response Int
requiredPositiveQuery name request = case queryValue name request of
    Nothing -> Left (Web.jsonErrorResponse status400 "missing_query_parameter" "required query parameter is absent")
    Just value -> case parseInt value of
        Just parsed | parsed > 0 -> Right parsed
        _ -> Left (Web.jsonErrorResponse status400 "invalid_query_parameter" "query parameter must be a positive integer")

optionalBoundedIntQuery :: ByteString -> Int -> Int -> Int -> Request -> Either Response Int
optionalBoundedIntQuery name lower upper fallback request = case queryValue name request of
    Nothing -> Right fallback
    Just value -> case parseInt value of
        Just parsed | parsed >= lower && parsed <= upper -> Right parsed
        _ -> Left (Web.jsonErrorResponse status400 "invalid_query_parameter" "numeric query parameter is out of range")

optionalTextQuery :: ByteString -> Request -> Either Response (Maybe Text)
optionalTextQuery name request = case queryValue name request of
    Nothing -> Right Nothing
    Just value -> case decodeUtf8' value of
        Left _ -> Left (Web.jsonErrorResponse status400 "invalid_query_parameter" "query parameter is not UTF-8")
        Right parsed -> Right (Just parsed)

queryValue :: ByteString -> Request -> Maybe ByteString
queryValue name request = lookup name (queryString request) >>= id

parseInt :: ByteString -> Maybe Int
parseInt = readMaybe . ByteString.unpack

decodeBody :: (FromJSON value) => Request -> IO (Either Response value)
decodeBody request = do
    body <- strictRequestBody request
    pure $ case eitherDecode body of
        Left _ -> Left (Web.jsonErrorResponse status400 "invalid_json" "request body does not match the contract")
        Right value -> Right value

documentKind :: Value -> Maybe DocumentKind
documentKind (Object value) = case KeyMap.lookup "kind" value of
    Just (String kind) -> parseDocumentKind kind
    _ -> Nothing
documentKind _ = Nothing

publicationResponse :: Request -> Value -> Response
publicationResponse request publication =
    case contentHash publication of
        Nothing -> storeErrorResponse (StoreUnavailable "publication hash is absent")
        Just hash
            | lookup "If-None-Match" (requestHeaders request) == Just (quoted hash) ->
                responseLBS status304 (publicDetailHeaders hash) ""
            | otherwise -> jsonResponse status200 (publicDetailHeaders hash) publication

contentHash :: Value -> Maybe ByteString
contentHash (Object value) = case KeyMap.lookup "content_sha256" value of
    Just (String hash) -> Just (encodeUtf8 hash)
    _ -> Nothing
contentHash _ = Nothing

quoted :: ByteString -> ByteString
quoted value = "\"" <> value <> "\""

publicListHeaders :: [Header]
publicListHeaders = [("Cache-Control", "public, max-age=60, stale-while-revalidate=300")]

publicDetailHeaders :: ByteString -> [Header]
publicDetailHeaders hash =
    [ ("Cache-Control", "public, max-age=60, stale-while-revalidate=300")
    , ("ETag", quoted hash)
    ]

inputDefectsResponse :: [Defect] -> Response
inputDefectsResponse defects =
    Web.apiErrorResponse
        status400
        (Web.ApiError "invalid_input" "request fields are invalid" (Just (toJSON defects)))

storeErrorResponse :: StoreError -> Response
storeErrorResponse = \case
    StoreNotFound -> Web.jsonErrorResponse status404 "not_found" "resource not found"
    StoreConflict code -> Web.jsonErrorResponse status409 code "request conflicts with current state"
    StoreInvalid code details ->
        Web.apiErrorResponse status422 (Web.ApiError code "operation is not valid" details)
    StoreUnavailable _ -> Web.jsonErrorResponse status503 "store_unavailable" "publishing store is unavailable"

jsonResponse :: (ToJSON value) => Status -> [Header] -> value -> Response
jsonResponse status headers value =
    responseLBS status ((hContentType, "application/json") : headers) (encode value)
