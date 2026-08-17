module Orbital.Publications.Client (main) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Int as Int
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.CodeUnits as CodeUnits
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Hydrogen.Data.Client as Client
import JSURI as JSURI
import Web.DOM.Element as Element
import Web.DOM.Node (setTextContent)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.HTML as HTML
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Location as Location
import Web.HTML.Window as Window

data PublicationKind
  = Post
  | Paper

data Mode
  = Index PublicationKind
  | Reader String

type Author =
  { display_name :: String
  }

type PublicationSummary =
  { kind :: String
  , slug :: String
  , title :: String
  , summary :: String
  , authors :: Array Author
  , tags :: Array String
  , published_at :: String
  }

type Publication =
  { kind :: String
  , slug :: String
  , title :: String
  , subtitle :: Maybe String
  , summary :: String
  , body :: String
  , source_format :: String
  , authors :: Array Author
  , tags :: Array String
  , paper :: Maybe PaperMetadata
  , assets :: Array Asset
  , published_at :: String
  }

type PaperMetadata =
  { version_label :: Maybe String
  , license_spdx :: Maybe String
  , pdf_asset_id :: Maybe String
  }

type Asset =
  { kind :: String
  , purpose :: String
  , external_url :: Maybe String
  , byte_size :: Maybe Int
  , sha256 :: Maybe String
  }

type PublicationPage =
  { items :: Array PublicationSummary
  , limit :: Int
  , offset :: Int
  }

data View
  = Loading
  | ListReady (Array PublicationSummary)
  | PublicationReady Publication
  | MissingSlug
  | Failed

type State =
  { mode :: Mode
  , view :: View
  }

data Action
  = Initialize
  | Retry

main :: Effect Unit
main = launchAff_ do
  HA.awaitLoad
  doc <- liftEffect $ HTML.window >>= Window.document
  let parent = HTMLDocument.toParentNode doc
  maybeContainer <- liftEffect $ querySelector (QuerySelector "#publications-app") parent
  case maybeContainer >>= HTMLElement.fromElement of
    Nothing -> pure unit
    Just container -> do
      modeName <- liftEffect $ Element.getAttribute "data-publications-mode" (HTMLElement.toElement container)
      slug <- liftEffect $ queryParam "slug"
      let mode = case modeName of
            Just "paper" -> Index Paper
            Just "reader" -> Reader slug
            _ -> Index Post
      liftEffect $ setTextContent "" (Element.toNode (HTMLElement.toElement container))
      void $ runUI component mode container

