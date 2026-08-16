{- |
Module      : Straylight.Web.Middleware.Error
Description : The uniform error object carried by middleware failures.

Adapted from @HyperModern.Server.Error@ in Looking Local. The shape is kept
small and language-neutral: a stable machine code, a human message, and
optional structured details.
-}
module Straylight.Web.Middleware.Error (
    ApiError (..),
    apiErrorResponse,
    jsonErrorResponse,
) where

import Data.Aeson (FromJSON (parseJSON), ToJSON (toJSON), Value, object, withObject, (.:), (.:?), (.=))
import Data.Aeson qualified as Aeson
import Data.Text (Text)
import Network.HTTP.Types (Status, hContentType)
import Network.Wai (Response, responseLBS)

-- | The stable error object crossing the HTTP boundary.
data ApiError = ApiError
    { apiErrorCode :: Text
    , apiErrorMessage :: Text
    , apiErrorDetails :: Maybe Value
    }
    deriving stock (Eq, Show)

instance ToJSON ApiError where
    toJSON ApiError{apiErrorCode, apiErrorMessage, apiErrorDetails} =
        object (fields <> maybe [] detail apiErrorDetails)
      where
        fields = ["code" .= apiErrorCode, "message" .= apiErrorMessage]
        detail value = ["details" .= value]

instance FromJSON ApiError where
    parseJSON = withObject "ApiError" $ \value ->
        ApiError
            <$> value .: "code"
            <*> value .: "message"
            <*> value .:? "details"

-- | Render a typed error using the canonical JSON content type.
apiErrorResponse :: Status -> ApiError -> Response
apiErrorResponse status apiError =
    responseLBS status [(hContentType, "application/json")] (Aeson.encode apiError)

-- | Convenience constructor for an error without structured details.
jsonErrorResponse :: Status -> Text -> Text -> Response
jsonErrorResponse status code message =
    apiErrorResponse status (ApiError code message Nothing)
