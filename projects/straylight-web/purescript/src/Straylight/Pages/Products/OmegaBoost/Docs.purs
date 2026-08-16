-- | omega//boost Documentation
-- | Complete docs for managed inference with custom CUTLASS kernels
module Straylight.Pages.Products.OmegaBoost.Docs 
  ( docsPage
  , renderContent
  , sidebar
  -- For SSG
  , renderStatic
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

import Straylight.UI (cls)

-- ============================================================
-- COMPONENT
-- ============================================================

type Input = { path :: String }

data Action = Receive Input

docsPage :: forall q o m. H.Component q Input o m
docsPage = H.mkComponent
  { initialState: \input -> { path: input.path }
  , render
  , eval: H.mkEval H.defaultEval
      { handleAction = handleAction
      , receive = Just <<< Receive
      }
  }

handleAction :: forall o m. Action -> H.HalogenM { path :: String } Action () o m Unit
handleAction (Receive input) = H.modify_ _ { path = input.path }

-- ============================================================
-- RENDER
-- ============================================================

render :: forall m. { path :: String } -> H.ComponentHTML Action () m
render state =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-12" ] ]
    [ HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-12" ] ]
        [ sidebar state.path
        , renderContent state.path
        ]
    ]

-- ============================================================
-- SIDEBAR
-- ============================================================

sidebar :: forall w i. String -> HH.HTML w i
sidebar currentPath =
  HH.nav
    [ cls [ "lg:sticky lg:top-24 lg:self-start" ] ]
    [ HH.div
        [ cls [ "space-y-6" ] ]
        [ sidebarSection "Getting Started"
            [ sidebarLink "/omega/boost/docs" "Overview" currentPath
            , sidebarLink "/omega/boost/docs/quickstart" "Quick Start" currentPath
            , sidebarLink "/omega/boost/docs/deployment" "Deployment" currentPath
            , sidebarLink "/omega/boost/docs/byok-setup" "BYOK Setup" currentPath
            ]
        , sidebarSection "Integration"
            [ sidebarLink "/omega/boost/docs/openai" "OpenAI" currentPath
            , sidebarLink "/omega/boost/docs/anthropic" "Anthropic" currentPath
            , sidebarLink "/omega/boost/docs/streaming" "Streaming" currentPath
            ]
        , sidebarSection "Performance"
            [ sidebarLink "/omega/boost/docs/kernels" "CUTLASS Kernels" currentPath
            , sidebarLink "/omega/boost/docs/performance" "Performance Tuning" currentPath
            , sidebarLink "/omega/boost/docs/batching" "Continuous Batching" currentPath
            ]
        , sidebarSection "Reference"
            [ sidebarLink "/omega/boost/docs/api" "API Reference" currentPath
            , sidebarLink "/omega/boost/docs/errors" "Error Handling" currentPath
            , sidebarLink "/omega/boost/docs/limits" "Rate Limits" currentPath
            ]
        ]
    ]

sidebarSection :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
sidebarSection title children =
  HH.div_
    [ HH.h3
        [ cls [ "text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-3" ] ]
        [ HH.text title ]
    , HH.ul
        [ cls [ "space-y-1" ] ]
        children
    ]

sidebarLink :: forall w i. String -> String -> String -> HH.HTML w i
sidebarLink href label currentPath =
  HH.li_
    [ HH.a
        [ HP.href href
        , cls [ "block py-1.5 px-3 rounded text-sm transition-colors"
              , if href == currentPath
                  then "bg-yellow-400/10 text-yellow-400 font-medium" 
                  else "text-muted-foreground hover:text-text hover:bg-card"
              ]
        ]
        [ HH.text label ]
    ]

-- ============================================================
-- STATIC RENDER (for SSG)
-- ============================================================

renderStatic :: forall w i. String -> HH.HTML w i
renderStatic path =
  HH.div
    [ cls [ "max-w-[1100px] mx-auto px-6 py-12" ] ]
    [ HH.div
        [ cls [ "grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-12" ] ]
        [ sidebar path
        , renderContent path
        ]
    ]

-- ============================================================
-- CONTENT ROUTER
-- ============================================================

renderContent :: forall w i. String -> HH.HTML w i
renderContent path = case path of
  "/omega/boost/docs" -> overviewContent
  "/omega/boost/docs/quickstart" -> quickstartContent
  "/omega/boost/docs/deployment" -> deploymentContent
  "/omega/boost/docs/byok-setup" -> byokContent
  "/omega/boost/docs/openai" -> openaiContent
  "/omega/boost/docs/anthropic" -> anthropicContent
  "/omega/boost/docs/streaming" -> streamingContent
  "/omega/boost/docs/kernels" -> kernelsContent
  "/omega/boost/docs/performance" -> performanceContent
  "/omega/boost/docs/batching" -> batchingContent
  "/omega/boost/docs/api" -> apiContent
  "/omega/boost/docs/errors" -> errorsContent
  "/omega/boost/docs/limits" -> limitsContent
  _ -> overviewContent

-- ============================================================
-- OVERVIEW
-- ============================================================

overviewContent :: forall w i. HH.HTML w i
overviewContent =
  article
    [ h1 "omega//boost Documentation"
    , p "Managed inference with custom CUTLASS 3.x sm_120 kernels. Co-located with your BYOK vendor. evring HTTP/1.1+2+3 stack."
    
    , HH.div
        [ cls [ "grid grid-cols-1 md:grid-cols-2 gap-4 my-8" ] ]
        [ docCard "/omega/boost/docs/quickstart" "Quick Start" "Get up and running in 5 minutes."
        , docCard "/omega/boost/docs/byok-setup" "BYOK Setup" "Configure your provider API keys."
        , docCard "/omega/boost/docs/performance" "Performance" "Optimize latency and throughput."
        , docCard "/omega/boost/docs/api" "API Reference" "Full endpoint documentation."
        ]
    
    , h2 "What is omega//boost?"
    , p "omega//boost is managed inference infrastructure powered by custom CUDA kernels. We build CUTLASS 3.x kernels targeting sm_120 (H100/B200) that outperform stock vLLM by 40-60%. Bring your own API keys from OpenAI, Anthropic, or other providers - we co-locate our infrastructure with yours for minimal latency."
    
    , h2 "Key Features"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "CUTLASS 3.x Kernels - Custom sm_120 CUDA kernels for H100/B200"
        , li' "BYOK Co-location - Your API keys, our optimized infrastructure"
        , li' "evring HTTP/1.1+2+3 - Full HTTP stack with 509k req/s throughput"
        , li' "Continuous Batching - PagedAttention with dynamic scheduling"
        , li' "Replace vLLM - No GPU ops, no tuning, just managed inference"
        ]
    
    , h2 "Quick example"
    , codeBlock
        [ codeLine "# " "Replace vLLM or raw provider API with omega//boost"
        , codeLine "" "client = OpenAI("
        , codeLine "" "    base_url=\"https://boost.omega.dev/v1\","
        , codeLine "" "    api_key=os.environ[\"OPENAI_API_KEY\"]"
        , codeLine "" ")"
        , HH.text "\n"
        , codeLine "# " "Custom CUTLASS kernels handle the rest"
        ]
    ]

