-- | Typed, public Forgejo API boundary. The application deliberately uses
-- | Forgejo's own resource model rather than translating it into GitHub terms.
module Forge.Forgejo
  ( Repository
  , ContentEntry
  , Branch
  , Tag
  , Commit
  , CommitDetail
  , CommitFile
  , CommitStats
  , TreeEntry
  , TreeListing
  , LanguageStat
  , Label
  , Issue
  , PullRequest
  , Release
  , listRepositories
  , listContents
  , listBranches
  , listTags
  , listCommits
  , listTree
  , listLanguages
  , readCommit
  , readCommitDiff
  , commitPatchUrl
  , listIssues
  , listPullRequests
  , listReleases
  , readRaw
  , rawUrl
  , encodeComponent
  , decodeComponent
  , encodePath
  , decodePath
  ) where

import Prelude

import Affjax.ResponseFormat as ResponseFormat
import Affjax.Web as AX
import Data.Argonaut.Decode (class DecodeJson, decodeJson, printJsonDecodeError)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe)
import Data.String as String
import Data.String.CodeUnits as SCU
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff)
import Foreign.Object as Object

type Repository =
  { name :: String
  , fullName :: String
  , description :: String
  , defaultBranch :: String
  , updatedAt :: String
  , language :: String
  , sizeKiB :: Int
  , openIssues :: Int
  , openPulls :: Int
  , releaseCount :: Int
  , stars :: Int
  , forks :: Int
  , watchers :: Int
  , topics :: Array String
  , license :: Maybe String
  , htmlUrl :: String
  , httpsUrl :: String
  , sshUrl :: String
  , archived :: Boolean
  }

type ContentEntry =
  { name :: String
  , path :: String
  , kind :: String
  , size :: Int
  , sha :: String
  , lastCommitSha :: Maybe String
  , lastCommitWhen :: Maybe String
  , downloadUrl :: Maybe String
  , htmlUrl :: String
  }

type Branch =
  { name :: String
  , sha :: String
  , message :: String
  , author :: String
  , updatedAt :: String
  , protected :: Boolean
  }

type Tag =
  { name :: String
  , message :: String
  , sha :: String
  , createdAt :: String
  , zipUrl :: String
  , tarUrl :: String
  }

type Commit =
  { sha :: String
  , shortSha :: String
  , message :: String
  , author :: String
  , createdAt :: String
  , htmlUrl :: String
  }

type CommitStats =
  { additions :: Int
  , deletions :: Int
  , total :: Int
  }

type CommitFile =
  { path :: String
  , status :: String
  }

type CommitDetail =
  { sha :: String
  , shortSha :: String
  , message :: String
  , author :: String
  , committer :: String
  , createdAt :: String
  , htmlUrl :: String
  , parents :: Array String
  , files :: Array CommitFile
  , stats :: CommitStats
  , verified :: Boolean
  , verificationReason :: String
  }

type TreeEntry =
  { path :: String
  , kind :: String
  , size :: Int
  }

type TreeListing =
  { entries :: Array TreeEntry
  , totalCount :: Int
  , truncated :: Boolean
  }

type LanguageStat =
  { name :: String
  , bytes :: Int
  }

type Label =
  { name :: String
  , color :: String
  }

type Issue =
  { number :: Int
  , title :: String
  , state :: String
  , htmlUrl :: String
  , createdAt :: String
  , updatedAt :: String
  , comments :: Int
  , author :: String
  , labels :: Array Label
  }

type PullRequest =
  { number :: Int
  , title :: String
  , state :: String
  , htmlUrl :: String
  , createdAt :: String
  , updatedAt :: String
  , author :: String
  , labels :: Array Label
  }

type Release =
  { tagName :: String
  , name :: String
  , body :: String
  , draft :: Boolean
  , prerelease :: Boolean
  , createdAt :: String
  , htmlUrl :: String
  , tarUrl :: String
  , zipUrl :: String
  }

type LicenseWire = { name :: String }

newtype RepositoryWire = RepositoryWire
  { name :: String
  , full_name :: String
  , description :: String
  , default_branch :: String
  , updated_at :: String
  , language :: String
  , size :: Int
  , open_issues_count :: Int
  , open_pr_counter :: Int
  , release_counter :: Int
  , stars_count :: Int
  , forks_count :: Int
  , watchers_count :: Int
  , topics :: Array String
  , license :: Maybe LicenseWire
  , html_url :: String
  , clone_url :: String
  , ssh_url :: String
  , archived :: Boolean
  }

derive newtype instance decodeRepositoryWire :: DecodeJson RepositoryWire