component :: forall query. H.Component query Mode Void Aff
component =
  H.mkComponent
    { initialState: \mode -> { mode, view: Loading }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

handleAction :: Action -> H.HalogenM State Action () Void Aff Unit
handleAction = case _ of
  Initialize -> load
  Retry -> load

load :: H.HalogenM State Action () Void Aff Unit
load = do
  H.modify_ _ { view = Loading }
  state <- H.get
  case state.mode of
    Index kind -> do
      result <- liftAff $ loadIndex kind
      case result of
        Left err -> failWith err
        Right page -> H.modify_ _ { view = ListReady page.items }
    Reader "" -> H.modify_ _ { view = MissingSlug }
    Reader slug -> do
      result <- liftAff $ loadPublication slug
      case result of
        Left err -> failWith err
        Right publication -> H.modify_ _ { view = PublicationReady publication }

failWith :: String -> H.HalogenM State Action () Void Aff Unit
failWith err = do
  liftEffect $ Console.error ("orbital-publications: " <> err)
  H.modify_ _ { view = Failed }

loadIndex :: PublicationKind -> Aff (Either String PublicationPage)
loadIndex kind =
  Client.get Client.defaultConfig
    ("/api/publications?channel=orbital&kind=" <> kindValue kind <> "&limit=100")

loadPublication :: String -> Aff (Either String Publication)
loadPublication slug =
  Client.get Client.defaultConfig
    ("/api/publications/orbital/" <> encoded slug)

render :: State -> H.ComponentHTML Action () Aff
render state = case state.view of
  Loading -> renderStatus "Loading from ORBITAL // CMS" false
  MissingSlug -> renderMissingSlug
  Failed -> renderStatus "The publishing feed is temporarily unavailable." true
  ListReady publications -> renderList (modeKind state.mode) publications
  PublicationReady publication -> renderPublication publication

renderStatus :: String -> Boolean -> H.ComponentHTML Action () Aff
renderStatus message retry =
  HH.div
    [ className "publication-status" ]
    ( [ HH.span
          [ className (if retry then "status-mark status-mark--error" else "spinner")
          , HP.attr (HH.AttrName "aria-hidden") "true"
          ]
          []
      , HH.span_ [ HH.text message ]
      ]
        <> if retry then
            [ HH.button
                [ className "btn ghost"
                , HP.type_ HP.ButtonButton
                , HE.onClick \_ -> Retry
                ]
                [ HH.text "Retry" ]
            ]
          else []
    )

renderMissingSlug :: H.ComponentHTML Action () Aff
renderMissingSlug =
  HH.div
    [ className "publication-empty" ]
    [ HH.div [ className "publication-empty__code" ] [ HH.text "400" ]
    , HH.h1_ [ HH.text "No publication selected." ]
    , HH.p_ [ HH.text "Choose a dispatch or paper from the publishing index." ]
    , HH.a [ className "link-cta", HP.href "journal.html" ] [ HH.text "Open journal" ]
    ]

renderList :: PublicationKind -> Array PublicationSummary -> H.ComponentHTML Action () Aff
renderList kind publications =
  if Array.null publications then
    HH.div
      [ className "publication-empty" ]
      [ HH.div [ className "publication-empty__code" ] [ HH.text "000" ]
      , HH.h2_ [ HH.text (emptyTitle kind) ]
      , HH.p_ [ HH.text (emptyMessage kind) ]
      ]
  else
    HH.div
      [ className "publication-list" ]
      (map renderSummary publications)

renderSummary :: PublicationSummary -> H.ComponentHTML Action () Aff
renderSummary publication =
  HH.article
    [ className "publication-card" ]
    [ HH.div
        [ className "publication-card__meta" ]
        [ HH.span
            [ className ("badge " <> badgeClass publication.kind) ]
            [ HH.text (kindDisplay publication.kind) ]
        , HH.time_ [ HH.text (shortDate publication.published_at) ]
        ]
    , HH.h2_
        [ HH.a
            [ HP.href (publicationHref publication.slug) ]
            [ HH.text publication.title ]
        ]
    , HH.p [ className "publication-card__summary" ] [ HH.text publication.summary ]
    , HH.div
        [ className "publication-card__footer" ]
        [ HH.span_ [ HH.text (byline publication.authors) ]
        , renderTags publication.tags
        ]
    ]

renderPublication :: Publication -> H.ComponentHTML Action () Aff
renderPublication publication =
  HH.article
    [ className "publication-reader" ]
    [ HH.a
        [ className "publication-reader__back"
        , HP.href (indexHref publication.kind)
        ]
        [ HH.text ("← " <> indexLabel publication.kind) ]
    , HH.header
        [ className "publication-reader__header" ]
        [ HH.div
            [ className "publication-card__meta" ]
            [ HH.span
                [ className ("badge " <> badgeClass publication.kind) ]
                [ HH.text (kindDisplay publication.kind) ]
            , HH.time_ [ HH.text (shortDate publication.published_at) ]
            , HH.span_ [ HH.text publication.source_format ]
            ]
        , HH.h1_ [ HH.text publication.title ]
        , case publication.subtitle of
            Just subtitle -> HH.p [ className "publication-reader__subtitle" ] [ HH.text subtitle ]
            Nothing -> HH.text ""
        , HH.p [ className "publication-reader__summary" ] [ HH.text publication.summary ]
        , HH.div
            [ className "publication-reader__credits" ]
            [ HH.span_ [ HH.text (byline publication.authors) ]
            , renderTags publication.tags
            ]
        ]
    , renderPaperArtifact publication
    , renderBody publication
    ]

renderPaperArtifact :: Publication -> H.ComponentHTML Action () Aff
renderPaperArtifact publication =
  case Array.find isPdf publication.assets >>= _.external_url of
    Nothing -> HH.text ""
    Just url ->
      HH.aside
        [ className "paper-artifact" ]
        [ HH.div
            [ className "paper-artifact__meta" ]
            [ HH.span [ className "paper-artifact__label" ] [ HH.text "Canonical artifact" ]
            , HH.span_ [ HH.text (artifactDetails publication) ]
            ]
        , HH.a
            [ className "btn primary paper-artifact__download"
            , HP.href url
            , HP.attr (HH.AttrName "target") "_blank"
            , HP.attr (HH.AttrName "rel") "noopener"
            ]
            [ HH.text "Download PDF ↗" ]
        ]
  where
  isPdf asset = asset.kind == "pdf" && asset.purpose == "pdf"

artifactDetails :: Publication -> String
artifactDetails publication =
  String.joinWith " · " (Array.catMaybes [ version, license, size, digest ])
  where
  version = publication.paper >>= _.version_label
  license = publication.paper >>= _.license_spdx
  pdf = Array.find (\asset -> asset.kind == "pdf" && asset.purpose == "pdf") publication.assets
  size = pdf >>= _.byte_size <#> humanBytes
  digest = pdf >>= _.sha256 <#> (\value -> "sha256:" <> String.take 12 value)

humanBytes :: Int -> String
humanBytes bytes = show bytes <> " bytes"

renderBody :: Publication -> H.ComponentHTML Action () Aff
renderBody publication =
  if publication.source_format == "markdown" then
    HH.div
      [ className "publication-body" ]
      (map renderMarkdownBlock (parseMarkdown publication.body))
  else
    HH.div
      [ className "publication-source" ]
      [ HH.div
          [ className "publication-source__label" ]
          [ HH.text ("Canonical " <> publication.source_format <> " source") ]
      , HH.pre_ [ HH.code_ [ HH.text publication.body ] ]
      ]

data MarkdownBlock
  = Heading Int String
  | Paragraph String
  | Quote String
  | CodeBlock String String
  | UnorderedList (Array String)
  | OrderedList (Array String)
  | Rule

parseMarkdown :: String -> Array MarkdownBlock
parseMarkdown = parseLines <<< String.split (Pattern "\n")

parseLines :: Array String -> Array MarkdownBlock
parseLines lines = case Array.uncons lines of
  Nothing -> []
  Just { head, tail }
    | String.null (String.trim head) -> parseLines tail
    | Just language <- strip "```" (String.trim head) ->
        let code = Array.span (not <<< isFence <<< String.trim) tail
            remaining = dropClosingFence code.rest
        in [ CodeBlock (String.trim language) (String.joinWith "\n" code.init) ] <> parseLines remaining
    | Just heading <- strip "#### " (String.trim head) -> [ Heading 4 heading ] <> parseLines tail
    | Just heading <- strip "### " (String.trim head) -> [ Heading 3 heading ] <> parseLines tail
    | Just heading <- strip "## " (String.trim head) -> [ Heading 2 heading ] <> parseLines tail
    | Just heading <- strip "# " (String.trim head) -> [ Heading 1 heading ] <> parseLines tail
    | isRule (String.trim head) -> [ Rule ] <> parseLines tail
    | isQuote head ->
        let quoted = Array.span isQuote tail
            body = String.joinWith " " (map stripQuote ([ head ] <> quoted.init))
        in [ Quote body ] <> parseLines quoted.rest
    | isUnordered head ->
        let items = Array.span isUnordered tail
        in [ UnorderedList (map stripUnordered ([ head ] <> items.init)) ] <> parseLines items.rest
    | isOrdered head ->
        let items = Array.span isOrdered tail
        in [ OrderedList (map stripOrdered ([ head ] <> items.init)) ] <> parseLines items.rest
    | otherwise ->
        let paragraph = Array.span (not <<< startsBlock) tail
            body = String.joinWith " " (map String.trim ([ head ] <> paragraph.init))
        in [ Paragraph body ] <> parseLines paragraph.rest

renderMarkdownBlock :: MarkdownBlock -> H.ComponentHTML Action () Aff
renderMarkdownBlock = case _ of
  Heading 1 source -> HH.h2_ (renderInline source)
  Heading 2 source -> HH.h3_ (renderInline source)
  Heading _ source -> HH.h4_ (renderInline source)
  Paragraph source -> HH.p_ (renderInline source)
  Quote source -> HH.blockquote_ (renderInline source)
  CodeBlock language source ->
    HH.pre
      [ HP.attr (HH.AttrName "data-language") (if String.null language then "text" else language) ]
      [ HH.code_ [ HH.text source ] ]
  UnorderedList items -> HH.ul_ (map (HH.li_ <<< renderInline) items)
  OrderedList items -> HH.ol_ (map (HH.li_ <<< renderInline) items)
  Rule -> HH.hr_

renderInline :: String -> Array (H.ComponentHTML Action () Aff)
renderInline source
  | String.null source = []
  | Just match <- bracketed "![" source =
      [ HH.img
          [ HP.src match.destination
          , HP.alt match.label
          , HP.attr (HH.AttrName "loading") "lazy"
          ]
      ] <> renderInline match.rest
  | Just match <- bracketed "[" source =
      [ HH.a [ HP.href match.destination ] (renderInline match.label) ] <> renderInline match.rest
  | Just match <- enclosed "**" "**" source =
      [ HH.strong_ (renderInline match.contents) ] <> renderInline match.rest
  | Just match <- enclosed "`" "`" source =
      [ HH.code_ [ HH.text match.contents ] ] <> renderInline match.rest
  | Just match <- enclosed "*" "*" source =
      [ HH.em_ (renderInline match.contents) ] <> renderInline match.rest
  | otherwise =
      case nextSpecial source of
        Just 0 -> [ HH.text (String.take 1 source) ] <> renderInline (String.drop 1 source)
        Just index -> [ HH.text (String.take index source) ] <> renderInline (String.drop index source)
        Nothing -> [ HH.text source ]

type Bracketed =
  { label :: String
  , destination :: String
  , rest :: String
  }

bracketed :: String -> String -> Maybe Bracketed
bracketed opening source = do
  afterOpening <- strip opening source
  labelEnd <- String.indexOf (Pattern "](") afterOpening
  let labelParts = String.splitAt labelEnd afterOpening
      afterLabel = String.drop 2 labelParts.after
  destinationEnd <- String.indexOf (Pattern ")") afterLabel
  let destinationParts = String.splitAt destinationEnd afterLabel
  pure
    { label: labelParts.before
    , destination: destinationParts.before
    , rest: String.drop 1 destinationParts.after
    }

type Enclosed =
  { contents :: String
  , rest :: String
  }

enclosed :: String -> String -> String -> Maybe Enclosed
enclosed opening closing source = do
  afterOpening <- strip opening source
  closingIndex <- String.indexOf (Pattern closing) afterOpening
  let parts = String.splitAt closingIndex afterOpening
  pure
    { contents: parts.before
    , rest: String.drop (String.length closing) parts.after
    }

nextSpecial :: String -> Maybe Int
nextSpecial = Array.findIndex isSpecial <<< CodeUnits.toCharArray
  where
  isSpecial character = character == '`' || character == '*' || character == '[' || character == '!'

startsBlock :: String -> Boolean
startsBlock source =
  let line = String.trim source
  in String.null line
      || isFence line
      || isRule line
      || isQuote line
      || isUnordered line
      || isOrdered line
      || starts "# " line
      || starts "## " line
      || starts "### " line
      || starts "#### " line

isFence :: String -> Boolean
isFence = starts "```"

isRule :: String -> Boolean
isRule source = String.length source >= 3 && Array.all (_ == '-') (CodeUnits.toCharArray source)

isQuote :: String -> Boolean
isQuote = starts ">" <<< String.trim

stripQuote :: String -> String
stripQuote source = String.trim (fromMaybe source (strip ">" (String.trim source)))

isUnordered :: String -> Boolean
isUnordered source = starts "- " (String.trim source) || starts "* " (String.trim source)

stripUnordered :: String -> String
stripUnordered = String.drop 2 <<< String.trim

isOrdered :: String -> Boolean
isOrdered = case _ of
  source -> case String.indexOf (Pattern ". ") (String.trim source) of
    Nothing -> false
    Just index -> case Int.fromString (String.take index (String.trim source)) of
      Nothing -> false
      Just _ -> true

stripOrdered :: String -> String
stripOrdered source = case String.indexOf (Pattern ". ") (String.trim source) of
  Nothing -> source
  Just index -> String.drop (index + 2) (String.trim source)

dropClosingFence :: Array String -> Array String
dropClosingFence lines = case Array.uncons lines of
  Just { head, tail } | isFence (String.trim head) -> tail
  _ -> lines

starts :: String -> String -> Boolean
starts prefix source = case strip prefix source of
  Just _ -> true
  Nothing -> false

strip :: String -> String -> Maybe String
strip prefix = String.stripPrefix (Pattern prefix)

renderTags :: Array String -> H.ComponentHTML Action () Aff
renderTags tags =
  HH.div
    [ className "publication-tags" ]
    (map (\tag -> HH.span [ className "tag" ] [ HH.text tag ]) tags)

modeKind :: Mode -> PublicationKind
modeKind = case _ of
  Index kind -> kind
  Reader _ -> Post

kindValue :: PublicationKind -> String
kindValue Post = "post"
kindValue Paper = "paper"

kindDisplay :: String -> String
kindDisplay "paper" = "Paper"
kindDisplay _ = "Dispatch"

badgeClass :: String -> String
badgeClass "paper" = "paper"
badgeClass _ = "essay"

indexHref :: String -> String
indexHref "paper" = "papers.html"
indexHref _ = "journal.html"

indexLabel :: String -> String
indexLabel "paper" = "All papers"
indexLabel _ = "All dispatches"

emptyTitle :: PublicationKind -> String
emptyTitle Post = "No dispatches published yet."
emptyTitle Paper = "No papers published yet."

emptyMessage :: PublicationKind -> String
emptyMessage Post = "The journal is wired and waiting for its first publication."
emptyMessage Paper = "Research will appear here as soon as it clears publication."

byline :: Array Author -> String
byline authors =
  if Array.null authors then "Orbital"
  else String.joinWith ", " (map _.display_name authors)

shortDate :: String -> String
shortDate = String.take 10

publicationHref :: String -> String
publicationHref slug = "publication.html?slug=" <> encoded slug

encoded :: String -> String
encoded value = fromMaybe value (JSURI.encodeURIComponent value)

queryParam :: String -> Effect String
queryParam key = do
  search <- HTML.window >>= Window.location >>= Location.search
  pure (lookupParam key search)

lookupParam :: String -> String -> String
lookupParam key search =
  let
    pairs = splitOn "&" (String.drop 1 search)
    match pair = case String.indexOf (Pattern "=") pair of
      Just index ->
        let parts = String.splitAt index pair
        in if parts.before == key then
            JSURI.decodeFormURLComponent (String.drop 1 parts.after)
          else Nothing
      Nothing -> Nothing
  in
    fromMaybe "" (firstJust (map match pairs))

splitOn :: String -> String -> Array String
splitOn separator source = case String.indexOf (Pattern separator) source of
  Nothing -> [ source ]
  Just index ->
    let parts = String.splitAt index source
    in [ parts.before ] <> splitOn separator (String.drop 1 parts.after)

firstJust :: forall a. Array (Maybe a) -> Maybe a
firstJust values = case Array.find isJust values of
  Just (Just value) -> Just value
  _ -> Nothing
  where
  isJust = case _ of
    Just _ -> true
    Nothing -> false

className :: forall r i. String -> HP.IProp (class :: String | r) i
className = HP.attr (HH.AttrName "class")
