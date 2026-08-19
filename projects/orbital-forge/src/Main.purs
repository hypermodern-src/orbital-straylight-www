module Main where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.CodeUnits as SCU
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Forge.Data (Project, Publication, fromRepository, languageColor, sourceLanguage)
import Forge.Forgejo as Forgejo
import Forge.Markdown (MarkdownBlock(..), parseMarkdown)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Halogen.VDom.Driver (runUI)
import Hydrogen.Data.Format (formatBytes)
import Hydrogen.Data.RemoteData (RemoteData(..))
import Hydrogen.Orbital.Brand (defaultBrandmark, brandmark)
import Hydrogen.Orbital.Code (defaultCodeViewer, codeViewer)
import Hydrogen.Orbital.Navigation as Nav
import Hydrogen.Orbital.Shell (defaultAppShell, appShell)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.Event.Event (EventType(..))
import Web.File.Url as FileURL
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window

foreign import currentHash :: Effect String
foreign import setHash :: String -> Effect Unit
foreign import currentTheme :: Effect Boolean
foreign import applyTheme :: Boolean -> Effect Unit
foreign import copyText :: String -> Effect Unit
foreign import currentUrl :: Effect String

data RepoView
  = CodeView String String
  | BlobView String String
  | CommitsView String
  | CommitView String String
  | FileHistoryView String String
  | RefsView String
  | SearchView String
  | IssuesView
  | PullsView
  | ReleasesView
  | PapersView

derive instance eqRepoView :: Eq RepoView

data Route = ForgeHome | RepoRoute String RepoView

derive instance eqRoute :: Eq Route

data RepoTab = CodeTab | CommitsTab | IssuesTab | PullsTab | ReleasesTab | PapersTab

derive instance eqRepoTab :: Eq RepoTab

data CloneProtocol = OrbCli | Https | Ssh

derive instance eqCloneProtocol :: Eq CloneProtocol

data BlobKind
  = SourceBlob
  | MarkdownBlob
  | SvgBlob
  | ImageBlob
  | PdfBlob
  | AudioBlob
  | VideoBlob

derive instance eqBlobKind :: Eq BlobKind

type Readme =
  { path :: String
  , source :: String
  }

type SourceFile =
  { path :: String
  , language :: String
  , code :: String
  }

type State =
  { route :: Route
  , repositories :: RemoteData String (Array Project)
  , repositoryContext :: Maybe String
  , branches :: RemoteData String (Array Forgejo.Branch)
  , tags :: RemoteData String (Array Forgejo.Tag)
  , languages :: RemoteData String (Array Forgejo.LanguageStat)
  , contents :: RemoteData String (Array Forgejo.ContentEntry)
  , latestCommit :: RemoteData String (Maybe Forgejo.Commit)
  , readme :: RemoteData String (Maybe Readme)
  , source :: RemoteData String SourceFile
  , assetUrl :: RemoteData String String
  , commits :: RemoteData String (Array Forgejo.Commit)
  , commitDetail :: RemoteData String Forgejo.CommitDetail
  , commitDiff :: RemoteData String String
  , searchIndex :: RemoteData String Forgejo.TreeListing
  , searchQuery :: String
  , issues :: RemoteData String (Array Forgejo.Issue)
  , pulls :: RemoteData String (Array Forgejo.PullRequest)
  , releases :: RemoteData String (Array Forgejo.Release)
  , cloneProtocol :: CloneProtocol
  , copied :: Boolean
  , copiedLink :: Boolean
  , blobPreview :: Boolean
  , dark :: Boolean
  }

data Action
  = Initialize
  | HashChanged
  | Navigate Route
  | SelectTab RepoTab
  | SelectRef String
  | SelectProtocol CloneProtocol
  | CopyClone
  | CopyPermalink
  | SetBlobPreview Boolean
  | UpdateSearch String
  | ToggleTheme
  | RetryRepositories
  | RetryRoute

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
        , repositoryContext: Nothing
        , branches: NotAsked
        , tags: NotAsked
        , languages: NotAsked
        , contents: NotAsked
        , latestCommit: NotAsked
        , readme: NotAsked
        , source: NotAsked
        , assetUrl: NotAsked
        , commits: NotAsked
        , commitDetail: NotAsked
        , commitDiff: NotAsked
        , searchIndex: NotAsked
        , searchQuery: ""
        , issues: NotAsked
        , pulls: NotAsked
        , releases: NotAsked
        , cloneProtocol: OrbCli
        , copied: false
        , copiedLink: false
        , blobPreview: true
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
    releaseAssetUrl
    hash <- liftEffect currentHash
    let route = parseHash hash
    H.modify_ _ { route = route, copied = false, copiedLink = false, blobPreview = true }
    loadRoute route
  Navigate route -> do
    releaseAssetUrl
    H.modify_ _ { route = route, copied = false, copiedLink = false, blobPreview = true }
    liftEffect $ setHash (routeHash route)
  SelectTab tab -> do
    state <- H.get
    case projectForRoute state state.route of
      Nothing -> pure unit
      Just project -> handleAction $ Navigate $ RepoRoute project.slug case tab of
        CodeTab -> CodeView (activeRef project state.route) ""
        CommitsTab -> CommitsView (activeRef project state.route)
        IssuesTab -> IssuesView
        PullsTab -> PullsView
        ReleasesTab -> ReleasesView
        PapersTab -> PapersView
  SelectRef ref -> do
    state <- H.get
    case state.route of
      RepoRoute slug (CodeView _ path) -> handleAction (Navigate (RepoRoute slug (CodeView ref path)))
      RepoRoute slug (BlobView _ path) -> handleAction (Navigate (RepoRoute slug (BlobView ref path)))
      RepoRoute slug (CommitsView _) -> handleAction (Navigate (RepoRoute slug (CommitsView ref)))
      RepoRoute slug (FileHistoryView _ path) -> handleAction (Navigate (RepoRoute slug (FileHistoryView ref path)))
      RepoRoute slug (RefsView _) -> handleAction (Navigate (RepoRoute slug (RefsView ref)))
      RepoRoute slug (SearchView _) -> handleAction (Navigate (RepoRoute slug (SearchView ref)))
      _ -> pure unit
  SelectProtocol protocol -> H.modify_ _ { cloneProtocol = protocol, copied = false }
  CopyClone -> do
    state <- H.get
    case projectForRoute state state.route of
      Nothing -> pure unit
      Just project -> do
        liftEffect $ copyText (cloneCommand state.cloneProtocol project)
        H.modify_ _ { copied = true }
  CopyPermalink -> do
    state <- H.get
    url <- liftEffect currentUrl
    liftEffect $ copyText (permalinkUrl state url)
    H.modify_ _ { copiedLink = true }
  SetBlobPreview preview -> H.modify_ _ { blobPreview = preview }
  UpdateSearch query -> H.modify_ _ { searchQuery = query }
  ToggleTheme -> do
    state <- H.get
    let dark = not state.dark
    liftEffect $ applyTheme dark
    H.modify_ _ { dark = dark }
  RetryRepositories -> loadRepositories
  RetryRoute -> do
    state <- H.get
    loadRoute state.route

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
  ForgeHome -> pure unit
  route@(RepoRoute slug view) -> do
    state <- H.get
    case projectForSlug state slug of
      Nothing -> pure unit
      Just project -> do
        when (state.repositoryContext /= Just slug) (loadRepositoryChrome project)
        case view of
          CodeView requestedRef path -> loadDirectory project (resolveRef project requestedRef) path
          BlobView requestedRef path -> loadBlob project (resolveRef project requestedRef) path
          CommitsView requestedRef -> loadCommitHistory project (resolveRef project requestedRef)
          CommitView _ sha -> loadCommitDetail project sha
          FileHistoryView requestedRef path -> loadFileHistory project (resolveRef project requestedRef) path
          RefsView _ -> pure unit
          SearchView requestedRef -> loadSearchIndex project (resolveRef project requestedRef)
          IssuesView -> loadIssues project
          PullsView -> loadPulls project
          ReleasesView -> loadReleases project
          PapersView -> pure unit
        final <- H.get
        when (final.route /= route) (pure unit)

