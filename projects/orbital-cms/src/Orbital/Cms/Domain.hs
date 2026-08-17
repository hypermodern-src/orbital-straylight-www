module Orbital.Cms.Domain (
    AppendRevision (..),
    AssetInput (..),
    AuthorInput (..),
    CreateDocument (..),
    Defect (..),
    DocumentKind (..),
    PaperInput (..),
    RevisionInput (..),
    SourceFormat (..),
    TransitionDocument (..),
    WorkflowState (..),
    documentKindText,
    parseDocumentKind,
    parseWorkflowState,
    publicationDefects,
    revisionValue,
    transitionAllowed,
    validateAppendRevision,
    validateAssetInput,
    validateCreateDocument,
    validateTransitionDocument,
    workflowStateText,
) where

import Data.Aeson (
    FromJSON (parseJSON),
    ToJSON (toJSON),
    Value,
    object,
    withObject,
    withText,
    (.!=),
    (.:),
    (.:?),
    (.=),
 )
import Data.List (nub, sort)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Time (UTCTime)
import Data.UUID (UUID)

data DocumentKind = Post | Paper
    deriving stock (Eq, Show)

data SourceFormat = Markdown | Typst | LaTeX
    deriving stock (Eq, Show)

data WorkflowState = Draft | Review | Scheduled | Published | Archived
    deriving stock (Eq, Show)

data AuthorInput = AuthorInput
    { authorSlug :: Text
    , authorDisplayName :: Text
    , authorOrcid :: Maybe Text
    , authorPosition :: Int
    , authorRole :: Text
    , authorAffiliation :: Maybe Text
    }
    deriving stock (Eq, Show)

data AssetInput = AssetInput
    { assetKind :: Text
    , assetObjectKey :: Maybe Text
    , assetExternalUrl :: Maybe Text
    , assetMediaType :: Text
    , assetByteSize :: Maybe Integer
    , assetSha256 :: Maybe Text
    , assetAltText :: Maybe Text
    , assetCaption :: Maybe Text
    , assetCredit :: Maybe Text
    , assetLicenseSpdx :: Maybe Text
    }
    deriving stock (Eq, Show)

data PaperInput = PaperInput
    { paperDoi :: Maybe Text
    , paperArxivId :: Maybe Text
    , paperVenue :: Maybe Text
    , paperVersionLabel :: Maybe Text
    , paperLicenseSpdx :: Maybe Text
    , paperBibliographyBibtex :: Maybe Text
    , paperReferencesCsl :: [Value]
    , paperPdfAssetId :: Maybe UUID
    }
    deriving stock (Eq, Show)

data RevisionInput = RevisionInput
    { revisionTitle :: Text
    , revisionSubtitle :: Maybe Text
    , revisionSummary :: Text
    , revisionBody :: Text
    , revisionSourceFormat :: SourceFormat
    , revisionLanguage :: Text
    , revisionAuthors :: [AuthorInput]
    , revisionTags :: [Text]
    , revisionPaper :: Maybe PaperInput
    }
    deriving stock (Eq, Show)

data CreateDocument = CreateDocument
    { createChannel :: Text
    , createKind :: DocumentKind
    , createSlug :: Text
    , createRevision :: RevisionInput
    }
    deriving stock (Eq, Show)

data AppendRevision = AppendRevision
    { appendExpectedRevision :: Int
    , appendRevision :: RevisionInput
    }
    deriving stock (Eq, Show)

data TransitionDocument = TransitionDocument
    { transitionExpectedRevision :: Int
    , transitionTarget :: WorkflowState
    , transitionScheduledFor :: Maybe UTCTime
    , transitionPublishedAt :: Maybe UTCTime
    }
    deriving stock (Eq, Show)

data Defect = Defect
    { defectCode :: Text
    , defectMessage :: Text
    }
    deriving stock (Eq, Show)

instance FromJSON DocumentKind where
    parseJSON = withText "DocumentKind" $ \value ->
        maybe (fail "expected post or paper") pure (parseDocumentKind value)

