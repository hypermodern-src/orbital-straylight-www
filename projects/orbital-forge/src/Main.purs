module Main where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Forge.Data (Project, Publication, ReadmeBlock(..), SourceFile, fromRepository, sourceLanguage)
import Forge.Forgejo as Forgejo
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Halogen.VDom.Driver (runUI)
import Hydrogen.Data.RemoteData (RemoteData(..))
import Hydrogen.Orbital.Brand (defaultBrandmark, brandmark)
import Hydrogen.Orbital.Code (defaultCodeViewer, codeViewer)
import Hydrogen.Orbital.Navigation as Nav
import Hydrogen.Orbital.Shell (defaultAppShell, appShell)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.Event.Event (EventType(..))
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window

foreign import currentHash :: Effect String
foreign import setHash :: String -> Effect Unit
foreign import currentTheme :: Effect Boolean
foreign import applyTheme :: Boolean -> Effect Unit
foreign import copyText :: String -> Effect Unit

data ProjectTab = Overview | Source | Papers

derive instance eqProjectTab :: Eq ProjectTab

data Route = ForgeHome | ProjectRoute String ProjectTab

derive instance eqRoute :: Eq Route

data CloneProtocol = OrbCli | Https | Ssh

derive instance eqCloneProtocol :: Eq CloneProtocol

type State =
  { route :: Route
  , repositories :: RemoteData String (Array Project)
  , sourceRepository :: Maybe String
  , tree :: RemoteData String Forgejo.TreeListing
  , selectedFile :: Int
  , requestedPath :: Maybe String
  , source :: RemoteData String SourceFile
  , cloneProtocol :: CloneProtocol
  , copied :: Boolean
  , dark :: Boolean
  }

data Action
  = Initialize
  | HashChanged
  | Navigate Route
  | SelectTab ProjectTab
  | SelectFile Int
  | SelectProtocol CloneProtocol
  | CopyClone
  | ToggleTheme
  | RetryRepositories
  | RetrySource

main :: Effect Unit
main = launchAff_ do
  HA.awaitLoad
  doc <- liftEffect $ window >>= Window.document
  container <- liftEffect $ querySelector (QuerySelector "#app") (HTMLDocument.toParentNode doc)
  case container >>= HTMLElement.fromElement of
    Nothing -> pure unit
    Just root -> void $ runUI component unit root

component :: forall q i o. H.Component q i o Aff
component =
  H.mkComponent
    { initialState: const
        { route: ForgeHome
        , repositories: NotAsked
        , sourceRepository: Nothing
        , tree: NotAsked
        , selectedFile: 0
        , requestedPath: Nothing
        , source: NotAsked
        , cloneProtocol: OrbCli
        , copied: false
        , dark: false
        }
    , render
    , eval: H.mkEval H.defaultEval
        { initialize = Just Initialize
        , handleAction = handleAction
        }
    }

handleAction :: forall o. Action -> H.HalogenM State Action () o Aff Unit
handleAction = case _ of
  Initialize -> do
    hash <- liftEffect currentHash
    dark <- liftEffect currentTheme
    H.modify_ _ { route = parseHash hash, dark = dark }
    win <- liftEffect window
    void $ H.subscribe $ eventListener (EventType "hashchange") (Window.toEventTarget win) (const (Just HashChanged))
    loadRepositories
  HashChanged -> do
    hash <- liftEffect currentHash
    let route = parseHash hash
    H.modify_ _ { route = route, selectedFile = 0, cloneProtocol = OrbCli, copied = false }
    loadRoute route
  Navigate route -> do
    H.modify_ _ { route = route, selectedFile = 0, cloneProtocol = OrbCli, copied = false }
    liftEffect $ setHash (routeHash route)
    loadRoute route
  SelectTab tab -> do
    state <- H.get
    case state.route of
      ProjectRoute slug _ -> handleAction (Navigate (ProjectRoute slug tab))
      ForgeHome -> pure unit
  SelectFile index -> do
    state <- H.get
    case projectForRoute state state.route, state.tree of
      Just project, Success listing -> case listing.files Array.!! index of
        Nothing -> pure unit
        Just entry -> loadFile project index entry
      _, _ -> pure unit
  SelectProtocol protocol -> H.modify_ _ { cloneProtocol = protocol, copied = false }
  CopyClone -> do
    state <- H.get
    case projectForRoute state state.route of
      Nothing -> pure unit
      Just project -> do
        liftEffect $ copyText (cloneCommand state.cloneProtocol project)
        H.modify_ _ { copied = true }
  ToggleTheme -> do
    state <- H.get
    let dark = not state.dark
    liftEffect $ applyTheme dark
    H.modify_ _ { dark = dark }
  RetryRepositories -> loadRepositories
  RetrySource -> do
    state <- H.get
    case projectForRoute state state.route of
      Nothing -> pure unit
      Just project -> loadTree project