-- ============================================================
-- QUICKSTART
-- ============================================================

quickstartContent :: forall w i. HH.HTML w i
quickstartContent =
  article
    [ h1 "Quick Start"
    , p "Get omega//boost running in 5 minutes. Custom CUTLASS kernels, zero ops burden."
    
    , h2 "1. Create an account"
    , p "Sign up at straylight.dev and navigate to the omega//boost dashboard."
    
    , h2 "2. Add your BYOK credentials"
    , p "Add your OpenAI, Anthropic, or other provider API key. We co-locate with your vendor automatically."
    , codeBlock
        [ codeLine "# " "In your dashboard, add your provider key:"
        , codeLine "" "Provider: OpenAI"
        , codeLine "" "Key: sk-..."
        , codeLine "" "Region: auto  # We co-locate automatically"
        ]
    
    , h2 "3. Update your base URL"
    , codeBlock
        [ codeLine "# " "Replace vLLM or raw provider API"
        , codeLine "" "from openai import OpenAI"
        , HH.text "\n"
        , codeLine "" "client = OpenAI("
        , codeLine "" "    base_url=\"https://boost.omega.dev/v1\","
        , codeLine "" "    api_key=\"your-openai-key\""
        , codeLine "" ")"
        , HH.text "\n"
        , codeLine "# " "CUTLASS kernels handle inference optimization"
        , codeLine "" "response = client.chat.completions.create("
        , codeLine "" "    model=\"gpt-4-turbo-preview\","
        , codeLine "" "    messages=[{\"role\": \"user\", \"content\": \"Hello!\"}]"
        , codeLine "" ")"
        ]
    
    , h2 "4. Verify CUTLASS is active"
    , codeBlock
        [ codeLine "$ " "curl https://boost.omega.dev/v1/health"
        , codeLine "" "{"
        , codeLine "" "  \"status\": \"ok\","
        , codeLine "" "  \"kernel\": \"cutlass-3.x-sm_120\","
        , codeLine "" "  \"region\": \"us-east-1\""
        , codeLine "" "}"
        ]
    
    , h2 "Next steps"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground" ] ]
        [ li link "/omega/boost/docs/performance" "Tune latency and throughput"
        , li link "/omega/boost/docs/kernels" "Learn about CUTLASS kernels"
        , li link "/omega/boost/docs/batching" "Configure continuous batching"
        ]
    ]

