module Ponce.SSG (main) where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (traverse_)
import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (throw)
import Ponce.Content (Page, SiteData, decodeSiteData)
import Ponce.SSG.Node (contentPath, mkdirp, outputDirectory, readJsonFile, writeTextFile)
import Ponce.Site (Language(..), pageSlug, renderPage)

main :: Effect Unit
main = do
  output <- outputDirectory
  content <- contentPath >>= readJsonFile
  siteData <- case decodeSiteData content of
    Left error -> throw ("ponce-speedway: invalid content/site.json: " <> error)
    Right value -> pure value
  mkdirp output
  traverse_ (writeLanguage output siteData) [ English, Spanish ]
  log "ponce-speedway: rendered 14 Hydrogen routes"

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
  log ("ponce-speedway: " <> destination)
