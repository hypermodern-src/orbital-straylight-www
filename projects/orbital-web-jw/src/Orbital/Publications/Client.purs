module Orbital.Publications.Client (main) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
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
  , revision_created_at :: String
  }

type Publication =
  { kind :: String
  , slug :: String
  , title :: String
  , summary :: String
  , body :: String
  , source_format :: String
  , authors :: Array Author
  , tags :: Array String
  , revision_created_at :: String
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
        , HH.time_ [ HH.text (shortDate publication.revision_created_at) ]
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
            , HH.time_ [ HH.text (shortDate publication.revision_created_at) ]
            , HH.span_ [ HH.text publication.source_format ]
            ]
        , HH.h1_ [ HH.text publication.title ]
        , HH.p [ className "publication-reader__summary" ] [ HH.text publication.summary ]
        , HH.div
            [ className "publication-reader__credits" ]
            [ HH.span_ [ HH.text (byline publication.authors) ]
            , renderTags publication.tags
            ]
        ]
    , renderBody publication
    ]

renderBody :: Publication -> H.ComponentHTML Action () Aff
renderBody publication =
  if publication.source_format == "markdown" then
    HH.div
      [ className "publication-body" ]
      ( map renderMarkdownBlock
          (Array.filter (not <<< String.null) (map String.trim (String.split (Pattern "\n\n") publication.body)))
      )
  else
    HH.div
      [ className "publication-source" ]
      [ HH.div
          [ className "publication-source__label" ]
          [ HH.text ("Canonical " <> publication.source_format <> " source") ]
      , HH.pre_ [ HH.code_ [ HH.text publication.body ] ]
      ]

renderMarkdownBlock :: String -> H.ComponentHTML Action () Aff
renderMarkdownBlock block =
  case String.stripPrefix (Pattern "### ") block of
    Just heading -> HH.h4_ [ HH.text heading ]
    Nothing -> case String.stripPrefix (Pattern "## ") block of
      Just heading -> HH.h3_ [ HH.text heading ]
      Nothing -> case String.stripPrefix (Pattern "# ") block of
        Just heading -> HH.h2_ [ HH.text heading ]
        Nothing -> case String.stripPrefix (Pattern "> ") block of
          Just quote -> HH.blockquote_ [ HH.text quote ]
          Nothing -> case String.stripPrefix (Pattern "```" ) block of
            Just source ->
              HH.pre_ [ HH.code_ [ HH.text (String.trim (fromMaybe source (String.stripSuffix (Pattern "```") source))) ] ]
            Nothing -> HH.p_ [ HH.text block ]

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
