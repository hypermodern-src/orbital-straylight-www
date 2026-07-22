-- | The seven panels, transcribed class-for-class from the golden mock
-- | (original-mocks/hypermodern-website-final/Hypermodern v2.html). Pure
-- | render functions; the deck wraps them in section.pn with state classes.
module Site.Content
  ( Panel
  , panels
  ) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Int as Int
import Data.String (split)
import Data.String.Pattern (Pattern(..))
import Halogen.HTML as HH
import Halogen.HTML.Core (AttrName(..))
import Halogen.HTML.Properties as HP
import Site.Svg (monogram)

type Panel w i =
  { label :: String -- data-screen-label
  , dark :: Boolean
  , body :: HH.HTML w i
  }

cls :: forall r i. String -> HH.IProp (class :: String | r) i
cls = HP.class_ <<< HH.ClassName

style :: forall r i. String -> HH.IProp r i
style = HP.attr (AttrName "style")

dAttr :: forall r i. String -> String -> HH.IProp r i
dAttr n = HP.attr (AttrName n)

-- watermark ink fill, as in the mock
inkWm :: forall w i. HH.HTML w i
inkWm = HH.div [ cls "mono-wm" ] [ monogram "var(--ink)" ]

sl :: forall w i. String -> String -> HH.HTML w i
sl num name = HH.div [ cls "sl" ] [ HH.span [ cls "sln" ] [ HH.text num ], HH.text (" " <> name) ]

divider :: forall w i. HH.HTML w i
divider = HH.div [ cls "divider" ] []

subhead :: forall w i. String -> HH.HTML w i
subhead t = HH.div [ cls "subhead sr" ] [ HH.text t ]

ax :: forall w i. String -> HH.HTML w i
ax t = HH.div [ cls "ax" ] [ HH.text t ]

panels :: forall w i. Array (Panel w i)
panels = [ hero, thesis, practices, record, method, principles, inquiries ]

-- ============================================================
-- 0: HERO
-- ============================================================

heroWords :: forall w i. Array (HH.HTML w i)
heroWords =
  mapWithIndex word (split (Pattern " ") "Consulting for the technically serious.")
  where
  word i w =
    HH.span
      [ cls "word", style ("animation-delay:" <> show (0.4 + 0.07 * Int.toNumber i) <> "s") ]
      [ HH.text (w <> "\x00A0") ]

hero :: forall w i. Panel w i
hero =
  { label: "01 Home"
  , dark: false
  , body:
      HH.div_
        [ inkWm
        , HH.div [ cls "pb" ]
            [ HH.div [ cls "hero-screen" ]
                [ HH.div [ cls "hl" ]
                    [ HH.div [ cls "hc" ]
                        [ HH.div [ cls "he" ] [ HH.text "Hypermodern LLC · San Juan, Puerto Rico" ]
                        , HH.h1 [ cls "ht", HP.id "htit" ] heroWords
                        , HH.p [ cls "hs" ] [ HH.text "AI-native infrastructure consulting. We build alongside you — and we teach the methodology so it outlasts the engagement." ]
                        , HH.div [ cls "hr" ] []
                        , HH.div [ cls "hero-stats", style "opacity:0;animation:wi 1s cubic-bezier(.22,1,.36,1) 1.2s forwards" ]
                            [ heroStat "20+" "Years shipping systems"
                            , heroStat "29K" "Lines Lean 4, zero sorry"
                            , heroStat "$7B+" "Marginal revenue shipped"
                            ]
                        ]
                    , HH.div [ cls "hg" ]
                        [ HH.div [ style "position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:60%;opacity:.04" ]
                            [ monogram "var(--accent)" ]
                        , HH.div [ cls "gl" ] []
                        , HH.div [ cls "gl" ] []
                        , HH.div [ cls "gl" ] []
                        ]
                    ]
                ]
            , HH.div [ cls "hero-more" ]
                [ divider
                , HH.p [ cls "lede sr" ] [ HH.text "A small firm for problems institutions can't staff." ]
                , HH.div [ cls "pos-grid sr" ]
                    [ posCell "What we do" "Build the hard part" "Inference infrastructure, verified build systems, sub-microsecond data paths. The cross-cutting, unsexy work that never makes a product roadmap."
                    , posCell "How we work" "AI as collaborator" "Frontier models as genuine engineering partners — drafting proofs, tracing architectures, catching errors at compile speed. Not autocomplete."
                    , posCell "What you keep" "The capability" "Every engagement transfers the method. Your team leaves fluent in a way of working most organizations won't discover for years."
                    ]
                ]
            ]
        ]
  }
  where
  heroStat v l = HH.div [ cls "hero-stat" ] [ HH.div [ cls "val" ] [ HH.text v ], HH.div [ cls "lbl" ] [ HH.text l ] ]
  posCell k h p = HH.div [ cls "pos-cell" ] [ HH.div [ cls "k" ] [ HH.text k ], HH.h4_ [ HH.text h ], HH.p_ [ HH.text p ] ]