instance ToJSON DocumentKind where
    toJSON = toJSON . documentKindText

instance FromJSON SourceFormat where
    parseJSON = withText "SourceFormat" $ \case
        "markdown" -> pure Markdown
        "typst" -> pure Typst
        "latex" -> pure LaTeX
        _ -> fail "expected markdown, typst, or latex"

instance ToJSON SourceFormat where
    toJSON = toJSON . sourceFormatText

instance FromJSON WorkflowState where
    parseJSON = withText "WorkflowState" $ \value ->
        maybe (fail "expected draft, review, scheduled, published, or archived") pure (parseWorkflowState value)

instance ToJSON WorkflowState where
    toJSON = toJSON . workflowStateText

instance FromJSON AuthorInput where
    parseJSON = withObject "AuthorInput" $ \value ->
        AuthorInput
            <$> value .: "slug"
            <*> value .: "display_name"
            <*> value .:? "orcid"
            <*> value .: "position"
            <*> value .: "role"
            <*> value .:? "affiliation"

instance ToJSON AuthorInput where
    toJSON AuthorInput{..} =
        object
            [ "slug" .= authorSlug
            , "display_name" .= authorDisplayName
            , "orcid" .= authorOrcid
            , "position" .= authorPosition
            , "role" .= authorRole
            , "affiliation" .= authorAffiliation
            ]

instance FromJSON AssetInput where
    parseJSON = withObject "AssetInput" $ \value ->
        AssetInput
            <$> value .: "kind"
            <*> value .:? "object_key"
            <*> value .:? "external_url"
            <*> value .: "media_type"
            <*> value .:? "byte_size"
            <*> value .:? "sha256"
            <*> value .:? "alt_text"
            <*> value .:? "caption"
            <*> value .:? "credit"
            <*> value .:? "license_spdx"

instance ToJSON AssetInput where
    toJSON AssetInput{..} =
        object
            [ "kind" .= assetKind
            , "object_key" .= assetObjectKey
            , "external_url" .= assetExternalUrl
            , "media_type" .= assetMediaType
            , "byte_size" .= assetByteSize
            , "sha256" .= assetSha256
            , "alt_text" .= assetAltText
            , "caption" .= assetCaption
            , "credit" .= assetCredit
            , "license_spdx" .= assetLicenseSpdx
            ]

instance FromJSON PaperInput where
    parseJSON = withObject "PaperInput" $ \value ->
        PaperInput
            <$> value .:? "doi"
            <*> value .:? "arxiv_id"
            <*> value .:? "venue"
            <*> value .:? "version_label"
            <*> value .:? "license_spdx"
            <*> value .:? "bibliography_bibtex"
            <*> value .:? "references_csl" .!= []
            <*> value .:? "pdf_asset_id"

instance ToJSON PaperInput where
    toJSON PaperInput{..} =
        object
            [ "doi" .= paperDoi
            , "arxiv_id" .= paperArxivId
            , "venue" .= paperVenue
            , "version_label" .= paperVersionLabel
            , "license_spdx" .= paperLicenseSpdx
            , "bibliography_bibtex" .= paperBibliographyBibtex
            , "references_csl" .= paperReferencesCsl
            , "pdf_asset_id" .= paperPdfAssetId
            ]

instance FromJSON RevisionInput where
    parseJSON = withObject "RevisionInput" $ \value ->
        RevisionInput
            <$> value .: "title"
            <*> value .:? "subtitle"
            <*> value .: "summary"
            <*> value .: "body"
            <*> value .: "source_format"
            <*> value .: "language"
            <*> value .: "authors"
            <*> value .: "tags"
            <*> value .:? "paper"