loadRepositoryChrome :: forall o. Project -> H.HalogenM State Action () o Aff Unit
loadRepositoryChrome project = do
  H.modify_ _
    { repositoryContext = Just project.slug
    , branches = Loading
    , tags = Loading
    , languages = Loading
    , contents = NotAsked
    , latestCommit = NotAsked
    , readme = NotAsked
    , source = NotAsked
    , assetUrl = NotAsked
    , commits = NotAsked
    , commitDetail = NotAsked
    , commitDiff = NotAsked
    , searchIndex = NotAsked
    , searchQuery = ""
    , issues = NotAsked
    , pulls = NotAsked
    , releases = NotAsked
    }
  branchResult <- H.liftAff $ Forgejo.listBranches project.repository
  H.modify_ _ { branches = eitherRemote branchResult }
  tagResult <- H.liftAff $ Forgejo.listTags project.repository
  H.modify_ _ { tags = eitherRemote tagResult }
  languageResult <- H.liftAff $ Forgejo.listLanguages project.repository
  H.modify_ _ { languages = eitherRemote languageResult }

loadDirectory :: forall o. Project -> String -> String -> H.HalogenM State Action () o Aff Unit
loadDirectory project ref path = do
  H.modify_ _
    { contents = Loading
    , latestCommit = Loading
    , readme = NotAsked
    , source = NotAsked
    }
  result <- H.liftAff $ Forgejo.listContents project.repository ref path
  case result of
    Left error -> H.modify_ _ { contents = Failure error, latestCommit = NotAsked, readme = NotAsked }
    Right entries -> do
      let sorted = Array.sortBy entryOrder entries
      H.modify_ _ { contents = Success sorted }
      commitResult <- H.liftAff $ Forgejo.listCommits project.repository ref path
      H.modify_ _ { latestCommit = map Array.head (eitherRemote commitResult) }
      case Array.find isReadme sorted of
        Nothing -> H.modify_ _ { readme = Success Nothing }
        Just entry -> do
          H.modify_ _ { readme = Loading }
          readmeResult <- H.liftAff $ Forgejo.readRaw project.repository ref entry.path
          H.modify_ _ { readme = case readmeResult of
            Left error -> Failure error
            Right source -> Success (Just { path: entry.path, source })
          }

loadBlob :: forall o. Project -> String -> String -> H.HalogenM State Action () o Aff Unit
loadBlob project ref path = do
  let kind = blobKind path
  H.modify_ _
    { source = if blobHasSource kind then Loading else NotAsked
    , assetUrl = if kind == PdfBlob then Loading else NotAsked
    , latestCommit = Loading
    , contents = NotAsked
    , readme = NotAsked
    , blobPreview = true
    }
  when (blobHasSource kind) do
    result <- H.liftAff $ Forgejo.readRaw project.repository ref path
    H.modify_ _ { source = case result of
      Left error -> Failure error
      Right code -> Success { path, language: sourceLanguage path, code }
    }
  when (kind == PdfBlob) do
    result <- H.liftAff $ Forgejo.readBlobUrl project.repository ref path
    H.modify_ _ { assetUrl = eitherRemote result }
  commitResult <- H.liftAff $ Forgejo.listCommits project.repository ref path
  H.modify_ _ { latestCommit = map Array.head (eitherRemote commitResult) }

loadCommitHistory :: forall o. Project -> String -> H.HalogenM State Action () o Aff Unit
loadCommitHistory project ref = do
  H.modify_ _ { commits = Loading }
  result <- H.liftAff $ Forgejo.listCommits project.repository ref ""
  H.modify_ _ { commits = eitherRemote result }

loadFileHistory :: forall o. Project -> String -> String -> H.HalogenM State Action () o Aff Unit
loadFileHistory project ref path = do
  H.modify_ _ { commits = Loading }
  result <- H.liftAff $ Forgejo.listCommits project.repository ref path
  H.modify_ _ { commits = eitherRemote result }

loadCommitDetail :: forall o. Project -> String -> H.HalogenM State Action () o Aff Unit
loadCommitDetail project sha = do
  H.modify_ _ { commitDetail = Loading, commitDiff = Loading }
  detailResult <- H.liftAff $ Forgejo.readCommit project.repository sha
  H.modify_ _ { commitDetail = eitherRemote detailResult }
  diffResult <- H.liftAff $ Forgejo.readCommitDiff project.repository sha
  H.modify_ _ { commitDiff = eitherRemote diffResult }

loadSearchIndex :: forall o. Project -> String -> H.HalogenM State Action () o Aff Unit
loadSearchIndex project ref = do
  H.modify_ _ { searchIndex = Loading }
  result <- H.liftAff $ Forgejo.listTree project.repository ref
  H.modify_ _ { searchIndex = eitherRemote result }

loadIssues :: forall o. Project -> H.HalogenM State Action () o Aff Unit
loadIssues project = do
  H.modify_ _ { issues = Loading }
  result <- H.liftAff $ Forgejo.listIssues project.repository
  H.modify_ _ { issues = eitherRemote result }

loadPulls :: forall o. Project -> H.HalogenM State Action () o Aff Unit
loadPulls project = do
  H.modify_ _ { pulls = Loading }
  result <- H.liftAff $ Forgejo.listPullRequests project.repository
  H.modify_ _ { pulls = eitherRemote result }

loadReleases :: forall o. Project -> H.HalogenM State Action () o Aff Unit
loadReleases project = do
  H.modify_ _ { releases = Loading }
  result <- H.liftAff $ Forgejo.listReleases project.repository
  H.modify_ _ { releases = eitherRemote result }

eitherRemote :: forall a. Either String a -> RemoteData String a
eitherRemote = case _ of
  Left error -> Failure error
  Right value -> Success value

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  appShell
    ( defaultAppShell
        { header = [ renderNav state ]
        , main =
            [ HH.div
                [ HP.class_ (HH.ClassName (if isBlobRoute state.route then "forge-scroll is-source" else "forge-scroll")) ]
                [ HH.div [ HP.class_ (HH.ClassName "forge-wrap") ] [ renderRoute state ] ]
            ]
        , statusLeft = statusLeft state
        , statusRight = statusRight state
        , sourceMode = isBlobRoute state.route
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
  RepoRoute slug view -> case projectForSlug state slug of
    Just project -> renderProject state project view
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
        , HH.p_ [ HH.text "The Straylight Forgejo surface: repositories, source, history, collaboration, releases, and the technical writing attached to the work." ]
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
    , metric (show (foldl (\count project -> count + project.openPulls) 0 projects)) "Open pulls"
    , metric (show (foldl (\count project -> count + project.releaseCount) 0 projects)) "Releases"
    ]
  _ -> map (\label -> metric "—" label) [ "Repositories", "Open issues", "Open pulls", "Releases" ]
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
            [ HH.text (show project.openIssues <> " issues · " <> show project.openPulls <> " pulls · " <> show project.releaseCount <> " releases") ]
        ]
    , HH.span [ HP.class_ (HH.ClassName "forge-project-arrow"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "→" ]
    ]
  where
  route = RepoRoute project.slug (CodeView "" "")

languageBar :: forall w. Project -> HH.HTML w Action
languageBar project =
  HH.div
    [ HP.class_ (HH.ClassName "forge-language-bar")
    , HP.attr (HH.AttrName "aria-label") "Primary repository language"
    ]
    (map segment project.languages)
  where
  segment language = HH.i [ HP.style ("width:" <> show language.percent <> "%;background:" <> language.color), HP.title language.name ] []