-- ============================================================
-- 1: THESIS
-- ============================================================

thesis :: forall w i. Panel w i
thesis =
  { label: "02 Thesis"
  , dark: false
  , body:
      HH.div_
        [ inkWm
        , HH.div [ cls "pb" ]
            [ HH.div [ cls "pc" ]
                [ sl "02" "Thesis"
                , HH.div [ cls "tl" ]
                    [ HH.div [ cls "tm" ]
                        [ HH.h2_ [ HH.text "Choices dominate resources. The constraint is the insight." ]
                        , HH.p_ [ HH.text "DeepSeek matched GPT-4 on a fraction of the compute — not because they had better hardware, but because the opposite was true. Export controls meant H100s were expensive and H800s were what they had, so the constraint forced the architecture." ]
                        , HH.p_ [ HH.text "American labs have the compute, but they don't have the constraint, and when you can always add more GPUs, you never learn to subtract. Hypermodern operates like it's under sanctions — by choice — because that's the only way to know what's real." ]
                        , HH.h3_ [ HH.text "We work with frontier AI as genuine collaborators, not autocomplete." ]
                        , HH.p_
                            [ HH.text "The CDR methodology — Claude, DeepSeek, Reesman, alphabetical by convention — is how we formally verified 29,000 lines of Lean 4 with zero "
                            , HH.em_ [ HH.text "sorry" ]
                            , HH.text ", discharged proofs for $0.63, and ship systems that institutional labs can't because their incentive structures won't let them."
                            ]
                        , HH.p_ [ HH.text "This isn't prompt engineering. It's engineering discipline applied to a new kind of collaborator — one that can write proofs, trace architectures, and catch errors at compile speed, but only if you know how to ask. We don't just consult. We transfer the capability. Every engagement leaves your team fluent in a way of working with AI that most organizations won't discover for years." ]
                        , HH.h3_ [ HH.text "Subtraction is the whole discipline." ]
                        , HH.p_
                            [ HH.strong_ [ HH.text "Capability is not the bottleneck; constraint is." ]
                            , HH.text " The engineers who could solve these problems already have jobs — with clearances to protect, stock vesting on a schedule, and politics to navigate. Their incentives are managed by institutions that need them to stay manageable. The work that matters is exactly the work no one's roadmap rewards."
                            ]
                        , HH.p_ [ HH.text "So we impose the constraint ourselves. Fewer launches. Fewer copies. Fewer illusions. We pin layouts, share weights, fuse what we can, and ship. The result is systems that are smaller, faster, and provably correct — not because we are cleverer, but because we refused the option to add more." ]
                        ]
                    , HH.div [ cls "ts_" ]
                        [ HH.div [ cls "gc tq" ]
                            [ HH.blockquote_ [ HH.text "Capability isn't the bottleneck; constraint is. The engineers who could solve this problem have jobs, with clearances to protect, stock vesting on a schedule, career trajectories to manage. Their incentives are managed by institutions that need them to stay manageable." ]
                            , HH.cite_ [ HH.text "The Inhuman Quality of Starlight" ]
                            ]
                        , HH.div [ cls "gc tq" ]
                            [ HH.blockquote_ [ HH.text "Precision is a budget, not a theology. Share weights, pin layouts, fuse what you can, ship." ]
                            , HH.cite_ [ HH.text "Working Axioms · No. 3" ]
                            ]
                        , HH.p [ cls "tnote" ] [ HH.text "We're here to do great work for our own benefit, but we like being the useful kind of competition — all the more so when the stakes are this high." ]
                        ]
                    ]
                ]
            ]
        ]
  }

