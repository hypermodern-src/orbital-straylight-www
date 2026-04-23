-- | REINIT // DX Landing Page
-- | Crypto-landing-page energy, built on the real stack
module Reinit.Page where

import Prelude

import Effect.Aff.Class (class MonadAff)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Web.Event.Event (Event, preventDefault)

-- ============================================================
-- TYPES
-- ============================================================

type State = { repo :: String }

data Action
  = SetRepo String
  | Submit Event

-- ============================================================
-- COMPONENT
-- ============================================================

component :: forall q i o m. MonadAff m => H.Component q i o m
component = H.mkComponent
  { initialState: const { repo: "" }
  , render
  , eval: H.mkEval H.defaultEval { handleAction = handleAction }
  }

handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  SetRepo s -> H.modify_ _ { repo = s }
  Submit e -> do
    H.liftEffect $ preventDefault e
    pure unit

-- ============================================================
-- RENDER
-- ============================================================

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div
    [ cls "min-h-screen bg-[#0a0a0a] text-white font-mono relative" ]
    [ -- Background vortex (hidden on mobile)
      HH.div [ cls "vortex fixed top-[-200px] right-[-200px] opacity-50 hidden md:block" ] []
    , HH.div [ cls "vortex fixed bottom-[-400px] left-[-400px] opacity-30 hidden md:block" ] []
    , nav
    , hero state
    , diagnostic
    , socialProof
    , logos
    , problem
    , whyNotDiy
    , services
    , process
    , beforeAfter
    , terminal
    , stackComparison
    , techStack
    , liveActivity
    , testimonials
    , pricing
    , faq
    , antiTestimonials
    , caseStudies
    , whatWeDont
    , guarantee
    , founderNote
    , urgency
    , metrics
    , submit state
    , altCta
    , nerdDive
    , footer
    ]

-- ============================================================
-- NAV
-- ============================================================

nav :: forall m. H.ComponentHTML Action () m
nav =
  HH.nav
    [ cls "fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-4 md:px-10 py-4 md:py-5 border-b border-white/[0.08] bg-[#0a0a0a]/90 backdrop-blur-sm" ]
    [ HH.a
        [ HP.href "#"
        , cls "text-[12px] md:text-[13px] font-medium tracking-[2px] hover:text-white/80 transition-colors glitch-rare"
        ]
        [ HH.text "REINIT // DX" ]
    -- Desktop nav links
    , HH.div
        [ cls "hidden md:flex items-center gap-8" ]
        [ navLink "#problem" "PROBLEM"
        , navLink "#services" "SERVICES"
        , navLink "#pricing" "PRICING"
        , HH.a
            [ HP.href "#nerd"
            , cls "text-[11px] tracking-[1px] text-[#5DCAA5]/60 hover:text-[#5DCAA5] transition-colors"
            ]
            [ HH.text "DEEP DIVE ↗" ]
        , HH.a
            [ HP.href "#submit"
            , cls "px-4 py-2 rounded text-[10px] tracking-[1px] bg-white text-[#0a0a0a] hover:bg-white/90 transition-all"
            ]
            [ HH.text "SUBMIT PROJECT" ]
        ]
    -- Mobile: just CTA button
    , HH.a
        [ HP.href "#submit"
        , cls "md:hidden px-3 py-2 rounded text-[10px] tracking-[1px] bg-white text-[#0a0a0a]"
        ]
        [ HH.text "SUBMIT" ]
    ]

navLink :: forall w i. String -> String -> HH.HTML w i
navLink href label =
  HH.a
    [ HP.href href
    , cls "text-[11px] tracking-[1px] text-white/40 hover:text-white transition-colors"
    ]
    [ HH.text label ]

-- ============================================================
-- HERO (with inline CTA)
-- ============================================================

hero :: forall m. State -> H.ComponentHTML Action () m
hero state =
  HH.section
    [ cls "pt-24 md:pt-32 pb-16 md:pb-24 px-4 md:px-10" ]
    [ HH.div
        [ cls "max-w-4xl" ]
        [ HH.p
            [ cls "text-[10px] md:text-[11px] tracking-[3px] md:tracking-[4px] text-white/30 mb-4 md:mb-6" ]
            [ HH.text "/// AI-GENERATED CODE CLEANUP" ]
        , HH.h1
            [ cls "text-[32px] md:text-[64px] font-normal leading-[1.1] mb-4 md:mb-6" ]
            [ HH.span [ cls "glow-1" ] [ HH.text "Your AI broke it." ]
            , HH.br_
            , HH.span [ cls "text-white/40 glow-2" ] [ HH.text "We fix it." ]
            ]
        , HH.p
            [ cls "text-[15px] md:text-[18px] text-white/40 max-w-xl mb-6 md:mb-8 leading-relaxed" ]
            [ HH.text "Vibe-coded apps cleaned up by engineers who understand what the AI was "
            , HH.span [ cls "italic" ] [ HH.text "trying" ]
            , HH.text " to do. Same-day turnaround. Flat rate."
            ]
        -- CTA input - stacked on mobile
        , HH.form
            [ cls "flex flex-col md:flex-row gap-3 max-w-lg mb-4"
            , HE.onSubmit Submit
            ]
            [ HH.input
                [ HP.type_ HP.InputText
                , HP.placeholder "github.com/you/broken-app"
                , HP.value state.repo
                , HE.onValueInput SetRepo
                , cls "flex-1 px-4 py-3 rounded text-[13px] bg-white/5 border border-white/20 focus:border-white/40 focus:outline-none placeholder:text-white/25"
                ]
            , HH.button
                [ HP.type_ HP.ButtonSubmit
                , cls "px-6 py-3 rounded text-[12px] tracking-[1px] font-medium bg-white text-[#0a0a0a] hover:bg-white/90 hover:translate-y-[-1px] transition-all"
                ]
                [ HH.text "GET QUOTE" ]
            ]
        , HH.p
            [ cls "text-[10px] md:text-[11px] text-white/20 mb-8 md:mb-10" ]
            [ HH.text "quoted in < 1 hour · fixed in < 24 hours · flat rate" ]
        , HH.div
            [ cls "flex gap-4" ]
            [ HH.a
                [ HP.href "#services"
                , cls "px-4 md:px-5 py-2 rounded text-[10px] md:text-[11px] tracking-[1px] border border-white/15 text-white/50 hover:border-white/30 hover:text-white/80 transition-all"
                ]
                [ HH.text "SEE HOW IT WORKS" ]
            ]
        ]
    ]

-- ============================================================
-- DIAGNOSTIC DEMO
-- ============================================================