-- ============================================================
-- DEPLOYMENT
-- ============================================================

deploymentContent :: forall w i. HH.HTML w i
deploymentContent =
  article
    [ h1 "Deployment"
    , p "omega//boost runs in multiple regions co-located with major AI providers."
    
    , h2 "Supported Regions"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "us-east-1 - Co-located with OpenAI, Anthropic"
        , li' "us-west-2 - Co-located with OpenAI, Google AI"
        , li' "eu-west-1 - Co-located with Anthropic, Mistral"
        , li' "ap-northeast-1 - Co-located with OpenAI"
        ]
    
    , h2 "Automatic Routing"
    , p "omega//boost automatically routes requests to the region closest to your configured BYOK provider. No configuration needed - we detect your provider and co-locate automatically."
    
    , h2 "GPU Infrastructure"
    , p "All regions run on NVIDIA H100 SXM5 80GB GPUs with our custom CUTLASS 3.x sm_120 kernels. Enterprise customers can request dedicated B200 capacity."
    
    , h2 "Network Topology"
    , codeBlock
        [ codeLine "" "Your App -> omega//boost Edge (anycast)"
        , codeLine "" "         -> CUTLASS Inference (regional)"
        , codeLine "" "         -> BYOK Provider (co-located)"
        ]
    
    , h2 "Failover"
    , p "omega//boost automatically fails over between regions if a GPU cluster or provider experiences issues. Failover typically completes in <100ms with no dropped requests."
    ]

-- ============================================================
-- BYOK CONTENT
-- ============================================================

