# straylight-api

OpenAPI 3.1.0 specifications for all Straylight products, backed by Servant type-safe API definitions.

## Products

### sensenet

| Product | Description | Spec |
|---------|-------------|------|
| `sensenet//cache` | Attestation-aware binary cache | `/openapi/sensenet/cache.json` |
| `sensenet//build` | Typed build system with Lean4 proofs | `/openapi/sensenet/build.json` |
| `sensenet//converge` | Desired-state infrastructure | `/openapi/sensenet/converge.json` |
| `sensenet//confirm` | CI with proof obligations | `/openapi/sensenet/confirm.json` |
| `sensenet//forge` | Stacked diffs code review | `/openapi/sensenet/forge.json` |
| `sensenet//publish` | Scope-graph documentation | `/openapi/sensenet/publish.json` |

### omega

| Product | Description | Spec |
|---------|-------------|------|
| `omega//code` | Native TUI AI coding agent | `/openapi/omega/code.json` |
| `omega//work` | Desktop AI for teams | `/openapi/omega/work.json` |
| `omega//proxy` | Verified inference proxy | `/openapi/omega/proxy.json` |
| `omega//boost` | Managed CUTLASS inference | `/openapi/omega/boost.json` |

## Usage

### Run the spec server

```bash
cabal run straylight-api
# Server runs on port 8080

cabal run straylight-api -- --port 3000
# Custom port
```

### Export specs to files

```bash
cabal run straylight-api -- --export
# Exports all specs to current directory

cabal run straylight-api -- --export ./specs
# Export to custom directory
```

### Use in Haskell

```haskell
import Api
import Api.OpenApi

-- Get OpenAPI spec for a product
cacheSpec :: OpenApi
cacheSpec = cacheOpenApi

-- Serve the combined API
app :: Application
app = serve straylightApi handlers
```

## API Structure

Each product API follows a consistent pattern:

```
/{product-line}/{product}/v1/
├── /health           GET  - Health check
├── /info             GET  - API info
├── /{resource}       GET  - List resources
├── /{resource}       POST - Create resource
├── /{resource}/{id}  GET  - Get resource
├── /{resource}/{id}  PUT  - Update resource
├── /{resource}/{id}  DELETE - Delete resource
└── ...
```

## Authentication

All authenticated endpoints expect:

```
Authorization: Bearer <token>
```

## Development

```bash
# Build
cabal build

# Run tests
cabal test

# Generate docs
cabal haddock
```

## License

MIT