-- ============================================================
-- 2: PRACTICES
-- ============================================================

practices :: forall w i. Panel w i
practices =
  { label: "03 Practices"
  , dark: false
  , body:
      HH.div_
        [ inkWm
        , HH.div [ cls "pb" ]
            [ HH.div [ cls "pc" ]
                [ sl "03" "Practices"
                , HH.p [ cls "intro-lede sr" ] [ HH.text "Six disciplines. One standard: the system proves itself." ]
                , HH.a [ cls "pub-cta sr", HP.href "../orbital-website-final/Forge.html" ] [ HH.text "Browse the Forge — source & the essays that explain it →" ]
                , HH.div [ cls "pg" ]
                    [ pp "01" "AI Infrastructure" [ HH.text "Architecture and optimization for large-scale inference. GPU kernel design, NVFP4 quantization, and performance engineering across Blackwell and embedded targets." ] [ "Blackwell", "NVFP4", "Inference" ]
                    , pp "02" "Formally Verified Systems" [ HH.text "Build infrastructure and protocol implementations in Lean 4. Supply chain integrity by construction — not by scanning. Zero ", HH.em_ [ HH.text "sorry" ], HH.text "." ] [ "Lean 4", "Proofs", "Provenance" ]
                    , pp "03" "Performance Engineering" [ HH.text "Sub-microsecond latency. Branchless SIMD parsers. HFT-grade order entry. SASS disassembly with 100% roundtrip. We write the code that can't be slow." ] [ "SIMD", "Latency", "SASS" ]
                    , pp "04" "Supply Chain Security" [ HH.text "Reproducible builds with Nix. Deterministic extraction of NVIDIA's CUDA stack. Vulnerability disclosure to the defense community. Security as construction." ] [ "Nix", "Reproducible", "Defense" ]
                    , pp "05" "AI Collaboration & Mentorship" [ HH.text "The CDR methodology: working with frontier models as genuine engineering collaborators. We teach your team the muscle memory that turns AI from novelty into force multiplier." ] [ "CDR", "Transfer", "Fluency" ]
                    , pp "06" "Strategic Advisory" [ HH.text "Technical due diligence, architecture review, and positioning for companies navigating AI capability, export controls, and defense-industrial requirements." ] [ "Due Diligence", "Export", "Positioning" ]
                    ]
                , divider
                , subhead "How the work is shaped"
                , HH.div [ cls "shapes sr" ]
                    [ shape "A" "Build" "We sit in your codebase and ship production systems alongside your team. Hands on keys, not slideware."
                    , shape "B" "Verify" "We encode your invariants as types and discharge them. The kernel signs off, or it doesn't ship."
                    , shape "C" "Transfer" "We leave your engineers fluent in the method. No bench, no dependency, no vendor lock."
                    , shape "D" "Advise" "We review architecture, diligence targets, and position you for export-controlled and defense work."
                    ]
                , HH.div [ cls "axiom-strip sr" ]
                    [ ax "Logic is hygiene."
                    , ax "Precision is a budget, not a theology."
                    , ax "Share weights, pin layouts, fuse what you can, ship."
                    ]
                ]
            ]
        ]
  }
  where
  pp n h body tags =
    HH.div [ cls "gc pp sc" ]
      [ HH.div [ cls "pn_" ] [ HH.text n ]
      , HH.h3_ [ HH.text h ]
      , HH.p_ body
      , HH.div [ cls "tags" ] (map (\t -> HH.span_ [ HH.text t ]) tags)
      ]
  shape n h p =
    HH.div [ cls "shape" ]
      [ HH.h4_ [ HH.span [ cls "sn" ] [ HH.text n ], HH.text h ], HH.p_ [ HH.text p ] ]