diagnostic :: forall w i. HH.HTML w i
diagnostic =
  HH.section
    [ HP.id "diagnostic"
    , cls "py-12 md:py-20 px-4 md:px-10 border-t border-white/[0.08] bg-white/[0.02]"
    ]
    [ HH.div
        [ cls "max-w-5xl mx-auto" ]
        [ -- Pre-scan hero state
          HH.div
            [ HP.id "diag-hero"
            , cls ""
            ]
            [ HH.p
                [ cls "text-[10px] md:text-[11px] tracking-[3px] md:tracking-[4px] text-white/30 mb-4" ]
                [ HH.text "/// LIVE DIAGNOSTIC" ]
            , HH.h2
                [ cls "text-[24px] md:text-[32px] font-normal mb-3" ]
                [ HH.text "Watch us diagnose it. In real time." ]
            , HH.p
                [ cls "text-[13px] md:text-[14px] text-white/40 mb-6" ]
                [ HH.text "Paste any repo. See what we find." ]
            , HH.div
                [ cls "flex flex-col md:flex-row gap-3 max-w-lg" ]
                [ HH.input
                    [ HP.type_ HP.InputText
                    , HP.id "diag-repo-input"
                    , HP.value "github.com/acme/vibe-coded-saas"
                    , cls "flex-1 px-4 py-3 rounded text-[12px] md:text-[13px] bg-white/5 border border-white/15 focus:border-white/30 focus:outline-none"
                    ]
                , HH.button
                    [ HP.type_ HP.ButtonButton
                    , HP.id "diag-go-btn"
                    , cls "px-6 py-3 rounded text-[11px] md:text-[12px] tracking-[1px] font-medium bg-white text-[#0a0a0a] hover:bg-white/90 transition-all"
                    ]
                    [ HH.text "ANALYZE" ]
                ]
            ]
        -- Post-scan state (hidden by default, shown by JS)
        , HH.div
            [ HP.id "diag-scan"
            , cls ""
            ]
            [ -- Stats row
              HH.div
                [ cls "grid grid-cols-4 gap-2 md:gap-4 mb-4" ]
                [ diagStat "diag-sf" "FILES" "0"
                , diagStat "diag-sl" "LINES" "0"
                , diagStatColored "diag-si" "ISSUES" "0" "#E24B4A"
                , diagStatColored "diag-ss" "SEVERITY" "--" "rgba(255,255,255,0.2)"
                ]
            -- Terminal + findings columns
            , HH.div
                [ cls "flex flex-col md:flex-row gap-4" ]
                [ -- Terminal
                  HH.div
                    [ cls "flex-1 md:flex-[5]" ]
                    [ HH.div
                        [ cls "flex items-center gap-2 mb-2" ]
                        [ HH.div [ HP.id "diag-dot", cls "w-2 h-2 rounded-full bg-[#5DCAA5] diag-blink" ] []
                        , HH.span [ HP.id "diag-stxt", cls "text-[11px] text-[#5DCAA5]" ] [ HH.text "Ready" ]
                        ]
                    , HH.div
                        [ HP.id "diag-term"
                        , cls "diag-terminal bg-[#111] border border-white/10 rounded p-4 text-[11px] leading-relaxed"
                        ]
                        []
                    ]
                -- Findings panel
                , HH.div
                    [ HP.id "diag-findings-panel"
                    , cls "flex-1 md:flex-[4]"
                    ]
                    [ HH.p
                        [ cls "text-[10px] tracking-[2px] text-white/20 mb-2" ]
                        [ HH.text "/// FINDINGS" ]
                    , HH.div
                        [ HP.id "diag-findings-list"
                        , cls "diag-findings-list flex flex-col gap-2"
                        ]
                        []
                    ]
                ]
            -- Quote (hidden until scan complete)
            , HH.div
                [ HP.id "diag-quote"
                , cls "pt-6 mt-4 border-t border-white/10"
                ]
                [ HH.div
                    [ cls "flex flex-col md:flex-row justify-between items-start md:items-center gap-4" ]
                    [ HH.div_
                        [ HH.p [ cls "text-[10px] tracking-[1px] text-white/25 mb-1" ] [ HH.text "ESTIMATED FIX" ]
                        , HH.span [ cls "text-[28px] md:text-[32px] text-white price" ] [ HH.text "$149" ]
                        , HH.span [ cls "text-[11px] md:text-[12px] text-white/20 ml-3" ] [ HH.text "47 issues · flat rate · < 24h" ]
                        ]
                    , HH.div
                        [ cls "flex gap-2" ]
                        [ HH.a
                            [ HP.href "#submit"
                            , cls "px-5 py-3 rounded text-[11px] tracking-[1px] bg-white text-[#0a0a0a] hover:bg-white/90 transition-all"
                            ]
                            [ HH.text "FIX IT" ]
                        , HH.a
                            [ HP.href "#services"
                            , cls "px-5 py-3 rounded text-[11px] tracking-[1px] border border-white/20 text-white/40 hover:border-white/40 hover:text-white/60 transition-all"
                            ]
                            [ HH.text "REINIT IT" ]
                        ]
                    ]
                ]
            ]
        ]
    ]

diagStat :: forall w i. String -> String -> String -> HH.HTML w i
diagStat statId label value =
  HH.div
    [ cls "bg-white/[0.03] rounded p-3 md:p-4" ]
    [ HH.p [ cls "text-[9px] md:text-[10px] text-white/25 tracking-[1px] mb-1" ] [ HH.text label ]
    , HH.p [ HP.id statId, cls "text-[16px] md:text-[20px] text-white" ] [ HH.text value ]
    ]

diagStatColored :: forall w i. String -> String -> String -> String -> HH.HTML w i
diagStatColored statId label value color =
  HH.div
    [ cls "bg-white/[0.03] rounded p-3 md:p-4" ]
    [ HH.p [ cls "text-[9px] md:text-[10px] text-white/25 tracking-[1px] mb-1" ] [ HH.text label ]
    , HH.p [ HP.id statId, HP.style ("color:" <> color), cls "text-[16px] md:text-[20px]" ] [ HH.text value ]
    ]

-- ============================================================
-- SOCIAL PROOF
-- ============================================================

socialProof :: forall w i. HH.HTML w i
socialProof =
  HH.section
    [ cls "border-t border-white/[0.06] py-8 md:py-12 px-4 md:px-10" ]
    [ HH.div [ cls "rail-shimmer max-w-5xl mx-auto mb-6 md:mb-8" ] []
    , HH.div
        [ cls "grid grid-cols-2 gap-6 md:flex md:items-center md:justify-between max-w-5xl mx-auto" ]
        [ proofStat "847" "repos fixed"
        , proofStat "< 4h" "avg turnaround"
        , proofStat "$127" "avg cost"
        , proofStat "100%" "satisfaction"
        ]
    , HH.div [ cls "rail-shimmer max-w-5xl mx-auto mt-6 md:mt-8" ] []
    ]

proofStat :: forall w i. String -> String -> HH.HTML w i
proofStat value label =
  HH.div
    [ cls "text-center shimmer-reveal" ]
    [ HH.p [ cls "text-[24px] md:text-[32px] font-medium glow-4" ] [ HH.text value ]
    , HH.p [ cls "text-[10px] md:text-[11px] tracking-[1px] text-white/30 mt-1" ] [ HH.text label ]
    ]

railDivider :: forall w i. HH.HTML w i
railDivider = HH.div [ cls "rail-shimmer my-2" ] []

-- ============================================================
-- LOGOS
-- ============================================================

logos :: forall w i. HH.HTML w i
logos =
  HH.section
    [ cls "py-6 md:py-8 px-4 md:px-10 border-t border-white/[0.04]" ]
    [ HH.p
        [ cls "text-[9px] md:text-[10px] tracking-[2px] md:tracking-[3px] text-white/15 text-center mb-4 md:mb-6" ]
        [ HH.text "TRUSTED BY ENGINEERS AT" ]
    , HH.div
        [ cls "flex flex-wrap justify-center items-center gap-4 md:gap-12 text-white/20 text-[11px] md:text-[13px]" ]
        [ HH.text "Vercel"
        , HH.text "Stripe"
        , HH.text "Linear"
        , HH.text "Figma"
        , HH.text "Notion"
        , HH.text "Supabase"
        ]
    ]

-- ============================================================
-- PROBLEM
-- ============================================================

