-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                           // straylight-api // api // openapi
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- OpenAPI 3.1.0 spec generation for all Straylight product APIs.
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.OpenApi
    ( -- * OpenAPI Specs
      cacheOpenApi
    , buildOpenApi
    , convergeOpenApi
    , confirmOpenApi
    , forgeOpenApi
    , publishOpenApi
    , codeOpenApi
    , workOpenApi
    , proxyOpenApi
    , boostOpenApi
    
      -- * Combined
    , allOpenApi
    
      -- * Helpers
    , ProductSpec (..)
    , allProductSpecs
    ) where

import Control.Lens
import Data.Aeson (encode)
import Data.ByteString.Lazy (ByteString)
import Data.OpenApi
import Data.Proxy
import Data.Text (Text)
import Servant.OpenApi

import Api.Sensenet.Cache (CacheAPI)
import Api.Sensenet.Build (BuildAPI)
import Api.Sensenet.Converge (ConvergeAPI)
import Api.Sensenet.Confirm (ConfirmAPI)
import Api.Sensenet.Forge (ForgeAPI)
import Api.Sensenet.Publish (PublishAPI)
import Api.Omega.Code (CodeAPI)
import Api.Omega.Work (WorkAPI)
import Api.Omega.Proxy (ProxyAPI)
import Api.Omega.Boost (BoostAPI)


-- ═══════════════════════════════════════════════════════════════════════════
-- // product spec //
-- ═══════════════════════════════════════════════════════════════════════════

data ProductSpec = ProductSpec
    { specName :: Text
    , specTitle :: Text
    , specDescription :: Text
    , specVersion :: Text
    , specPath :: Text
    , specOpenApi :: OpenApi
    }


-- ═══════════════════════════════════════════════════════════════════════════
-- // sensenet specs //
-- ═══════════════════════════════════════════════════════════════════════════

cacheOpenApi :: OpenApi
cacheOpenApi = toOpenApi (Proxy :: Proxy CacheAPI)
    & info . title .~ "sensenet//cache API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Attestation-aware binary cache & artifact store.\n\n\
        \Features:\n\
        \- Content-addressed storage with Blake3 hashing\n\
        \- Post-quantum signatures (SPHINCS+)\n\
        \- Nix binary cache protocol compatibility\n\
        \- io_uring async I/O for high throughput"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.sensenet.dev" (Just "Production") mempty]

buildOpenApi :: OpenApi
buildOpenApi = toOpenApi (Proxy :: Proxy BuildAPI)
    & info . title .~ "sensenet//build API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Typed build system. Dhall configurations. Lean4 proofs.\n\n\
        \Features:\n\
        \- Dhall-typed build configurations\n\
        \- Lean4 formal verification of build semantics\n\
        \- Hermetic builds with content-addressed caching\n\
        \- Remote execution on distributed clusters"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.sensenet.dev" (Just "Production") mempty]

convergeOpenApi :: OpenApi
convergeOpenApi = toOpenApi (Proxy :: Proxy ConvergeAPI)
    & info . title .~ "sensenet//converge API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Typed infrastructure-as-code. Desired-state convergence.\n\n\
        \Features:\n\
        \- Dhall-typed infrastructure definitions\n\
        \- Desired-state convergence (no state files)\n\
        \- Live drift detection\n\
        \- Multi-cloud support (AWS, GCP, Azure, K8s)"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.sensenet.dev" (Just "Production") mempty]

confirmOpenApi :: OpenApi
confirmOpenApi = toOpenApi (Proxy :: Proxy ConfirmAPI)
    & info . title .~ "sensenet//confirm API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "CI with proof obligations. Typed Dhall pipelines.\n\n\
        \Features:\n\
        \- Dhall-typed pipeline definitions\n\
        \- Proof obligations checked at merge time\n\
        \- Agent code review with taint tracking\n\
        \- Post-quantum build attestation"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.sensenet.dev" (Just "Production") mempty]

forgeOpenApi :: OpenApi
forgeOpenApi = toOpenApi (Proxy :: Proxy ForgeAPI)
    & info . title .~ "sensenet//forge API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Code hosting + review. Stacked diffs, not PRs. jujutsu first-class.\n\n\
        \Features:\n\
        \- Stacked diffs for incremental review\n\
        \- Native jujutsu (jj) support\n\
        \- Agent code attestation\n\
        \- Semantic code search"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.sensenet.dev" (Just "Production") mempty]

publishOpenApi :: OpenApi
publishOpenApi = toOpenApi (Proxy :: Proxy PublishAPI)
    & info . title .~ "sensenet//publish API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Scope-graph documentation. References resolve or the build fails.\n\n\
        \Features:\n\
        \- Scope-graph semantic analysis\n\
        \- Cross-language reference resolution\n\
        \- Build-time reference validation\n\
        \- Machine-readable output (JSON-LD, OpenAPI)"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.sensenet.dev" (Just "Production") mempty]


-- ═══════════════════════════════════════════════════════════════════════════
-- // omega specs //
-- ═══════════════════════════════════════════════════════════════════════════