-- ============================================================
-- 3: RECORD
-- ============================================================

record :: forall w i. Panel w i
record =
  { label: "04 Record"
  , dark: false
  , body:
      HH.div_
        [ inkWm
        , HH.div [ cls "pb" ]
            [ HH.div [ cls "pc" ]
                [ sl "04" "Record"
                , HH.div [ cls "roster sr" ]
                    [ person "Founder · Principal" "Benjamin Reesman" "Large-scale computing, performance-sensitive systems, AI infrastructure, and formal verification. Twenty years of systems at scale."
                    , person "Chief Operating Officer" "Jesse Wilson" "Operations, business development, and client engagement. Builds the structure that lets the technical work ship."
                    ]
                , subhead "Selected engagements"
                , HH.div [ cls "rg" ]
                    [ re "2017 – 2018 · Instagram" "Feed Content Bumping" [ HH.text "Model to re-display content delivered but not seen. 10% increase in IG Feed engagement." ] [ dAttr "data-target" "7", dAttr "data-prefix" "$", dAttr "data-suffix" "B/yr ARR" ] "0"
                    , re "2013 – 2017 · Facebook Ads" "Push-Based Budget Consumption" [ HH.text "Novel P2P system for pushing budget consumption statistics in Ads delivery." ] [ dAttr "data-static" "2-3% total FB Ads" ] "2-3% total FB Ads"
                    , re "2011 – 2013 · Facebook Ads" "Early Log-Structured Merge" [ HH.text "Principal implementor of FB's earliest LSM KV database. Served ML features on ~80K machines for all Ads delivery." ] [ dAttr "data-target" "80", dAttr "data-prefix" "~", dAttr "data-suffix" "K machines" ] "0"
                    , re "2018 · Instagram" "Embedding Recommender Systems" [ HH.text "Technical lead on earliest use of embedding-based techniques for extreme-scale recommendation on unstructured UGC." ] [ dAttr "data-static" "EM, ML Infra" ] "EM, ML Infra"
                    , re "2020 – 2022 · Rocinante R&D" "Fastest Known JSON Parser" [ HH.text "~4KB input in ~400ns at p95. Haskell compiler to hand-rolled SIMD and simdjson. Head of Technology." ] [ dAttr "data-target" "400", dAttr "data-suffix" "ns p95" ] "0"
                    , re "2006 – 2010 · Intercasting" "J2ME Browser & JS Engine" [ HH.text "ECMA-262 compiler/VM for mobile. CSS 2.1 layout rendering patent. Co-written with Downey and DiMeo." ] [ dAttr "data-target" "2", dAttr "data-suffix" " patents" ] "0"
                    , re "2024 – Present · Straylight" "Continuity & Estoque" [ HH.text "Formally verified build system, 29K+ lines Lean 4, zero ", HH.em_ [ HH.text "sorry" ], HH.text ". ML inference targeting Blackwell SM120. Defense License." ] [ dAttr "data-target" "29", dAttr "data-suffix" "K lines Lean 4" ] "0"
                    , re "2019 – 2023 · Independent" "GPU & Trading Systems" [ HH.text "Sub-μs glass-to-glass order entry. SASS disassembler with octal encoding discovery. Bioinformatics, BFT load testing." ] [ dAttr "data-target" "100", dAttr "data-suffix" "% roundtrip" ] "0"
                    ]
                , divider
                , subhead "Patents, disclosures & recognition"
                , HH.div [ cls "disc-list sr" ]
                    [ disc "2009" "CSS 2.1 layout rendering" " — granted patent, mobile rendering pipeline."
                    , disc "2010" "ECMA-262 compilation on constrained devices" " — granted patent, co-inventor."
                    , disc "2021" "SASS octal encoding" " — undocumented instruction encoding discovered via 100%-roundtrip disassembly."
                    , disc "2025" "CUDA stack CVE disclosure" " — coordinated vulnerability disclosure to the defense community."
                    , disc "2025" "Estoque Defense License" " — verified inference runtime cleared for embedded targets."
                    , disc "2026" "26 theorems, 0 sorry" " — mdspan-cute bridge, machine-checked end to end."
                    ]
                , HH.div [ cls "rc sr" ] [ HH.text "fbshipit strips internal attribution from all Meta open-source exports. Absence of public git attribution is a structural artifact, not a gap. Left on principle over conduct confirmed by two juries." ]
                ]
            ]
        ]
  }
  where
  person role name p =
    HH.div [ cls "roster-person" ]
      [ HH.div [ cls "role" ] [ HH.text role ], HH.h3_ [ HH.text name ], HH.p_ [ HH.text p ] ]
  re era h body statAttrs statText =
    HH.div [ cls "gc re sr sc" ]
      [ HH.div [ cls "re-era" ] [ HH.text era ]
      , HH.h3_ [ HH.text h ]
      , HH.p_ body
      , HH.div ([ cls "re-stat" ] <> statAttrs) [ HH.text statText ]
      ]
  disc y b rest =
    HH.div [ cls "disc" ]
      [ HH.span [ cls "dy" ] [ HH.text y ]
      , HH.span [ cls "dt" ] [ HH.b_ [ HH.text b ], HH.text rest ]
      ]

