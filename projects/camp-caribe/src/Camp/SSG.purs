module Camp.SSG (main) where

import Prelude

import Camp.Content (Page, SiteData, decodeSiteData)
import Camp.SSG.Node (contentPath, mkdirp, outputDirectory, readJsonFile, writeTextFile)
import Camp.Site (Language(..), pageSlug, renderPage)
import Data.Either (Either(..))
import Data.Foldable (traverse_)
import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (throw)

main :: Effect Unit
main = do
  output <- outputDirectory
  content <- contentPath >>= readJsonFile
  siteData <- case decodeSiteData content of
    Left error -> throw ("camp-caribe: invalid content/site.json: " <> error)
    Right value -> pure value
  mkdirp output
  traverse_ (writeLanguage output siteData) [ English, Spanish ]
  log "camp-caribe: rendered 10 Hydrogen routes"

writeLanguage :: String -> SiteData -> Language -> Effect Unit
writeLanguage output siteData language =
  traverse_ (writePage output siteData language) siteData.pages

writePage :: String -> SiteData -> Language -> Page -> Effect Unit
writePage output siteData language page = do
  let
    slug = pageSlug language page
    directory = if slug == "" then output else output <> "/" <> slug
    destination = directory <> "/index.html"
  mkdirp directory
  writeTextFile destination (renderPage siteData language page)
  log ("camp-caribe: " <> destination)