loadRepositories :: forall o. H.HalogenM State Action () o Aff Unit
loadRepositories = do
  H.modify_ _ { repositories = Loading }
  result <- H.liftAff Forgejo.listRepositories
  case result of
    Left error -> H.modify_ _ { repositories = Failure error }
    Right repositories -> do
      let projects = repositories # map fromRepository # Array.sortBy newestFirst
      H.modify_ _ { repositories = Success projects }
      state <- H.get
      loadRoute state.route
  where
  newestFirst left right = compare right.repository.updatedAt left.repository.updatedAt

loadRoute :: forall o. Route -> H.HalogenM State Action () o Aff Unit
loadRoute = case _ of
  ProjectRoute slug Source -> do
    state <- H.get
    case projectForSlug state slug of
      Just project | state.sourceRepository /= Just slug -> loadTree project
      _ -> pure unit
  _ -> pure unit

loadTree :: forall o. Project -> H.HalogenM State Action () o Aff Unit
loadTree project = do
  H.modify_ _
    { sourceRepository = Just project.slug
    , tree = Loading
    , source = NotAsked
    , requestedPath = Nothing
    , selectedFile = 0
    }
  result <- H.liftAff $ Forgejo.listSource project.repository
  case result of
    Left error -> H.modify_ _ { tree = Failure error, source = NotAsked }
    Right listing -> do
      let selected = fromMaybe 0 (Array.findIndex (\entry -> entry.path == "README.md") listing.files)
      H.modify_ _ { tree = Success listing, selectedFile = selected }
      case listing.files Array.!! selected of
        Nothing -> H.modify_ _ { source = Failure "This repository has no readable source files." }
        Just entry -> loadFile project selected entry

loadFile :: forall o. Project -> Int -> Forgejo.SourceEntry -> H.HalogenM State Action () o Aff Unit
loadFile project index entry = do
  H.modify_ _
    { selectedFile = index
    , requestedPath = Just entry.path
    , source = Loading
    }
  result <- H.liftAff $ Forgejo.readSource project.repository entry
  state <- H.get
  when (state.sourceRepository == Just project.slug && state.requestedPath == Just entry.path) do
    H.modify_ _ { source = case result of
      Left error -> Failure error
      Right code -> Success { path: entry.path, language: sourceLanguage entry.path, code }
    }

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  appShell
    ( defaultAppShell
        { header = [ renderNav state ]
        , main =
            [ HH.div
                [ HP.class_ (HH.ClassName (if isSourceRoute state.route then "forge-scroll is-source" else "forge-scroll")) ]
                [ HH.div [ HP.class_ (HH.ClassName "forge-wrap") ] [ renderRoute state ] ]
            ]
        , statusLeft = statusLeft state
        , statusRight = statusRight state
        , sourceMode = isSourceRoute state.route
        , class_ = "forge-app"
        }
    )

renderNav :: forall w. State -> HH.HTML w Action
renderNav state =
  Nav.navBar
    ( Nav.defaultNavBar
        { brand =
            [ brandmark
                ( defaultBrandmark
                    { product = Just "forge"
                    , href = Just "#/"
                    }
                )
            ]
        , primary = [ { label: "Orbital", href: "https://orbital.foo/", current: false } ]
        , secondary =
            [ { label: "Forge", href: "#/", current: true }
            , { label: "Journal", href: "https://orbital.foo/journal.html", current: false }
            , { label: "Papers", href: "https://orbital.foo/papers.html", current: false }
            ]
        , actions =
            [ HH.button
                [ HP.type_ HP.ButtonButton
                , HP.class_ (HH.ClassName "forge-theme")
                , HP.attr (HH.AttrName "aria-label") (if state.dark then "Use light theme" else "Use dark theme")
                , HE.onClick (const ToggleTheme)
                ]
                [ HH.span [ HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text (if state.dark then "○" else "●") ]
                , HH.span [ HP.class_ (HH.ClassName "forge-theme-label") ] [ HH.text "Theme" ]
                ]
            ]
        }
    )