byokContent :: forall w i. HH.HTML w i
byokContent =
  article
    [ h1 "BYOK Setup"
    , p "Bring your own API keys. We co-locate our CUTLASS kernels with your provider for optimal performance."
    
    , h2 "Supported Providers"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "OpenAI (GPT-4, GPT-4 Turbo, GPT-3.5, embeddings)"
        , li' "Anthropic (Claude 3 Opus, Sonnet, Haiku)"
        , li' "Google (Gemini Pro, Gemini Ultra)"
        , li' "Mistral AI (Mistral Large, Medium, Small)"
        , li' "Together AI (Llama, Mixtral)"
        , li' "Custom OpenAI-compatible endpoints"
        ]
    
    , h2 "Adding BYOK Credentials"
    , p "Navigate to Dashboard > Settings > BYOK Providers. Click 'Add Provider' and enter:"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Provider - Select from the dropdown"
        , li' "API Key - Your key (encrypted immediately with AES-256-GCM)"
        , li' "Label - A friendly name (e.g., 'production', 'staging')"
        , li' "Region - Auto (recommended) or manual selection"
        ]
    
    , h2 "Co-location"
    , p "When you add a BYOK provider, omega//boost automatically routes requests through our nearest GPU cluster. This co-location minimizes network latency - typically <1ms to your provider."
    
    , h2 "Key Security"
    , p "Your API keys are encrypted at rest using AES-256-GCM in isolated secure enclaves. Keys are decrypted only during request processing in isolated memory. We never log raw keys or request content."
    
    , h2 "Key Rotation"
    , p "To rotate a key, add the new key first, test it, then delete the old one. Zero downtime during rotation. All in-flight requests complete on the old key."
    ]

-- ============================================================
-- OPENAI CONTENT
-- ============================================================

openaiContent :: forall w i. HH.HTML w i
openaiContent =
  article
    [ h1 "OpenAI Integration"
    , p "omega//boost is a drop-in replacement for the OpenAI API."
    
    , h2 "Python SDK"
    , codeBlock
        [ codeLine "" "from openai import OpenAI"
        , HH.text "\n"
        , codeLine "" "client = OpenAI("
        , codeLine "" "    base_url=\"https://boost.omega.dev/v1\""
        , codeLine "" ")"
        , HH.text "\n"
        , codeLine "# " "Everything else works exactly the same"
        , codeLine "" "response = client.chat.completions.create("
        , codeLine "" "    model=\"gpt-4-turbo-preview\","
        , codeLine "" "    messages=[{\"role\": \"user\", \"content\": \"Hello!\"}]"
        , codeLine "" ")"
        ]
    
    , h2 "Node.js SDK"
    , codeBlock
        [ codeLine "" "import OpenAI from 'openai';"
        , HH.text "\n"
        , codeLine "" "const client = new OpenAI({"
        , codeLine "" "  baseURL: 'https://boost.omega.dev/v1'"
        , codeLine "" "});"
        ]
    
    , h2 "Supported Endpoints"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "/v1/chat/completions"
        , li' "/v1/completions"
        , li' "/v1/embeddings"
        , li' "/v1/models"
        ]
    
    , h2 "Headers"
    , p "omega//boost passes through all OpenAI headers. Additional headers:"
    , codeBlock
        [ codeLine "" "X-Boost-Batch: true|false    # Force batch mode"
        , codeLine "" "X-Boost-Cache: true|false    # Enable KV caching"
        , codeLine "" "X-Boost-Priority: 1-10       # Request priority"
        ]
    ]

-- ============================================================
-- ANTHROPIC CONTENT
-- ============================================================

anthropicContent :: forall w i. HH.HTML w i
anthropicContent =
  article
    [ h1 "Anthropic Integration"
    , p "Full support for Claude models through omega//boost."
    
    , h2 "Python SDK"
    , codeBlock
        [ codeLine "" "import anthropic"
        , HH.text "\n"
        , codeLine "" "client = anthropic.Anthropic("
        , codeLine "" "    base_url=\"https://boost.omega.dev/anthropic\""
        , codeLine "" ")"
        , HH.text "\n"
        , codeLine "" "message = client.messages.create("
        , codeLine "" "    model=\"claude-3-opus-20240229\","
        , codeLine "" "    max_tokens=1024,"
        , codeLine "" "    messages=[{\"role\": \"user\", \"content\": \"Hello!\"}]"
        , codeLine "" ")"
        ]
    
    , h2 "Supported Models"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "claude-3-opus-20240229"
        , li' "claude-3-sonnet-20240229"
        , li' "claude-3-haiku-20240307"
        , li' "claude-2.1"
        , li' "claude-2.0"
        ]
    ]