instance ToJSON RevisionInput where
    toJSON RevisionInput{..} =
        object
            [ "title" .= revisionTitle
            , "subtitle" .= revisionSubtitle
            , "summary" .= revisionSummary
            , "body" .= revisionBody
            , "source_format" .= revisionSourceFormat
            , "language" .= revisionLanguage
            , "authors" .= revisionAuthors
            , "tags" .= revisionTags
            , "paper" .= revisionPaper
            ]

instance FromJSON CreateDocument where
    parseJSON = withObject "CreateDocument" $ \value ->
        CreateDocument
            <$> value .: "channel"
            <*> value .: "kind"
            <*> value .: "slug"
            <*> value .: "revision"

instance FromJSON AppendRevision where
    parseJSON = withObject "AppendRevision" $ \value ->
        AppendRevision
            <$> value .: "expected_revision"
            <*> value .: "revision"

instance FromJSON TransitionDocument where
    parseJSON = withObject "TransitionDocument" $ \value ->
        TransitionDocument
            <$> value .: "expected_revision"
            <*> value .: "target"
            <*> value .:? "scheduled_for"
            <*> value .:? "published_at"

instance ToJSON Defect where
    toJSON Defect{..} = object ["code" .= defectCode, "message" .= defectMessage]

documentKindText :: DocumentKind -> Text
documentKindText Post = "post"
documentKindText Paper = "paper"

parseDocumentKind :: Text -> Maybe DocumentKind
parseDocumentKind "post" = Just Post
parseDocumentKind "paper" = Just Paper
parseDocumentKind _ = Nothing

sourceFormatText :: SourceFormat -> Text
sourceFormatText Markdown = "markdown"
sourceFormatText Typst = "typst"
sourceFormatText LaTeX = "latex"

workflowStateText :: WorkflowState -> Text
workflowStateText Draft = "draft"
workflowStateText Review = "review"
workflowStateText Scheduled = "scheduled"
workflowStateText Published = "published"
workflowStateText Archived = "archived"

parseWorkflowState :: Text -> Maybe WorkflowState
parseWorkflowState "draft" = Just Draft
parseWorkflowState "review" = Just Review
parseWorkflowState "scheduled" = Just Scheduled
parseWorkflowState "published" = Just Published
parseWorkflowState "archived" = Just Archived
parseWorkflowState _ = Nothing

revisionValue :: RevisionInput -> Value
revisionValue = toJSON

validateAssetInput :: AssetInput -> [Defect]
validateAssetInput AssetInput{..} =
    concat
        [ [Defect "invalid_asset_kind" "asset kind is not supported" | assetKind `notElem` assetKinds]
        , [Defect "missing_asset_location" "object_key or external_url is required" | noLocation]
        , maybe [] (bounded "object_key" 1000) assetObjectKey
        , maybe [] externalUrlDefects assetExternalUrl
        , mediaTypeDefects assetMediaType
        , [Defect "invalid_byte_size" "byte_size must be non-negative" | maybe False (< 0) assetByteSize]
        , maybe [] sha256Defects assetSha256
        , maybe [] (bounded "alt_text" 1000) assetAltText
        , maybe [] (bounded "caption" 4000) assetCaption
        , maybe [] (bounded "credit" 1000) assetCredit
        , [Defect "missing_asset_credit" "external assets require credit" | externalWithoutCredit]
        ]
  where
    assetKinds = ["image", "video", "audio", "pdf", "source", "dataset", "archive"]
    noLocation = maybe True (Text.null . Text.strip) assetObjectKey && maybe True (Text.null . Text.strip) assetExternalUrl
    externalWithoutCredit =
        maybe False (not . Text.null . Text.strip) assetExternalUrl
            && maybe True (Text.null . Text.strip) assetCredit

externalUrlDefects :: Text -> [Defect]
externalUrlDefects value =
    [Defect "invalid_external_url" "external_url must use https" | not ("https://" `Text.isPrefixOf` value)]

mediaTypeDefects :: Text -> [Defect]
mediaTypeDefects value =
    [ Defect "invalid_media_type" "media_type must be a type/subtype value"
    | Text.null major || Text.null minor || Text.any (== ' ') value
    ]
  where
    (major, suffix) = Text.breakOn "/" value
    minor = Text.drop 1 suffix

