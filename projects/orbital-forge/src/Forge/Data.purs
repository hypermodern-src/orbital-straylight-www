module Forge.Data
  ( Language
  , Stats
  , CloneUrls
  , ReadmeBlock(..)
  , SourceFile
  , Project
  , Publication
  , projects
  ) where

type Language =
  { name :: String
  , percent :: Int
  , color :: String
  }

type Stats =
  { lines :: Int
  , modules :: Int
  , proofs :: Int
  }

type CloneUrls =
  { cli :: String
  , https :: String
  , ssh :: String
  }

data ReadmeBlock
  = Heading2 String
  | Heading3 String
  | Paragraph String
  | BulletList (Array String)
  | CodeBlock String String
  | Note String

type SourceFile =
  { path :: String
  , language :: String
  , code :: String
  }

type Publication =
  { kind :: String
  , title :: String
  , date :: String
  , excerpt :: String
  , href :: String
  }

type Project =
  { slug :: String
  , name :: String
  , owner :: String
  , updated :: String
  , blurb :: String
  , languages :: Array Language
  , tags :: Array String
  , license :: String
  , stats :: Stats
  , clone :: CloneUrls
  , publications :: Array Publication
  , readme :: Array ReadmeBlock
  , files :: Array SourceFile
  }

projects :: Array Project
projects =
  [ { slug: "orbital-forge"
    , name: "orbital-forge"
    , owner: "straylight"
    , updated: "18 Aug 2026"
    , blurb: "The source and publishing browser for Orbital projects: a real Halogen application with repository navigation, clone protocols, and papers joined to the systems they explain."
    , languages:
        [ { name: "PureScript", percent: 62, color: "#5d7894" }
        , { name: "CSS", percent: 32, color: "#7957a8" }
        , { name: "JavaScript", percent: 6, color: "#b69c3b" }
        ]
    , tags: [ "PureScript", "Halogen", "Forge", "Publishing" ]
    , license: "Internal"
    , stats: { lines: 785, modules: 2, proofs: 0 }
    , clone:
        { cli: "git clone ssh://git@git.s4.gl/straylight/www.git"
        , https: "https://git.s4.gl/straylight/www.git"
        , ssh: "ssh://git@git.s4.gl/straylight/www.git"
        }
    , publications:
        [ { kind: "Journal", title: "Source and reasons in one place", date: "Aug 2026", excerpt: "Treating the repository and its technical argument as two views of the same project.", href: "https://orbital.foo/journal.html" }
        ]
    , readme:
        [ Heading2 "ORBITAL // FORGE"
        , Paragraph "Forge keeps consequential source beside the papers and field notes that explain why it exists. It is a reader first: repository browsing, clone commands, and publication joins without issue queues, reaction counters, or social theatre."
        , Paragraph "The application is written in PureScript with Halogen. Its shell, navigation, breadcrumbs, tabs, and code viewer are reusable Hydrogen.Orbital components rather than page-local JavaScript widgets."
        , Heading3 "First slice"
        , BulletList
            [ "Hash-addressable project overview, source, and papers views."
            , "File tree derived from repository paths."
            , "Responsive code viewer with line numbers and independent overflow."
            , "Theme-aware viewport shell and working clone copy controls."
            ]
        , Heading3 "Build"
        , CodeBlock "shell" "cd projects/orbital-forge\nnpm ci\nnpm run check"
        , Note "The project is monorepo-hosted but owns its Spago manifest, Nix entrypoint, Vercel output, and asset boundary so it can split cleanly later."
        ]
    , files:
        [ { path: "README.md", language: "markdown", code: "# ORBITAL // FORGE\n\nThe source and publishing browser for Orbital projects.\n\nBuilt with PureScript, Halogen, Hydrogen, and Spago.\n" }
        , { path: "spago.yaml"
          , language: "yaml"
          , code: "package:\n  name: orbital-forge\n  dependencies:\n    - aff\n    - halogen\n    - hydrogen\n\nworkspace:\n  packageSet:\n    registry: 73.2.0\n  extraPackages:\n    hydrogen:\n      path: ../hydrogen"
          }
        , { path: "src/Main.purs"
          , language: "purescript"
          , code: "component =\n  H.mkComponent\n    { initialState: const initialState\n    , render\n    , eval: H.mkEval H.defaultEval\n        { initialize = Just Initialize\n        , handleAction = handleAction\n        }\n    }\n\nrender state =\n  appShell (defaultAppShell\n    { header = [ renderNav state ]\n    , main = [ renderRoute state ]\n    })"
          }
        , { path: "src/Forge/Data.purs"
          , language: "purescript"
          , code: "type Project =\n  { slug :: String\n  , name :: String\n  , owner :: String\n  , languages :: Array Language\n  , clone :: CloneUrls\n  , publications :: Array Publication\n  , readme :: Array ReadmeBlock\n  , files :: Array SourceFile\n  }"
          }
        ]
    }
  , { slug: "hydrogen"
    , name: "hydrogen"
    , owner: "straylight"
    , updated: "18 Aug 2026"
    , blurb: "A PureScript and Halogen web application framework with typed design primitives, Radix-grade interaction behavior, and no framework JavaScript dependency."
    , languages:
        [ { name: "PureScript", percent: 82, color: "#5d7894" }
        , { name: "CSS", percent: 12, color: "#7957a8" }
        , { name: "JavaScript", percent: 6, color: "#b69c3b" }
        ]
    , tags: [ "PureScript", "Halogen", "UI", "Design systems" ]
    , license: "Internal"
    , stats: { lines: 24572, modules: 115, proofs: 0 }
    , clone:
        { cli: "git clone ssh://git@git.s4.gl/straylight/hydrogen.git"
        , https: "https://git.s4.gl/straylight/hydrogen.git"
        , ssh: "ssh://git@git.s4.gl/straylight/hydrogen.git"
        }
    , publications:
        [ { kind: "Journal", title: "Encoding the design guide", date: "Aug 2026", excerpt: "From visual goldens to closed PureScript component contracts.", href: "https://orbital.foo/journal.html" }
        ]
    , readme:
        [ Heading2 "Hydrogen"
        , Paragraph "Hydrogen is the UI substrate for Orbital applications. Components are PureScript values, behavior is explicit Halogen state, and the visual contract is a checked asset rather than a JavaScript package."
        , Heading3 "Current surface"
        , BulletList
            [ "Typed ORBITAL foundation, brand, typography, shell, navigation, and source primitives."
            , "Radix-inspired interactive controls implemented in Halogen."
            , "Spago is the canonical build path for framework and consumers."
            ]
        , CodeBlock "shell" "nix develop\nnpm test\nnpm run build:orbital"
        ]
    , files:
        [ { path: "README.md", language: "markdown", code: "# Hydrogen\n\nA typed PureScript/Halogen framework for Orbital applications.\n\nThe Spago manifest is canonical. Buck2 and Bazel are intentionally unsupported.\n" }
        , { path: "spago.yaml", language: "yaml", code: "package:\n  name: hydrogen\n  dependencies:\n    - aff\n    - halogen\n    - web-html\n\nworkspace:\n  packageSet:\n    registry: 73.2.0\n" }
        , { path: "src/Hydrogen/Orbital/Shell.purs"
          , language: "purescript"
          , code: "module Hydrogen.Orbital.Shell\n  ( AppShellInput\n  , defaultAppShell\n  , appShell\n  ) where\n\n-- The middle row owns overflow; source panes can own theirs.\nappShell o =\n  HH.div shellProps\n    [ HH.header headerProps o.header\n    , HH.main mainProps o.main\n    , HH.footer statusProps [ status o ]\n    ]"
          }
        , { path: "src/Hydrogen/Orbital/Code.purs"
          , language: "purescript"
          , code: "module Hydrogen.Orbital.Code\n  ( CodeViewerInput\n  , defaultCodeViewer\n  , codeViewer\n  ) where\n\ncodeViewer o =\n  HH.div viewerProps\n    [ renderHeader o\n    , renderLines o.startLine o.code\n    ]"
          }
        ]
    }
  , { slug: "orbital-cms"
    , name: "orbital-cms"
    , owner: "orbital"
    , updated: "17 Aug 2026"
    , blurb: "The publishing system behind Orbital journals and papers: structured content, citations, revisions, and stable public artifacts in one place."
    , languages:
        [ { name: "Haskell", percent: 61, color: "#7b5aa6" }
        , { name: "PostgreSQL", percent: 24, color: "#487ca8" }
        , { name: "JavaScript", percent: 15, color: "#b69c3b" }
        ]
    , tags: [ "CMS", "Papers", "Publishing", "Supabase" ]
    , license: "Internal"
    , stats: { lines: 1193, modules: 5, proofs: 0 }
    , clone:
        { cli: "git clone ssh://git@git.s4.gl/straylight/www.git"
        , https: "https://git.s4.gl/straylight/www.git"
        , ssh: "ssh://git@git.s4.gl/straylight/www.git"
        }
    , publications:
        [ { kind: "Journal", title: "A CMS for papers, not pages", date: "Aug 2026", excerpt: "Why citations, versions, and machine-readable blocks belong in the content model.", href: "https://orbital.foo/journal.html" }
        ]
    , readme:
        [ Heading2 "Orbital CMS"
        , Paragraph "A single publishing path for articles and research papers. PostgreSQL owns immutable revisions and workflow transitions; the Haskell service exposes editorial and cache-aware public APIs; sites own rendering."
        , Heading3 "Content contract"
        , BulletList [ "Immutable canonical Markdown, Typst, and LaTeX revisions.", "Draft, review, scheduled, published, and archived workflow states.", "Paper metadata, authors, citations, figures, and content-addressed PDF assets.", "No untrusted MDX execution and no shadow HTML." ]
        , CodeBlock "shell" "cd projects/orbital-cms\nDATABASE_URL=postgresql://localhost/orbital_cms nix run .#migrate\nnix run"
        ]
    , files:
        [ { path: "README.md", language: "markdown", code: "# orbital-cms\n\nStructured publishing for Orbital journals and papers.\n" }
        , { path: "src/Orbital/Cms/Domain.hs"
          , language: "haskell"
          , code: "data DocumentKind = Post | Paper\n    deriving stock (Eq, Show)\n\ndata SourceFormat = Markdown | Typst | LaTeX\n    deriving stock (Eq, Show)\n\ndata WorkflowState\n    = Draft\n    | Review\n    | Scheduled\n    | Published\n    | Archived\n    deriving stock (Eq, Show)"
          }
        , { path: "db/migrations/001_initial.sql"
          , language: "sql"
          , code: "create schema if not exists cms;\n\ncreate type cms.document_kind as enum ('post', 'paper');\ncreate type cms.workflow_state as enum\n  ('draft', 'review', 'scheduled', 'published', 'archived');\n\ncreate table cms.documents (\n  id uuid primary key default gen_random_uuid(),\n  slug text not null unique,\n  kind cms.document_kind not null\n);"
          }
        ]
    }
  , { slug: "orbital-web"
    , name: "orbital-web"
    , owner: "orbital"
    , updated: "18 Aug 2026"
    , blurb: "The public Orbital product and publishing surface, statically rendered from PureScript and deployed as immutable assets."
    , languages:
        [ { name: "PureScript", percent: 67, color: "#5d7894" }
        , { name: "CSS", percent: 25, color: "#7957a8" }
        , { name: "JavaScript", percent: 8, color: "#b69c3b" }
        ]
    , tags: [ "PureScript", "SSG", "Vercel", "Products" ]
    , license: "Internal"
    , stats: { lines: 4991, modules: 15, proofs: 0 }
    , clone:
        { cli: "git clone ssh://git@git.s4.gl/straylight/www.git"
        , https: "https://git.s4.gl/straylight/www.git"
        , ssh: "ssh://git@git.s4.gl/straylight/www.git"
        }
    , publications: []
    , readme:
        [ Heading2 "Orbital Web"
        , Paragraph "Product pages, journal, papers, and application surfaces share the Hydrogen implementation of the Orbital design system. Pages render ahead of time; interactive islands remain small and typed."
        , Heading3 "Build"
        , CodeBlock "shell" "cd projects/orbital-web-jw\nnpm ci\nnpm run check"
        , Note "The web workspace is a monorepo today. Project boundaries are recorded so each application can split into its own repository without changing its build contract."
        ]
    , files:
        [ { path: "PROJECTS.toml"
          , language: "toml"
          , code: "[projects.orbital-web-jw]\npath = \"projects/orbital-web-jw\"\nkind = \"application\"\nsource = \"git@github.com:sensenet-ai/orbital-web-jw.git\"\nvercel = [\"orbital-web-jw\"]\n\n[projects.orbital-forge]\npath = \"projects/orbital-forge\"\nkind = \"application\"\nsource = \"monorepo://projects/orbital-forge\""
          }
        , { path: "projects/orbital-web-jw/spago.yaml"
          , language: "yaml"
          , code: "package:\n  name: orbital-web\n  dependencies:\n    - halogen\n    - hydrogen\n\nworkspace:\n  packageSet:\n    registry: 73.2.0\n  extraPackages:\n    hydrogen:\n      path: ../hydrogen"
          }
        , { path: "projects/orbital-web-jw/src/Orbital/SSG.purs"
          , language: "purescript"
          , code: "main :: Effect Unit\nmain = do\n  outputDir <- Node.argvAt 2\n  traverse_ (writeRoute outputDir) allRoutes\n\nwriteRoute outputDir route =\n  Node.writeText\n    (outputDir <> \"/\" <> fileName route)\n    (renderPage route)"
          }
        ]
    }
  , { slug: "web-middleware"
    , name: "web-middleware"
    , owner: "straylight"
    , updated: "16 Aug 2026"
    , blurb: "The shared Haskell/WAI HTTP policy boundary for web services: request identity, bounded observations, uniform errors, hostile-text rejection, security headers, and lifecycle probes."
    , languages:
        [ { name: "Haskell", percent: 84, color: "#7b5aa6" }
        , { name: "Nix", percent: 16, color: "#6f86c4" }
        ]
    , tags: [ "Middleware", "WAI", "HTTP", "Lean boundary" ]
    , license: "Internal"
    , stats: { lines: 1451, modules: 7, proofs: 0 }
    , clone:
        { cli: "git clone ssh://git@git.s4.gl/straylight/www.git"
        , https: "https://git.s4.gl/straylight/www.git"
        , ssh: "ssh://git@git.s4.gl/straylight/www.git"
        }
    , publications: []
    , readme:
        [ Heading2 "Web Middleware"
        , Paragraph "The public contract is HTTP, not Haskell. Services can adopt the policy stack now and retain the behavior when the implementation moves to Lean."
        , Heading3 "Policy stack"
        , BulletList [ "Canonical validated request IDs.", "Privacy-bounded structured observations and uniform JSON errors.", "Conservative security headers and bounded hostile-text rejection.", "Liveness plus warm, ready, and draining lifecycle probes." ]
        ]
    , files:
        [ { path: "README.md", language: "markdown", code: "# Straylight web middleware\n\nA shared Haskell/WAI HTTP policy boundary with an implementation seam for Lean.\n" }
        , { path: "src/Straylight/Web/Middleware/Core.hs"
          , language: "haskell"
          , code: "middleware :: Runtime -> Middleware\nmiddleware runtime app =\n    requestIdMiddleware runtime\n      (requestLogger runtime\n        (securityHeadersMiddleware runtime\n          (exceptionBoundary runtime\n            (rejectHostileText\n              (middlewareMaxJsonBodyBytes (runtimeSettings runtime))\n              (operationalEndpoints runtime app)))))"
          }
        , { path: "src/Straylight/Web/Middleware/Runtime.hs"
          , language: "haskell"
          , code: "data Readiness\n    = Warming\n    | Ready\n    | Draining\n    deriving stock (Eq, Show)\n\ndata Runtime = Runtime\n    { runtimeSettings :: MiddlewareSettings\n    , runtimeReadiness :: TVar Readiness\n    , runtimeRequestIdKey :: Vault.Key Text\n    }"
          }
        ]
    }
  ]
