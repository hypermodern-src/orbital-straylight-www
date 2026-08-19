module Forge.Forgejo
  ( Repository
  , SourceEntry
  , TreeListing
  , listRepositories
  , listSource
  , readSource
  ) where

import Prelude

import Affjax.ResponseFormat as ResponseFormat
import Affjax.Web as AX
import Data.Argonaut.Decode (class DecodeJson, decodeJson, printJsonDecodeError)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Effect.Aff (Aff)

type Repository =
  { name :: String
  , fullName :: String
  , description :: String
  , defaultBranch :: String
  , updatedAt :: String
  , language :: String
  , sizeKiB :: Int
  , openIssues :: Int
  , topics :: Array String
  , license :: Maybe String
  , htmlUrl :: String
  , httpsUrl :: String
  , sshUrl :: String
  , archived :: Boolean
  }

type SourceEntry =
  { path :: String
  , size :: Int
  }

type TreeListing =
  { files :: Array SourceEntry
  , totalCount :: Int
  , truncated :: Boolean
  }

type LicenseWire =
  { name :: String
  }

newtype RepositoryWire = RepositoryWire
  { name :: String
  , full_name :: String
  , description :: String
  , default_branch :: String
  , updated_at :: String
  , language :: String
  , size :: Int
  , open_issues_count :: Int
  , topics :: Array String
  , license :: Maybe LicenseWire
  , html_url :: String
  , clone_url :: String
  , ssh_url :: String
  , archived :: Boolean
  }

derive newtype instance decodeRepositoryWire :: DecodeJson RepositoryWire

newtype TreeEntryWire = TreeEntryWire
  { path :: String
  , type :: String
  , size :: Int
  }

derive newtype instance decodeTreeEntryWire :: DecodeJson TreeEntryWire

newtype TreeWire = TreeWire
  { tree :: Array TreeEntryWire
  , total_count :: Int
  , truncated :: Boolean
  }

derive newtype instance decodeTreeWire :: DecodeJson TreeWire

apiBase :: String
apiBase = "https://git.s4.gl/api/v1"

listRepositories :: Aff (Either String (Array Repository))
listRepositories = do
  result <- getJson (apiBase <> "/orgs/straylight/repos?limit=50")
  pure case result of
    Left error -> Left error
    Right repositories -> Right (map fromRepositoryWire repositories)

listSource :: Repository -> Aff (Either String TreeListing)
listSource repository = do
  let
    path =
      "/repos/straylight/" <> encodeComponent repository.name
        <> "/git/trees/" <> encodeComponent repository.defaultBranch
        <> "?recursive=true&per_page=1000"
  result <- getJson (apiBase <> path)
  pure case result of
    Left error -> Left error
    Right (TreeWire response) ->
      let
        files = response.tree
          # Array.mapMaybe fromTreeEntryWire
          # Array.filter isReadableSource
          # Array.sortBy (\left right -> compare left.path right.path)
          # Array.take 400
      in
        Right
          { files
          , totalCount: response.total_count
          , truncated: response.truncated || Array.length files == 400
          }

readSource :: Repository -> SourceEntry -> Aff (Either String String)
readSource repository entry = do
  let
    url = apiBase
      <> "/repos/straylight/" <> encodeComponent repository.name
      <> "/raw/" <> encodePath entry.path
      <> "?ref=" <> encodeComponent repository.defaultBranch
  result <- AX.get ResponseFormat.string url
  pure case result of
    Left error -> Left (AX.printError error)
    Right response -> Right response.body

getJson :: forall a. DecodeJson a => String -> Aff (Either String a)
getJson url = do
  result <- AX.get ResponseFormat.json url
  pure case result of
    Left error -> Left (AX.printError error)
    Right response -> case decodeJson response.body of
      Left error -> Left (printJsonDecodeError error)
      Right value -> Right value

fromRepositoryWire :: RepositoryWire -> Repository
fromRepositoryWire (RepositoryWire repository) =
  { name: repository.name
  , fullName: repository.full_name
  , description: repository.description
  , defaultBranch: repository.default_branch
  , updatedAt: repository.updated_at
  , language: repository.language
  , sizeKiB: repository.size
  , openIssues: repository.open_issues_count
  , topics: repository.topics
  , license: map _.name repository.license
  , htmlUrl: repository.html_url
  , httpsUrl: repository.clone_url
  , sshUrl: repository.ssh_url
  , archived: repository.archived
  }

fromTreeEntryWire :: TreeEntryWire -> Maybe SourceEntry
fromTreeEntryWire (TreeEntryWire entry)
  | entry.type == "blob" = Just { path: entry.path, size: entry.size }
  | otherwise = Nothing

isReadableSource :: SourceEntry -> Boolean
isReadableSource entry =
  entry.size <= 300000
    && (Array.elem (String.toLower entry.path) readableNames || Array.any hasSuffix readableSuffixes)
  where
  hasSuffix suffix = case String.stripSuffix (Pattern suffix) (String.toLower entry.path) of
    Just _ -> true
    Nothing -> false

readableNames :: Array String
readableNames =
  [ ".env.example"
  , ".gitignore"
  , ".gitmodules"
  , ".ignore"
  , "dockerfile"
  , "justfile"
  , "license"
  , "makefile"
  ]

readableSuffixes :: Array String
readableSuffixes =
  [ ".c", ".cc", ".conf", ".cpp", ".css", ".cxx"
  , ".dhall", ".el", ".elm", ".graphql", ".h", ".hpp", ".hs"
  , ".html", ".java", ".js", ".json", ".jsx", ".lean", ".lock"
  , ".lua", ".md", ".mdx", ".mjs", ".nix", ".org", ".proto"
  , ".purs", ".py", ".rb", ".rs", ".scss", ".sh", ".sql", ".svg"
  , ".tex", ".toml", ".ts", ".tsx", ".txt", ".typ", ".xml", ".yaml", ".yml"
  ]

encodePath :: String -> String
encodePath = String.joinWith "/" <<< map encodeComponent <<< String.split (Pattern "/")

foreign import encodeComponent :: String -> String