sha256Defects :: Text -> [Defect]
sha256Defects value =
    [ Defect "invalid_sha256" "sha256 must contain 64 lower-case hexadecimal characters"
    | Text.length value /= 64 || not (Text.all lowerHex value)
    ]
  where
    lowerHex character =
        (character >= '0' && character <= '9') || (character >= 'a' && character <= 'f')

validateCreateDocument :: CreateDocument -> [Defect]
validateCreateDocument CreateDocument{..} =
    concat
        [ fieldSlug "channel" createChannel
        , fieldSlug "slug" createSlug
        , validateRevision createKind createRevision
        ]

validateAppendRevision :: DocumentKind -> AppendRevision -> [Defect]
validateAppendRevision kind AppendRevision{..} =
    positive "expected_revision" appendExpectedRevision <> validateRevision kind appendRevision

validateTransitionDocument :: TransitionDocument -> [Defect]
validateTransitionDocument TransitionDocument{..} =
    positive "expected_revision" transitionExpectedRevision
        <> scheduleDefects transitionTarget transitionScheduledFor
        <> publicationDateDefects transitionTarget transitionPublishedAt

publicationDefects :: DocumentKind -> RevisionInput -> [Defect]
publicationDefects kind RevisionInput{..} =
    concat
        [ required "title" revisionTitle
        , required "summary" revisionSummary
        , required "body" revisionBody
        , [Defect "missing_author" "at least one author is required" | null revisionAuthors]
        , paperDefects kind revisionPaper
        ]

transitionAllowed :: WorkflowState -> WorkflowState -> Bool
transitionAllowed Draft target = target `elem` [Review, Scheduled, Published]
transitionAllowed Review target = target `elem` [Draft, Scheduled, Published]
transitionAllowed Scheduled target = target `elem` [Draft, Published]
transitionAllowed Published target = target `elem` [Draft, Archived]
transitionAllowed Archived target = target == Draft

validateRevision :: DocumentKind -> RevisionInput -> [Defect]
validateRevision kind RevisionInput{..} =
    concat
        [ bounded "title" 300 revisionTitle
        , maybe [] (bounded "subtitle" 500) revisionSubtitle
        , bounded "summary" 4000 revisionSummary
        , bounded "body" 900000 revisionBody
        , languageDefects revisionLanguage
        , concatMap validateAuthor revisionAuthors
        , authorPositionDefects revisionAuthors
        , concatMap (fieldSlug "tags") revisionTags
        , [Defect "duplicate_tag" "tags must be unique" | length revisionTags /= length (nub revisionTags)]
        , sourceDefects kind revisionSourceFormat
        , metadataDefects kind revisionPaper
        ]

validateAuthor :: AuthorInput -> [Defect]
validateAuthor AuthorInput{..} =
    concat
        [ fieldSlug "authors.slug" authorSlug
        , required "authors.display_name" authorDisplayName
        , bounded "authors.display_name" 200 authorDisplayName
        , maybe [] (bounded "authors.affiliation" 300) authorAffiliation
        , [Defect "invalid_author_position" "author position must be non-negative" | authorPosition < 0]
        , [ Defect "invalid_author_role" "author role must be author, editor, translator, or contributor"
          | authorRole `notElem` ["author", "editor", "translator", "contributor"]
          ]
        , maybe [] orcidDefects authorOrcid
        ]

authorPositionDefects :: [AuthorInput] -> [Defect]
authorPositionDefects authors =
    [ Defect "invalid_author_positions" "author positions must be contiguous and start at zero"
    | sort (fmap authorPosition authors) /= [0 .. length authors - 1]
    ]

sourceDefects :: DocumentKind -> SourceFormat -> [Defect]
sourceDefects Post format =
    [Defect "post_source_format" "posts must use markdown" | format /= Markdown]