-- ============================================================
-- STREAMING CONTENT
-- ============================================================

streamingContent :: forall w i. HH.HTML w i
streamingContent =
  article
    [ h1 "Streaming"
    , p "omega//boost fully supports streaming responses."
    
    , h2 "OpenAI Streaming"
    , codeBlock
        [ codeLine "" "stream = client.chat.completions.create("
        , codeLine "" "    model=\"gpt-4-turbo-preview\","
        , codeLine "" "    messages=[{\"role\": \"user\", \"content\": \"Hello!\"}],"
        , codeLine "" "    stream=True"
        , codeLine "" ")"
        , HH.text "\n"
        , codeLine "" "for chunk in stream:"
        , codeLine "" "    print(chunk.choices[0].delta.content, end=\"\")"
        ]
    
    , h2 "Batching with Streaming"
    , p "Streaming requests can still be batched. We buffer the initial prompt processing and stream the response tokens. This means you get the same streaming experience with batching cost savings."
    ]

-- ============================================================
-- KERNELS CONTENT
-- ============================================================

kernelsContent :: forall w i. HH.HTML w i
kernelsContent =
  article
    [ h1 "CUTLASS Kernels"
    , p "omega//boost runs custom CUDA kernels built on NVIDIA's CUTLASS 3.x library."
    
    , h2 "What is CUTLASS?"
    , p "CUTLASS (CUDA Templates for Linear Algebra Subroutines) is NVIDIA's open-source library for high-performance matrix operations. We build custom kernels on CUTLASS 3.x targeting sm_120 architecture (H100, B200 GPUs)."
    
    , h2 "Our Kernel Stack"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "FlashAttention-3 - Custom attention kernels with async copy"
        , li' "Fused MoE - Optimized kernels for Mixtral/DBRX architectures"
        , li' "Warp-specialized GEMM - 1.8x faster than cuBLAS"
        , li' "PagedAttention - Memory-efficient KV cache management"
        ]
    
    , h2 "Performance vs vLLM"
    , codeBlock
        [ codeLine "# " "Benchmark: Llama-70B on H100 SXM5"
        , codeLine "" "Operation     | vLLM    | omega//boost"
        , codeLine "" "Attention     | 1.0x    | 2.1x"
        , codeLine "" "GEMM          | 1.0x    | 1.8x"
        , codeLine "" "Overall TTFT  | 12ms    | <5ms"
        , codeLine "" "Throughput    | 8k t/s  | 12k t/s"
        ]
    
    , h2 "sm_120 Architecture"
    , p "Our kernels target sm_120 (Hopper/Blackwell architecture) exclusively. This allows us to use features not available on older GPUs: TMA (Tensor Memory Accelerator), warp-specialized pipelines, and 4th-gen Tensor Cores."
    ]

-- ============================================================
-- PERFORMANCE CONTENT
-- ============================================================