newtype ContentEntryWire = ContentEntryWire
  { name :: String
  , path :: String
  , type :: String
  , size :: Int
  , sha :: String
  , last_commit_sha :: Maybe String
  , last_commit_when :: Maybe String
  , download_url :: Maybe String
  , html_url :: String
  }

derive newtype instance decodeContentEntryWire :: DecodeJson ContentEntryWire

newtype SignatureWire = SignatureWire
  { name :: String
  , username :: String
  }

derive newtype instance decodeSignatureWire :: DecodeJson SignatureWire

newtype BranchCommitWire = BranchCommitWire
  { id :: String
  , message :: String
  , author :: SignatureWire
  , timestamp :: String
  }

derive newtype instance decodeBranchCommitWire :: DecodeJson BranchCommitWire

newtype BranchWire = BranchWire
  { name :: String
  , commit :: BranchCommitWire
  , protected :: Boolean
  }

derive newtype instance decodeBranchWire :: DecodeJson BranchWire

newtype TagCommitWire = TagCommitWire
  { sha :: String
  , created :: String
  }

derive newtype instance decodeTagCommitWire :: DecodeJson TagCommitWire

newtype TagWire = TagWire
  { name :: String
  , message :: String
  , commit :: TagCommitWire
  , zipball_url :: String
  , tarball_url :: String
  }

derive newtype instance decodeTagWire :: DecodeJson TagWire

newtype CommitAuthorWire = CommitAuthorWire
  { name :: String
  , date :: String
  }

derive newtype instance decodeCommitAuthorWire :: DecodeJson CommitAuthorWire

newtype CommitPayloadWire = CommitPayloadWire
  { message :: String
  , author :: CommitAuthorWire
  }

derive newtype instance decodeCommitPayloadWire :: DecodeJson CommitPayloadWire

newtype CommitWire = CommitWire
  { sha :: String
  , html_url :: String
  , commit :: CommitPayloadWire
  }

derive newtype instance decodeCommitWire :: DecodeJson CommitWire

newtype CommitVerificationWire = CommitVerificationWire
  { verified :: Boolean
  , reason :: String
  }

derive newtype instance decodeCommitVerificationWire :: DecodeJson CommitVerificationWire

newtype CommitDetailPayloadWire = CommitDetailPayloadWire
  { message :: String
  , author :: CommitAuthorWire
  , committer :: CommitAuthorWire
  , verification :: CommitVerificationWire
  }

derive newtype instance decodeCommitDetailPayloadWire :: DecodeJson CommitDetailPayloadWire

newtype CommitParentWire = CommitParentWire { sha :: String }

derive newtype instance decodeCommitParentWire :: DecodeJson CommitParentWire

newtype CommitFileWire = CommitFileWire
  { filename :: String
  , status :: String
  }

derive newtype instance decodeCommitFileWire :: DecodeJson CommitFileWire

newtype CommitStatsWire = CommitStatsWire
  { additions :: Int
  , deletions :: Int
  , total :: Int
  }

derive newtype instance decodeCommitStatsWire :: DecodeJson CommitStatsWire

newtype CommitDetailWire = CommitDetailWire
  { sha :: String
  , html_url :: String
  , created :: String
  , commit :: CommitDetailPayloadWire
  , parents :: Array CommitParentWire
  , files :: Array CommitFileWire
  , stats :: CommitStatsWire
  }

derive newtype instance decodeCommitDetailWire :: DecodeJson CommitDetailWire

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

newtype LanguageStatisticsWire = LanguageStatisticsWire (Object.Object Int)

derive newtype instance decodeLanguageStatisticsWire :: DecodeJson LanguageStatisticsWire

newtype UserWire = UserWire { login :: String }

derive newtype instance decodeUserWire :: DecodeJson UserWire

newtype LabelWire = LabelWire
  { name :: String
  , color :: String
  }

derive newtype instance decodeLabelWire :: DecodeJson LabelWire

newtype IssueWire = IssueWire
  { number :: Int
  , title :: String
  , state :: String
  , html_url :: String
  , created_at :: String
  , updated_at :: String
  , comments :: Int
  , user :: UserWire
  , labels :: Array LabelWire
  }

derive newtype instance decodeIssueWire :: DecodeJson IssueWire

newtype PullRequestWire = PullRequestWire
  { number :: Int
  , title :: String
  , state :: String
  , html_url :: String
  , created_at :: String
  , updated_at :: String
  , user :: UserWire
  , labels :: Array LabelWire
  }

derive newtype instance decodePullRequestWire :: DecodeJson PullRequestWire

newtype ReleaseWire = ReleaseWire
  { tag_name :: String
  , name :: String
  , body :: String
  , draft :: Boolean
  , prerelease :: Boolean
  , created_at :: String
  , html_url :: String
  , tarball_url :: String
  , zipball_url :: String
  }

