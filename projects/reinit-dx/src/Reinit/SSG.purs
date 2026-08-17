-- | Static Site Generation for REINIT // DX
-- |
-- | Renders the landing page to static HTML for:
-- | - Faster first contentful paint
-- | - SEO (crawlers see content immediately)  
-- | - Progressive enhancement (works without JS)
-- |
-- | Bundled and executed by `npm run build`.
module Reinit.SSG
  ( renderStatic
  , staticPage
  , main
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String.CodeUnits as CU
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Console (log)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Runtime.Renderer as Renderer
import Reinit.Page as Page

-- | SSG entrypoint (node), run by the Spago site builder. The builder hands us
-- | the shell path on argv and captures our
-- | stdout as index.html. ALL policy lives here — reinit is a single static page,
-- | so we prerender it unconditionally; a multi-route app would consult
-- | Hydrogen.Runtime.Router's RouteMetadata (isStaticRoute) and any late/CMS config to
-- | decide per route. "Served to googlebot as SSG" is just: prerender it.
main :: Effect Unit
main = do
  shellPath <- argv1
  shell <- readFileUtf8 shellPath
  log (injectApp shell renderStatic)

-- | Inject prerendered content into the shell's `<div id="app">…</div>` — the
-- | `</div>` immediately before the client `reinit.js` script tag. App-specific
-- | by design.
injectApp :: String -> String -> String
injectApp shell content =
  case CU.indexOf (Pattern appOpen) shell, CU.indexOf (Pattern scriptTag) shell of
    Just openIdx, Just scriptIdx ->
      let
        openEnd = openIdx + CU.length appOpen
        beforeScript = CU.take scriptIdx shell
      in
        case CU.lastIndexOf (Pattern "</div>") beforeScript of
          Just closeIdx -> CU.take openEnd shell <> content <> CU.drop closeIdx shell
          Nothing -> shell
    _, _ -> shell
  where
  appOpen = "<div id=\"app\">"
  scriptTag = "<script src=\"/reinit.js\">"

-- | argv[1] under `node -e`: the shell HTML path the site builder passes.
foreign import argv1 :: Effect String

-- | Read a UTF-8 file (node fs). Used only at SSG time (node), never in the
-- | browser bundle.
foreign import readFileUtf8 :: String -> Effect String

-- | Render the landing page to a static HTML string
-- | This is the #app contents - the shell (head, scripts) is in index.html
renderStatic :: String
renderStatic = Renderer.render staticPage

-- | The complete landing page as static HTML
-- | Uses static versions of hero/submit (no event handlers)
staticPage :: forall w i. HH.HTML w i
staticPage =
  HH.div
    [ Page.cls "min-h-screen bg-[#0a0a0a] text-white font-mono relative" ]
    [ -- Background vortex (hidden on mobile)
      HH.div [ Page.cls "vortex fixed top-[-200px] right-[-200px] opacity-50 hidden md:block" ] []
    , HH.div [ Page.cls "vortex fixed bottom-[-400px] left-[-400px] opacity-30 hidden md:block" ] []
    , Page.nav
    , staticHero
    , Page.diagnostic
    , Page.socialProof
    , Page.logos
    , Page.problem
    , Page.whyNotDiy
    , Page.services
    , Page.process
    , Page.beforeAfter
    , Page.terminal
    , Page.stackComparison
    , Page.techStack
    , Page.liveActivity
    , Page.testimonials
    , Page.pricing
    , Page.faq
    , Page.antiTestimonials
    , Page.caseStudies
    , Page.whatWeDont
    , Page.guarantee
    , Page.founderNote
    , Page.urgency
    , Page.metrics
    , staticSubmit
    , Page.altCta
    , Page.nerdDive
    , Page.footer
    ]

-- ============================================================
-- STATIC HERO (matches Page.hero without event handlers)
-- ============================================================

staticHero :: forall w i. HH.HTML w i
staticHero =
  HH.section
    [ Page.cls "pt-24 md:pt-32 pb-16 md:pb-24 px-4 md:px-10" ]
    [ HH.div
        [ Page.cls "max-w-4xl" ]
        [ HH.p
            [ Page.cls "text-[10px] md:text-[11px] tracking-[3px] md:tracking-[4px] text-white/30 mb-4 md:mb-6" ]
            [ HH.text "/// AI-GENERATED CODE CLEANUP" ]
        , HH.h1
            [ Page.cls "text-[32px] md:text-[64px] font-normal leading-[1.1] mb-4 md:mb-6" ]
            [ HH.span [ Page.cls "glow-1" ] [ HH.text "Your AI broke it." ]
            , HH.br_
            , HH.span [ Page.cls "text-white/40 glow-2" ] [ HH.text "We fix it." ]
            ]
        , HH.p
            [ Page.cls "text-[15px] md:text-[18px] text-white/40 max-w-xl mb-6 md:mb-8 leading-relaxed" ]
            [ HH.text "Vibe-coded apps cleaned up by engineers who understand what the AI was "
            , HH.span [ Page.cls "italic" ] [ HH.text "trying" ]
            , HH.text " to do. Same-day turnaround. Flat rate."
            ]
        -- CTA form (static version - no onSubmit handler)
        , HH.form
            [ Page.cls "flex flex-col md:flex-row gap-3 max-w-lg mb-4"
            , HP.attr (HH.AttrName "action") "#submit"
            ]
            [ HH.input
                [ HP.type_ HP.InputText
                , HP.placeholder "github.com/you/broken-app"
                , Page.cls "flex-1 px-4 py-3 rounded text-[13px] bg-white/5 border border-white/20 focus:border-white/40 focus:outline-none placeholder:text-white/25"
                ]
            , HH.button
                [ HP.type_ HP.ButtonSubmit
                , Page.cls "px-6 py-3 rounded text-[12px] tracking-[1px] font-medium bg-white text-[#0a0a0a] hover:bg-white/90 hover:translate-y-[-1px] transition-all"
                ]
                [ HH.text "GET QUOTE" ]
            ]
        , HH.p
            [ Page.cls "text-[10px] md:text-[11px] text-white/20 mb-8 md:mb-10" ]
            [ HH.text "quoted in < 1 hour · fixed in < 24 hours · flat rate" ]
        , HH.div
            [ Page.cls "flex gap-4" ]
            [ HH.a
                [ HP.href "#services"
                , Page.cls "px-4 md:px-5 py-2 rounded text-[10px] md:text-[11px] tracking-[1px] border border-white/15 text-white/50 hover:border-white/30 hover:text-white/80 transition-all"
                ]
                [ HH.text "SEE HOW IT WORKS" ]
            ]
        ]
    ]

-- ============================================================
-- STATIC SUBMIT (no event handlers)
-- ============================================================

staticSubmit :: forall w i. HH.HTML w i
staticSubmit =
  HH.section
    [ HP.id "submit"
    , Page.cls "py-20 md:py-32 px-4 md:px-10 bg-gradient-to-b from-transparent to-[#5DCAA5]/5 relative"
    ]
    [ HH.div
        [ Page.cls "absolute inset-0 bg-gradient-to-t from-[#5DCAA5]/10 to-transparent opacity-50" ] []
    , HH.div
        [ Page.cls "max-w-lg mx-auto text-center relative z-10" ]
        [ HH.span
            [ Page.cls "text-[10px] md:text-[11px] tracking-[2px] text-[#5DCAA5]/60 block mb-4" ]
            [ HH.text "/// READY?" ]
        , HH.h2
            [ Page.cls "text-[28px] md:text-[36px] font-normal mb-4 md:mb-6" ]
            [ HH.text "Submit your repo." ]
        , HH.p
            [ Page.cls "text-[13px] md:text-[14px] text-white/40 mb-8 md:mb-10" ]
            [ HH.text "We'll diagnose it, quote it, and have it back to you before you can hire a contractor." ]
        , HH.div
            [ Page.cls "space-y-3 md:space-y-4" ]
            [ HH.input
                [ HP.type_ HP.InputText
                , HP.placeholder "github.com/your/repo"
                , Page.cls "w-full px-4 py-3 md:py-4 rounded bg-white/5 border border-white/10 text-[13px] md:text-[14px] placeholder:text-white/20 focus:outline-none focus:border-[#5DCAA5]/50 transition-all"
                ]
            , HH.input
                [ HP.type_ HP.InputText
                , HP.placeholder "your@email.com"
                , Page.cls "w-full px-4 py-3 md:py-4 rounded bg-white/5 border border-white/10 text-[13px] md:text-[14px] placeholder:text-white/20 focus:outline-none focus:border-[#5DCAA5]/50 transition-all"
                ]
            , HH.button
                [ HP.type_ HP.ButtonSubmit
                , Page.cls "w-full px-6 py-3 md:py-4 rounded bg-[#5DCAA5] text-[#0a0a0a] text-[12px] md:text-[13px] tracking-[1px] font-medium hover:bg-[#5DCAA5]/90 transition-all"
                ]
                [ HH.text "GET DIAGNOSIS →" ]
            ]
        , HH.p
            [ Page.cls "text-[10px] text-white/20 mt-4 md:mt-6" ]
            [ HH.text "Diagnosis is free. Quote delivered in under 1 hour." ]
        ]
    ]
