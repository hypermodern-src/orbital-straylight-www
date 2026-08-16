module Main (
    main,
) where

import Data.Aeson (Value, object, (.=))
import Data.ByteString (ByteString)
import Data.ByteString.Lazy.Char8 qualified as LBS
import Data.Text (Text)
import Data.UUID (UUID)
import Data.UUID qualified as UUID
import Network.HTTP.Types (HeaderName, hAuthorization, methodGet, methodPost, status200, status201, status304, status400, status401, status503)
import Network.Wai (Application, Request (..), defaultRequest)
import Network.Wai.Test (SRequest (SRequest), SResponse (..), runSession, setPath, srequest)
import Test.Hspec (Spec, describe, hspec, it, shouldBe, shouldContain)

import Straylight.Cms.Application (AppEnv (..), application)
import Straylight.Cms.Domain (
    AuthorInput (..),
    Defect (..),
    DocumentKind (..),
    PaperInput (..),
    RevisionInput (..),
    SourceFormat (..),
    WorkflowState (..),
    publicationDefects,
    transitionAllowed,
 )
import Straylight.Cms.Store (Store (..))

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
    describe "publication workflow" $ do
        it "keeps draft authoring permissive but names every publication defect" $ do
            fmap defectCode (publicationDefects Paper emptyPaper)
                `shouldBe` ["missing_title", "missing_summary", "missing_body", "missing_author", "missing_paper_metadata"]

        it "accepts a complete licensed paper" $ do
            publicationDefects Paper completePaper `shouldBe` []

        it "models review as useful but not mandatory" $ do
            transitionAllowed Draft Published `shouldBe` True
            transitionAllowed Draft Review `shouldBe` True
            transitionAllowed Published Review `shouldBe` False
            transitionAllowed Archived Draft `shouldBe` True

    describe "public delivery" $ do
        it "returns cache metadata and honors the exact revision ETag" $ do
            first <- perform methodGet "/v1/publications/straylight/native-inference" [] "" publicApp
            simpleStatus first `shouldBe` status200
            lookup "ETag" (simpleHeaders first) `shouldBe` Just quotedHash

            cached <-
                perform
                    methodGet
                    "/v1/publications/straylight/native-inference"
                    [("If-None-Match", quotedHash)]
                    ""
                    publicApp
            simpleStatus cached `shouldBe` status304
            simpleBody cached `shouldBe` ""

        it "returns bounded publication pages" $ do
            response <- perform methodGet "/v1/publications?kind=paper&limit=1" [] "" publicApp
            simpleStatus response `shouldBe` status200
            LBS.unpack (simpleBody response) `shouldContain` "\"limit\":1"

        it "rejects malformed list parameters" $ do
            response <- perform methodGet "/v1/publications?limit=500" [] "" publicApp
            simpleStatus response `shouldBe` status400

    describe "editorial boundary" $ do
        it "is unavailable rather than accidentally open when identity is not configured" $ do
            response <- perform methodPost "/v1/editorial/documents" [] validCreate (appWithToken Nothing)
            simpleStatus response `shouldBe` status503

        it "rejects an invalid bearer token" $ do
            response <-
                perform
                    methodPost
                    "/v1/editorial/documents"
                    [(hAuthorization, "Bearer wrong")]
                    validCreate
                    (appWithToken (Just editorToken))
            simpleStatus response `shouldBe` status401

        it "creates a valid authenticated draft without imposing publish completeness" $ do
            response <-
                perform
                    methodPost
                    "/v1/editorial/documents"
                    [(hAuthorization, "Bearer " <> editorToken)]
                    validCreate
                    (appWithToken (Just editorToken))
            simpleStatus response `shouldBe` status201

        it "lists drafts for an authenticated editorial studio" $ do
            response <-
                perform
                    methodGet
                    "/v1/editorial/documents?state=draft"
                    [(hAuthorization, "Bearer " <> editorToken)]
                    ""
                    (appWithToken (Just editorToken))
            simpleStatus response `shouldBe` status200

        it "rejects invalid stable slugs before calling the store" $ do
            response <-
                perform
                    methodPost
                    "/v1/editorial/documents"
                    [(hAuthorization, "Bearer " <> editorToken)]
                    invalidCreate
                    (appWithToken (Just editorToken))
            simpleStatus response `shouldBe` status400