derive newtype instance decodeReleaseWire :: DecodeJson ReleaseWire

apiBase :: String
apiBase = "https://git.s4.gl/api/v1"

repositoryBase :: Repository -> String
repositoryBase repository = apiBase <> "/repos/straylight/" <> encodeComponent repository.name

listRepositories :: Aff (Either String (Array Repository))
listRepositories = map (map (map fromRepositoryWire)) $ getJson (apiBase <> "/orgs/straylight/repos?limit=50")

listContents :: Repository -> String -> String -> Aff (Either String (Array ContentEntry))
listContents repository ref path =
  let suffix = if path == "" then "" else "/" <> encodePath path
  in map (map (map fromContentEntryWire)) $ getJson
      (repositoryBase repository <> "/contents" <> suffix <> "?ref=" <> encodeComponent ref)

listBranches :: Repository -> Aff (Either String (Array Branch))
listBranches repository = map (map (map fromBranchWire)) $ getJson
  (repositoryBase repository <> "/branches?limit=100")

listTags :: Repository -> Aff (Either String (Array Tag))
listTags repository = map (map (map fromTagWire)) $ getJson
  (repositoryBase repository <> "/tags?limit=100")

listCommits :: Repository -> String -> String -> Aff (Either String (Array Commit))
listCommits repository ref path =
  let pathQuery = if path == "" then "" else "&path=" <> encodeComponent path
  in map (map (map fromCommitWire)) $ getJson
      (repositoryBase repository <> "/commits?sha=" <> encodeComponent ref <> pathQuery <> "&limit=50")

listTree :: Repository -> String -> Aff (Either String TreeListing)
listTree repository ref = map (map fromTreeWire) $ getJson
  (repositoryBase repository <> "/git/trees/" <> encodeComponent ref <> "?recursive=true&per_page=1000")

listLanguages :: Repository -> Aff (Either String (Array LanguageStat))
listLanguages repository = map (map fromLanguageStatisticsWire) $ getJson
  (repositoryBase repository <> "/languages")

readCommit :: Repository -> String -> Aff (Either String CommitDetail)
readCommit repository sha = map (map fromCommitDetailWire) $ getJson
  (repositoryBase repository <> "/git/commits/" <> encodeComponent sha <> "?stat=true&files=true&verification=true")

readCommitDiff :: Repository -> String -> Aff (Either String String)
readCommitDiff repository sha = getText
  (repositoryBase repository <> "/git/commits/" <> encodeComponent sha <> ".diff")

commitPatchUrl :: Repository -> String -> String
commitPatchUrl repository sha =
  repositoryBase repository <> "/git/commits/" <> encodeComponent sha <> ".patch"

listIssues :: Repository -> Aff (Either String (Array Issue))
listIssues repository = map (map (map fromIssueWire)) $ getJson
  (repositoryBase repository <> "/issues?state=all&limit=50")

listPullRequests :: Repository -> Aff (Either String (Array PullRequest))
listPullRequests repository = map (map (map fromPullRequestWire)) $ getJson
  (repositoryBase repository <> "/pulls?state=all&limit=50")

listReleases :: Repository -> Aff (Either String (Array Release))
listReleases repository = map (map (map fromReleaseWire)) $ getJson
  (repositoryBase repository <> "/releases?limit=50")

readRaw :: Repository -> String -> String -> Aff (Either String String)
readRaw repository ref path = do
  getText (rawUrl repository ref path)

getText :: String -> Aff (Either String String)
getText url = do
  result <- AX.get ResponseFormat.string url
  pure case result of
    Left error -> Left (AX.printError error)
    Right response -> Right response.body

rawUrl :: Repository -> String -> String -> String
rawUrl repository ref path =
  repositoryBase repository <> "/raw/" <> encodePath path <> "?ref=" <> encodeComponent ref

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
  , openPulls: repository.open_pr_counter
  , releaseCount: repository.release_counter
  , stars: repository.stars_count
  , forks: repository.forks_count
  , watchers: repository.watchers_count
  , topics: repository.topics
  , license: map _.name repository.license
  , htmlUrl: repository.html_url
  , httpsUrl: repository.clone_url
  , sshUrl: repository.ssh_url
  , archived: repository.archived
  }

fromContentEntryWire :: ContentEntryWire -> ContentEntry
fromContentEntryWire (ContentEntryWire entry) =
  { name: entry.name
  , path: entry.path
  , kind: entry.type
  , size: entry.size
  , sha: entry.sha
  , lastCommitSha: entry.last_commit_sha
  , lastCommitWhen: entry.last_commit_when
  , downloadUrl: entry.download_url
  , htmlUrl: entry.html_url
  }

