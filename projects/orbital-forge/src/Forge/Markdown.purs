-- | A deliberately small Markdown block parser for repository READMEs. It is
-- | native PureScript, deterministic, and covers the conventional document
-- | structure without injecting server-produced HTML into the application.
module Forge.Markdown
  ( MarkdownBlock(..)
  , parseMarkdown
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.Pattern (Pattern(..))

data MarkdownBlock
  = Heading Int String
  | Paragraph String
  | BulletList (Array String)
  | OrderedList (Array String)
  | Quote String
  | CodeFence String String
  | Rule

parseMarkdown :: String -> Array MarkdownBlock
parseMarkdown = parseLines <<< String.split (Pattern "\n")

parseLines :: Array String -> Array MarkdownBlock
parseLines lines = case Array.uncons lines of
  Nothing -> []
  Just { head, tail }
    | String.trim head == "" -> parseLines tail
    | isFence head ->
        let
          language = String.trim (String.drop 3 (String.trim head))
          body = Array.takeWhile (not <<< isFence) tail
          rest = Array.drop 1 (Array.dropWhile (not <<< isFence) tail)
        in Array.cons (CodeFence language (String.joinWith "\n" body)) (parseLines rest)
    | Just heading <- parseHeading head -> Array.cons heading (parseLines tail)
    | Just first <- stripBullet head ->
        let
          more = Array.takeWhile hasBullet tail
          values = Array.cons first (Array.mapMaybe stripBullet more)
        in Array.cons (BulletList values) (parseLines (Array.drop (Array.length more) tail))
    | Just first <- stripOrdered head ->
        let
          more = Array.takeWhile hasOrdered tail
          values = Array.cons first (Array.mapMaybe stripOrdered more)
        in Array.cons (OrderedList values) (parseLines (Array.drop (Array.length more) tail))
    | Just value <- String.stripPrefix (Pattern "> ") (String.trim head) ->
        Array.cons (Quote value) (parseLines tail)
    | isRule head -> Array.cons Rule (parseLines tail)
    | otherwise ->
        let
          more = Array.takeWhile (not <<< isBlockStart) tail
          value = String.joinWith " " (map String.trim (Array.cons head more))
        in Array.cons (Paragraph value) (parseLines (Array.drop (Array.length more) tail))

parseHeading :: String -> Maybe MarkdownBlock
parseHeading value = find 1
  where
  trimmed = String.trim value
  find level
    | level > 6 = Nothing
    | otherwise = case String.stripPrefix (Pattern (String.joinWith "" (Array.replicate level "#") <> " ")) trimmed of
        Just title -> Just (Heading level title)
        Nothing -> find (level + 1)

stripBullet :: String -> Maybe String
stripBullet value =
  let trimmed = String.trim value
  in case String.stripPrefix (Pattern "- ") trimmed of
      Just item -> Just item
      Nothing -> String.stripPrefix (Pattern "* ") trimmed

stripOrdered :: String -> Maybe String
stripOrdered value = Array.findMap strip (Array.range 1 99)
  where
  trimmed = String.trim value
  strip index = String.stripPrefix (Pattern (show index <> ". ")) trimmed

hasBullet :: String -> Boolean
hasBullet value = case stripBullet value of
  Just _ -> true
  Nothing -> false

hasOrdered :: String -> Boolean
hasOrdered value = case stripOrdered value of
  Just _ -> true
  Nothing -> false

isFence :: String -> Boolean
isFence value = String.take 3 (String.trim value) == "```"

isRule :: String -> Boolean
isRule value = Array.elem (String.trim value) [ "---", "***", "___" ]

isBlockStart :: String -> Boolean
isBlockStart value =
  String.trim value == ""
    || isFence value
    || isRule value
    || hasBullet value
    || hasOrdered value
    || String.take 1 (String.trim value) == "#"
    || String.take 1 (String.trim value) == ">"