-- ============================================================
-- 4: METHOD (dark)
-- ============================================================

method :: forall w i. Panel w i
method =
  { label: "05 Method"
  , dark: true
  , body:
      HH.div_
        [ HH.div [ cls "glow", dAttr "aria-hidden" "true" ] []
        , HH.div [ cls "pb" ]
            [ HH.div [ cls "pc" ]
                [ sl "05" "Method"
                , HH.div [ cls "method-intro" ]
                    [ HH.h2_ [ HH.text "CDR: Claude, DeepSeek, Reesman." ]
                    , HH.p_ [ HH.text "Alphabetical by convention. The methodology behind every engagement. Not a tool — a way of working that produces results institutional labs cannot replicate, because their structure won't let them." ]
                    ]
                , HH.div [ cls "method-grid" ]
                    [ mi "01 · Formulate" "Formulate precisely" "The model is only as good as the question. We teach your team to decompose problems into specifications a theorem prover can check — then hand those specifications to AI collaborators who can draft, iterate, and verify at compile speed."
                    , mi "02 · Verify" "Verify everything" "AI output is a draft, not a deliverable. Every line of code, every proof step, every architectural claim gets verified against the formal spec. The Lean kernel doesn't negotiate. Neither do we."
                    , mi "03 · Route" "Route by strength" "DeepSeek V4 Flash for tool-heavy agentic work at $0.14/M input tokens. Claude for deep architectural reasoning. Humans for taste, judgment, and the thing no model can do: knowing when to stop."
                    , mi "04 · Transfer" "Transfer the capability" "Every engagement ends with your team owning the methodology. Not dependent on us, not locked into a vendor. The muscle memory of working with AI as a genuine collaborator — formulate, draft, verify, ship."
                    ]
                , HH.div [ cls "cascade", style "margin-top:clamp(2rem,4vh,3rem)" ]
                    [ HH.div [ cls "cascade-step" ] [ HH.text "High Trust" ]
                    , HH.div [ cls "cascade-arrow" ] [ HH.text "→" ]
                    , HH.div [ cls "cascade-step" ] [ HH.text "High Integrity" ]
                    , HH.div [ cls "cascade-arrow" ] [ HH.text "→" ]
                    , HH.div [ cls "cascade-step" ] [ HH.text "High Accountability" ]
                    , HH.div [ cls "cascade-arrow" ] [ HH.text "→" ]
                    , HH.div [ cls "cascade-step", style "border-color:hsla(var(--hue),58%,48%,.4);color:hsla(var(--hue),20%,99%,.8)" ] [ HH.text "Unreplicable Outcomes" ]
                    ]
                , divider
                , subhead "What an engagement looks like"
                , HH.div [ cls "timeline sr" ]
                    [ tline "Week 0" "Scope & specify" "We map the problem to invariants. If it can't be specified, we say so before money changes hands."
                    , tline "Weeks 1–2" "Spike & prove" "A working spike of the hard part, with the load-bearing claims formally discharged. Early, ugly, correct."
                    , tline "Weeks 3–6" "Build alongside" "We ship into your codebase with your engineers in the loop — pairing on the CDR method as we go."
                    , tline "Close" "Transfer & leave" "Runbooks, proofs, and a team that can carry it. No retainer designed to make us indispensable."
                    ]
                , divider
                , subhead "Routing, concretely"
                , HH.div [ cls "routes sr" ]
                    [ route "DeepSeek V4 Flash" "Tool-heavy agentic loops, broad search, cheap iteration." "$0.14 / M in"
                    , route "Claude" "Architectural reasoning, proof structure, prose that has to be right." "Depth"
                    , route "Lean kernel" "The final arbiter. Accepts or rejects. Does not have opinions." "Ground truth"
                    , route "Human" "Taste, judgment, and knowing when the thing is done." "Stop"
                    ]
                , HH.div [ cls "dk-axioms sr" ]
                    [ ax "The terminal doesn't lie. The terminal doesn't comfort."
                    , ax "Understand invariants or you don't understand."
                    , ax "Fewer launches, fewer copies, fewer illusions."
                    ]
                ]
            ]
        ]
  }
  where
  mi k h p =
    HH.div [ cls "method-item sc" ]
      [ HH.span [ cls "mk" ] [ HH.text k ], HH.h4_ [ HH.text h ], HH.p_ [ HH.text p ] ]
  tline w h p =
    HH.div [ cls "tline" ]
      [ HH.span [ cls "tw" ] [ HH.text w ]
      , HH.div [ cls "tb" ] [ HH.h5_ [ HH.text h ], HH.p_ [ HH.text p ] ]
      ]
  route n d p =
    HH.div [ cls "route" ]
      [ HH.span [ cls "rn" ] [ HH.text n ]
      , HH.span [ cls "rd" ] [ HH.text d ]
      , HH.span [ cls "rp" ] [ HH.text p ]
      ]