publicApp :: Application
publicApp = appWithToken Nothing

appWithToken :: Maybe ByteString -> Application
appWithToken token =
    application
        AppEnv
            { appStore = fakeStore
            , appEditorToken = token
            , appEditorActor = "spec-editor"
            }

fakeStore :: Store
fakeStore =
    Store
        { storeListEditorialDocuments = \_ -> pure (Right [sampleEditorialDocument])
        , storeListPublications = \_ -> pure (Right [samplePublication])
        , storeGetPublication = \_ _ -> pure (Right samplePublication)
        , storeGetEditorialDocument = \_ -> pure (Right sampleEditorialDocument)
        , storeGetReadiness = \_ _ -> pure (Right [])
        , storeCreateDocument = \_ _ -> pure (Right sampleEditorialDocument)
        , storeAppendRevision = \_ _ _ _ -> pure (Right sampleEditorialDocument)
        , storeTransitionDocument = \_ _ _ -> pure (Right sampleEditorialDocument)
        }

samplePublication :: Value
samplePublication =
    object
        [ "id" .= documentId
        , "channel" .= ("straylight" :: Text)
        , "kind" .= ("paper" :: Text)
        , "slug" .= ("native-inference" :: Text)
        , "revision" .= (2 :: Int)
        , "title" .= ("Native inference" :: Text)
        , "content_sha256" .= contentHash
        ]

sampleEditorialDocument :: Value
sampleEditorialDocument =
    object
        [ "id" .= documentId
        , "kind" .= ("paper" :: Text)
        , "workflow_state" .= ("draft" :: Text)
        , "current_revision" .= (2 :: Int)
        , "content_sha256" .= contentHash
        ]

documentId :: UUID
documentId = maybe (error "spec UUID is invalid") id (UUID.fromString "11111111-1111-4111-8111-111111111111")

contentHash :: Text
contentHash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

quotedHash :: ByteString
quotedHash = "\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\""

editorToken :: ByteString
editorToken = "0123456789abcdef0123456789abcdef"

emptyPaper :: RevisionInput
emptyPaper =
    RevisionInput
        { revisionTitle = ""
        , revisionSubtitle = Nothing
        , revisionSummary = ""
        , revisionBody = ""
        , revisionSourceFormat = Markdown
        , revisionLanguage = "en"
        , revisionAuthors = []
        , revisionTags = []
        , revisionPaper = Nothing
        }

completePaper :: RevisionInput
completePaper =
    emptyPaper
        { revisionTitle = "Native inference"
        , revisionSummary = "A systems paper."
        , revisionBody = "# Native inference"
        , revisionAuthors = [AuthorInput "straylight-research" "Straylight Research" Nothing 0 "author" Nothing]
        , revisionPaper = Just (PaperInput Nothing Nothing Nothing (Just "preprint") (Just "CC-BY-4.0") Nothing [] Nothing)
        }

validCreate :: LBS.ByteString
validCreate =
    "{\"channel\":\"straylight\",\"kind\":\"paper\",\"slug\":\"native-inference\",\"revision\":{\"title\":\"\",\"summary\":\"\",\"body\":\"\",\"source_format\":\"markdown\",\"language\":\"en\",\"authors\":[],\"tags\":[]}}"

invalidCreate :: LBS.ByteString
invalidCreate =
    "{\"channel\":\"straylight\",\"kind\":\"paper\",\"slug\":\"Not Fine\",\"revision\":{\"title\":\"\",\"summary\":\"\",\"body\":\"\",\"source_format\":\"markdown\",\"language\":\"en\",\"authors\":[],\"tags\":[]}}"

perform :: ByteString -> ByteString -> [(HeaderName, ByteString)] -> LBS.ByteString -> Application -> IO SResponse
perform method path headers body app =
    runSession (srequest (SRequest requestValue body)) app
  where
    requestValue =
        (setPath defaultRequest path)
            { requestMethod = method
            , requestHeaders = headers
            }
