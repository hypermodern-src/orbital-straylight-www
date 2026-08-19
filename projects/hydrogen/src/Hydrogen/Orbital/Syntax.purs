-- | Small, native syntax lexer for source surfaces. It intentionally stops at
-- | lexical colour: source text remains source text, rendering stays in
-- | Halogen, and consumers do not need a JavaScript highlighter at runtime.
module Hydrogen.Orbital.Syntax
  ( SyntaxKind(..)
  , SyntaxToken
  , highlightLine
  , syntaxClass
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.CodeUnits as SCU

data SyntaxKind
  = Plain
  | Comment
  | Keyword
  | TypeName
  | StringLiteral
  | NumberLiteral
  | Operator
  | Punctuation
  | DiffAdded
  | DiffRemoved
  | DiffMeta

derive instance eqSyntaxKind :: Eq SyntaxKind

instance showSyntaxKind :: Show SyntaxKind where
  show = syntaxClass

type SyntaxToken =
  { kind :: SyntaxKind
  , text :: String
  }

syntaxClass :: SyntaxKind -> String
syntaxClass = case _ of
  Plain -> "orbital-syntax-plain"
  Comment -> "orbital-syntax-comment"
  Keyword -> "orbital-syntax-keyword"
  TypeName -> "orbital-syntax-type"
  StringLiteral -> "orbital-syntax-string"
  NumberLiteral -> "orbital-syntax-number"
  Operator -> "orbital-syntax-operator"
  Punctuation -> "orbital-syntax-punctuation"
  DiffAdded -> "orbital-syntax-diff-added"
  DiffRemoved -> "orbital-syntax-diff-removed"
  DiffMeta -> "orbital-syntax-diff-meta"

highlightLine :: String -> String -> Array SyntaxToken
highlightLine language source
  | String.toLower language == "diff" = [ token (diffKind source) (if source == "" then " " else source) ]
  | otherwise = coalesce (lexLine (String.toLower language) source)

diffKind :: String -> SyntaxKind
diffKind source
  | String.take 2 source == "@@" = DiffMeta
  | String.take 4 source == "diff" = DiffMeta
  | String.take 5 source == "index" = DiffMeta
  | String.take 3 source == "+++" = DiffMeta
  | String.take 3 source == "---" = DiffMeta
  | String.take 1 source == "+" = DiffAdded
  | String.take 1 source == "-" = DiffRemoved
  | otherwise = Plain

lexLine :: String -> String -> Array SyntaxToken
lexLine language source
  | source == "" = [ token Plain " " ]
  | otherwise = go source
  where
  go remaining = case SCU.uncons remaining of
    Nothing -> []
    Just { head }
      | isCommentStart language remaining -> [ token Comment remaining ]
      | head == '"' || head == '\'' || head == '`' ->
          let quoted = takeQuoted head remaining
          in Array.cons (token StringLiteral quoted.taken) (go quoted.rest)
      | isSpace head -> consume Plain isSpace remaining
      | isDigit head -> consume NumberLiteral isNumberPart remaining
      | isIdentifierStart head ->
          let word = SCU.takeWhile isIdentifierPart remaining
          in Array.cons (token (wordKind language word) word) (go (SCU.drop (String.length word) remaining))
      | isOperator head -> consume Operator isOperator remaining
      | otherwise -> consume Punctuation isPunctuation remaining

  consume kind predicate remaining =
    let
      taken = SCU.takeWhile predicate remaining
      count = max 1 (String.length taken)
      value = if taken == "" then SCU.take 1 remaining else taken
    in
      Array.cons (token kind value) (go (SCU.drop count remaining))

token :: SyntaxKind -> String -> SyntaxToken
token kind text = { kind, text }

coalesce :: Array SyntaxToken -> Array SyntaxToken
coalesce = Array.foldl append []
  where
  append result next = case Array.unsnoc result of
    Just { init, last } | last.kind == next.kind -> init <> [ last { text = last.text <> next.text } ]
    _ -> result <> [ next ]

takeQuoted :: Char -> String -> { taken :: String, rest :: String }
takeQuoted quote source =
  let result = walk false 1 (SCU.drop 1 source)
  in
    { taken: SCU.take result source
    , rest: SCU.drop result source
    }
  where
  walk escaped count remaining = case SCU.uncons remaining of
    Nothing -> count
    Just { head, tail }
      | escaped -> walk false (count + 1) tail
      | head == '\\' -> walk true (count + 1) tail
      | head == quote -> count + 1
      | otherwise -> walk false (count + 1) tail

wordKind :: String -> String -> SyntaxKind
wordKind language word
  | Array.elem word (keywords language) = Keyword
  | Array.elem word commonLiterals = NumberLiteral
  | startsUpper word = TypeName
  | otherwise = Plain

keywords :: String -> Array String
keywords language = commonKeywords <> case language of
  "purescript" -> [ "ado", "class", "data", "derive", "do", "else", "foreign", "forall", "if", "import", "in", "infix", "instance", "let", "module", "newtype", "of", "then", "type", "where" ]
  "haskell" -> [ "class", "data", "deriving", "do", "else", "foreign", "forall", "if", "import", "in", "infix", "instance", "let", "module", "newtype", "of", "then", "type", "where" ]
  "javascript" -> jsKeywords
  "typescript" -> jsKeywords <> [ "abstract", "declare", "enum", "implements", "interface", "keyof", "namespace", "private", "protected", "public", "readonly", "type" ]
  "rust" -> [ "as", "async", "await", "const", "crate", "dyn", "enum", "extern", "fn", "impl", "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "self", "struct", "trait", "type", "unsafe", "use", "where" ]
  "python" -> [ "and", "as", "assert", "async", "await", "class", "def", "del", "elif", "except", "finally", "from", "global", "import", "in", "is", "lambda", "nonlocal", "not", "or", "pass", "raise", "try", "with", "yield" ]
  "lean" -> [ "abbrev", "axiom", "class", "def", "deriving", "do", "end", "example", "import", "inductive", "instance", "namespace", "opaque", "open", "partial", "private", "protected", "structure", "theorem", "universe", "variable", "where" ]
  "nix" -> [ "assert", "builtins", "else", "if", "import", "in", "inherit", "let", "or", "rec", "then", "with" ]
  "css" -> [ "var", "calc", "color-mix", "inherit", "initial", "unset" ]
  "sql" -> [ "alter", "and", "as", "asc", "by", "create", "delete", "desc", "distinct", "drop", "from", "group", "having", "insert", "into", "join", "limit", "not", "null", "on", "or", "order", "select", "set", "table", "union", "update", "values", "where" ]
  _ -> []

commonKeywords :: Array String
commonKeywords = [ "break", "case", "catch", "continue", "default", "else", "export", "extends", "finally", "for", "if", "new", "return", "switch", "throw", "try", "while" ]

jsKeywords :: Array String
jsKeywords = [ "async", "await", "const", "delete", "function", "import", "in", "instanceof", "let", "of", "static", "this", "typeof", "var", "void", "yield" ]

commonLiterals :: Array String
commonLiterals = [ "false", "null", "true", "undefined", "Nothing", "Just", "Left", "Right" ]

isCommentStart :: String -> String -> Boolean
isCommentStart language source =
  Array.any (\prefix -> String.take (String.length prefix) source == prefix) (commentPrefixes language)

commentPrefixes :: String -> Array String
commentPrefixes = case _ of
  "purescript" -> [ "--" ]
  "haskell" -> [ "--" ]
  "sql" -> [ "--" ]
  "lean" -> [ "--" ]
  "python" -> [ "#" ]
  "nix" -> [ "#" ]
  "shell" -> [ "#" ]
  "bash" -> [ "#" ]
  "css" -> [ "/*", "*" ]
  "html" -> [ "<!--" ]
  "markdown" -> [ "<!--" ]
  language | Array.elem language [ "c", "cpp", "c++", "java", "javascript", "typescript", "rust" ] -> [ "//", "/*", "*" ]
  _ -> []

isSpace :: Char -> Boolean
isSpace value = Array.elem value [ ' ', '\t', '\r' ]

isDigit :: Char -> Boolean
isDigit value = value >= '0' && value <= '9'

isAsciiLetter :: Char -> Boolean
isAsciiLetter value = (value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z')

isIdentifierStart :: Char -> Boolean
isIdentifierStart value = isAsciiLetter value || value == '_' || value == '$'

isIdentifierPart :: Char -> Boolean
isIdentifierPart value = isIdentifierStart value || isDigit value || value == '\'' || value == '-'

isNumberPart :: Char -> Boolean
isNumberPart value = isDigit value || Array.elem value [ '.', '_', 'a', 'b', 'c', 'd', 'e', 'f', 'A', 'B', 'C', 'D', 'E', 'F', 'o', 'x' ]

isOperator :: Char -> Boolean
isOperator value = Array.elem value [ '+', '-', '*', '/', '%', '=', '<', '>', '!', '&', '|', '^', '~', ':', '?', '.' ]

isPunctuation :: Char -> Boolean
isPunctuation value = Array.elem value [ '(', ')', '[', ']', '{', '}', ',', ';' ]

startsUpper :: String -> Boolean
startsUpper value = case SCU.uncons value of
  Just { head } -> head >= 'A' && head <= 'Z'
  Nothing -> false