performanceContent :: forall w i. HH.HTML w i
performanceContent =
  article
    [ h1 "Performance Tuning"
    , p "Optimize latency, throughput, and cost for your workload."
    
    , h2 "Key Metrics"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "TTFT (Time to First Token) - Critical for interactive use cases"
        , li' "TBT (Time Between Tokens) - Affects streaming experience"
        , li' "Throughput (tok/s) - Total tokens processed per second"
        , li' "GPU Utilization - Higher is better for cost efficiency"
        ]
    
    , h2 "Latency Optimization"
    , p "For minimum TTFT, use these headers:"
    , codeBlock
        [ codeLine "" "X-Boost-Priority: high      # Skip batch queuing"
        , codeLine "" "X-Boost-Prefill: eager      # Immediate prefill"
        ]
    
    , h2 "Throughput Optimization"
    , p "For maximum throughput at the cost of latency:"
    , codeBlock
        [ codeLine "" "X-Boost-Priority: normal    # Allow batching"
        , codeLine "" "X-Boost-Batch-Window: 50    # 50ms batch window"
        ]
    
    , h2 "Monitoring"
    , p "Monitor your inference performance in the dashboard or via API:"
    , codeBlock
        [ codeLine "" "GET /v1/metrics/latency     # p50, p95, p99"
        , codeLine "" "GET /v1/metrics/throughput  # tok/s, req/s"
        , codeLine "" "GET /v1/metrics/gpu         # utilization, memory"
        ]
    ]

-- ============================================================
-- BATCHING CONTENT
-- ============================================================

batchingContent :: forall w i. HH.HTML w i
batchingContent =
  article
    [ h1 "Continuous Batching"
    , p "omega//boost implements continuous batching with PagedAttention for maximum GPU utilization."
    
    , h2 "How It Works"
    , p "Unlike static batching, continuous batching adds and removes requests from the batch every iteration. Our CUTLASS kernels implement this with PagedAttention for memory-efficient KV cache management."
    
    , h2 "Batching Modes"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "auto (default) - Dynamic scheduling based on queue depth"
        , li' "eager - Minimize latency, batch when requests arrive together"
        , li' "throughput - Maximize throughput, larger batch windows"
        ]
    
    , h2 "Configuration"
    , codeBlock
        [ codeLine "# " "Via header"
        , codeLine "" "X-Boost-Batch-Mode: auto    # auto, eager, throughput"
        , codeLine "" "X-Boost-Batch-Window: 10    # milliseconds (throughput mode)"
        , HH.text "\n"
        , codeLine "# " "Via dashboard"
        , codeLine "" "Settings > Batching > Mode: auto"
        ]
    
    , h2 "Batching + Streaming"
    , p "Continuous batching works seamlessly with streaming responses. Each request in a batch can start streaming independently as soon as its first token is generated."
    ]

-- ============================================================
-- API CONTENT
-- ============================================================

apiContent :: forall w i. HH.HTML w i
apiContent =
  article
    [ h1 "API Reference"
    , p "Complete API documentation for omega//boost managed inference."
    
    , h2 "Base URL"
    , codeBlock
        [ codeLine "" "https://boost.omega.dev"
        ]
    
    , h2 "Authentication"
    , p "Pass your BYOK provider API key in the Authorization header:"
    , codeBlock
        [ codeLine "" "Authorization: Bearer sk-your-provider-key"
        ]
    
    , h2 "Provider Endpoints"
    , p "omega//boost proxies all standard OpenAI/Anthropic endpoints:"
    , codeBlock
        [ codeLine "" "POST /v1/chat/completions   # OpenAI chat"
        , codeLine "" "POST /v1/completions        # OpenAI completions"
        , codeLine "" "POST /v1/embeddings         # OpenAI embeddings"
        , codeLine "" "POST /anthropic/messages    # Anthropic messages"
        ]
    
    , h2 "Boost Headers"
    , p "Control kernel behavior with these headers:"
    , codeBlock
        [ codeLine "" "X-Boost-Priority: high|normal|low"
        , codeLine "" "X-Boost-Batch-Mode: auto|eager|throughput"
        , codeLine "" "X-Boost-Batch-Window: <milliseconds>"
        , codeLine "" "X-Boost-Prefill: eager|batched"
        ]
    
    , h2 "Management Endpoints"
    , codeBlock
        [ codeLine "" "GET  /v1/health             # Kernel status"
        , codeLine "" "GET  /v1/metrics/*          # Performance metrics"
        , codeLine "" "GET  /v1/usage              # Token usage"
        ]
    ]