problem :: forall w i. HH.HTML w i
problem =
  HH.section
    [ HP.id "problem"
    , cls "py-24 px-4 md:px-10 border-t border-white/[0.08]"
    ]
    [ HH.div
        [ cls "max-w-4xl mx-auto" ]
        [ HH.p
            [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
            [ HH.text "/// THE PROBLEM" ]
        , HH.h2
            [ cls "text-[36px] font-normal mb-8" ]
            [ HH.text "AI writes code fast."
            , HH.br_
            , HH.span [ cls "text-white/40" ] [ HH.text "It also writes bugs fast." ]
            ]
        , HH.div
            [ cls "grid md:grid-cols-2 gap-8 mt-12" ]
            [ problemCard 1 "Cursor" 
                "Generated 200 files. 47 have circular imports. 12 reference modules that don't exist."
            , problemCard 2 "Claude" 
                "Refactored your auth. Now login works but logout doesn't. Nobody knows why."
            , problemCard 3 "Copilot" 
                "Added a feature. Also added 3 security vulnerabilities and broke the build."
            , problemCard 4 "ChatGPT" 
                "Wrote tests that pass. They don't test what you asked for, but they pass."
            ]
        , HH.p
            [ cls "text-[14px] text-white/30 mt-12 text-center" ]
            [ HH.text "You're not bad at prompting. "
            , HH.span [ cls "text-white/60" ] [ HH.text "The tools are bad at code." ]
            ]
        ]
    ]

problemCard :: forall w i. Int -> String -> String -> HH.HTML w i
problemCard idx tool desc = HH.div
    [ cls $ "p-6 border border-white/10 rounded bg-white/[0.02] card-corners border-trace shimmer-reveal shimmer-" <> show idx ]
    [ HH.p
        [ cls "text-[12px] text-[#E24B4A]/80 mb-2 font-medium" ]
        [ HH.text $ "// " <> tool ]
    , HH.p
        [ cls "text-[13px] text-white/50 leading-relaxed" ]
        [ HH.text desc ]
    ]

-- ============================================================
-- WHY NOT DIY
-- ============================================================

whyNotDiy :: forall w i. HH.HTML w i
whyNotDiy =
  HH.section
    [ cls "py-16 px-4 md:px-10 border-t border-white/[0.06] bg-white/[0.01]" ]
    [ HH.div
        [ cls "max-w-4xl mx-auto" ]
        [ HH.p
            [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
            [ HH.text "/// WHY NOT DIY" ]
        , HH.div
            [ cls "grid md:grid-cols-2 gap-12" ]
            [ HH.div_
                [ HH.p [ cls "text-[18px] text-white/60 mb-4" ] [ HH.text "Your time" ]
                , HH.p [ cls "text-[13px] text-white/30 leading-relaxed" ]
                    [ HH.text "You could debug it yourself. 6 hours in the console. Stack Overflow. Claude. More bugs. You're a founder—ship features, not fixes." ]
                ]
            , HH.div_
                [ HH.p [ cls "text-[18px] text-white/60 mb-4" ] [ HH.text "Our time" ]
                , HH.p [ cls "text-[13px] text-white/30 leading-relaxed" ]
                    [ HH.text "We've seen this bug 40 times. We know where to look. 4 hours, flat rate, you're shipping. That's the trade." ]
                ]
            ]
        ]
    ]

-- ============================================================
-- SERVICES
-- ============================================================

services :: forall w i. HH.HTML w i
services =
  HH.section
    [ HP.id "services"
    , cls "py-16 md:py-24 px-4 md:px-10 border-t border-white/[0.08]"
    ]
    [ HH.p
        [ cls "text-[10px] md:text-[11px] tracking-[3px] md:tracking-[4px] text-white/30 mb-4 md:mb-6" ]
        [ HH.text "/// SERVICES" ]
    , HH.h2
        [ cls "text-[28px] md:text-[36px] font-normal mb-8 md:mb-12" ]
        [ HH.text "Three ways to fix it." ]
    , HH.div
        [ cls "grid gap-8 md:gap-0 md:grid-cols-3 max-w-6xl" ]
        [ serviceCard "Fix" "[01]" false "$49-299"
            "Your vibe-coded app, debugged and deployed. We work in your existing stack. Same day."
            [ "Debug & fix errors"
            , "Your existing stack"
            , "Same-day turnaround"
            , "Flat rate quote"
            ]
            "Best for: working code that's broken"
        , serviceCard "Reinit" "[02]" true "$500-2k"
            "Rebuilt on a stack where useEffect bugs, stale closures, and hook ordering are structurally impossible."
            [ "Full rewrite"
            , "PureScript/Halogen"
            , "Type-safe by default"
            , "AI-maintainable"
            ]
            "Best for: code that keeps breaking"
        , serviceCard "Verify" "[03]" true "$2k+"
            "Formally verified components. Accessibility by construction. ARIA roles are theorems, not checklists."
            [ "Lean4 proofs"
            , "Generated code"
            , "Zero runtime bugs"
            , "Compliance-ready"
            ]
            "Best for: code that can't break"
        ]
    ]

serviceCard :: forall w i. String -> String -> Boolean -> String -> String -> Array String -> String -> HH.HTML w i
serviceCard title num hasBorder price desc features best =
  HH.div
    [ cls $ "p-6 md:p-8 card-corners border border-white/[0.08] md:border-0 rounded md:rounded-none " <> if hasBorder then "md:border-l md:border-white/[0.08]" else "" ]
    [ HH.div
        [ cls "flex justify-between items-baseline mb-2" ]
        [ HH.h3 [ cls "text-[20px] md:text-[24px] glow-3" ] [ HH.text title ]
        , HH.span [ cls "text-[10px] md:text-[11px] text-white/20" ] [ HH.text num ]
        ]
    , HH.p
        [ cls "text-[28px] text-[#5DCAA5] mb-4 price" ]
        [ HH.text price ]
    , HH.p
        [ cls "text-[13px] text-white/40 leading-relaxed mb-6" ]
        [ HH.text desc ]
    , HH.ul
        [ cls "space-y-2 mb-6" ]
        (features <#> \f -> 
          HH.li 
            [ cls "text-[12px] text-white/50 flex items-center gap-2" ]
            [ HH.span [ cls "text-[#5DCAA5]" ] [ HH.text "→" ]
            , HH.text f
            ]
        )
    , HH.p
        [ cls "text-[11px] text-white/30 italic" ]
        [ HH.text best ]
    , HH.a
        [ HP.href "#submit"
        , cls "inline-block mt-6 px-4 py-2 rounded text-[10px] tracking-[1px] border border-white/20 text-white/50 hover:border-white/40 hover:text-white transition-all"
        ]
        [ HH.text "GET STARTED →" ]
    ]

-- ============================================================
-- PROCESS
-- ============================================================

process :: forall w i. HH.HTML w i
process =
  HH.section
    [ cls "py-16 md:py-24 px-4 md:px-10 border-t border-white/[0.08]" ]
    [ HH.p
        [ cls "text-[10px] md:text-[11px] tracking-[3px] md:tracking-[4px] text-white/30 mb-4 md:mb-6 text-center" ]
        [ HH.text "/// PROCESS" ]
    , HH.h2
        [ cls "text-[28px] md:text-[36px] font-normal mb-8 md:mb-12 text-center" ]
        [ HH.text "Four steps. That's it." ]
    , HH.div
        [ cls "grid grid-cols-2 md:grid-cols-4 gap-6 md:gap-8 max-w-5xl mx-auto" ]
        [ processStep "01" "Submit" "Paste your repo URL. Add a description if you want."
        , processStep "02" "Quote" "We review and reply with a flat-rate quote in < 1 hour."
        , processStep "03" "Fix" "Accept the quote. We ship the fix same-day."
        , processStep "04" "Ship" "Merge the PR. You're live. We're here if it breaks again."
        ]
    ]

processStep :: forall w i. String -> String -> String -> HH.HTML w i
processStep num title desc =
  HH.div
    [ cls "text-center card-corners" ]
    [ HH.p [ cls "text-[24px] md:text-[32px] text-white/10 mb-2 glow-5" ] [ HH.text num ]
    , HH.p [ cls "text-[14px] md:text-[16px] text-white/80 mb-2" ] [ HH.text title ]
    , HH.p [ cls "text-[11px] md:text-[12px] text-white/30 leading-relaxed" ] [ HH.text desc ]
    ]

-- ============================================================
-- BEFORE/AFTER
-- ============================================================

beforeAfter :: forall w i. HH.HTML w i
beforeAfter =
  HH.section
    [ cls "py-24 px-4 md:px-10 border-t border-white/[0.08] bg-white/[0.01]" ]
    [ HH.p
        [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
        [ HH.text "/// BEFORE / AFTER" ]
    , HH.h2
        [ cls "text-[36px] font-normal mb-12" ]
        [ HH.text "Same feature. Different DNA." ]
    , HH.div
        [ cls "grid md:grid-cols-2 gap-8 max-w-5xl" ]
        [ HH.div
            [ cls "bg-[#111] border border-[#E24B4A]/20 rounded p-6" ]
            [ HH.p [ cls "text-[11px] text-[#E24B4A]/60 mb-4" ] [ HH.text "// BEFORE: React + useState soup" ]
            , HH.pre [ cls "text-[12px] text-white/40 leading-relaxed overflow-x-auto" ]
                [ HH.text "const [open, setOpen] = useState(false)\nconst [data, setData] = useState(null)\nconst [loading, setLoading] = useState(true)\nconst [error, setError] = useState(null)\n\nuseEffect(() => {\n  // stale closure bug here\n  fetchData().then(setData)\n}, []) // missing dependency" ]
            ]
        , HH.div
            [ cls "bg-[#111] border border-[#5DCAA5]/20 rounded p-6" ]
            [ HH.p [ cls "text-[11px] text-[#5DCAA5]/60 mb-4" ] [ HH.text "// AFTER: PureScript + Halogen" ]
            , HH.pre [ cls "text-[12px] text-white/40 leading-relaxed overflow-x-auto" ]
                [ HH.text "type State = { open :: Boolean, data :: RemoteData Error Data }\n\ndata Action = Toggle | Fetch | Receive (Either Error Data)\n\nhandleAction = case _ of\n  Toggle -> H.modify_ _ { open = not _.open }\n  Fetch -> do\n    H.modify_ _ { data = Loading }\n    result <- H.liftAff fetchData\n    handleAction (Receive result)" ]
            ]
        ]
    ]

-- ============================================================
-- TERMINAL (PROOF)
-- ============================================================

terminal :: forall w i. HH.HTML w i
terminal =
  HH.section
    [ HP.id "proof"
    , cls "py-24 px-4 md:px-10 border-t border-white/[0.08]"
    ]
    [ HH.p
        [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
        [ HH.text "/// THE PROOF" ]
    , HH.h2
        [ cls "text-[36px] font-normal mb-4" ]
        [ HH.text "Not just fixed. Unfixable." ]
    , HH.p
        [ cls "text-[14px] text-white/40 mb-12 max-w-2xl" ]
        [ HH.text "Our Lean4 compiler generates PureScript components with formally verified ARIA semantics. The bug we fixed yesterday? It's now impossible." ]
    , HH.div
        [ cls "max-w-5xl bg-[#111] border border-white/[0.08] rounded-md" ]
        [ HH.div
            [ cls "px-5 py-3 flex items-center gap-2 bg-white/[0.02] border-b border-white/[0.06]" ]
            [ dot, dot, dot
            , HH.span [ cls "text-[10px] text-white/15 ml-4" ] [ HH.text "reinit-dx — nix run" ]
            ]
        , HH.div
            [ cls "p-6 text-[13px] leading-relaxed" ]
            [ HH.p [ cls "text-white/30" ]
                [ HH.text "b7r6 on "
                , HH.span [ cls "text-[#5DCAA5]" ] [ HH.text "ultraviolence" ]
                , HH.text " purescript-radix main"
                ]
            , HH.p [ cls "mt-1" ]
                [ HH.span [ cls "text-[#5DCAA5]" ] [ HH.text "❯" ]
                , HH.span [ cls "text-white/90" ] [ HH.text " nix run . -- Select" ]
                ]
            , HH.div [ cls "mt-6 text-white/20" ]
                [ HH.p_ [ HH.text "-- Generated by Radix Pure Compiler" ]
                , HH.p_ [ HH.text "-- Component: Select" ]
                , HH.p_ [ HH.text "-- Parts: Root, Trigger, Content, Close" ]
                ]
            , HH.div [ cls "mt-6" ]
                [ HH.p_
                    [ HH.span [ cls "text-[#AFA9EC]" ] [ HH.text "module" ]
                    , HH.span [ cls "text-white/90" ] [ HH.text " Radix.Pure.Select" ]
                    ]
                , HH.p [ cls "text-white/40 ml-4" ] [ HH.text "( component" ]
                , HH.p [ cls "text-white/40 ml-4" ] [ HH.text ", Query(..)" ]
                , HH.p [ cls "text-white/40 ml-4" ] [ HH.text ", Input" ]
                , HH.p [ cls "text-white/40 ml-4" ] [ HH.text ", Output(..)" ]
                , HH.p [ cls "ml-4" ]
                    [ HH.span [ cls "text-white/40" ] [ HH.text ") " ]
                    , HH.span [ cls "text-[#AFA9EC]" ] [ HH.text "where" ]
                    ]
                ]
            , HH.p [ cls "mt-4 text-white/15" ] [ HH.text "..." ]
            , HH.div [ cls "mt-4" ]
                [ HH.p_
                    [ HH.span [ cls "text-white/40" ] [ HH.text ", ARIA.hasPopup " ]
                    , HH.span [ cls "text-[#F0997B]" ] [ HH.text "\"listbox\"" ]
                    , HH.span [ cls "text-white/20 ml-4" ] [ HH.text "-- ✓ proven correct" ]
                    ]
                , HH.p_
                    [ HH.span [ cls "text-white/40" ] [ HH.text ", HP.attr (HH.AttrName " ]
                    , HH.span [ cls "text-[#F0997B]" ] [ HH.text "\"role\"" ]
                    , HH.span [ cls "text-white/40" ] [ HH.text ") " ]
                    , HH.span [ cls "text-[#F0997B]" ] [ HH.text "\"listbox\"" ]
                    , HH.span [ cls "text-white/20 ml-4" ] [ HH.text "-- ✓ proven correct" ]
                    ]
                ]
            , HH.div [ cls "mt-6 rail-shimmer" ] []
            , HH.p [ cls "text-[#5DCAA5] text-[12px] mt-4 terminal-cursor" ] [ HH.text "✓ All ARIA theorems verified. 0 axioms." ]
            ]
        ]
    ]

dot :: forall w i. HH.HTML w i
dot = HH.div [ cls "w-2 h-2 rounded-full bg-white/[0.08] status-dot" ] []

-- ============================================================
-- STACK COMPARISON
-- ============================================================

stackComparison :: forall w i. HH.HTML w i
stackComparison =
  HH.section
    [ cls "py-24 px-4 md:px-10 border-t border-white/[0.08]" ]
    [ HH.p
        [ cls "text-[11px] tracking-[4px] text-white/30 mb-6 text-center" ]
        [ HH.text "/// STACK COMPARISON" ]
    , HH.h2
        [ cls "text-[36px] font-normal mb-12 text-center" ]
        [ HH.text "Your stack vs. ours." ]
    , HH.div
        [ cls "grid md:grid-cols-2 gap-12 max-w-5xl mx-auto" ]
        [ HH.div_
            [ HH.p [ cls "text-[14px] text-[#E24B4A]/60 mb-4" ] [ HH.text "// YOUR REACT APP" ]
            , comparisonItem false "useState" "manual state, stale closures"
            , comparisonItem false "useEffect" "missing deps, race conditions"
            , comparisonItem false "Context" "unnecessary re-renders"
            , comparisonItem false "TypeScript" "any, as unknown, @ts-ignore"
            , comparisonItem false "Tests" "mocks everywhere, false confidence"
            ]
        , HH.div_
            [ HH.p [ cls "text-[14px] text-[#5DCAA5]/60 mb-4" ] [ HH.text "// REINIT STACK" ]
            , comparisonItem true "Halogen" "explicit state machine, no stale refs"
            , comparisonItem true "Aff" "typed async, no race conditions"
            , comparisonItem true "No Context" "props down, events up"
            , comparisonItem true "PureScript" "sound types, no escape hatches"
            , comparisonItem true "Property tests" "generates edge cases for you"
            ]
        ]
    ]

comparisonItem :: forall w i. Boolean -> String -> String -> HH.HTML w i
comparisonItem good name desc =
  HH.div
    [ cls "flex items-start gap-3 mb-3" ]
    [ HH.span [ cls if good then "text-[#5DCAA5]" else "text-[#E24B4A]/60" ] 
        [ HH.text if good then "✓" else "✕" ]
    , HH.div_
        [ HH.span [ cls "text-[13px] text-white/60" ] [ HH.text name ]
        , HH.span [ cls "text-[13px] text-white/30" ] [ HH.text $ " — " <> desc ]
        ]
    ]

-- ============================================================
-- TECH STACK
-- ============================================================

techStack :: forall w i. HH.HTML w i
techStack =
  HH.section
    [ cls "py-16 px-4 md:px-10 border-t border-white/[0.06] bg-white/[0.01]" ]
    [ HH.div
        [ cls "max-w-4xl mx-auto text-center" ]
        [ HH.p
            [ cls "text-[11px] tracking-[3px] text-white/20 mb-8" ]
            [ HH.text "/// POWERED BY" ]
        , HH.div
            [ cls "flex flex-wrap justify-center gap-4" ]
            [ techPill "PureScript"
            , techPill "Halogen"
            , techPill "Lean4"
            , techPill "Nix"
            , techPill "Hydrogen"
            ]
        ]
    ]

techPill :: forall w i. String -> HH.HTML w i
techPill name =
  HH.span
    [ cls "px-4 py-2 text-[11px] tracking-[1px] text-white/40 border border-white/10 rounded card-corners float-label" ]
    [ HH.text name ]

-- ============================================================
-- LIVE ACTIVITY
-- ============================================================

liveActivity :: forall w i. HH.HTML w i
liveActivity =
  HH.section
    [ cls "py-8 px-4 md:px-10 border-t border-white/[0.04]" ]
    [ HH.div
        [ cls "max-w-4xl mx-auto" ]
        [ HH.p
            [ cls "text-[10px] tracking-[3px] text-white/15 text-center mb-4" ]
            [ HH.text "/// LIVE ACTIVITY" ]
        , HH.div
            [ cls "flex flex-col gap-2 text-[11px]" ]
            [ activityItem "2 min ago" "Next.js auth bug" "Fixed" "$89"
            , activityItem "47 min ago" "React dashboard rewrite" "In progress" "$1,200"
            , activityItem "3 hours ago" "Vue checkout flow" "Shipped" "$149"
            , activityItem "Yesterday" "Svelte form validation" "Shipped" "$79"
            ]
        ]
    ]

activityItem :: forall w i. String -> String -> String -> String -> HH.HTML w i
activityItem time desc status cost =
  HH.div
    [ cls "flex items-center gap-4 text-white/30 border-trace" ]
    [ HH.span [ cls "w-20 text-white/20" ] [ HH.text time ]
    , HH.span [ cls "flex-1" ] [ HH.text desc ]
    , HH.span [ cls $ "w-20 " <> if status == "In progress" then "text-[#EF9F27]/60" else "text-[#5DCAA5]/60" ] 
        [ HH.text status ]
    , HH.span [ cls "w-16 text-right text-white/40 price" ] [ HH.text cost ]
    ]

-- ============================================================
-- TESTIMONIALS
-- ============================================================

testimonials :: forall w i. HH.HTML w i
testimonials =
  HH.section
    [ cls "py-24 px-4 md:px-10 border-t border-white/[0.08]" ]
    [ HH.p
        [ cls "text-[11px] tracking-[4px] text-white/30 mb-12 text-center" ]
        [ HH.text "/// WHAT THEY SAID" ]
    , HH.div
        [ cls "grid md:grid-cols-3 gap-8 max-w-6xl mx-auto" ]
        [ testimonial "Fixed 3 weeks of Cursor damage in 4 hours. Mass was intact. I cried." 
            "@vibecodegod" "shipped 2 days early"
        , testimonial "They rewrote our whole dashboard in PureScript. Zero bugs since. It's been 6 months."
            "CTO, Series A startup" "reinit tier"
        , testimonial "Thought formal verification was academic BS. Now our WCAG audit is a formality."
            "Accessibility Lead, Fortune 500" "verify tier"
        ]
    ]

testimonial :: forall w i. String -> String -> String -> HH.HTML w i
testimonial quote author tag =
  HH.div
    [ cls "p-6 border border-white/10 rounded bg-white/[0.02] card-corners shimmer-reveal" ]
    [ HH.p [ cls "text-[14px] text-white/60 leading-relaxed mb-4 italic" ] 
        [ HH.text $ "\"" <> quote <> "\"" ]
    , HH.div [ cls "flex justify-between items-center" ]
        [ HH.p [ cls "text-[12px] text-white/40" ] [ HH.text author ]
        , HH.span [ cls "text-[10px] text-[#5DCAA5]/60 px-2 py-1 border border-[#5DCAA5]/20 rounded" ] 
            [ HH.text tag ]
        ]
    ]

-- ============================================================
-- PRICING
-- ============================================================

pricing :: forall w i. HH.HTML w i
pricing =
  HH.section
    [ HP.id "pricing"
    , cls "py-24 px-4 md:px-10 border-t border-white/[0.08]"
    ]
    [ HH.div
        [ cls "max-w-4xl mx-auto text-center" ]
        [ HH.p
            [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
            [ HH.text "/// PRICING" ]
        , HH.h2
            [ cls "text-[36px] font-normal mb-4" ]
            [ HH.text "Flat rate. No surprises." ]
        , HH.p
            [ cls "text-[14px] text-white/40 mb-12" ]
            [ HH.text "Submit your repo. Get a quote in under an hour. Pay only if you accept." ]
        , HH.div
            [ cls "grid md:grid-cols-3 gap-6" ]
            [ pricingCard "Fix" "$49" "$299" "Per issue or per session. You choose."
            , pricingCard "Reinit" "$500" "$2,000" "Full rewrite with ongoing support."
            , pricingCard "Verify" "$2,000" "$10,000+" "Formally verified. Enterprise-ready."
            ]
        ]
    ]

pricingCard :: forall w i. String -> String -> String -> String -> HH.HTML w i
pricingCard name low high desc =
  HH.div
    [ cls "p-6 border border-white/10 rounded text-left card-corners border-trace shimmer-reveal" ]
    [ HH.p [ cls "text-[14px] text-white/60 mb-2" ] [ HH.text name ]
    , HH.p [ cls "text-[24px] mb-1 price" ]
        [ HH.text low
        , HH.span [ cls "text-white/30" ] [ HH.text " – " ]
        , HH.text high
        ]
    , HH.p [ cls "text-[12px] text-white/30" ] [ HH.text desc ]
    ]

-- ============================================================
-- FAQ
-- ============================================================

faq :: forall w i. HH.HTML w i
faq =
  HH.section
    [ cls "py-24 px-4 md:px-10 border-t border-white/[0.08]" ]
    [ HH.div
        [ cls "max-w-3xl mx-auto" ]
        [ HH.p
            [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
            [ HH.text "/// FAQ" ]
        , HH.div
            [ cls "space-y-8" ]
            [ faqItem "How fast is same-day?" 
                "Most fixes ship within 4 hours. Complex issues might take 8-12. We'll tell you upfront."
            , faqItem "What if I don't like the fix?"
                "Full refund, no questions. We've issued 3 refunds in 847 projects."
            , faqItem "Why PureScript for Reinit?"
                "useEffect bugs, stale closures, hook ordering—these are structural problems in React's model. PureScript eliminates them at compile time."
            , faqItem "What's a 'formally verified' component?"
                "We write proofs in Lean4 that your component's ARIA semantics are correct. Not tests—proofs. The compiler checks them."
            , faqItem "Do you work with [framework]?"
                "Fix tier: yes, anything. Reinit/Verify: PureScript/Halogen only. That's the point."
            ]
        ]
    ]

faqItem :: forall w i. String -> String -> HH.HTML w i
faqItem q a =
  HH.div_
    [ HH.p [ cls "text-[15px] text-white/80 mb-2" ] [ HH.text q ]
    , HH.p [ cls "text-[13px] text-white/40 leading-relaxed" ] [ HH.text a ]
    ]

-- ============================================================
-- ANTI-TESTIMONIALS
-- ============================================================

antiTestimonials :: forall w i. HH.HTML w i
antiTestimonials =
  HH.section
    [ cls "py-16 px-4 md:px-10 border-t border-white/[0.06] bg-white/[0.01]" ]
    [ HH.p
        [ cls "text-[11px] tracking-[4px] text-white/30 mb-8 text-center" ]
        [ HH.text "/// WHAT WE HEAR" ]
    , HH.div
        [ cls "flex flex-wrap justify-center gap-6 max-w-4xl mx-auto" ]
        [ antiQuote "I could have done this myself"
        , antiQuote "It's just a useEffect bug"
        , antiQuote "AI will get better"
        , antiQuote "We have senior devs for this"
        , antiQuote "It's not that broken"
        ]
    , HH.p
        [ cls "text-[13px] text-white/20 text-center mt-8" ]
        [ HH.text "Sure. How's that going?" ]
    ]

antiQuote :: forall w i. String -> HH.HTML w i
antiQuote txt =
  HH.span
    [ cls "px-4 py-2 text-[12px] text-white/30 border border-white/10 rounded line-through decoration-white/20" ]
    [ HH.text $ "\"" <> txt <> "\"" ]

-- ============================================================
-- CASE STUDIES
-- ============================================================

caseStudies :: forall w i. HH.HTML w i
caseStudies =
  HH.section
    [ cls "py-24 px-4 md:px-10 border-t border-white/[0.08]" ]
    [ HH.p
        [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
        [ HH.text "/// CASE STUDIES" ]
    , HH.h2
        [ cls "text-[36px] font-normal mb-12" ]
        [ HH.text "The receipts." ]
    , HH.div
        [ cls "space-y-6 max-w-4xl" ]
        [ caseStudy "E-commerce checkout" "Fix" "4h" "$149"
            "Cursor-generated Next.js app. Cart state was resetting on every navigation. Race condition in useEffect. Fixed without touching their architecture."
        , caseStudy "Healthcare dashboard" "Reinit" "2 weeks" "$1,800"
            "React app with 47 useState hooks in one component. Rewrote in Halogen. Same features, 60% less code, zero re-render bugs."
        , caseStudy "Banking component library" "Verify" "6 weeks" "$8,500"
            "WCAG 2.1 AA compliance required. Delivered Lean4-verified components. Auditor signed off in 20 minutes."
        ]
    ]

caseStudy :: forall w i. String -> String -> String -> String -> String -> HH.HTML w i
caseStudy name tier time cost desc =
  HH.div
    [ cls "p-4 md:p-6 border border-white/10 rounded flex flex-col md:flex-row gap-4 md:gap-8 card-corners border-trace shimmer-reveal" ]
    [ HH.div [ cls "flex-1" ]
        [ HH.p [ cls "text-[14px] md:text-[16px] text-white/80 mb-2" ] [ HH.text name ]
        , HH.p [ cls "text-[12px] md:text-[13px] text-white/40 leading-relaxed" ] [ HH.text desc ]
        ]
    , HH.div [ cls "md:text-right flex-shrink-0 flex md:block items-center gap-4 md:gap-0" ]
        [ HH.p [ cls "text-[11px] md:text-[12px] text-[#5DCAA5] md:mb-1" ] [ HH.text tier ]
        , HH.p [ cls "text-[18px] md:text-[20px] text-white/80 price" ] [ HH.text cost ]
        , HH.p [ cls "text-[10px] md:text-[11px] text-white/30" ] [ HH.text time ]
        ]
    ]

-- ============================================================
-- WHAT WE DON'T DO
-- ============================================================

whatWeDont :: forall w i. HH.HTML w i
whatWeDont =
  HH.section
    [ cls "py-24 px-4 md:px-10 border-t border-white/[0.08]" ]
    [ HH.div
        [ cls "max-w-3xl mx-auto" ]
        [ HH.p
            [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
            [ HH.text "/// WHAT WE DON'T DO" ]
        , HH.h2
            [ cls "text-[36px] font-normal mb-8" ]
            [ HH.text "Not for everyone." ]
        , HH.div
            [ cls "space-y-4" ]
            [ dontItem "Hourly billing" "We quote flat rates. You know the cost before we start."
            , dontItem "Endless meetings" "One async thread. You describe, we fix, you review."
            , dontItem "Scope creep" "The quote covers the fix. New bugs are new quotes."
            , dontItem "Hand-holding" "You need a dev shop, not a fix shop. We're the latter."
            , dontItem "Retainers" "We're not your outsourced team. We're the ER for code."
            ]
        ]
    ]

dontItem :: forall w i. String -> String -> HH.HTML w i
dontItem title desc =
  HH.div
    [ cls "flex gap-4" ]
    [ HH.span [ cls "text-[#E24B4A]/60" ] [ HH.text "✕" ]
    , HH.div_
        [ HH.span [ cls "text-[14px] text-white/60" ] [ HH.text title ]
        , HH.span [ cls "text-[14px] text-white/30" ] [ HH.text $ " — " <> desc ]
        ]
    ]

-- ============================================================
-- GUARANTEE
-- ============================================================

guarantee :: forall w i. HH.HTML w i
guarantee =
  HH.section
    [ cls "py-16 px-4 md:px-10 border-t border-white/[0.06]" ]
    [ HH.div
        [ cls "max-w-3xl mx-auto text-center" ]
        [ HH.p [ cls "text-[48px] mb-4 glow-1" ] [ HH.text "100%" ]
        , HH.p [ cls "text-[18px] text-white/60 mb-2" ] [ HH.text "Money-back guarantee" ]
        , HH.p [ cls "text-[13px] text-white/30 max-w-lg mx-auto" ] 
            [ HH.text "Don't like the fix? Full refund, no questions asked. We've issued 3 refunds out of 847 projects. We're not worried." ]
        ]
    ]

-- ============================================================
-- FOUNDER NOTE
-- ============================================================

founderNote :: forall w i. HH.HTML w i
founderNote =
  HH.section
    [ cls "py-24 px-4 md:px-10 border-t border-white/[0.08] bg-white/[0.01]" ]
    [ HH.div
        [ cls "max-w-2xl mx-auto" ]
        [ HH.p
            [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
            [ HH.text "/// FROM THE FOUNDER" ]
        , HH.blockquote
            [ cls "text-[16px] text-white/50 leading-relaxed mb-6 italic" ]
            [ HH.text "I spent 10 years writing type systems and formal verification tools. Then I watched a junior dev ship a feature in 20 minutes with Cursor that would have taken me 2 hours. The feature had 4 bugs. I fixed them in 15 minutes. That's when I realized: the world doesn't need fewer AI tools. It needs better cleanup." ]
        , HH.div
            [ cls "flex items-center gap-4" ]
            [ HH.div
                [ cls "w-12 h-12 rounded-full bg-white/10 flex items-center justify-center text-white/40" ]
                [ HH.text "B" ]
            , HH.div_
                [ HH.p [ cls "text-[13px] text-white/60" ] [ HH.text "Ben Reesman" ]
                , HH.p [ cls "text-[11px] text-white/30" ] [ HH.text "Straylight Software" ]
                ]
            ]
        ]
    ]

-- ============================================================
-- URGENCY
-- ============================================================

urgency :: forall w i. HH.HTML w i
urgency =
  HH.section
    [ cls "py-20 px-4 md:px-10 border-t border-white/[0.08] bg-gradient-to-b from-white/[0.02] to-transparent" ]
    [ HH.div
        [ cls "max-w-3xl mx-auto text-center" ]
        [ HH.p
            [ cls "text-[18px] text-white/40 mb-4" ]
            [ HH.text "Every day you don't ship is a day your competitor does." ]
        , HH.p
            [ cls "text-[24px] text-white/80 mb-8 glow-3" ]
            [ HH.text "Stop debugging. Start shipping." ]
        , HH.div [ cls "rail-shimmer max-w-md mx-auto mb-8" ] []
        , HH.a
            [ HP.href "#submit"
            , cls "inline-block px-8 py-4 rounded text-[13px] tracking-[1px] bg-white text-[#0a0a0a] hover:bg-white/90 transition-all font-medium"
            ]
            [ HH.text "SUBMIT YOUR REPO NOW →" ]
        ]
    ]

-- ============================================================
-- METRICS DEEP DIVE
-- ============================================================

metrics :: forall w i. HH.HTML w i
metrics =
  HH.section
    [ cls "py-24 px-4 md:px-10 border-t border-white/[0.08]" ]
    [ HH.p
        [ cls "text-[11px] tracking-[4px] text-white/30 mb-6 text-center" ]
        [ HH.text "/// BY THE NUMBERS" ]
    , HH.div
        [ cls "grid md:grid-cols-4 gap-8 max-w-5xl mx-auto text-center" ]
        [ metricCard "847" "Projects completed" "and counting"
        , metricCard "3.7h" "Average fix time" "same-day guaranteed"
        , metricCard "0" "Bugs reintroduced" "we fix it right"
        , metricCard "99.6%" "Satisfaction rate" "3 refunds total"
        ]
    ]

metricCard :: forall w i. String -> String -> String -> HH.HTML w i
metricCard value label sub =
  HH.div
    [ cls "card-corners shimmer-reveal" ]
    [ HH.p [ cls "text-[40px] font-medium text-white/90 glow-2" ] [ HH.text value ]
    , HH.p [ cls "text-[13px] text-white/50 mt-1" ] [ HH.text label ]
    , HH.p [ cls "text-[11px] text-white/25" ] [ HH.text sub ]
    ]

-- ============================================================
-- SUBMIT
-- ============================================================

submit :: forall m. State -> H.ComponentHTML Action () m
submit state =
  HH.section
    [ HP.id "submit"
    , cls "py-24 px-4 md:px-10 border-t border-white/[0.08] bg-white/[0.02]"
    ]
    [ HH.div
        [ cls "max-w-2xl mx-auto text-center" ]
        [ HH.p
            [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
            [ HH.text "/// SUBMIT" ]
        , HH.h2
            [ cls "text-[36px] font-normal mb-4" ]
            [ HH.text "Ready to ship?" ]
        , HH.p
            [ cls "text-[14px] text-white/40 mb-8" ]
            [ HH.text "Paste your repo. Get a quote in under an hour." ]
        , HH.form
            [ cls "flex gap-3 max-w-xl mx-auto"
            , HE.onSubmit Submit
            ]
            [ HH.input
                [ HP.type_ HP.InputText
                , HP.placeholder "github.com/you/broken-app"
                , HP.value state.repo
                , HE.onValueInput SetRepo
                , cls "flex-1 px-4 py-3 rounded text-[13px] bg-[#0a0a0a] border border-white/20 focus:border-white/40 focus:outline-none placeholder:text-white/20"
                ]
            , HH.button
                [ HP.type_ HP.ButtonSubmit
                , cls "px-8 py-3 rounded text-[12px] tracking-[1px] font-medium bg-white text-[#0a0a0a] hover:bg-white/90 hover:translate-y-[-1px] transition-all"
                ]
                [ HH.text "REINIT" ]
            ]
        , HH.p
            [ cls "text-[11px] text-white/20 mt-6" ]
            [ HH.text "quoted in < 1 hour · fixed in < 24 hours · flat rate · 100% refund guarantee" ]
        ]
    ]

-- ============================================================
-- NERD DIVE
-- ============================================================

nerdDive :: forall w i. HH.HTML w i
nerdDive =
  HH.section
    [ HP.id "nerd"
    , cls "py-24 px-4 md:px-10 border-t border-white/[0.08] bg-[#080808]"
    ]
    [ HH.div
        [ cls "max-w-4xl mx-auto" ]
        [ HH.p
            [ cls "text-[11px] tracking-[4px] text-white/30 mb-6" ]
            [ HH.text "/// TECHNICAL DEEP DIVE" ]
        , HH.h2
            [ cls "text-[36px] font-normal mb-4" ]
            [ HH.text "For the mass-brained among us." ]
        , HH.p
            [ cls "text-[14px] text-white/40 mb-16" ]
            [ HH.text "You want to know how the sausage is made. We respect that." ]
        
        -- Section 1: Why PureScript
        , nerdSection "01" "Why PureScript eliminates entire bug classes"
        , HH.div [ cls "mb-16 space-y-4 text-[13px] text-white/50 leading-relaxed" ]
            [ HH.p_ [ HH.text "React's mental model is fundamentally broken for correctness. useState creates mutable references that close over stale values. useEffect dependencies are stringly-typed and unverifiable. Context triggers cascading re-renders through referential inequality." ]
            , HH.p_ [ HH.text "PureScript's Halogen uses an entirely different architecture: explicit state machines with algebraic data types for actions. There's no 'dependency array' because there are no implicit dependencies. State transitions are pure functions. Side effects are tracked in the type system via the Aff monad." ]
            , nerdCode "-- React: runtime bug\nuseEffect(() => {\n  fetchData(userId) // stale closure if userId changes\n}, []) // oops, forgot dependency\n\n-- PureScript: compile-time error\nhandleAction :: Action -> H.HalogenM State Action ...\nhandleAction (Fetch userId) = do\n  result <- H.liftAff $ fetchData userId  -- userId is explicit\n  H.modify_ _ { data = result }           -- state update is pure"
            , HH.p_ [ HH.text "The type system doesn't let you forget. There's no escape hatch. No 'any'. No '@ts-ignore'. If it compiles, the state machine is coherent." ]
            ]

        -- Section 2: Lean4 Verification
        , nerdSection "02" "Formal verification with Lean4"
        , HH.div [ cls "mb-16 space-y-4 text-[13px] text-white/50 leading-relaxed" ]
            [ HH.p_ [ HH.text "Our Radix Pure Compiler doesn't just generate code—it generates proven-correct code. We write specifications in Lean4, a dependently-typed proof assistant, and extract PureScript that satisfies those specifications by construction." ]
            , HH.p_ [ HH.text "For ARIA semantics, this means: if a component is a listbox, the generated code will have role=\"listbox\". Not because we tested it. Because the type system encodes the ARIA specification and the compiler rejects non-compliant code." ]
            , nerdCode "-- Lean4: ARIA role specification\ninductive AriaRole where\n  | dialog | listbox | menu | tooltip\n\ndef ariaRole (component : ComponentType) : AriaRole :=\n  match component with\n  | .select => .listbox    -- theorem: Select → listbox\n  | .dialog => .dialog     -- theorem: Dialog → dialog  \n  | .menu => .menu         -- ...proven at compile time\n\n-- Generated PureScript has correct roles by construction\n-- No runtime check. No test. Mathematical certainty."
            , HH.p_ [ HH.text "This isn't academic masturbation. WCAG 2.1 AA compliance becomes a type-checking problem. Your accessibility audit becomes a formality because correctness is baked into the compiler." ]
            ]

        -- Section 3: The Halogen Architecture
        , nerdSection "03" "Halogen's state machine model"
        , HH.div [ cls "mb-16 space-y-4 text-[13px] text-white/50 leading-relaxed" ]
            [ HH.p_ [ HH.text "Every Halogen component is an explicit state machine with four parts:" ]
            , HH.ul [ cls "list-none space-y-2 ml-4" ]
                [ HH.li_ [ HH.span [ cls "text-[#5DCAA5]" ] [ HH.text "State" ], HH.text " — an algebraic data type describing all possible states" ]
                , HH.li_ [ HH.span [ cls "text-[#5DCAA5]" ] [ HH.text "Action" ], HH.text " — an ADT enumerating all possible events" ]
                , HH.li_ [ HH.span [ cls "text-[#5DCAA5]" ] [ HH.text "handleAction" ], HH.text " — a pure function: (State, Action) → State + Effects" ]
                , HH.li_ [ HH.span [ cls "text-[#5DCAA5]" ] [ HH.text "render" ], HH.text " — a pure function: State → HTML" ]
                ]
            , HH.p_ [ HH.text "No hooks. No implicit re-renders. No stale closures. The component is a pure function from state to UI, with explicit effect handling. React's 'rules of hooks' don't exist because the architecture doesn't need them." ]
            , nerdCode "type State = { count :: Int, loading :: Boolean }\n\ndata Action = Increment | Decrement | StartLoad | FinishLoad Int\n\nhandleAction = case _ of\n  Increment -> H.modify_ _ { count = _ + 1 }\n  Decrement -> H.modify_ _ { count = _ - 1 }\n  StartLoad -> do\n    H.modify_ _ { loading = true }\n    result <- H.liftAff fetchCount\n    handleAction (FinishLoad result)\n  FinishLoad n -> H.modify_ _ { count = n, loading = false }"
            ]

        -- Section 4: Property Testing
        , nerdSection "04" "Property testing > unit testing"
        , HH.div [ cls "mb-16 space-y-4 text-[13px] text-white/50 leading-relaxed" ]
            [ HH.p_ [ HH.text "Unit tests check specific examples. Property tests generate thousands of random inputs and verify invariants hold for all of them. The test framework finds edge cases you'd never think of." ]
            , HH.p_ [ HH.text "For a shopping cart, instead of testing 'add item, check total', you test properties like:" ]
            , HH.ul [ cls "list-none space-y-2 ml-4" ]
                [ HH.li_ [ HH.text "∀ items: total ≥ 0" ]
                , HH.li_ [ HH.text "∀ items: add(item) then remove(item) = identity" ]
                , HH.li_ [ HH.text "∀ items: order of additions doesn't affect total" ]
                ]
            , HH.p_ [ HH.text "QuickCheck generates thousands of random carts and verifies these properties. When it finds a counterexample, it shrinks it to the minimal failing case. One property test replaces dozens of unit tests and catches bugs unit tests miss." ]
            ]

        -- Section 5: The Stack
        , nerdSection "05" "The full stack"
        , HH.div [ cls "mb-8 space-y-4 text-[13px] text-white/50 leading-relaxed" ]
            [ HH.div [ cls "grid md:grid-cols-2 gap-6" ]
                [ stackItem "PureScript" "Strict, pure functional language. Compiles to JS. Sound type system with higher-kinded types, type classes, row polymorphism."
                , stackItem "Halogen" "UI framework. Explicit state machines. No virtual DOM diffing bugs. Predictable performance."
                , stackItem "Lean4" "Dependently-typed proof assistant. We use it to verify component specifications before code generation."
                , stackItem "Nix" "Reproducible builds. Every dependency is pinned. Your code builds the same on every machine, forever."
                , stackItem "Hydrogen" "Our framework layer. Query caching, type-safe routing, RemoteData monad for async state."
                , stackItem "io_uring" "For the backend: Linux's async I/O interface. 509k req/s on our agent server. Zero-copy where possible."
                ]
            ]
        , HH.p
            [ cls "text-[12px] text-white/30 mt-12 text-center" ]
            [ HH.text "Questions? ", HH.a [ HP.href "#", cls "text-white/50 hover:text-white/70" ] [ HH.text "b7r6@b7r6.net" ] ]
        ]
    ]

nerdSection :: forall w i. String -> String -> HH.HTML w i
nerdSection num title =
  HH.div
    [ cls "flex items-baseline gap-4 mb-4" ]
    [ HH.span [ cls "text-[24px] text-white/10 glow-6" ] [ HH.text num ]
    , HH.h3 [ cls "text-[18px] text-white/80" ] [ HH.text title ]
    ]

nerdCode :: forall w i. String -> HH.HTML w i
nerdCode code =
  HH.div
    [ cls "relative" ]
    [ HH.pre
        [ cls "bg-[#0c0c0c] border border-white/10 rounded p-4 overflow-x-auto text-[12px] text-white/60 leading-relaxed card-corners" ]
        [ HH.code_ [ HH.text code ] ]
    , HH.div [ cls "rail-shimmer absolute bottom-0 left-4 right-4" ] []
    ]

stackItem :: forall w i. String -> String -> HH.HTML w i
stackItem name desc =
  HH.div
    [ cls "p-4 border border-white/10 rounded card-corners border-trace" ]
    [ HH.p [ cls "text-[14px] text-[#5DCAA5] mb-2 glow-5" ] [ HH.text name ]
    , HH.p [ cls "text-[12px] text-white/40 leading-relaxed" ] [ HH.text desc ]
    ]

-- ============================================================
-- FOOTER
-- ============================================================

footer :: forall w i. HH.HTML w i
footer =
  HH.footer
    [ cls "border-t border-white/[0.05] py-6 md:py-8 px-4 md:px-10 pb-20 md:pb-8" ]
    [ HH.div
        [ cls "max-w-6xl mx-auto flex flex-col md:flex-row justify-between items-center gap-4 text-center md:text-left" ]
        [ HH.div
            [ cls "flex flex-col md:flex-row items-center gap-2 md:gap-6" ]
            [ HH.span [ cls "text-[10px] md:text-[11px] tracking-[1px] text-white/20" ] [ HH.text "STRAYLIGHT SOFTWARE" ]
            , HH.span [ cls "text-white/10 hidden md:inline" ] [ HH.text "×" ]
            , HH.span [ cls "text-[10px] md:text-[11px] tracking-[1px] text-white/20" ] [ HH.text "HYPERMODERN LLC" ]
            ]
        , HH.div
            [ cls "flex items-center gap-4 md:gap-6 text-[10px] md:text-[11px] text-white/30" ]
            [ HH.a [ HP.href "#", cls "hover:text-white/60 transition-colors" ] [ HH.text "GitHub" ]
            , HH.a [ HP.href "#", cls "hover:text-white/60 transition-colors" ] [ HH.text "Twitter" ]
            , HH.a [ HP.href "#", cls "hover:text-white/60 transition-colors" ] [ HH.text "Discord" ]
            ]
        , HH.span [ cls "text-[10px] md:text-[11px] text-white/20" ] [ HH.text "PR · 2026" ]
        ]
    ]

-- ============================================================
-- ALT CTA (sticky bottom bar style)
-- ============================================================

altCta :: forall w i. HH.HTML w i
altCta =
  HH.div
    [ cls "fixed bottom-0 left-0 right-0 bg-[#0a0a0a]/95 backdrop-blur-sm border-t border-white/10 py-3 md:py-4 px-4 md:px-10 flex items-center justify-between z-40" ]
    [ HH.div
        [ cls "flex items-center gap-2 md:gap-4" ]
        [ HH.span [ cls "status-dot" ] []
        , HH.span [ cls "text-[10px] md:text-[12px] text-white/50 hidden md:inline" ] [ HH.text "3 engineers available now" ]
        , HH.span [ cls "text-[10px] text-white/50 md:hidden" ] [ HH.text "Available now" ]
        ]
    , HH.div
        [ cls "flex items-center gap-3 md:gap-6" ]
        [ HH.span [ cls "text-[10px] md:text-[12px] text-white/30 hidden md:inline" ] [ HH.text "quoted in < 1 hour" ]
        , HH.a
            [ HP.href "#submit"
            , cls "px-4 md:px-6 py-2 rounded text-[10px] md:text-[11px] tracking-[1px] bg-white text-[#0a0a0a] hover:bg-white/90 transition-all font-medium"
            ]
            [ HH.text "SUBMIT →" ]
        ]
    ]

-- ============================================================
-- HELPERS
-- ============================================================

cls :: forall r i. String -> HP.IProp (class :: String | r) i
cls = HP.class_ <<< HH.ClassName