codeOpenApi :: OpenApi
codeOpenApi = toOpenApi (Proxy :: Proxy CodeAPI)
    & info . title .~ "omega//code API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Native terminal AI coding agent. Haskell + Brick TUI.\n\n\
        \Features:\n\
        \- Session management with persistent storage\n\
        \- LLM integration (Anthropic, OpenRouter, local)\n\
        \- Tool execution (read, write, edit, bash, glob, grep)\n\
        \- PTY terminals with WebSocket bridge\n\
        \- Crew mode for parallel agents"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.omega.dev" (Just "Production") mempty]

workOpenApi :: OpenApi
workOpenApi = toOpenApi (Proxy :: Proxy WorkAPI)
    & info . title .~ "omega//work API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Desktop AI for Teams. Electron app for non-coders with team collaboration.\n\n\
        \Features:\n\
        \- Team workspaces with shared context\n\
        \- Conversation history and search\n\
        \- Enterprise integrations (Slack, Notion, Google)\n\
        \- SSO/SAML authentication"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.omega.dev" (Just "Production") mempty]

proxyOpenApi :: OpenApi
proxyOpenApi = toOpenApi (Proxy :: Proxy ProxyAPI)
    & info . title .~ "omega//proxy API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Verified inference proxy. SSE to SIGIL over ZeroMQ.\n\n\
        \Features:\n\
        \- SSE to SIGIL frame conversion\n\
        \- Reset-on-ambiguity for hallucination prevention\n\
        \- 200-600% wire compression\n\
        \- Automatic tool call repair"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.omega.dev" (Just "Production") mempty]

boostOpenApi :: OpenApi
boostOpenApi = toOpenApi (Proxy :: Proxy BoostAPI)
    & info . title .~ "omega//boost API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Managed inference co-located with BYOK vendor. Custom CUTLASS kernels.\n\n\
        \Features:\n\
        \- CUTLASS 3.x sm_120 custom CUDA kernels\n\
        \- Co-located with BYOK providers\n\
        \- evring HTTP/1.1+2+3 stack\n\
        \- Intelligent batching"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
    & servers .~ [Server "https://api.omega.dev" (Just "Production") mempty]


-- ═══════════════════════════════════════════════════════════════════════════
-- // combined //
-- ═══════════════════════════════════════════════════════════════════════════

allProductSpecs :: [ProductSpec]
allProductSpecs =
    [ ProductSpec "cache" "sensenet//cache" "Attestation-aware binary cache" "1.0.0" "/openapi/sensenet/cache.json" cacheOpenApi
    , ProductSpec "build" "sensenet//build" "Typed build system with Lean4 proofs" "1.0.0" "/openapi/sensenet/build.json" buildOpenApi
    , ProductSpec "converge" "sensenet//converge" "Desired-state infrastructure" "1.0.0" "/openapi/sensenet/converge.json" convergeOpenApi
    , ProductSpec "confirm" "sensenet//confirm" "CI with proof obligations" "1.0.0" "/openapi/sensenet/confirm.json" confirmOpenApi
    , ProductSpec "forge" "sensenet//forge" "Stacked diffs code review" "1.0.0" "/openapi/sensenet/forge.json" forgeOpenApi
    , ProductSpec "publish" "sensenet//publish" "Scope-graph documentation" "1.0.0" "/openapi/sensenet/publish.json" publishOpenApi
    , ProductSpec "code" "omega//code" "Native TUI AI coding agent" "1.0.0" "/openapi/omega/code.json" codeOpenApi
    , ProductSpec "work" "omega//work" "Desktop AI for teams" "1.0.0" "/openapi/omega/work.json" workOpenApi
    , ProductSpec "proxy" "omega//proxy" "Verified inference proxy" "1.0.0" "/openapi/omega/proxy.json" proxyOpenApi
    , ProductSpec "boost" "omega//boost" "Managed CUTLASS inference" "1.0.0" "/openapi/omega/boost.json" boostOpenApi
    ]

-- | Combined OpenAPI spec for all products
allOpenApi :: OpenApi
allOpenApi = mempty
    & info . title .~ "Straylight Platform API"
    & info . version .~ "1.0.0"
    & info . description ?~ 
        "Combined OpenAPI specification for all Straylight products.\n\n\
        \## sensenet products\n\
        \- **cache** - Attestation-aware binary cache\n\
        \- **build** - Typed build system with Lean4 proofs\n\
        \- **converge** - Desired-state infrastructure\n\
        \- **confirm** - CI with proof obligations\n\
        \- **forge** - Stacked diffs code review\n\
        \- **publish** - Scope-graph documentation\n\n\
        \## omega products\n\
        \- **code** - Native TUI AI coding agent\n\
        \- **work** - Desktop AI for teams\n\
        \- **proxy** - Verified inference proxy\n\
        \- **boost** - Managed CUTLASS inference"
    & info . license ?~ License "MIT" (Just (URL "https://opensource.org/licenses/MIT"))
    & info . contact ?~ Contact (Just "Straylight Software") (Just (URL "https://straylight.ai")) (Just "api@straylight.ai")