-- ============================================================
-- ERRORS CONTENT
-- ============================================================

errorsContent :: forall w i. HH.HTML w i
errorsContent =
  article
    [ h1 "Error Handling"
    , p "omega//boost passes through provider errors and adds boost-specific codes."
    
    , h2 "Boost Error Codes"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "BOOST_RATE_LIMITED - omega//boost rate limit exceeded"
        , li' "BOOST_KEY_INVALID - Invalid or expired API key in vault"
        , li' "BOOST_PROVIDER_ERROR - Upstream provider error"
        , li' "BOOST_BATCH_TIMEOUT - Batch window exceeded"
        ]
    
    , h2 "Retries"
    , p "omega//boost automatically retries transient errors with exponential backoff. Configure via header:"
    , codeBlock
        [ codeLine "" "X-Boost-Retries: 3  # max retries (default: 3)"
        ]
    ]

-- ============================================================
-- LIMITS CONTENT
-- ============================================================

limitsContent :: forall w i. HH.HTML w i
limitsContent =
  article
    [ h1 "Rate Limits"
    , p "omega//boost rate limits by plan."
    
    , h2 "Limits by Plan"
    , HH.ul
        [ cls [ "space-y-2 text-muted-foreground mb-6" ] ]
        [ li' "Starter: 100 req/s, 100k req/month"
        , li' "Pro: 1000 req/s, 1M req/month included"
        , li' "Enterprise: Custom"
        ]
    
    , h2 "Headers"
    , p "Rate limit info is included in response headers:"
    , codeBlock
        [ codeLine "" "X-RateLimit-Limit: 1000"
        , codeLine "" "X-RateLimit-Remaining: 999"
        , codeLine "" "X-RateLimit-Reset: 1708012800"
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

article :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
article = HH.article [ cls [ "prose prose-invert max-w-none" ] ]

h1 :: forall w i. String -> HH.HTML w i
h1 text = HH.h1 [ cls [ "text-3xl font-bold text-text mb-6" ] ] [ HH.text text ]

h2 :: forall w i. String -> HH.HTML w i
h2 text = HH.h2 [ cls [ "text-2xl font-semibold text-text mt-12 mb-4" ] ] [ HH.text text ]

p :: forall w i. String -> HH.HTML w i
p text = HH.p [ cls [ "text-muted-foreground mb-4" ] ] [ HH.text text ]

li' :: forall w i. String -> HH.HTML w i
li' text = HH.li [ cls [ "text-muted-foreground" ] ] [ HH.text text ]

li :: forall w i. (forall w' i'. String -> String -> HH.HTML w' i') -> String -> String -> HH.HTML w i
li f href text = HH.li_ [ f href text ]

link :: forall w i. String -> String -> HH.HTML w i
link href text = 
  HH.a 
    [ HP.href href
    , cls [ "text-yellow-400 hover:text-yellow-400/80" ]
    ] 
    [ HH.text text ]

docCard :: forall w i. String -> String -> String -> HH.HTML w i
docCard href title description =
  HH.a
    [ HP.href href
    , cls [ "block p-4 bg-card border border-border rounded-lg hover:border-yellow-400/50 transition-colors" ]
    ]
    [ HH.h3
        [ cls [ "text-text font-medium mb-1" ] ]
        [ HH.text title ]
    , HH.p
        [ cls [ "text-muted-foreground text-sm" ] ]
        [ HH.text description ]
    ]

codeBlock :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
codeBlock children =
  HH.pre
    [ cls [ "bg-card border border-border p-4 rounded-lg overflow-x-auto text-sm leading-relaxed mb-6" ] ]
    children

codeLine :: forall w i. String -> String -> HH.HTML w i
codeLine prefix content =
  HH.div_
    [ HH.span [ cls [ "text-muted-foreground" ] ] [ HH.text prefix ]
    , HH.span [ cls [ "text-text" ] ] [ HH.text content ]
    ]