sourceDefects Paper _ = []

metadataDefects :: DocumentKind -> Maybe PaperInput -> [Defect]
metadataDefects Post (Just _) = [Defect "paper_metadata_on_post" "posts cannot carry paper metadata"]
metadataDefects _ _ = []

paperDefects :: DocumentKind -> Maybe PaperInput -> [Defect]
paperDefects Post _ = []
paperDefects Paper Nothing = [Defect "missing_paper_metadata" "paper metadata is required"]
paperDefects Paper (Just PaperInput{paperLicenseSpdx}) =
    [ Defect "missing_paper_license" "an SPDX paper license is required"
    | maybe True (Text.null . Text.strip) paperLicenseSpdx
    ]

fieldSlug :: Text -> Text -> [Defect]
fieldSlug field value =
    [Defect ("invalid_" <> field) (field <> " must be a lower-case kebab slug") | not (validSlug value)]

validSlug :: Text -> Bool
validSlug value =
    not (Text.null value)
        && Text.length value <= 120
        && all validSegment (Text.splitOn "-" value)
  where
    validSegment segment = not (Text.null segment) && Text.all asciiLowerOrDigit segment
    asciiLowerOrDigit character =
        (character >= 'a' && character <= 'z') || (character >= '0' && character <= '9')

languageDefects :: Text -> [Defect]
languageDefects value =
    [Defect "invalid_language" "language must be a BCP 47-style language tag" | not valid]
  where
    pieces = Text.splitOn "-" value
    language = case pieces of
        [] -> ""
        first : _ -> first
    valid =
        Text.length language `elem` [2, 3]
            && Text.all asciiLower language
            && all validPiece pieces
    validPiece piece = not (Text.null piece) && Text.all asciiAlphaNumeric piece
    asciiLower character = character >= 'a' && character <= 'z'
    asciiAlphaNumeric character =
        (character >= 'a' && character <= 'z')
            || (character >= 'A' && character <= 'Z')
            || (character >= '0' && character <= '9')

orcidDefects :: Text -> [Defect]
orcidDefects value =
    [Defect "invalid_orcid" "ORCID must use the 0000-0000-0000-000X form" | not valid]
  where
    groups = Text.splitOn "-" value
    valid = case groups of
        [a, b, c, d] ->
            a == "0000"
                && all fourDigits [b, c]
                && Text.length d == 4
                && Text.all asciiDigit (Text.take 3 d)
                && maybe False (\lastCharacter -> asciiDigit lastCharacter || lastCharacter == 'X') (Text.unsnoc d >>= Just . snd)
        _ -> False
    fourDigits group = Text.length group == 4 && Text.all asciiDigit group
    asciiDigit character = character >= '0' && character <= '9'

scheduleDefects :: WorkflowState -> Maybe UTCTime -> [Defect]
scheduleDefects Scheduled Nothing = [Defect "missing_schedule" "scheduled_for is required for a scheduled transition"]
scheduleDefects Scheduled (Just _) = []
scheduleDefects _ Nothing = []
scheduleDefects _ (Just _) = [Defect "unexpected_schedule" "scheduled_for is only valid for a scheduled transition"]

publicationDateDefects :: WorkflowState -> Maybe UTCTime -> [Defect]
publicationDateDefects Published _ = []
publicationDateDefects _ Nothing = []
publicationDateDefects _ (Just _) = [Defect "unexpected_publication_date" "published_at is only valid for a published transition"]

required :: Text -> Text -> [Defect]
required field value = [Defect ("missing_" <> field) (field <> " is required") | Text.null (Text.strip value)]

bounded :: Text -> Int -> Text -> [Defect]
bounded field maximumLength value =
    [ Defect ("oversize_" <> field) (field <> " exceeds its maximum length")
    | Text.length value > maximumLength
    ]

positive :: Text -> Int -> [Defect]
positive field value = [Defect ("invalid_" <> field) (field <> " must be positive") | value < 1]
