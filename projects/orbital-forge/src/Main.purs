module Main where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Forge.Data (Project, Publication, fromRepository, sourceLanguage)
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
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window

foreign import currentHash :: Effect String
foreign import setHash :: String -> Effect Unit
foreign import currentTheme :: Effect Boolean
foreign import applyTheme :: Boolean -> Effect Unit
foreign import copyText :: String -> Effect Unit

data RepoView
  = CodeView String String
  | BlobView String String
  | CommitsView String
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
  , contents :: RemoteData String (Array Forgejo.ContentEntry)
  , latestCommit :: RemoteData String (Maybe Forgejo.Commit)
  , readme :: RemoteData String (Maybe Readme)
  , source :: RemoteData String SourceFile
  , commits :: RemoteData String (Array Forgejo.Commit)
  , issues :: RemoteData String (Array Forgejo.Issue)
  , pulls :: RemoteData String (Array Forgejo.PullRequest)
  , releases :: RemoteData String (Array Forgejo.Release)
  , cloneProtocol :: CloneProtocol
  , copied :: Boolean
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
        , contents: NotAsked
        , latestCommit: NotAsked
        , readme: NotAsked
        , source: NotAsked
        , commits: NotAsked
        , issues: NotAsked
        , pulls: NotAsked
        , releases: NotAsked
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
    H.modify_ _ { route = route, copied = false }
    loadRoute route
  Navigate route -> do
    H.modify_ _ { route = route, copied = false }
    liftEffect $ setHash (routeHash route)
    loadRoute route
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
      _ -> pure unit
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
    , contents = NotAsked
    , latestCommit = NotAsked
    , readme = NotAsked
    , source = NotAsked
    , commits = NotAsked
    , issues = NotAsked
    , pulls = NotAsked
    , releases = NotAsked
    }
  branchResult <- H.liftAff $ Forgejo.listBranches project.repository
  H.modify_ _ { branches = eitherRemote branchResult }
  tagResult <- H.liftAff $ Forgejo.listTags project.repository
  H.modify_ _ { tags = eitherRemote tagResult }

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
  H.modify_ _ { source = Loading, latestCommit = Loading, contents = NotAsked, readme = NotAsked }
  result <- H.liftAff $ Forgejo.readRaw project.repository ref path
  H.modify_ _ { source = case result of
    Left error -> Failure error
    Right code -> Success { path, language: sourceLanguage path, code }
  }
  commitResult <- H.liftAff $ Forgejo.listCommits project.repository ref path
  H.modify_ _ { latestCommit = map Array.head (eitherRemote commitResult) }

loadCommitHistory :: forall o. Project -> String -> H.HalogenM State Action () o Aff Unit
loadCommitHistory project ref = do
  H.modify_ _ { commits = Loading }
  result <- H.liftAff $ Forgejo.listCommits project.repository ref ""
  H.modify_ _ { commits = eitherRemote result }

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
        [ HH.span_ [ HH.b_ [ HH.text (remoteLength state.branches) ], HH.text " branches" ]
        , HH.span_ [ HH.b_ [ HH.text (remoteLength state.tags) ], HH.text " tags" ]
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-toolbar-spacer") ] []
    , HH.a [ HP.href project.htmlUrl, HP.target "_blank", HP.rel "noreferrer", HP.class_ (HH.ClassName "forge-small-button") ] [ HH.text "Forgejo ↗" ]
    ]

refOptions :: forall w. State -> Project -> String -> Array (HH.HTML w Action)
refOptions state project ref = branchOptions <> tagOptions
  where
  branchOptions = case state.branches of
    Success branches ->
      [ HH.optgroup [ HP.attr (HH.AttrName "label") "Branches" ]
          (map (\branch -> HH.option [ HP.value branch.name, HP.selected (branch.name == ref) ] [ HH.text branch.name ]) branches)
      ]
    _ -> [ HH.option [ HP.value ref ] [ HH.text (if ref == "" then project.defaultBranch else ref) ] ]
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
            [ renderLatestCommit state.latestCommit
            , HH.nav [ HP.class_ (HH.ClassName "forge-content-table"), HP.attr (HH.AttrName "aria-label") "Repository contents" ]
                (parentEntry project ref path <> map (renderContentEntry project ref) entries)
            ]
    , renderClone state project
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

renderLatestCommit :: forall w. RemoteData String (Maybe Forgejo.Commit) -> HH.HTML w Action
renderLatestCommit = case _ of
  Success (Just commit) ->
    HH.a [ HP.href commit.htmlUrl, HP.target "_blank", HP.rel "noreferrer", HP.class_ (HH.ClassName "forge-latest-commit") ]
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
  CodeFence language value -> HH.pre [ HP.class_ (HH.ClassName "forge-code-block"), HP.attr (HH.AttrName "data-language") language ] [ HH.code_ [ HH.text value ] ]
  Rule -> HH.hr_

renderBlob :: forall w. State -> Project -> String -> String -> HH.HTML w Action
renderBlob state project ref path =
  HH.div [ HP.class_ (HH.ClassName "forge-blob") ]
    [ renderRepoToolbar state project ref
    , renderPathCrumbs project ref path true
    , renderLatestCommit state.latestCommit
    , HH.div [ HP.class_ (HH.ClassName "forge-blob-actions") ]
        [ HH.a [ HP.href (Forgejo.rawUrl project.repository ref path), HP.target "_blank", HP.rel "noreferrer" ] [ HH.text "Raw" ]
        , HH.a [ HP.href (Forgejo.rawUrl project.repository ref path), HP.attr (HH.AttrName "download") (pathBase path) ] [ HH.text "Download" ]
        , HH.a [ HP.href (project.htmlUrl <> "/src/branch/" <> Forgejo.encodeComponent ref <> "/" <> Forgejo.encodePath path), HP.target "_blank", HP.rel "noreferrer" ] [ HH.text "View in Forgejo ↗" ]
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-viewer") ] [ renderViewer state.source ]
    ]

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
    , remoteList state.commits "Reading commit history" "No commits found on this ref." (map renderCommit)
    ]
  where
  renderCommit commit =
    HH.a [ HP.href commit.htmlUrl, HP.target "_blank", HP.rel "noreferrer", HP.class_ (HH.ClassName "forge-event-row") ]
      [ HH.span [ HP.class_ (HH.ClassName "forge-event-mark is-commit"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "◇" ]
      , HH.div [ HP.class_ (HH.ClassName "forge-event-main") ]
          [ HH.h3_ [ HH.text commit.message ]
          , HH.p_ [ HH.text (commit.author <> " committed on " <> shortDate commit.createdAt) ]
          ]
      , HH.code_ [ HH.text commit.shortSha ]
      ]

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
  IssuesView -> IssuesTab
  PullsView -> PullsTab
  ReleasesView -> ReleasesTab
  PapersView -> PapersTab

activeRef :: Project -> Route -> String
activeRef project = case _ of
  RepoRoute _ (CodeView ref _) -> resolveRef project ref
  RepoRoute _ (BlobView ref _) -> resolveRef project ref
  RepoRoute _ (CommitsView ref) -> resolveRef project ref
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

routeHash :: Route -> String
routeHash = case _ of
  ForgeHome -> "#/"
  RepoRoute slug (CodeView "" "") -> "#/p/" <> Forgejo.encodeComponent slug
  RepoRoute slug (CodeView ref path) -> repoPath slug "tree" ref path
  RepoRoute slug (BlobView ref path) -> repoPath slug "blob" ref path
  RepoRoute slug (CommitsView ref) -> "#/p/" <> Forgejo.encodeComponent slug <> "/commits/" <> Forgejo.encodeComponent ref
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
