module Main where

import Prelude

import Data.Array as Array
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Forge.Data (Project, Publication, ReadmeBlock(..), SourceFile, projects)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Halogen.VDom.Driver (runUI)
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
  , selectedFile :: Int
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
        , selectedFile: 0
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
  HashChanged -> do
    hash <- liftEffect currentHash
    H.modify_ _ { route = parseHash hash, selectedFile = 0, cloneProtocol = OrbCli, copied = false }
  Navigate route -> do
    H.modify_ _ { route = route, selectedFile = 0, cloneProtocol = OrbCli, copied = false }
    liftEffect $ setHash (routeHash route)
  SelectTab tab -> do
    state <- H.get
    case state.route of
      ProjectRoute slug _ -> handleAction (Navigate (ProjectRoute slug tab))
      ForgeHome -> pure unit
  SelectFile index -> H.modify_ _ { selectedFile = index }
  SelectProtocol protocol -> H.modify_ _ { cloneProtocol = protocol, copied = false }
  CopyClone -> do
    state <- H.get
    case projectForRoute state.route of
      Nothing -> pure unit
      Just project -> do
        liftEffect $ copyText (cloneCommand state.cloneProtocol project)
        H.modify_ _ { copied = true }
  ToggleTheme -> do
    state <- H.get
    let dark = not state.dark
    liftEffect $ applyTheme dark
    H.modify_ _ { dark = dark }

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
        , primary =
            [ { label: "Orbital", href: "https://orbital.foo/", current: false } ]
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
renderRoute state = case projectForRoute state.route of
  Nothing -> renderHome
  Just project -> case state.route of
    ProjectRoute _ tab -> renderProject state project tab
    ForgeHome -> renderHome

renderHome :: forall w. HH.HTML w Action
renderHome =
  HH.div_
    [ HH.header [ HP.class_ (HH.ClassName "forge-head") ]
        [ HH.div [ HP.class_ (HH.ClassName "forge-eyebrow") ] [ HH.text "Orbital // Forge" ]
        , HH.h1_ [ HH.text "Consequential systems, and the papers that explain them." ]
        , HH.p_ [ HH.text "A literary forge for working systems. Read the source, clone the repository, and follow the papers that state why it exists. No stars, no theatre — just the work and its reasons." ]
        , HH.div [ HP.class_ (HH.ClassName "forge-metrics") ]
            [ metric (show (Array.length projects)) "Projects"
            , metric (show totalModules) "Source modules"
            , metric (show totalPublications) "Linked publications"
            ]
        ]
    , HH.section
        [ HP.class_ (HH.ClassName "forge-project-list")
        , HP.attr (HH.AttrName "aria-label") "Projects"
        ]
        (map renderProjectRow projects)
    ]
  where
  totalModules = foldl (\n project -> n + project.stats.modules) 0 projects
  totalPublications = foldl (\n project -> n + Array.length project.publications) 0 projects
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
        , HH.div [ HP.class_ (HH.ClassName "forge-tags") ] (map renderTag project.tags)
        ]
    , HH.div [ HP.class_ (HH.ClassName "forge-project-signals") ]
        [ languageBar project
        , HH.div [ HP.class_ (HH.ClassName "forge-project-stat") ]
            [ HH.b_ [ HH.text (show project.stats.modules) ], HH.text " modules" ]
        , HH.div [ HP.class_ (HH.ClassName "forge-project-stat") ]
            [ HH.text (show project.stats.lines <> " lines · updated " <> project.updated) ]
        , HH.div [ HP.class_ (HH.ClassName "forge-project-reading") ]
            [ HH.text (show (Array.length project.publications) <> " linked publications →") ]
        ]
    , HH.span [ HP.class_ (HH.ClassName "forge-project-arrow"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "→" ]
    ]
  where
  route = ProjectRoute project.slug Overview
  renderTag value = HH.span_ [ HH.text value ]

