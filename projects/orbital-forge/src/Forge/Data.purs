module Forge.Data
  ( Language
  , CloneUrls
  , ReadmeBlock(..)
  , SourceFile
  , Project
  , Publication
  , fromRepository
  , sourceLanguage
  , languageColor
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Forge.Forgejo (Repository)

type Language =
  { name :: String
  , percent :: Int
  , color :: String
  }

type CloneUrls =
  { cli :: String
  , https :: String
  , ssh :: String
  }

data ReadmeBlock
  = Heading2 String
  | Heading3 String
  | Paragraph String
  | BulletList (Array String)
  | CodeBlock String String
  | Note String

type SourceFile =
  { path :: String
  , language :: String
  , code :: String
  }

type Publication =
  { kind :: String
  , title :: String
  , date :: String
  , excerpt :: String
  , href :: String
  }

type Project =
  { slug :: String
  , name :: String
  , owner :: String
  , updated :: String
  , blurb :: String
  , languages :: Array Language
  , tags :: Array String
  , license :: String
  , sizeKiB :: Int
  , openIssues :: Int
  , openPulls :: Int
  , releaseCount :: Int
  , stars :: Int
  , forks :: Int
  , watchers :: Int
  , defaultBranch :: String
  , archived :: Boolean
  , htmlUrl :: String
  , clone :: CloneUrls
  , publications :: Array Publication
  , readme :: Array ReadmeBlock
  , repository :: Repository
  }

fromRepository :: Repository -> Project
fromRepository repository =
  let
    language =
      if repository.name == "hydrogen" then "PureScript"
      else if repository.language == "" then "Source"
      else repository.language
    blurb = if repository.description == "" then fallbackBlurb repository.name language else repository.description
    tags = if Array.null repository.topics then [ language ] else repository.topics
  in
    { slug: repository.name
    , name: repository.name
    , owner: "straylight"
    , updated: String.take 10 repository.updatedAt
    , blurb
    , languages: [ { name: language, percent: 100, color: languageColor language } ]
    , tags
    , license: fromMaybe "Unspecified" repository.license
    , sizeKiB: repository.sizeKiB
    , openIssues: repository.openIssues
    , openPulls: repository.openPulls
    , releaseCount: repository.releaseCount
    , stars: repository.stars
    , forks: repository.forks
    , watchers: repository.watchers
    , defaultBranch: repository.defaultBranch
    , archived: repository.archived
    , htmlUrl: repository.htmlUrl
    , clone:
        { cli: "git clone " <> repository.sshUrl
        , https: repository.httpsUrl
        , ssh: repository.sshUrl
        }
    , publications: publicationsFor repository.name
    , readme: overviewFor repository.name blurb repository.defaultBranch
    , repository
    }

fallbackBlurb :: String -> String -> String
fallbackBlurb name language =
  name <> " — a " <> language <> " repository in the Straylight systems forge."

overviewFor :: String -> String -> String -> Array ReadmeBlock
overviewFor name blurb branch = case name of
  "hydrogen" ->
    [ Heading2 "Hydrogen"
    , Paragraph "Hydrogen is the typed PureScript and Halogen UI substrate for Orbital applications. Components carry behavior and design contracts without a JavaScript framework dependency."
    , Heading3 "Current surface"
    , BulletList
        [ "Typed ORBITAL foundation, brand, typography, shell, navigation, and source primitives."
        , "Radix-inspired interaction behavior implemented in Halogen."
        , "Spago is the canonical build path for framework and consumers."
        ]
    , CodeBlock "shell" "nix develop\nnpm test\nnpm run build:orbital"
    , Note ("Repository metadata and source are live from Forgejo branch " <> branch <> ".")
    ]
  "www" ->
    [ Heading2 "ORBITAL // WWW"
    , Paragraph "The web monorepo brings the public product surface, publishing system, middleware, and application UIs together while keeping each project independently buildable."
    , Heading3 "Projects"
    , BulletList
        [ "Orbital product and publishing sites in PureScript."
        , "Orbital CMS and the shared web middleware boundary."
        , "Forge, the source-and-papers reader you are using now."
        ]
    , CodeBlock "shell" "nix develop\ncd projects/orbital-forge\nnpm run check"
    , Note ("Repository metadata and source are live from Forgejo branch " <> branch <> ".")
    ]
  _ ->
    [ Heading2 name
    , Paragraph blurb
    , Note ("Repository metadata and source are live from Forgejo branch " <> branch <> ".")
    ]

publicationsFor :: String -> Array Publication
publicationsFor name = case name of
  "hydrogen" ->
    [ { kind: "Journal"
      , title: "Encoding the design guide"
      , date: "Aug 2026"
      , excerpt: "From visual goldens to closed PureScript component contracts."
      , href: "https://orbital.foo/journal.html"
      }
    ]
  "www" ->
    [ { kind: "Journal"
      , title: "Source and reasons in one place"
      , date: "Aug 2026"
      , excerpt: "Treating the repository and its technical argument as two views of the same project."
      , href: "https://orbital.foo/journal.html"
      }
    ]
  _ -> []

languageColor :: String -> String
languageColor = case _ of
  "C" -> "#555555"
  "C++" -> "#5d7894"
  "CSS" -> "#7957a8"
  "Haskell" -> "#7b5aa6"
  "JavaScript" -> "#b69c3b"
  "Lean" -> "#7a9b89"
  "Nix" -> "#6f86c4"
  "PureScript" -> "#5d7894"
  "Python" -> "#52789c"
  "Rust" -> "#a56b46"
  "Shell" -> "#718b57"
  _ -> "#78909c"

sourceLanguage :: String -> String
sourceLanguage path =
  let
    has suffix = case String.stripSuffix (Pattern suffix) (String.toLower path) of
      Just _ -> true
      Nothing -> false
  in
    if has ".css" then "css"
    else if has ".hs" then "haskell"
    else if has ".html" then "html"
    else if has ".js" || has ".mjs" then "javascript"
    else if has ".json" then "json"
    else if has ".lean" then "lean"
    else if has ".md" || has ".mdx" then "markdown"
    else if has ".nix" then "nix"
    else if has ".purs" then "purescript"
    else if has ".py" then "python"
    else if has ".rs" then "rust"
    else if has ".sql" then "sql"
    else if has ".toml" then "toml"
    else if has ".ts" || has ".tsx" then "typescript"
    else if has ".yaml" || has ".yml" then "yaml"
    else "text"
