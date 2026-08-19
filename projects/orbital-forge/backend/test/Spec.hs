{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (unless)
import Orbital.Forge.Application (originAllowed, stripProxyPrefix)
import Orbital.Forge.Backend.Forgejo (allowedForgejoPath)
import System.Exit (exitFailure)

main :: IO ()
main = do
  check "strips the stable API prefix"
    (stripProxyPrefix ["api", "forge", "v1", "repos", "straylight", "www"]
      == Just ["repos", "straylight", "www"])
  check "rejects a different API prefix"
    (stripProxyPrefix ["api", "v1", "repos"] == Nothing)
  check "allows the configured organization repository listing"
    (allowedForgejoPath "straylight" ["orgs", "straylight", "repos"])
  check "allows reads below a configured organization repository"
    (allowedForgejoPath "straylight" ["repos", "straylight", "www", "raw", "README.md"])
  check "rejects a different organization"
    (not $ allowedForgejoPath "straylight" ["repos", "root", "private", "contents"])
  check "rejects traversal segments"
    (not $ allowedForgejoPath "straylight" ["repos", "straylight", "www", "..", "private"])
  check "allows the stable Vercel origin"
    (originAllowed [] "https://orbital-forge-iota.vercel.app")
  check "allows Vercel preview origins"
    (originAllowed [] "https://orbital-forge-abcd-b7r6s-projects.vercel.app")
  check "does not allow lookalike Vercel domains"
    (not $ originAllowed [] "https://orbital-forge-evil.vercel.app.attacker.example")
  check "allows explicit origins"
    (originAllowed ["https://forge.example.internal"] "https://forge.example.internal")
  check "allows local development"
    (originAllowed [] "http://127.0.0.1:4173")
  putStrLn "orbital-forge-backend-test: all checks passed"

check :: String -> Bool -> IO ()
check label condition = unless condition $ do
  putStrLn $ "FAIL: " <> label
  exitFailure