renderProject :: forall w. State -> Project -> RepoView -> HH.HTML w Action
renderProject state project view =
  HH.div [ HP.class_ (HH.ClassName (if isBlob view then "forge-project-page is-source" else "forge-project-page")) ]
    [ HH.div [ HP.class_ (HH.ClassName "forge-crumb") ]
        [ Nav.breadcrumbs
            [ { label: "Forge", href: Just "#/" }
            , { label: project.owner, href: Nothing }
            , { label: project.name, href: Nothing }
            ]
        ]
    , HH.header [ HP.class_ (HH.ClassName "forge-project-head") ]
        [ HH.h1_
            [ HH.text project.name
            , if project.archived then HH.span [ HP.class_ (HH.ClassName "forge-archive") ] [ HH.text "Archived" ] else HH.text ""
            ]
        , HH.p [ HP.class_ (HH.ClassName "forge-project-sub") ] [ HH.text project.blurb ]
        , HH.div [ HP.class_ (HH.ClassName "forge-meta-row") ]
            [ HH.span [ HP.class_ (HH.ClassName "forge-live-dot"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "●" ]
            , HH.b_ [ HH.text (project.owner <> " / " <> project.name) ]
            , HH.span_ [ HH.text (show project.watchers <> " watching") ]
            , HH.span_ [ HH.text (show project.stars <> " stars") ]
            , HH.span_ [ HH.text (show project.forks <> " forks") ]
            , HH.a [ HP.href project.htmlUrl, HP.target "_blank", HP.rel "noreferrer", HP.class_ (HH.ClassName "forge-upstream") ] [ HH.text "Open in Forgejo ↗" ]
            ]
        ]
    , Nav.tabs "Repository sections"
        [ repoTab CodeTab "Code" Nothing (activeTab view)
        , repoTab CommitsTab "Commits" Nothing (activeTab view)
        , repoTab IssuesTab "Issues" (Just project.openIssues) (activeTab view)
        , repoTab PullsTab "Pull requests" (Just project.openPulls) (activeTab view)
        , repoTab ReleasesTab "Releases" (Just project.releaseCount) (activeTab view)
        , repoTab PapersTab "Papers" (Just (Array.length project.publications)) (activeTab view)
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-tab-panel"), HP.attr (HH.AttrName "role") "tabpanel" ]
        [ case view of
            CodeView requestedRef path -> renderDirectory state project (resolveRef project requestedRef) path
            BlobView requestedRef path -> renderBlob state project (resolveRef project requestedRef) path
            CommitsView requestedRef -> renderCommits state project (resolveRef project requestedRef)
            CommitView requestedRef sha -> renderCommitDetail state project (resolveRef project requestedRef) sha
            FileHistoryView requestedRef path -> renderFileHistory state project (resolveRef project requestedRef) path
            RefsView requestedRef -> renderRefs state project (resolveRef project requestedRef)
            SearchView requestedRef -> renderSearch state project (resolveRef project requestedRef)
            IssuesView -> renderIssues state project
            PullsView -> renderPulls state project
            ReleasesView -> renderReleases state project
            PapersView -> renderPapers project
        ]
    ]
  where
  repoTab value label count active = { label, count, active: value == active, attrs: [ HE.onClick (const (SelectTab value)) ] }

renderRepoToolbar :: forall w. State -> Project -> String -> HH.HTML w Action
renderRepoToolbar state project ref =
  HH.div [ HP.class_ (HH.ClassName "forge-repo-toolbar") ]
    [ HH.div [ HP.class_ (HH.ClassName "forge-ref-control") ]
        [ HH.span [ HP.class_ (HH.ClassName "forge-ref-icon"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "⑂" ]
        , HH.select
            [ HP.attr (HH.AttrName "aria-label") "Branch or tag"
            , HP.value ref
            , HE.onValueChange SelectRef
            ]
            (refOptions state project ref)
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-ref-counts") ]
        [ internalLink (RepoRoute project.slug (RefsView ref)) [ HH.b_ [ HH.text (remoteLength state.branches) ], HH.text " branches" ]
        , internalLink (RepoRoute project.slug (RefsView ref)) [ HH.b_ [ HH.text (remoteLength state.tags) ], HH.text " tags" ]
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-toolbar-spacer") ] []
    , internalLinkClass "forge-small-button" (RepoRoute project.slug (SearchView ref)) [ HH.text "Go to file /" ]
    , HH.a [ HP.href project.htmlUrl, HP.target "_blank", HP.rel "noreferrer", HP.class_ (HH.ClassName "forge-small-button") ] [ HH.text "Forgejo ↗" ]
    ]

refOptions :: forall w. State -> Project -> String -> Array (HH.HTML w Action)
refOptions state project ref = detachedOption <> branchOptions <> tagOptions
  where
  detachedOption
    | knownRef = []
    | otherwise =
        [ HH.option [ HP.value ref, HP.selected true ]
            [ HH.text (if ref == "" then project.defaultBranch else String.take 12 ref) ]
        ]
  knownRef = branchKnown || tagKnown
  branchKnown = case state.branches of
    Success branches -> Array.any (\branch -> branch.name == ref) branches
    _ -> false
  tagKnown = case state.tags of
    Success tags -> Array.any (\tag -> tag.name == ref) tags
    _ -> false
  branchOptions = case state.branches of
    Success branches ->
      [ HH.optgroup [ HP.attr (HH.AttrName "label") "Branches" ]
          (map (\branch -> HH.option [ HP.value branch.name, HP.selected (branch.name == ref) ] [ HH.text branch.name ]) branches)
      ]
    _ -> []
  tagOptions = case state.tags of
    Success tags | not (Array.null tags) ->
      [ HH.optgroup [ HP.attr (HH.AttrName "label") "Tags" ]
          (map (\tag -> HH.option [ HP.value tag.name, HP.selected (tag.name == ref) ] [ HH.text tag.name ]) tags)
      ]
    _ -> []

renderDirectory :: forall w. State -> Project -> String -> String -> HH.HTML w Action
renderDirectory state project ref path =
  HH.div [ HP.class_ (HH.ClassName "forge-code-page") ]
    [ renderRepoToolbar state project ref
    , renderPathCrumbs project ref path false
    , case state.contents of
        NotAsked -> renderLoading "Reading repository"
        Loading -> renderLoading "Reading repository"
        Failure error -> renderFailure "Could not read this directory" error RetryRoute
        Success entries ->
          HH.div_
            [ renderLatestCommit project ref state.latestCommit
            , HH.nav [ HP.class_ (HH.ClassName "forge-content-table"), HP.attr (HH.AttrName "aria-label") "Repository contents" ]
                (parentEntry project ref path <> map (renderContentEntry project ref) entries)
            ]
    , renderClone state project
    , if path == "" then renderLanguages state.languages else HH.text ""
    , renderReadme state.readme
    ]

renderPathCrumbs :: forall w. Project -> String -> String -> Boolean -> HH.HTML w Action
renderPathCrumbs project ref path blob =
  HH.nav [ HP.class_ (HH.ClassName "forge-path"), HP.attr (HH.AttrName "aria-label") "Source path" ]
    ( [ HH.a [ HP.href (routeHash (RepoRoute project.slug (CodeView ref ""))), HE.onClick (const (Navigate (RepoRoute project.slug (CodeView ref "")))) ] [ HH.text project.name ] ]
        <> Array.concat (Array.mapWithIndex crumb (pathParts path))
    )
  where
  crumb index part =
    let
      current = index == Array.length (pathParts path) - 1
      partial = String.joinWith "/" (Array.take (index + 1) (pathParts path))
      route = if current && blob then RepoRoute project.slug (BlobView ref partial) else RepoRoute project.slug (CodeView ref partial)
    in
      [ HH.span [ HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "/" ]
      , if current then HH.span [ HP.class_ (HH.ClassName "is-current") ] [ HH.text part ]
        else HH.a [ HP.href (routeHash route), HE.onClick (const (Navigate route)) ] [ HH.text part ]
      ]

renderLatestCommit :: forall w. Project -> String -> RemoteData String (Maybe Forgejo.Commit) -> HH.HTML w Action
renderLatestCommit project ref = case _ of
  Success (Just commit) ->
    internalLinkClass "forge-latest-commit" (RepoRoute project.slug (CommitView ref commit.sha))
      [ HH.span [ HP.class_ (HH.ClassName "forge-commit-author") ] [ HH.text commit.author ]
      , HH.span [ HP.class_ (HH.ClassName "forge-commit-message") ] [ HH.text commit.message ]
      , HH.code_ [ HH.text commit.shortSha ]
      , HH.span_ [ HH.text (shortDate commit.createdAt) ]
      ]
  Loading -> HH.div [ HP.class_ (HH.ClassName "forge-latest-commit is-loading") ] [ HH.text "Reading latest commit…" ]
  _ -> HH.text ""

parentEntry :: forall w. Project -> String -> String -> Array (HH.HTML w Action)
parentEntry project ref path
  | path == "" = []
  | otherwise =
      let route = RepoRoute project.slug (CodeView ref (parentPath path))
      in [ HH.a [ HP.href (routeHash route), HE.onClick (const (Navigate route)), HP.class_ (HH.ClassName "forge-content-row is-parent") ]
            [ HH.span [ HP.class_ (HH.ClassName "forge-content-icon is-dir"), HP.attr (HH.AttrName "aria-hidden") "true" ] []
            , HH.span [ HP.class_ (HH.ClassName "forge-content-name") ] [ HH.text ".." ]
            , HH.span [ HP.class_ (HH.ClassName "forge-content-meta") ] [ HH.text "Parent directory" ]
            , HH.span [ HP.class_ (HH.ClassName "forge-content-size") ] []
            ]
         ]

renderContentEntry :: forall w. Project -> String -> Forgejo.ContentEntry -> HH.HTML w Action
renderContentEntry project ref entry =
  HH.a
    [ HP.href (routeHash route)
    , HE.onClick (const (Navigate route))
    , HP.class_ (HH.ClassName "forge-content-row")
    ]
    [ HH.span [ HP.class_ (HH.ClassName (if entry.kind == "dir" then "forge-content-icon is-dir" else "forge-content-icon is-file")), HP.attr (HH.AttrName "aria-hidden") "true" ] []
    , HH.span [ HP.class_ (HH.ClassName "forge-content-name") ] [ HH.text entry.name ]
    , HH.span [ HP.class_ (HH.ClassName "forge-content-meta") ] [ HH.text (maybeText "" shortDate entry.lastCommitWhen) ]
    , HH.span [ HP.class_ (HH.ClassName "forge-content-size") ] [ HH.text (if entry.kind == "dir" then "—" else formatBytes (toNumber entry.size)) ]
    ]
  where
  route = if entry.kind == "dir" then RepoRoute project.slug (CodeView ref entry.path) else RepoRoute project.slug (BlobView ref entry.path)

renderClone :: forall w. State -> Project -> HH.HTML w Action
renderClone state project =
  HH.div [ HP.class_ (HH.ClassName "forge-clone") ]
    [ HH.div [ HP.class_ (HH.ClassName "forge-clone-head") ]
        [ HH.span [ HP.class_ (HH.ClassName "forge-clone-label") ] [ HH.text "Clone repository" ]
        , HH.div [ HP.class_ (HH.ClassName "forge-clone-tabs"), HP.attr (HH.AttrName "role") "group", HP.attr (HH.AttrName "aria-label") "Clone protocol" ]
            [ protocolButton OrbCli "GIT CLI", protocolButton Https "HTTPS", protocolButton Ssh "SSH" ]
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-clone-body") ]
        [ HH.code
            [ HP.tabIndex 0
            , HP.attr (HH.AttrName "aria-label") "Clone command"
            ]
            [ HH.text (cloneCommand state.cloneProtocol project) ]
        , HH.button [ HP.type_ HP.ButtonButton, HP.class_ (HH.ClassName (if state.copied then "forge-copy is-done" else "forge-copy")), HE.onClick (const CopyClone) ]
            [ HH.text (if state.copied then "Copied" else "Copy") ]
        ]
    ]
  where
  protocolButton protocol label =
    HH.button [ HP.type_ HP.ButtonButton, HP.attr (HH.AttrName "data-state") (if state.cloneProtocol == protocol then "active" else "inactive"), HE.onClick (const (SelectProtocol protocol)) ] [ HH.text label ]

renderReadme :: forall w. RemoteData String (Maybe Readme) -> HH.HTML w Action
renderReadme = case _ of
  Success (Just readme) ->
    HH.article [ HP.class_ (HH.ClassName "forge-readme forge-repository-readme") ]
      ( [ HH.header
            [ HP.class_ (HH.ClassName "forge-readme-head") ]
            [ HH.span_ [ HH.text "README" ]
            , HH.code_ [ HH.text readme.path ]
            ]
        ]
          <> map renderMarkdownBlock (parseMarkdown readme.source)
      )
  Loading -> HH.div [ HP.class_ (HH.ClassName "forge-readme-loading") ] [ HH.text "Rendering README…" ]
  _ -> HH.text ""

renderLanguages :: forall w. RemoteData String (Array Forgejo.LanguageStat) -> HH.HTML w Action
renderLanguages = case _ of
  Success languages | not (Array.null languages) ->
    let total = foldl (\sum language -> sum + language.bytes) 0 languages
    in HH.section [ HP.class_ (HH.ClassName "forge-language-panel"), HP.attr (HH.AttrName "aria-label") "Repository languages" ]
        [ HH.div [ HP.class_ (HH.ClassName "forge-language-total") ]
            [ HH.span_ [ HH.text "Languages" ]
            , HH.span_ [ HH.text (formatBytes (toNumber total) <> " indexed") ]
            ]
        , HH.div [ HP.class_ (HH.ClassName "forge-language-breakdown") ]
            (map (renderLanguageSegment total) languages)
        , HH.div [ HP.class_ (HH.ClassName "forge-language-legend") ]
            (map (renderLanguageLegend total) languages)
        ]
  _ -> HH.text ""

renderLanguageSegment :: forall w. Int -> Forgejo.LanguageStat -> HH.HTML w Action
renderLanguageSegment total language =
  HH.i
    [ HP.style ("width:" <> show (languagePercent total language.bytes) <> "%;background:" <> languageColor language.name)
    , HP.title (language.name <> " " <> show (languagePercent total language.bytes) <> "%")
    ]
    []

renderLanguageLegend :: forall w. Int -> Forgejo.LanguageStat -> HH.HTML w Action
renderLanguageLegend total language =
  HH.span_
    [ HH.i [ HP.style ("background:" <> languageColor language.name), HP.attr (HH.AttrName "aria-hidden") "true" ] []
    , HH.b_ [ HH.text language.name ]
    , HH.text (show (languagePercent total language.bytes) <> "%")
    ]

languagePercent :: Int -> Int -> Int
languagePercent total bytes
  | total <= 0 = 0
  | otherwise = (bytes * 100) / total

renderMarkdownBlock :: forall w. MarkdownBlock -> HH.HTML w Action
renderMarkdownBlock = case _ of
  Heading level value -> case level of
    1 -> HH.h1_ [ HH.text value ]
    2 -> HH.h2_ [ HH.text value ]
    3 -> HH.h3_ [ HH.text value ]
    _ -> HH.h4_ [ HH.text value ]
  Paragraph value -> HH.p_ [ HH.text value ]
  BulletList values -> HH.ul [ HP.class_ (HH.ClassName "forge-bullet-list") ] (map (\value -> HH.li_ [ HH.text value ]) values)
  OrderedList values -> HH.ol [ HP.class_ (HH.ClassName "forge-ordered-list") ] (map (\value -> HH.li_ [ HH.text value ]) values)
  Quote value -> HH.blockquote_ [ HH.text value ]
  CodeFence language value -> HH.pre
    [ HP.class_ (HH.ClassName "forge-code-block")
    , HP.attr (HH.AttrName "data-language") language
    , HP.attr (HH.AttrName "aria-label") (if language == "" then "Code block" else language <> " code block")
    , HP.tabIndex 0
    ]
    [ HH.code_ [ HH.text value ] ]
  Rule -> HH.hr_

renderBlob :: forall w. State -> Project -> String -> String -> HH.HTML w Action
renderBlob state project ref path =
  let kind = blobKind path
  in
  HH.div [ HP.class_ (HH.ClassName "forge-blob") ]
    [ renderRepoToolbar state project ref
    , renderPathCrumbs project ref path true
    , renderLatestCommit project ref state.latestCommit
    , HH.div [ HP.class_ (HH.ClassName "forge-blob-actions") ]
        [ renderBlobModeSwitch state kind
        , internalLink (RepoRoute project.slug (FileHistoryView ref path)) [ HH.text "History" ]
        , HH.button
            [ HP.type_ HP.ButtonButton
            , HP.class_ (HH.ClassName (if state.copiedLink then "is-done" else ""))
            , HE.onClick (const CopyPermalink)
            ]
            [ HH.text (if state.copiedLink then "Link copied" else "Permalink") ]
        , HH.a [ HP.href (Forgejo.rawUrl project.repository ref path), HP.target "_blank", HP.rel "noreferrer" ] [ HH.text "Raw" ]
        , HH.a [ HP.href (Forgejo.rawUrl project.repository ref path), HP.attr (HH.AttrName "download") (pathBase path) ] [ HH.text "Download" ]
        , HH.a [ HP.href (project.htmlUrl <> "/src/branch/" <> Forgejo.encodeComponent ref <> "/" <> Forgejo.encodePath path), HP.target "_blank", HP.rel "noreferrer" ] [ HH.text "View in Forgejo ↗" ]
        ]
    , renderBlobViewer state project ref path kind
    ]

renderBlobModeSwitch :: forall w. State -> BlobKind -> HH.HTML w Action
renderBlobModeSwitch state kind =
  if blobHasPreview kind && blobHasSource kind then
    let
      modeButton preview label = HH.button
        [ HP.type_ HP.ButtonButton
        , HP.attr (HH.AttrName "data-state") (if state.blobPreview == preview then "active" else "inactive")
        , HE.onClick (const (SetBlobPreview preview))
        ]
        [ HH.text label ]
    in
      HH.div [ HP.class_ (HH.ClassName "forge-blob-modes"), HP.attr (HH.AttrName "aria-label") "Blob display mode" ]
        [ modeButton true "Preview"
        , modeButton false "Source"
        ]
  else HH.text ""

renderBlobViewer :: forall w. State -> Project -> String -> String -> BlobKind -> HH.HTML w Action
renderBlobViewer state project ref path kind
  | blobHasPreview kind && state.blobPreview = renderAssetPreview kind path (Forgejo.rawUrl project.repository ref path) state.source state.assetUrl
  | otherwise = HH.div [ HP.class_ (HH.ClassName "forge-viewer") ] [ renderViewer state.source ]

renderAssetPreview :: forall w. BlobKind -> String -> String -> RemoteData String SourceFile -> RemoteData String String -> HH.HTML w Action
renderAssetPreview kind path raw source assetUrl =
  HH.div [ HP.class_ (HH.ClassName ("forge-viewer is-asset " <> assetClass kind)) ] case kind of
    SvgBlob -> [ renderImage raw path ]
    ImageBlob -> [ renderImage raw path ]
    PdfBlob -> [ renderDocument assetUrl ]
    AudioBlob ->
      [ HH.div [ HP.class_ (HH.ClassName "forge-media-preview") ]
          [ HH.div [ HP.class_ (HH.ClassName "forge-media-mark"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "♫" ]
          , HH.h2_ [ HH.text (pathBase path) ]
          , HH.audio [ HP.src raw, HP.controls true ] [ HH.text "Your browser cannot play this audio file." ]
          ]
      ]
    VideoBlob ->
      [ HH.video [ HP.src raw, HP.controls true, HP.class_ (HH.ClassName "forge-video-preview") ]
          [ HH.text "Your browser cannot play this video file." ]
      ]
    MarkdownBlob -> [ renderMarkdownAsset source ]
    SourceBlob -> [ renderViewer source ]
  where
  renderDocument = case _ of
    Success url -> HH.iframe
      [ HP.src url
      , HP.title ("PDF preview of " <> pathBase path)
      , HP.class_ (HH.ClassName "forge-document-preview")
      ]
    Loading -> renderLoading "Preparing PDF preview"
    Failure error -> renderFailure "Could not prepare PDF preview" error RetryRoute
    NotAsked -> renderEmpty "No PDF preview is available."
  renderImage url value = HH.a
    [ HP.href url
    , HP.target "_blank"
    , HP.rel "noreferrer"
    , HP.class_ (HH.ClassName "forge-image-preview")
    , HP.title "Open original asset"
    ]
    [ HH.img
        [ HP.src url
        , HP.alt ("Rendered preview of " <> pathBase value)
        , HP.attr (HH.AttrName "loading") "eager"
        ]
    ]

renderMarkdownAsset :: forall w. RemoteData String SourceFile -> HH.HTML w Action
renderMarkdownAsset = case _ of
  Success source ->
    HH.article [ HP.class_ (HH.ClassName "forge-markdown-preview forge-readme") ]
      (map renderMarkdownBlock (parseMarkdown source.code))
  Loading -> renderLoading "Rendering Markdown"
  Failure error -> renderFailure "Could not render Markdown" error RetryRoute
  NotAsked -> renderEmpty "No Markdown source is available."

renderViewer :: forall w. RemoteData String SourceFile -> HH.HTML w Action
renderViewer = case _ of
  NotAsked -> viewer { path: "source", language: "text", code: "Select a source file." }
  Loading -> viewer { path: "loading", language: "text", code: "Reading source from Forgejo…" }
  Failure error -> viewer { path: "unavailable", language: "text", code: "Could not read this file.\n\n" <> error }
  Success source -> viewer source
  where
  viewer source = codeViewer (defaultCodeViewer { path = source.path, language = source.language, code = source.code, class_ = "forge-code-viewer" })

renderCommits :: forall w. State -> Project -> String -> HH.HTML w Action
renderCommits state project ref =
  HH.div_
    [ renderRepoToolbar state project ref
    , renderSectionHead "Commit history" ("Latest commits on " <> ref) (project.htmlUrl <> "/commits/branch/" <> Forgejo.encodeComponent ref) "Open history in Forgejo ↗"
    , remoteList state.commits "Reading commit history" "No commits found on this ref." (map (renderCommitRow project ref))
    ]

renderFileHistory :: forall w. State -> Project -> String -> String -> HH.HTML w Action
renderFileHistory state project ref path =
  HH.div_
    [ renderRepoToolbar state project ref
    , renderPathCrumbs project ref path true
    , renderSectionHead "File history" path (project.htmlUrl <> "/commits/branch/" <> Forgejo.encodeComponent ref <> "/" <> Forgejo.encodePath path) "Open in Forgejo ↗"
    , remoteList state.commits "Reading file history" "No commits found for this path." (map (renderCommitRow project ref))
    ]

renderCommitRow :: forall w. Project -> String -> Forgejo.Commit -> HH.HTML w Action
renderCommitRow project ref commit =
  internalLinkClass "forge-event-row" (RepoRoute project.slug (CommitView ref commit.sha))
    [ HH.span [ HP.class_ (HH.ClassName "forge-event-mark is-commit"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "◇" ]
    , HH.div [ HP.class_ (HH.ClassName "forge-event-main") ]
        [ HH.h3_ [ HH.text commit.message ]
        , HH.p_ [ HH.text (commit.author <> " committed on " <> shortDate commit.createdAt) ]
        ]
    , HH.code_ [ HH.text commit.shortSha ]
    ]

renderCommitDetail :: forall w. State -> Project -> String -> String -> HH.HTML w Action
renderCommitDetail state project ref sha =
  HH.div [ HP.class_ (HH.ClassName "forge-commit-detail") ]
    [ HH.div [ HP.class_ (HH.ClassName "forge-detail-back") ]
        [ internalLink (RepoRoute project.slug (CommitsView ref)) [ HH.text "← Commit history" ] ]
    , case state.commitDetail of
        NotAsked -> renderLoading "Reading commit"
        Loading -> renderLoading "Reading commit"
        Failure error -> renderFailure "Could not read commit" error RetryRoute
        Success detail -> renderCommitSummary project ref detail
    , renderCommitDiff sha state.commitDiff
    ]

renderCommitSummary :: forall w. Project -> String -> Forgejo.CommitDetail -> HH.HTML w Action
renderCommitSummary project ref detail =
  HH.article [ HP.class_ (HH.ClassName "forge-commit-card") ]
    [ HH.header_
        [ HH.h2_ [ HH.text (firstLine detail.message) ]
        , HH.div [ HP.class_ (HH.ClassName "forge-commit-byline") ]
            [ HH.b_ [ HH.text detail.author ]
            , HH.text (" committed " <> shortDate detail.createdAt)
            , HH.span
                [ HP.class_ (HH.ClassName (if detail.verified then "forge-verification is-verified" else "forge-verification"))
                , HP.title detail.verificationReason
                ]
                [ HH.text (if detail.verified then "Verified" else "Unverified") ]
            ]
        ]
    , HH.pre [ HP.class_ (HH.ClassName "forge-commit-message-full") ] [ HH.text detail.message ]
    , HH.div [ HP.class_ (HH.ClassName "forge-commit-identifiers") ]
        ( [ HH.span_ [ HH.text "Commit" ], HH.code_ [ HH.text detail.sha ] ]
            <> Array.concatMap renderParent detail.parents
        )
    , HH.div [ HP.class_ (HH.ClassName "forge-diff-stats") ]
        [ HH.b_ [ HH.text (show detail.stats.total <> " changed lines") ]
        , HH.span [ HP.class_ (HH.ClassName "is-addition") ] [ HH.text ("+" <> show detail.stats.additions) ]
        , HH.span [ HP.class_ (HH.ClassName "is-deletion") ] [ HH.text ("−" <> show detail.stats.deletions) ]
        , HH.span_ [ HH.text (show (Array.length detail.files) <> " files") ]
        , HH.a [ HP.href (Forgejo.commitPatchUrl project.repository detail.sha), HP.attr (HH.AttrName "download") (detail.shortSha <> ".patch") ] [ HH.text "Patch ↓" ]
        , HH.a [ HP.href detail.htmlUrl, HP.target "_blank", HP.rel "noreferrer" ] [ HH.text "Forgejo ↗" ]
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-changed-files") ] (map renderFile detail.files)
    ]
  where
  renderParent parent =
    [ HH.span_ [ HH.text "Parent" ]
    , internalLinkClass "forge-parent-sha" (RepoRoute project.slug (CommitView ref parent)) [ HH.text (String.take 7 parent) ]
    ]
  renderFile file
    | file.status == "deleted" = HH.div [ HP.class_ (HH.ClassName "forge-changed-file") ] (fileParts file)
    | otherwise = internalLinkClass "forge-changed-file" (RepoRoute project.slug (BlobView detail.sha file.path)) (fileParts file)
  fileParts file =
    [ HH.span [ HP.class_ (HH.ClassName ("forge-file-status is-" <> file.status)) ] [ HH.text (String.take 1 (String.toUpper file.status)) ]
    , HH.span_ [ HH.text file.path ]
    , HH.span [ HP.class_ (HH.ClassName "forge-changed-arrow"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "→" ]
    ]

renderCommitDiff :: forall w. String -> RemoteData String String -> HH.HTML w Action
renderCommitDiff sha = case _ of
  NotAsked -> HH.text ""
  Loading -> renderLoading "Reading unified diff"
  Failure error -> renderFailure "Could not read unified diff" error RetryRoute
  Success diff ->
    HH.section [ HP.class_ (HH.ClassName "forge-diff-view") ]
      [ HH.header_ [ HH.h2_ [ HH.text "Unified diff" ], HH.span_ [ HH.text (String.take 7 sha) ] ]
      , codeViewer (defaultCodeViewer { path = String.take 7 sha <> ".diff", language = "diff", code = diff, class_ = "forge-diff-code" })
      ]

renderRefs :: forall w. State -> Project -> String -> HH.HTML w Action
renderRefs state project ref =
  HH.div_
    [ renderRepoToolbar state project ref
    , HH.div [ HP.class_ (HH.ClassName "forge-refs-grid") ]
        [ renderBranchList state.branches
        , renderTagList state.tags
        ]
    ]
  where
  renderBranchList remote = HH.section_
    [ HH.header [ HP.class_ (HH.ClassName "forge-list-title") ] [ HH.h2_ [ HH.text "Branches" ], HH.span_ [ HH.text (remoteLength remote) ] ]
    , case remote of
        Success branches | Array.null branches -> renderEmpty "No branches found."
        Success branches -> HH.div [ HP.class_ (HH.ClassName "forge-ref-list") ] (map renderBranch branches)
        Failure error -> renderFailure "Could not read branches" error RetryRoute
        _ -> renderLoading "Reading branches"
    ]
  renderBranch branch =
    internalLinkClass "forge-ref-row" (RepoRoute project.slug (CodeView branch.name ""))
      [ HH.span [ HP.class_ (HH.ClassName "forge-ref-symbol"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "⑂" ]
      , HH.div_ [ HH.h3_ [ HH.text branch.name ], HH.p_ [ HH.text (branch.message <> " · " <> branch.author <> " · " <> shortDate branch.updatedAt) ] ]
      , if branch.protected then HH.span [ HP.class_ (HH.ClassName "forge-ref-badge") ] [ HH.text "Protected" ] else HH.text ""
      , HH.code_ [ HH.text (String.take 7 branch.sha) ]
      ]
  renderTagList remote = HH.section_
    [ HH.header [ HP.class_ (HH.ClassName "forge-list-title") ] [ HH.h2_ [ HH.text "Tags" ], HH.span_ [ HH.text (remoteLength remote) ] ]
    , case remote of
        Success tags | Array.null tags -> renderEmpty "No tags have been published."
        Success tags -> HH.div [ HP.class_ (HH.ClassName "forge-ref-list") ] (map renderTag tags)
        Failure error -> renderFailure "Could not read tags" error RetryRoute
        _ -> renderLoading "Reading tags"
    ]
  renderTag tag =
    HH.div [ HP.class_ (HH.ClassName "forge-ref-row") ]
      [ HH.span [ HP.class_ (HH.ClassName "forge-ref-symbol"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "◇" ]
      , HH.div_
          [ HH.h3_ [ internalLink (RepoRoute project.slug (CodeView tag.name "")) [ HH.text tag.name ] ]
          , HH.p_ [ HH.text ((if tag.message == "" then "Tagged commit" else tag.message) <> " · " <> shortDate tag.createdAt) ]
          ]
      , HH.div [ HP.class_ (HH.ClassName "forge-tag-downloads") ] [ HH.a [ HP.href tag.tarUrl ] [ HH.text "tar" ], HH.a [ HP.href tag.zipUrl ] [ HH.text "zip" ] ]
      , HH.code_ [ HH.text (String.take 7 tag.sha) ]
      ]

renderSearch :: forall w. State -> Project -> String -> HH.HTML w Action
renderSearch state project ref =
  HH.div [ HP.class_ (HH.ClassName "forge-search-page") ]
    [ renderRepoToolbar state project ref
    , HH.header [ HP.class_ (HH.ClassName "forge-search-head") ]
        [ HH.div_ [ HH.h2_ [ HH.text "Go to file" ], HH.p_ [ HH.text ("Search every path on " <> ref <> ".") ] ]
        , HH.span_ [ HH.text (searchIndexMeta state.searchIndex) ]
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-search-input") ]
        [ HH.span [ HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "/" ]
        , HH.input
            [ HP.type_ HP.InputSearch
            , HP.placeholder "Type a file or directory path…"
            , HP.value state.searchQuery
            , HP.autofocus true
            , HP.attr (HH.AttrName "aria-label") "Search repository paths"
            , HE.onValueInput UpdateSearch
            ]
        , HH.kbd_ [ HH.text (show (Array.length (searchResults state.searchQuery state.searchIndex)) <> " matches") ]
        ]
    , case state.searchIndex of
        NotAsked -> renderLoading "Indexing repository tree"
        Loading -> renderLoading "Indexing repository tree"
        Failure error -> renderFailure "Could not index repository" error RetryRoute
        Success _ | String.trim state.searchQuery == "" -> renderEmpty "Start typing to find a path."
        Success _ | Array.null (searchResults state.searchQuery state.searchIndex) -> renderEmpty "No paths match that query."
        Success _ -> HH.nav [ HP.class_ (HH.ClassName "forge-search-results"), HP.attr (HH.AttrName "aria-label") "Matching repository paths" ]
          (map (renderSearchResult project ref) (searchResults state.searchQuery state.searchIndex))
    ]

renderSearchResult :: forall w. Project -> String -> Forgejo.TreeEntry -> HH.HTML w Action
renderSearchResult project ref entry =
  internalLinkClass "forge-search-result" route
    [ HH.span [ HP.class_ (HH.ClassName (if entry.kind == "tree" then "forge-content-icon is-dir" else "forge-content-icon is-file")), HP.attr (HH.AttrName "aria-hidden") "true" ] []
    , HH.span_ [ HH.text entry.path ]
    , HH.span_ [ HH.text (if entry.kind == "tree" then "directory" else formatBytes (toNumber entry.size)) ]
    , HH.span [ HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "→" ]
    ]
  where
  route = if entry.kind == "tree" then RepoRoute project.slug (CodeView ref entry.path) else RepoRoute project.slug (BlobView ref entry.path)

renderIssues :: forall w. State -> Project -> HH.HTML w Action
renderIssues state project =
  HH.div_
    [ renderSectionHead "Issues" "Work tracked by Forgejo" (project.htmlUrl <> "/issues") "New issue in Forgejo ↗"
    , remoteList state.issues "Reading issues" "No issues have been opened in this repository." (map renderIssue)
    ]
  where
  renderIssue issue =
    HH.a [ HP.href issue.htmlUrl, HP.target "_blank", HP.rel "noreferrer", HP.class_ (HH.ClassName "forge-event-row") ]
      [ HH.span [ HP.class_ (HH.ClassName ("forge-event-mark is-" <> issue.state)), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "○" ]
      , HH.div [ HP.class_ (HH.ClassName "forge-event-main") ]
          [ HH.h3_ ([ HH.text issue.title ] <> renderLabels issue.labels)
          , HH.p_ [ HH.text ("#" <> show issue.number <> " opened by " <> issue.author <> " · updated " <> shortDate issue.updatedAt) ]
          ]
      , HH.span [ HP.class_ (HH.ClassName "forge-event-count") ] [ HH.text (show issue.comments <> " comments") ]
      ]

renderPulls :: forall w. State -> Project -> HH.HTML w Action
renderPulls state project =
  HH.div_
    [ renderSectionHead "Pull requests" "Changes proposed and reviewed in Forgejo" (project.htmlUrl <> "/pulls") "New pull request ↗"
    , remoteList state.pulls "Reading pull requests" "No pull requests have been opened in this repository." (map renderPull)
    ]
  where
  renderPull pull =
    HH.a [ HP.href pull.htmlUrl, HP.target "_blank", HP.rel "noreferrer", HP.class_ (HH.ClassName "forge-event-row") ]
      [ HH.span [ HP.class_ (HH.ClassName ("forge-event-mark is-" <> pull.state)), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "⑂" ]
      , HH.div [ HP.class_ (HH.ClassName "forge-event-main") ]
          [ HH.h3_ ([ HH.text pull.title ] <> renderLabels pull.labels)
          , HH.p_ [ HH.text ("#" <> show pull.number <> " opened by " <> pull.author <> " · updated " <> shortDate pull.updatedAt) ]
          ]
      ]

renderReleases :: forall w. State -> Project -> HH.HTML w Action
renderReleases state project =
  HH.div_
    [ renderSectionHead "Releases" "Versioned artifacts published by Forgejo" (project.htmlUrl <> "/releases") "Manage releases ↗"
    , remoteList state.releases "Reading releases" "No releases have been published in this repository." (map renderRelease)
    ]
  where
  renderRelease release =
    HH.article [ HP.class_ (HH.ClassName "forge-release") ]
      [ HH.div [ HP.class_ (HH.ClassName "forge-release-meta") ]
          [ HH.span [ HP.class_ (HH.ClassName "forge-release-tag") ] [ HH.text release.tagName ]
          , HH.span_ [ HH.text (shortDate release.createdAt) ]
          , if release.prerelease then HH.span [ HP.class_ (HH.ClassName "forge-release-state") ] [ HH.text "Pre-release" ] else HH.text ""
          , if release.draft then HH.span [ HP.class_ (HH.ClassName "forge-release-state") ] [ HH.text "Draft" ] else HH.text ""
          ]
      , HH.h2_ [ HH.a [ HP.href release.htmlUrl, HP.target "_blank", HP.rel "noreferrer" ] [ HH.text (if release.name == "" then release.tagName else release.name) ] ]
      , HH.div [ HP.class_ (HH.ClassName "forge-release-body") ] (map renderMarkdownBlock (parseMarkdown release.body))
      , HH.div [ HP.class_ (HH.ClassName "forge-release-downloads") ]
          [ HH.a [ HP.href release.tarUrl ] [ HH.text "tar.gz" ]
          , HH.a [ HP.href release.zipUrl ] [ HH.text "zip" ]
          ]
      ]

renderSectionHead :: forall w. String -> String -> String -> String -> HH.HTML w Action
renderSectionHead title description href action =
  HH.header [ HP.class_ (HH.ClassName "forge-section-head") ]
    [ HH.div_ [ HH.h2_ [ HH.text title ], HH.p_ [ HH.text description ] ]
    , HH.a [ HP.href href, HP.target "_blank", HP.rel "noreferrer", HP.class_ (HH.ClassName "forge-small-button") ] [ HH.text action ]
    ]

renderLabels :: forall w. Array Forgejo.Label -> Array (HH.HTML w Action)
renderLabels = map (\label -> HH.span [ HP.class_ (HH.ClassName "forge-label"), HP.style ("--label-color:#" <> label.color) ] [ HH.text label.name ])

remoteList :: forall w a. RemoteData String (Array a) -> String -> String -> (Array a -> Array (HH.HTML w Action)) -> HH.HTML w Action
remoteList remote loading empty renderItems = case remote of
  NotAsked -> renderLoading loading
  Loading -> renderLoading loading
  Failure error -> renderFailure "Forgejo could not load this view" error RetryRoute
  Success values | Array.null values -> renderEmpty empty
  Success values -> HH.div [ HP.class_ (HH.ClassName "forge-event-list") ] (renderItems values)

renderPapers :: forall w. Project -> HH.HTML w Action
renderPapers project
  | Array.null project.publications = renderEmpty "No papers are linked to this repository yet."
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

renderEmpty :: forall w. String -> HH.HTML w Action
renderEmpty message =
  HH.div [ HP.class_ (HH.ClassName "forge-empty") ]
    [ HH.span [ HP.class_ (HH.ClassName "forge-empty-mark") ] [ HH.text "//" ]
    , HH.h2_ [ HH.text "Nothing here yet." ]
    , HH.p_ [ HH.text message ]
    ]

renderLoading :: forall w. String -> HH.HTML w Action
renderLoading label =
  HH.div [ HP.class_ (HH.ClassName "forge-remote-state"), HP.attr (HH.AttrName "role") "status" ]
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
    [ HH.span [ HP.class_ (HH.ClassName "forge-empty-mark") ] [ HH.text "404" ]
    , HH.h2_ [ HH.text "Repository not found" ]
    , HH.p_ [ HH.text ("straylight/" <> slug <> " is not in the public Forgejo index.") ]
    , HH.a [ HP.href "#/" ] [ HH.text "Return to Forge →" ]
    ]

statusLeft :: forall w. State -> Array (HH.HTML w Action)
statusLeft state = case projectForRoute state state.route of
  Just project ->
    [ HH.span [ HP.class_ (HH.ClassName "forge-status-dot"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "●" ]
    , HH.span_ [ HH.b_ [ HH.text project.owner ], HH.text (" / " <> project.name) ]
    ]
  Nothing ->
    [ HH.span [ HP.class_ (HH.ClassName (if repositoriesConnected state.repositories then "forge-status-dot" else "forge-status-dot is-offline")), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "●" ]
    , HH.span_ [ HH.text (if repositoriesConnected state.repositories then "Forgejo / connected" else "Forgejo / connecting") ]
    ]

statusRight :: forall w. State -> Array (HH.HTML w Action)
statusRight state = case projectForRoute state state.route of
  Just project ->
    [ HH.span [ HP.class_ (HH.ClassName "forge-status-optional") ] [ HH.text (activeRef project state.route) ]
    , HH.span_ [ HH.text (show project.sizeKiB <> " KiB · " <> show project.openIssues <> " issues · " <> show project.openPulls <> " pulls") ]
    ]
  Nothing -> case state.repositories of
    Success projects -> [ HH.span_ [ HH.text (show (Array.length projects) <> " repositories") ], HH.span_ [ HH.text "© 2026" ] ]
    Failure _ -> [ HH.span_ [ HH.text "Forgejo unavailable" ] ]
    _ -> [ HH.span_ [ HH.text "Loading repositories" ] ]

activeTab :: RepoView -> RepoTab
activeTab = case _ of
  CodeView _ _ -> CodeTab
  BlobView _ _ -> CodeTab
  CommitsView _ -> CommitsTab
  CommitView _ _ -> CommitsTab
  FileHistoryView _ _ -> CodeTab
  RefsView _ -> CodeTab
  SearchView _ -> CodeTab
  IssuesView -> IssuesTab
  PullsView -> PullsTab
  ReleasesView -> ReleasesTab
  PapersView -> PapersTab

activeRef :: Project -> Route -> String
activeRef project = case _ of
  RepoRoute _ (CodeView ref _) -> resolveRef project ref
  RepoRoute _ (BlobView ref _) -> resolveRef project ref
  RepoRoute _ (CommitsView ref) -> resolveRef project ref
  RepoRoute _ (CommitView ref _) -> resolveRef project ref
  RepoRoute _ (FileHistoryView ref _) -> resolveRef project ref
  RepoRoute _ (RefsView ref) -> resolveRef project ref
  RepoRoute _ (SearchView ref) -> resolveRef project ref
  _ -> project.defaultBranch

resolveRef :: Project -> String -> String
resolveRef project ref = if ref == "" then project.defaultBranch else ref

entryOrder :: Forgejo.ContentEntry -> Forgejo.ContentEntry -> Ordering
entryOrder left right
  | left.kind == "dir" && right.kind /= "dir" = LT
  | left.kind /= "dir" && right.kind == "dir" = GT
  | otherwise = compare (String.toLower left.name) (String.toLower right.name)

isReadme :: Forgejo.ContentEntry -> Boolean
isReadme entry = entry.kind == "file" && Array.elem (String.toLower entry.name) [ "readme", "readme.md", "readme.markdown", "readme.mdx", "readme.org" ]

remoteLength :: forall a. RemoteData String (Array a) -> String
remoteLength = case _ of
  Success values -> show (Array.length values)
  _ -> "—"

searchResults :: String -> RemoteData String Forgejo.TreeListing -> Array Forgejo.TreeEntry
searchResults query remote
  | String.trim query == "" = []
  | otherwise = case remote of
  Success listing -> listing.entries
    # Array.filter (\entry -> String.contains (Pattern (String.toLower (String.trim query))) (String.toLower entry.path))
    # Array.sortBy (\left right -> compare (String.length left.path) (String.length right.path) <> compare left.path right.path)
    # Array.take 100
  _ -> []

searchIndexMeta :: RemoteData String Forgejo.TreeListing -> String
searchIndexMeta = case _ of
  Success listing -> show listing.totalCount <> " entries" <> if listing.truncated then " · truncated" else ""
  Loading -> "Indexing…"
  _ -> ""

firstLine :: String -> String
firstLine = SCU.takeWhile (_ /= '\n')

shortDate :: String -> String
shortDate = String.take 10

maybeText :: forall a. String -> (a -> String) -> Maybe a -> String
maybeText fallback renderValue = case _ of
  Just value -> renderValue value
  Nothing -> fallback

repositoriesConnected :: RemoteData String (Array Project) -> Boolean
repositoriesConnected (Success _) = true
repositoriesConnected _ = false

connectionHelp :: String -> String
connectionHelp error = "Connect this browser to the S4 tailnet and allow Local Network Access for Orbital Forge, then retry. " <> error

projectForRoute :: State -> Route -> Maybe Project
projectForRoute state = case _ of
  ForgeHome -> Nothing
  RepoRoute slug _ -> projectForSlug state slug

projectForSlug :: State -> String -> Maybe Project
projectForSlug state slug = case state.repositories of
  Success projects -> Array.find (\project -> project.slug == slug) projects
  _ -> Nothing

cloneCommand :: CloneProtocol -> Project -> String
cloneCommand protocol project = case protocol of
  OrbCli -> project.clone.cli
  Https -> project.clone.https
  Ssh -> project.clone.ssh

permalinkUrl :: State -> String -> String
permalinkUrl state current = case state.route, state.latestCommit of
  RepoRoute slug (BlobView _ path), Success (Just commit) ->
    base <> routeHash (RepoRoute slug (BlobView commit.sha path))
  _, _ -> current
  where
  base = fromMaybe current (Array.head (String.split (Pattern "#") current))

releaseAssetUrl :: forall o. H.HalogenM State Action () o Aff Unit
releaseAssetUrl = do
  state <- H.get
  case state.assetUrl of
    Success url -> liftEffect (FileURL.revokeObjectURL url)
    _ -> pure unit
  H.modify_ _ { assetUrl = NotAsked }

internalLink :: forall w. Route -> Array (HH.HTML w Action) -> HH.HTML w Action
internalLink route = HH.a [ HP.href (routeHash route), HE.onClick (const (Navigate route)) ]

internalLinkClass :: forall w. String -> Route -> Array (HH.HTML w Action) -> HH.HTML w Action
internalLinkClass className route =
  HH.a [ HP.href (routeHash route), HP.class_ (HH.ClassName className), HE.onClick (const (Navigate route)) ]

routeHash :: Route -> String
routeHash = case _ of
  ForgeHome -> "#/"
  RepoRoute slug (CodeView "" "") -> "#/p/" <> Forgejo.encodeComponent slug
  RepoRoute slug (CodeView ref path) -> repoPath slug "tree" ref path
  RepoRoute slug (BlobView ref path) -> repoPath slug "blob" ref path
  RepoRoute slug (CommitsView ref) -> "#/p/" <> Forgejo.encodeComponent slug <> "/commits/" <> Forgejo.encodeComponent ref
  RepoRoute slug (CommitView ref sha) -> "#/p/" <> Forgejo.encodeComponent slug <> "/commit/" <> Forgejo.encodeComponent ref <> "/" <> Forgejo.encodeComponent sha
  RepoRoute slug (FileHistoryView ref path) -> repoPath slug "history" ref path
  RepoRoute slug (RefsView ref) -> "#/p/" <> Forgejo.encodeComponent slug <> "/refs/" <> Forgejo.encodeComponent ref
  RepoRoute slug (SearchView ref) -> "#/p/" <> Forgejo.encodeComponent slug <> "/search/" <> Forgejo.encodeComponent ref
  RepoRoute slug IssuesView -> "#/p/" <> Forgejo.encodeComponent slug <> "/issues"
  RepoRoute slug PullsView -> "#/p/" <> Forgejo.encodeComponent slug <> "/pulls"
  RepoRoute slug ReleasesView -> "#/p/" <> Forgejo.encodeComponent slug <> "/releases"
  RepoRoute slug PapersView -> "#/p/" <> Forgejo.encodeComponent slug <> "/papers"

repoPath :: String -> String -> String -> String -> String
repoPath slug kind ref path =
  "#/p/" <> Forgejo.encodeComponent slug <> "/" <> kind <> "/" <> Forgejo.encodeComponent ref
    <> if path == "" then "" else "/" <> Forgejo.encodePath path

parseHash :: String -> Route
parseHash hash = fromMaybe ForgeHome do
  rest <- String.stripPrefix (Pattern "#/p/") hash
  let parts = String.split (Pattern "/") rest
  encodedSlug <- parts Array.!! 0
  let slug = Forgejo.decodeComponent encodedSlug
  if slug == "" then Nothing
  else Just $ RepoRoute slug case parts Array.!! 1 of
    Just "tree" -> CodeView (decodePart 2 parts) (decodeTail 3 parts)
    Just "blob" -> BlobView (decodePart 2 parts) (decodeTail 3 parts)
    Just "commits" -> CommitsView (decodePart 2 parts)
    Just "commit" -> CommitView (decodePart 2 parts) (decodePart 3 parts)
    Just "history" -> FileHistoryView (decodePart 2 parts) (decodeTail 3 parts)
    Just "refs" -> RefsView (decodePart 2 parts)
    Just "search" -> SearchView (decodePart 2 parts)
    Just "issues" -> IssuesView
    Just "pulls" -> PullsView
    Just "releases" -> ReleasesView
    Just "papers" -> PapersView
    Just "source" -> CodeView "" ""
    _ -> CodeView "" ""

decodePart :: Int -> Array String -> String
decodePart index values = fromMaybe "" (map Forgejo.decodeComponent (values Array.!! index))

decodeTail :: Int -> Array String -> String
decodeTail index = Forgejo.decodePath <<< String.joinWith "/" <<< Array.drop index

isBlobRoute :: Route -> Boolean
isBlobRoute (RepoRoute _ (BlobView _ _)) = true
isBlobRoute _ = false

isBlob :: RepoView -> Boolean
isBlob (BlobView _ _) = true
isBlob _ = false

blobKind :: String -> BlobKind
blobKind path =
  let
    lower = String.toLower path
    has suffix = case String.stripSuffix (Pattern suffix) lower of
      Just _ -> true
      Nothing -> false
    hasAny = Array.any has
  in
    if has ".svg" || has ".svgz" then SvgBlob
    else if hasAny [ ".md", ".markdown", ".mdx" ] then MarkdownBlob
    else if hasAny [ ".png", ".jpg", ".jpeg", ".gif", ".webp", ".avif", ".bmp", ".ico", ".tif", ".tiff" ] then ImageBlob
    else if has ".pdf" then PdfBlob
    else if hasAny [ ".mp3", ".wav", ".ogg", ".oga", ".flac", ".m4a", ".aac", ".opus" ] then AudioBlob
    else if hasAny [ ".mp4", ".webm", ".ogv", ".mov", ".m4v" ] then VideoBlob
    else SourceBlob

blobHasPreview :: BlobKind -> Boolean
blobHasPreview SourceBlob = false
blobHasPreview _ = true

blobHasSource :: BlobKind -> Boolean
blobHasSource kind = Array.elem kind [ SourceBlob, MarkdownBlob, SvgBlob ]

assetClass :: BlobKind -> String
assetClass = case _ of
  SvgBlob -> "is-image is-svg"
  ImageBlob -> "is-image"
  PdfBlob -> "is-document"
  AudioBlob -> "is-audio"
  VideoBlob -> "is-video"
  MarkdownBlob -> "is-markdown"
  SourceBlob -> "is-source"

pathParts :: String -> Array String
pathParts = Array.filter (_ /= "") <<< String.split (Pattern "/")

pathBase :: String -> String
pathBase path = case Array.unsnoc (pathParts path) of
  Nothing -> path
  Just parts -> parts.last

parentPath :: String -> String
parentPath path = case Array.unsnoc (pathParts path) of
  Nothing -> ""
  Just parts -> String.joinWith "/" parts.init