-- ============================================================
-- 5: PRINCIPLES (dark)
-- ============================================================

principles :: forall w i. Panel w i
principles =
  { label: "06 Principles"
  , dark: true
  , body:
      HH.div_
        [ HH.div [ cls "glow", dAttr "aria-hidden" "true" ] []
        , HH.div [ cls "pb" ]
            [ HH.div [ cls "pc" ]
                [ sl "06" "Principles"
                , HH.div [ cls "method-intro" ]
                    [ HH.h2_ [ HH.text "Nullius in verba." ]
                    , HH.p_ [ HH.text "On nobody's authority. The standards we hold ourselves to before we ask you to hold us to anything. They apply bidirectionally — to us, and to you." ]
                    ]
                , HH.div [ cls "pri-grid" ]
                    [ pri "The supply chain is the attack surface" "The build system is the proof. Systems that cannot formally account for their own provenance are systems that cannot be trusted."
                    , pri "Declared axioms, zero sorry" "Every assumption is explicit. Every derivation is machine-checked. Conjectures are labeled. This is the Straylight standard."
                    , pri "Capacity, never policy" "Security is a property of construction, not configuration. If the system can be misconfigured into an insecure state, it is insecure."
                    , pri "Narrow and deep" "We take very few engagements. The ones we take receive the full weight of attention. No bench, no leverage model, no juniors."
                    , pri "Verification over reputation" "Claims are settled by evidence, not credentials. We would rather show you a proof than tell you our résumé."
                    , pri "We launch once" "Symmetry is a way of not lying to yourself. We ship the thing correctly the first time and we do not come back to patch what we should have proven."
                    ]
                , HH.div [ cls "dk-axioms sr", style "margin-top:clamp(2rem,4vh,3rem)" ]
                    [ ax "Symmetry is a way of not lying to yourself."
                    , ax "The garage is everywhere now."
                    , ax "We launch once and never come back."
                    , ax "Prices are memories of power."
                    ]
                ]
            ]
        ]
  }
  where
  pri h p = HH.div [ cls "pri-item sc" ] [ HH.h4_ [ HH.text h ], HH.p_ [ HH.text p ] ]