fromBranchWire :: BranchWire -> Branch
fromBranchWire (BranchWire branch) = case branch.commit of
  BranchCommitWire commit -> case commit.author of
    SignatureWire author ->
      { name: branch.name
      , sha: commit.id
      , message: firstLine commit.message
      , author: if author.username == "" then author.name else author.username
      , updatedAt: commit.timestamp
      , protected: branch.protected
      }

fromTagWire :: TagWire -> Tag
fromTagWire (TagWire tag) = case tag.commit of
  TagCommitWire commit ->
    { name: tag.name
    , message: firstLine tag.message
    , sha: commit.sha
    , createdAt: commit.created
    , zipUrl: tag.zipball_url
    , tarUrl: tag.tarball_url
    }

fromCommitWire :: CommitWire -> Commit
fromCommitWire (CommitWire value) = case value.commit of
  CommitPayloadWire commit -> case commit.author of
    CommitAuthorWire author ->
      { sha: value.sha
      , shortSha: String.take 7 value.sha
      , message: firstLine commit.message
      , author: author.name
      , createdAt: author.date
      , htmlUrl: value.html_url
      }

fromCommitDetailWire :: CommitDetailWire -> CommitDetail
fromCommitDetailWire (CommitDetailWire value) = case value.commit, value.stats of
  CommitDetailPayloadWire commit, CommitStatsWire stats -> case commit.author, commit.committer, commit.verification of
    CommitAuthorWire author, CommitAuthorWire committer, CommitVerificationWire verification ->
      { sha: value.sha
      , shortSha: String.take 7 value.sha
      , message: commit.message
      , author: author.name
      , committer: committer.name
      , createdAt: value.created
      , htmlUrl: value.html_url
      , parents: map (\(CommitParentWire parent) -> parent.sha) value.parents
      , files: map (\(CommitFileWire file) -> { path: file.filename, status: file.status }) value.files
      , stats: { additions: stats.additions, deletions: stats.deletions, total: stats.total }
      , verified: verification.verified
      , verificationReason: verification.reason
      }

fromTreeWire :: TreeWire -> TreeListing
fromTreeWire (TreeWire tree) =
  { entries: map (\(TreeEntryWire entry) -> { path: entry.path, kind: entry.type, size: entry.size }) tree.tree
  , totalCount: tree.total_count
  , truncated: tree.truncated
  }

fromLanguageStatisticsWire :: LanguageStatisticsWire -> Array LanguageStat
fromLanguageStatisticsWire (LanguageStatisticsWire statistics) =
  (Object.toUnfoldable statistics :: Array (Tuple String Int))
    # map (\(Tuple name bytes) -> { name, bytes })
    # Array.sortBy (\left right -> compare right.bytes left.bytes)

fromLabelWire :: LabelWire -> Label
fromLabelWire (LabelWire label) = { name: label.name, color: label.color }

fromIssueWire :: IssueWire -> Issue
fromIssueWire (IssueWire issue) = case issue.user of
  UserWire user ->
    { number: issue.number
    , title: issue.title
    , state: issue.state
    , htmlUrl: issue.html_url
    , createdAt: issue.created_at
    , updatedAt: issue.updated_at
    , comments: issue.comments
    , author: user.login
    , labels: map fromLabelWire issue.labels
    }

fromPullRequestWire :: PullRequestWire -> PullRequest
fromPullRequestWire (PullRequestWire pull) = case pull.user of
  UserWire user ->
    { number: pull.number
    , title: pull.title
    , state: pull.state
    , htmlUrl: pull.html_url
    , createdAt: pull.created_at
    , updatedAt: pull.updated_at
    , author: user.login
    , labels: map fromLabelWire pull.labels
    }

fromReleaseWire :: ReleaseWire -> Release
fromReleaseWire (ReleaseWire release) =
  { tagName: release.tag_name
  , name: release.name
  , body: release.body
  , draft: release.draft
  , prerelease: release.prerelease
  , createdAt: release.created_at
  , htmlUrl: release.html_url
  , tarUrl: release.tarball_url
  , zipUrl: release.zipball_url
  }

firstLine :: String -> String
firstLine = SCU.takeWhile (_ /= '\n')

encodePath :: String -> String
encodePath = String.joinWith "/" <<< map encodeComponent <<< String.split (Pattern "/")

decodePath :: String -> String
decodePath = String.joinWith "/" <<< map decodeComponent <<< String.split (Pattern "/")

foreign import encodeComponent :: String -> String
foreign import decodeComponent :: String -> String