renderRoute :: forall w. State -> HH.HTML w Action
renderRoute state = case state.route of
  ForgeHome -> renderHome state
  ProjectRoute slug tab -> case projectForSlug state slug of
    Just project -> renderProject state project tab
    Nothing -> case state.repositories of
      NotAsked -> renderLoading "Opening repository"
      Loading -> renderLoading "Opening repository"
      Failure error -> renderFailure "Forgejo is unavailable" (connectionHelp error) RetryRepositories
      Success _ -> renderMissing slug

renderHome :: forall w. State -> HH.HTML w Action
renderHome state =
  HH.div_
    [ HH.header [ HP.class_ (HH.ClassName "forge-head") ]
        [ HH.div [ HP.class_ (HH.ClassName "forge-eyebrow") ] [ HH.text "Orbital // Forge" ]
        , HH.h1_ [ HH.text "Consequential systems, and the papers that explain them." ]
        , HH.p_ [ HH.text "A literary forge for working systems. Read the source, clone the repository, and follow the papers that state why it exists. No stars, no theatre — just the work and its reasons." ]
        , HH.div [ HP.class_ (HH.ClassName "forge-metrics") ] (homeMetrics state.repositories)
        ]
    , case state.repositories of
        NotAsked -> renderLoading "Connecting to Forgejo"
        Loading -> renderLoading "Connecting to Forgejo"
        Failure error -> renderFailure "Could not reach Forgejo" (connectionHelp error) RetryRepositories
        Success projects ->
          HH.section
            [ HP.class_ (HH.ClassName "forge-project-list")
            , HP.attr (HH.AttrName "aria-label") "Repositories"
            ]
            (map renderProjectRow projects)
    ]

homeMetrics :: forall w. RemoteData String (Array Project) -> Array (HH.HTML w Action)
homeMetrics repositories = case repositories of
  Success projects ->
    [ metric (show (Array.length projects)) "Repositories"
    , metric (show (foldl (\count project -> count + project.openIssues) 0 projects)) "Open issues"
    , metric (show (foldl (\count project -> count + Array.length project.publications) 0 projects)) "Linked publications"
    ]
  _ -> [ metric "—" "Repositories", metric "—" "Open issues", metric "—" "Linked publications" ]
  where
  metric value label =
    HH.div [ HP.class_ (HH.ClassName "forge-metric") ]
      [ HH.span [ HP.class_ (HH.ClassName "forge-metric-value") ] [ HH.text value ]
      , HH.span [ HP.class_ (HH.ClassName "forge-metric-label") ] [ HH.text label ]
      ]