-- ============================================================
-- 6: INQUIRIES
-- ============================================================

inquiries :: forall w i. Panel w i
inquiries =
  { label: "07 Inquiries"
  , dark: false
  , body:
      HH.div_
        [ inkWm
        , HH.div [ cls "pb" ]
            [ HH.div [ cls "pc" ]
                [ sl "07" "Inquiries"
                , HH.div [ cls "cb" ]
                    [ HH.div [ cls "cl" ]
                        [ HH.h2_ [ HH.text "Begin a conversation." ]
                        , HH.p_ [ HH.text "Engagements are by introduction or direct inquiry. We respond to serious requests within 48 hours. Mentorship and methodology transfer available as standalone engagements." ]
                        ]
                    , HH.div [ cls "cr" ]
                        [ HH.a [ HP.href "mailto:inquire@hypermodern.consulting" ] [ HH.text "inquire@hypermodern.consulting" ]
                        , HH.div [ cls "cm" ] [ HH.text "Hypermodern LLC · Act 60 · Puerto Rico" ]
                        ]
                    ]
                , divider
                , subhead "Ways to engage"
                , HH.div [ cls "engage sr" ]
                    [ eng "01" "Build" "A fixed-scope sprint on the hard part of your system, shipped alongside your team. Typically 4–8 weeks."
                    , eng "02" "Verify" "We take an existing system and encode its load-bearing claims as machine-checked proofs."
                    , eng "03" "Mentor" "Standalone capability transfer. Your team leaves fluent in the CDR method. No ongoing dependency."
                    ]
                , divider
                , subhead "Before you write"
                , HH.div [ cls "faq sr" ]
                    [ fq "What makes a good fit?" "A problem that is cross-cutting, correctness-sensitive, and that your roadmap keeps deferring. The harder and less glamorous, the more interested we are."
                    , fq "Do you sign NDAs and clear for defense work?" "Yes. We work under export-controlled and defense-industrial requirements and disclose vulnerabilities responsibly."
                    , fq "Will we depend on you afterward?" "No — by design. Every engagement ends with your team owning the method and the proofs. We would rather lose the retainer than keep you captive."
                    ]
                , HH.div [ cls "epigraph sr" ]
                    [ HH.p_ [ HH.text "Not because we have better tools. Not because we have more capital. Because we take integrity seriously. Because integrity enables trust. Because trust enables accountability. Because accountability enables velocity. Because velocity compounds into outcomes that no amount of money can buy." ]
                    , HH.cite_ [ HH.text "Build trust. Ship code. Arbitrage dysfunction." ]
                    ]
                ]
            ]
        ]
  }
  where
  eng k h p = HH.div [ cls "eng-cell" ] [ HH.div [ cls "k" ] [ HH.text k ], HH.h4_ [ HH.text h ], HH.p_ [ HH.text p ] ]
  fq h p = HH.div [ cls "fq" ] [ HH.h5_ [ HH.text h ], HH.p_ [ HH.text p ] ]