languageBar :: forall w. Project -> HH.HTML w Action
languageBar project =
  HH.div
    [ HP.class_ (HH.ClassName "forge-language-bar")
    , HP.attr (HH.AttrName "aria-label") "Language composition"
    ]
    (map segment project.languages)
  where
  segment language =
    HH.i
      [ HP.style ("width:" <> show language.percent <> "%;background:" <> language.color)
      , HP.title (language.name <> " " <> show language.percent <> "%")
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
            [ HH.span [ HP.class_ (HH.ClassName "forge-live-dot") ] [ HH.text "●" ]
            , HH.b_ [ HH.text (fromMaybe "Source" (map _.name (Array.head project.languages))) ]
            , HH.span_ [ HH.text project.license ]
            , HH.span_ [ HH.text ("updated " <> project.updated) ]
            , HH.span_ [ HH.text (show project.stats.modules <> " modules") ]
            ]
        ]
    , Nav.tabs "Project sections"
        [ projectTab Overview "Overview" Nothing tab
        , projectTab Source "Source" (Just (Array.length project.files)) tab
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

renderOverview :: forall w. State -> Project -> HH.HTML w Action
renderOverview state project =
  HH.div [ HP.class_ (HH.ClassName "forge-overview") ]
    [ HH.article [ HP.class_ (HH.ClassName "forge-readme") ] (map renderBlock project.readme)
    , HH.aside [ HP.class_ (HH.ClassName "forge-sidebar"), HP.attr (HH.AttrName "aria-label") "Repository details" ]
        [ HH.div [ HP.class_ (HH.ClassName "forge-side-block forge-clone-block") ] [ renderClone state project ]
        , sideBlock "Languages"
            [ HH.div [ HP.class_ (HH.ClassName "forge-language-list") ] (map renderLanguage project.languages) ]
        , sideBlock "Signals"
            ( proofSignal
                <>
                  [ signal "Modules" (show project.stats.modules)
                  , signal "Lines" (show project.stats.lines)
                  ]
            )
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
      , HH.span [ HP.class_ (HH.ClassName "forge-language-percent") ] [ HH.text (show language.percent <> "%") ]
      ]
  proofSignal = if project.stats.proofs == 0 then [] else [ signal "Proofs" (show project.stats.proofs) ]
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
renderSource state project =
  HH.div [ HP.class_ (HH.ClassName "forge-source") ]
    [ HH.nav [ HP.class_ (HH.ClassName "forge-tree"), HP.attr (HH.AttrName "aria-label") "Repository files" ]
        (Array.mapWithIndex (renderFileItem state project) project.files)
    , HH.div [ HP.class_ (HH.ClassName "forge-viewer") ]
        [ codeViewer
            ( defaultCodeViewer
                { path = selected.path
                , language = selected.language
                , code = selected.code
                , class_ = "forge-code-viewer"
                }
            )
        ]
    ]
  where
  selected = fromMaybe fallbackFile (project.files Array.!! state.selectedFile)

renderFileItem :: forall w. State -> Project -> Int -> SourceFile -> HH.HTML w Action
renderFileItem state project index file =
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
  previousDirectory = case project.files Array.!! (index - 1) of
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
  | otherwise =
      HH.div [ HP.class_ (HH.ClassName "forge-publications") ] (map renderPublication project.publications)

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

statusLeft :: forall w. State -> Array (HH.HTML w Action)
statusLeft state = case projectForRoute state.route of
  Nothing ->
    [ HH.span [ HP.class_ (HH.ClassName "forge-status-dot") ] [ HH.text "●" ]
    , HH.span_ [ HH.text "Orbital Forge" ]
    ]
  Just project ->
    [ HH.span [ HP.class_ (HH.ClassName "forge-status-dot") ] [ HH.text "●" ]
    , HH.span_ [ HH.b_ [ HH.text project.name ], HH.text (" / " <> project.owner) ]
    ]

statusRight :: forall w. State -> Array (HH.HTML w Action)
statusRight state = case projectForRoute state.route of
  Nothing -> [ HH.span_ [ HH.text (show (Array.length projects) <> " projects") ], HH.span_ [ HH.text "© 2026" ] ]
  Just project ->
    [ HH.span [ HP.class_ (HH.ClassName "forge-status-optional") ] [ HH.text project.license ]
    , HH.span_ [ HH.text (show project.stats.modules <> " modules · " <> show project.stats.lines <> " lines") ]
    ]

projectForRoute :: Route -> Maybe Project
projectForRoute = case _ of
  ForgeHome -> Nothing
  ProjectRoute slug _ -> Array.find (\project -> project.slug == slug) projects

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
  let
    tab = case parts Array.!! 1 of
      Just "source" -> Source
      Just "papers" -> Papers
      _ -> Overview
  if Array.any (\project -> project.slug == slug) projects then
    Just (ProjectRoute slug tab)
  else
    Nothing

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

fallbackFile :: SourceFile
fallbackFile = { path: "empty", language: "text", code: "No source file selected." }