renderProjectRow :: forall w. Project -> HH.HTML w Action
renderProjectRow project =
  HH.a
    [ HP.href (routeHash route)
    , HP.class_ (HH.ClassName "forge-project")
    , HE.onClick (const (Navigate route))
    ]
    [ HH.div [ HP.class_ (HH.ClassName "forge-project-main") ]
        [ HH.div [ HP.class_ (HH.ClassName "forge-project-name") ]
            [ HH.text project.name
            , HH.span [ HP.class_ (HH.ClassName "forge-owner") ] [ HH.text ("/ " <> project.owner) ]
            ]
        , HH.p [ HP.class_ (HH.ClassName "forge-project-blurb") ] [ HH.text project.blurb ]
        , HH.div [ HP.class_ (HH.ClassName "forge-tags") ] (map (\value -> HH.span_ [ HH.text value ]) project.tags)
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-project-signals") ]
        [ languageBar project
        , HH.div [ HP.class_ (HH.ClassName "forge-project-stat") ]
            [ HH.b_ [ HH.text (show project.sizeKiB) ], HH.text " KiB" ]
        , HH.div [ HP.class_ (HH.ClassName "forge-project-stat") ]
            [ HH.text (project.defaultBranch <> " branch · updated " <> project.updated) ]
        , HH.div [ HP.class_ (HH.ClassName "forge-project-reading") ]
            [ HH.text (show (Array.length project.publications) <> " linked publications →") ]
        ]
    , HH.span [ HP.class_ (HH.ClassName "forge-project-arrow"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "→" ]
    ]
  where
  route = ProjectRoute project.slug Overview

languageBar :: forall w. Project -> HH.HTML w Action
languageBar project =
  HH.div
    [ HP.class_ (HH.ClassName "forge-language-bar")
    , HP.attr (HH.AttrName "aria-label") "Primary repository language"
    ]
    (map segment project.languages)
  where
  segment language =
    HH.i
      [ HP.style ("width:" <> show language.percent <> "%;background:" <> language.color)
      , HP.title language.name
      ]
      []

renderProject :: forall w. State -> Project -> ProjectTab -> HH.HTML w Action
renderProject state project tab =
  HH.div [ HP.class_ (HH.ClassName (if tab == Source then "forge-project-page is-source" else "forge-project-page")) ]
    [ HH.div [ HP.class_ (HH.ClassName "forge-crumb") ]
        [ Nav.breadcrumbs
            [ { label: "Forge", href: Just "#/" }
            , { label: project.name, href: Nothing }
            ]
        ]
    , HH.header [ HP.class_ (HH.ClassName "forge-project-head") ]
        [ HH.h1_
            [ HH.text project.name
            , HH.span [ HP.class_ (HH.ClassName "forge-owner") ] [ HH.text ("/ " <> project.owner) ]
            ]
        , HH.p [ HP.class_ (HH.ClassName "forge-project-sub") ] [ HH.text project.blurb ]
        , HH.div [ HP.class_ (HH.ClassName "forge-meta-row") ]
            [ HH.span [ HP.class_ (HH.ClassName "forge-live-dot"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "●" ]
            , HH.b_ [ HH.text (fromMaybe "Source" (map _.name (Array.head project.languages))) ]
            , HH.span_ [ HH.text project.defaultBranch ]
            , HH.span_ [ HH.text ("updated " <> project.updated) ]
            , HH.a
                [ HP.href project.htmlUrl
                , HP.target "_blank"
                , HP.rel "noreferrer"
                , HP.class_ (HH.ClassName "forge-upstream")
                ]
                [ HH.text "Open in Forgejo ↗" ]
            ]
        ]
    , Nav.tabs "Repository sections"
        [ projectTab Overview "Overview" Nothing tab
        , projectTab Source "Source" (sourceCount state project) tab
        , projectTab Papers "Papers" (Just (Array.length project.publications)) tab
        ]
    , HH.div
        [ HP.class_ (HH.ClassName "forge-tab-panel")
        , HP.attr (HH.AttrName "role") "tabpanel"
        ]
        [ case tab of
            Overview -> renderOverview state project
            Source -> renderSource state project
            Papers -> renderPapers project
        ]
    ]
  where
  projectTab value label count active =
    { label
    , count
    , active: value == active
    , attrs: [ HE.onClick (const (SelectTab value)) ]
    }

sourceCount :: State -> Project -> Maybe Int
sourceCount state project
  | state.sourceRepository /= Just project.slug = Nothing
  | otherwise = case state.tree of
      Success listing -> Just (Array.length listing.files)
      _ -> Nothing

renderOverview :: forall w. State -> Project -> HH.HTML w Action
renderOverview state project =
  HH.div [ HP.class_ (HH.ClassName "forge-overview") ]
    [ HH.article [ HP.class_ (HH.ClassName "forge-readme") ] (map renderBlock project.readme)
    , HH.aside [ HP.class_ (HH.ClassName "forge-sidebar"), HP.attr (HH.AttrName "aria-label") "Repository details" ]
        [ HH.div [ HP.class_ (HH.ClassName "forge-side-block forge-clone-block") ] [ renderClone state project ]
        , sideBlock "Languages"
            [ HH.div [ HP.class_ (HH.ClassName "forge-language-list") ] (map renderLanguage project.languages) ]
        , sideBlock "Repository"
            [ signal "Branch" project.defaultBranch
            , signal "Size" (show project.sizeKiB <> " KiB")
            , signal "Open issues" (show project.openIssues)
            , signal "Archived" (if project.archived then "Yes" else "No")
            ]
        , sideBlock "License" [ HH.p [ HP.class_ (HH.ClassName "forge-license") ] [ HH.text project.license ] ]
        , if Array.null project.publications then HH.text ""
          else sideBlock "Reading"
            [ HH.p [ HP.class_ (HH.ClassName "forge-license") ]
                [ HH.text (show (Array.length project.publications) <> " linked publications — open the Papers tab.") ]
            ]
        ]
    ]
  where
  renderLanguage language =
    HH.div [ HP.class_ (HH.ClassName "forge-language-row") ]
      [ HH.span [ HP.class_ (HH.ClassName "forge-language-dot"), HP.style ("background:" <> language.color) ] []
      , HH.text language.name
      , HH.span [ HP.class_ (HH.ClassName "forge-language-percent") ] [ HH.text "primary" ]
      ]
  signal label value =
    HH.div [ HP.class_ (HH.ClassName "forge-signal") ] [ HH.span_ [ HH.text label ], HH.b_ [ HH.text value ] ]

sideBlock :: forall w. String -> Array (HH.HTML w Action) -> HH.HTML w Action
sideBlock label children =
  HH.div [ HP.class_ (HH.ClassName "forge-side-block") ]
    ([ HH.div [ HP.class_ (HH.ClassName "forge-side-label") ] [ HH.text label ] ] <> children)

renderClone :: forall w. State -> Project -> HH.HTML w Action
renderClone state project =
  HH.div [ HP.class_ (HH.ClassName "forge-clone") ]
    [ HH.div [ HP.class_ (HH.ClassName "forge-clone-head") ]
        [ HH.span [ HP.class_ (HH.ClassName "forge-clone-label") ] [ HH.text "Clone" ]
        , HH.div [ HP.class_ (HH.ClassName "forge-clone-tabs"), HP.attr (HH.AttrName "role") "group", HP.attr (HH.AttrName "aria-label") "Clone protocol" ]
            [ protocolButton OrbCli "GIT CLI"
            , protocolButton Https "HTTPS"
            , protocolButton Ssh "SSH"
            ]
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-clone-body") ]
        [ HH.code_ [ HH.text (cloneCommand state.cloneProtocol project) ]
        , HH.button
            [ HP.type_ HP.ButtonButton
            , HP.class_ (HH.ClassName (if state.copied then "forge-copy is-done" else "forge-copy"))
            , HE.onClick (const CopyClone)
            ]
            [ HH.text (if state.copied then "Copied" else "Copy") ]
        ]
    ]
  where
  protocolButton protocol label =
    HH.button
      [ HP.type_ HP.ButtonButton
      , HP.attr (HH.AttrName "data-state") (if state.cloneProtocol == protocol then "active" else "inactive")
      , HE.onClick (const (SelectProtocol protocol))
      ]
      [ HH.text label ]

renderBlock :: forall w. ReadmeBlock -> HH.HTML w Action
renderBlock = case _ of
  Heading2 value -> HH.h2_ [ HH.text value ]
  Heading3 value -> HH.h3_ [ HH.text value ]
  Paragraph value -> HH.p_ [ HH.text value ]
  BulletList values -> HH.ul [ HP.class_ (HH.ClassName "forge-bullet-list") ] (map (\value -> HH.li_ [ HH.text value ]) values)
  CodeBlock language value ->
    HH.pre
      [ HP.class_ (HH.ClassName "forge-code-block")
      , HP.attr (HH.AttrName "data-language") language
      ]
      [ HH.code_ [ HH.text value ] ]
  Note value -> HH.aside [ HP.class_ (HH.ClassName "forge-note") ] [ HH.text value ]

renderSource :: forall w. State -> Project -> HH.HTML w Action
renderSource state project
  | state.sourceRepository /= Just project.slug = renderLoading "Reading repository tree"
  | otherwise = case state.tree of
      NotAsked -> renderLoading "Reading repository tree"
      Loading -> renderLoading "Reading repository tree"
      Failure error -> renderFailure "Could not read repository source" error RetrySource
      Success listing
        | Array.null listing.files -> renderFailure "No readable source" "Forgejo returned no text files for this branch." RetrySource
        | otherwise ->
            HH.div [ HP.class_ (HH.ClassName "forge-source") ]
              [ HH.nav [ HP.class_ (HH.ClassName "forge-tree"), HP.attr (HH.AttrName "aria-label") "Repository files" ]
                  ( (if listing.truncated then
                        [ HH.div [ HP.class_ (HH.ClassName "forge-tree-note") ]
                            [ HH.text ("Showing " <> show (Array.length listing.files) <> " text files from " <> show listing.totalCount <> " entries") ]
                        ]
                     else [])
                      <> Array.mapWithIndex (renderFileItem state listing.files) listing.files
                  )
              , HH.div [ HP.class_ (HH.ClassName "forge-viewer") ] [ renderViewer state.source ]
              ]

renderViewer :: forall w. RemoteData String SourceFile -> HH.HTML w Action
renderViewer = case _ of
  NotAsked -> viewer { path: "source", language: "text", code: "Select a source file." }
  Loading -> viewer { path: "loading", language: "text", code: "Reading source from Forgejo…" }
  Failure error -> viewer { path: "unavailable", language: "text", code: "Could not read this file.\n\n" <> error }
  Success source -> viewer source
  where
  viewer source =
    codeViewer
      ( defaultCodeViewer
          { path = source.path
          , language = source.language
          , code = source.code
          , class_ = "forge-code-viewer"
          }
      )

renderFileItem :: forall w. State -> Array Forgejo.SourceEntry -> Int -> Forgejo.SourceEntry -> HH.HTML w Action
renderFileItem state files index file =
  HH.div_
    ( directoryHeading <>
        [ HH.button
            [ HP.type_ HP.ButtonButton
            , HP.class_ (HH.ClassName "forge-file")
            , HP.attr (HH.AttrName "data-state") (if state.selectedFile == index then "active" else "inactive")
            , HE.onClick (const (SelectFile index))
            ]
            [ HH.span [ HP.class_ (HH.ClassName "forge-file-icon"), HP.attr (HH.AttrName "aria-hidden") "true" ] []
            , HH.span_ [ HH.text (pathBase file.path) ]
            ]
        ]
    )
  where
  directory = pathDirectory file.path
  previousDirectory = case files Array.!! (index - 1) of
    Nothing -> ""
    Just previous -> pathDirectory previous.path
  directoryHeading =
    if directory == "" || directory == previousDirectory then []
    else [ HH.div [ HP.class_ (HH.ClassName "forge-directory") ] [ HH.text (directory <> "/") ] ]

renderPapers :: forall w. Project -> HH.HTML w Action
renderPapers project
  | Array.null project.publications =
      HH.div [ HP.class_ (HH.ClassName "forge-empty") ]
        [ HH.span [ HP.class_ (HH.ClassName "forge-empty-mark") ] [ HH.text "//" ]
        , HH.h2_ [ HH.text "No linked papers yet." ]
        , HH.p_ [ HH.text "The join is live; this repository has not published into it." ]
        ]
  | otherwise = HH.div [ HP.class_ (HH.ClassName "forge-publications") ] (map renderPublication project.publications)

renderPublication :: forall w. Publication -> HH.HTML w Action
renderPublication publication =
  HH.a [ HP.href publication.href, HP.class_ (HH.ClassName "forge-publication") ]
    [ HH.span [ HP.class_ (HH.ClassName "forge-publication-date") ] [ HH.text publication.date ]
    , HH.div_
        [ HH.span [ HP.class_ (HH.ClassName "forge-publication-kind") ] [ HH.text publication.kind ]
        , HH.h3_ [ HH.text publication.title ]
        , HH.p_ [ HH.text publication.excerpt ]
        ]
    , HH.span [ HP.class_ (HH.ClassName "forge-publication-arrow"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "→" ]
    ]

renderLoading :: forall w. String -> HH.HTML w Action
renderLoading label =
  HH.div
    [ HP.class_ (HH.ClassName "forge-remote-state")
    , HP.attr (HH.AttrName "role") "status"
    ]
    [ HH.span [ HP.class_ (HH.ClassName "forge-loader"), HP.attr (HH.AttrName "aria-hidden") "true" ] []
    , HH.p_ [ HH.text label ]
    ]

renderFailure :: forall w. String -> String -> Action -> HH.HTML w Action
renderFailure title error retry =
  HH.div [ HP.class_ (HH.ClassName "forge-remote-state is-error"), HP.attr (HH.AttrName "role") "alert" ]
    [ HH.span [ HP.class_ (HH.ClassName "forge-empty-mark"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "//" ]
    , HH.h2_ [ HH.text title ]
    , HH.p_ [ HH.text error ]
    , HH.button [ HP.type_ HP.ButtonButton, HE.onClick (const retry) ] [ HH.text "Retry" ]
    ]

renderMissing :: forall w. String -> HH.HTML w Action
renderMissing slug =
  HH.div [ HP.class_ (HH.ClassName "forge-remote-state") ]
    [ HH.span [ HP.class_ (HH.ClassName "forge-empty-mark"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "404" ]
    , HH.h2_ [ HH.text "Repository not found" ]
    , HH.p_ [ HH.text ("straylight/" <> slug <> " is not in the public Forgejo index.") ]
    , HH.a [ HP.href "#/" ] [ HH.text "Return to Forge →" ]
    ]

statusLeft :: forall w. State -> Array (HH.HTML w Action)
statusLeft state = case projectForRoute state state.route of
  Just project ->
    [ HH.span [ HP.class_ (HH.ClassName "forge-status-dot"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "●" ]
    , HH.span_ [ HH.b_ [ HH.text project.name ], HH.text (" / " <> project.owner) ]
    ]
  Nothing ->
    [ HH.span [ HP.class_ (HH.ClassName (if repositoriesConnected state.repositories then "forge-status-dot" else "forge-status-dot is-offline")), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "●" ]
    , HH.span_ [ HH.text (if repositoriesConnected state.repositories then "Forgejo / connected" else "Forgejo / connecting") ]
    ]

statusRight :: forall w. State -> Array (HH.HTML w Action)
statusRight state = case projectForRoute state state.route of
  Just project ->
    [ HH.span [ HP.class_ (HH.ClassName "forge-status-optional") ] [ HH.text project.defaultBranch ]
    , HH.span_ [ HH.text (show project.sizeKiB <> " KiB · " <> show project.openIssues <> " open issues") ]
    ]
  Nothing -> case state.repositories of
    Success projects -> [ HH.span_ [ HH.text (show (Array.length projects) <> " repositories") ], HH.span_ [ HH.text "© 2026" ] ]
    Failure _ -> [ HH.span_ [ HH.text "Forgejo unavailable" ] ]
    _ -> [ HH.span_ [ HH.text "Loading repositories" ] ]

repositoriesConnected :: RemoteData String (Array Project) -> Boolean
repositoriesConnected (Success _) = true
repositoriesConnected _ = false

connectionHelp :: String -> String
connectionHelp error =
  "Connect this browser to the S4 tailnet and allow Local Network Access for Orbital Forge, then retry. " <> error

projectForRoute :: State -> Route -> Maybe Project
projectForRoute state = case _ of
  ForgeHome -> Nothing
  ProjectRoute slug _ -> projectForSlug state slug

projectForSlug :: State -> String -> Maybe Project
projectForSlug state slug = case state.repositories of
  Success projects -> Array.find (\project -> project.slug == slug) projects
  _ -> Nothing

cloneCommand :: CloneProtocol -> Project -> String
cloneCommand protocol project = case protocol of
  OrbCli -> project.clone.cli
  Https -> project.clone.https
  Ssh -> project.clone.ssh

routeHash :: Route -> String
routeHash = case _ of
  ForgeHome -> "#/"
  ProjectRoute slug Overview -> "#/p/" <> slug
  ProjectRoute slug Source -> "#/p/" <> slug <> "/source"
  ProjectRoute slug Papers -> "#/p/" <> slug <> "/papers"

parseHash :: String -> Route
parseHash hash = fromMaybe ForgeHome do
  rest <- String.stripPrefix (Pattern "#/p/") hash
  let parts = String.split (Pattern "/") rest
  slug <- parts Array.!! 0
  if slug == "" then Nothing
  else
    let
      tab = case parts Array.!! 1 of
        Just "source" -> Source
        Just "papers" -> Papers
        _ -> Overview
    in
      Just (ProjectRoute slug tab)

isSourceRoute :: Route -> Boolean
isSourceRoute (ProjectRoute _ Source) = true
isSourceRoute _ = false

pathParts :: String -> Array String
pathParts = String.split (Pattern "/")

pathBase :: String -> String
pathBase path = case Array.unsnoc (pathParts path) of
  Nothing -> path
  Just parts -> parts.last

pathDirectory :: String -> String
pathDirectory path = case Array.unsnoc (pathParts path) of
  Nothing -> ""
  Just parts -> String.joinWith "/" parts.init
