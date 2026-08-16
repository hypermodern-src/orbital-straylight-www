# Early-access nurture sequence (drafts for review)

Six emails between signup and launch, per the pre-launch plan. Style rules apply: no em-dashes, lay-readable, bold Orbital product names on first use, every number labeled measured, target, or estimate. Replies matter more than opens: a founder reads and answers replies, and reply content feeds the launch email.

Segmentation available from the signup form: product list joined (cache, build, platform) and the optional "what do you build with" answer (Nix / Bazel or Buck2 / GitHub Actions / other / compliance or safety-critical). Compliance signups get a personal founder note instead of emails 3 to 5.

`TODO(team)` marks everything blocked on pricing, dates, or unshipped features.

---

## Email 1 · immediately on signup · "You're in"

Subject: You're on the Orbital early-access list

You're in. **CACHE**, verified binary storage, targets an August 2026 public release; **BUILD**, the typed build system, targets September. You'll hear from us a handful of times between now and then: what we're building, how the benchmarks are run, and one early-access offer before the public release.

Your referral link, if teammates share your build: {{referral_link}}
One referral: a boosted free-tier allowance for your first launch month (exact allowance publishes with pricing). Three: access ahead of the public release, plus a priority slot for the proof bot when it ships (planned; it opens a pull request against your repo and reports before and after times measured on your own code).

Reply to this email and a founder reads it.

## Email 2 · day 3 or 4 · the problem, not the product

Subject: The build that lied to you

The failure nobody logs: an artifact store that verified an upload once, months ago, and has been trusting those bytes ever since. Every fetch since then was an act of faith. Meanwhile your agents multiplied the number of builds, your CI bill went up in March, and the one thing nobody can tell you is whether the binary that shipped is the binary that was built.

That moment, when you realize you cannot answer "where did this artifact actually come from," is the problem we started with.

(No product pitch. One line at the end:) We're building the answer. More soon.

## Email 3 · week 2 · behind the scenes, credibility

Subject: How we run a benchmark before we're allowed to publish it

Walk through the benchmark methodology: pinned hardware, pinned workloads, raw logs, rerunnable harness, and the house rule that no number appears on the site unless it is measured and its basis is linked. Close with the measured claim slot on the site being empty on purpose, until the figure is real. TODO(team): link methodology repo when public.

## Email 4 · week 3 · a direct question

Subject: How do you handle this today?

One question, genuinely asked: when a build breaks or a binary is suspect, how do you trace where it came from today? Two sentences on why we ask (it shapes what ships first). Every reply gets a human answer. Replies here are the launch email's raw material and the clearest early signal of product fit.

## Email 5 · one week before launch · the early-access offer

Subject: Early access opens this week

The list gets in before the public release. The offer, with a real deadline (public launch day):
- TODO(team): the launch offer. Candidates consistent with decided architecture: boosted launch-month allowance, or a concierge onboarding call for the first N teams (founder-led). Founding-member pricing is unavailable as an offer until pricing resolves (Q&A 1.7).
- One CTA. One deadline. Nothing else.

## Email 6 · launch day · short, one action

Subject: CACHE is live

Acknowledge the wait. One paragraph, no re-explaining. One CTA: the config line and where to paste it. Deadline restated if the offer expires. Send segmented: Nix users get the Nix line, Bazel users the Bazel line.

---

Operational notes:
- Open rates on engaged waitlist launch emails typically run 40 to 60% (source: article citing Mailchimp 2025 software benchmarks; external estimate, not our measurement) and decay within 24 to 48 hours; send follow-up to non-openers at hour 36, subject changed, body identical.
- Referral notifications: email the referrer every time someone joins through their link ("a teammate just joined through your link; you are 1 referral from early access"). This is the strongest re-engagement trigger in the loop. Requires a trigger or scheduled job on `waitlist_signups` inserts where `referred_by` is set.
- Do not go silent between emails 4 and 5 if the gap exceeds two weeks; a short progress note (one shipped thing, one screenshot or terminal capture) keeps the list warm. Lists go cold fast when the sender disappears.
- Launch-day invitations go out in referrer order: top referrers first, then compliance-flagged signups (those get a founder email, not the blast), then everyone else. Top referrers are the likeliest advocates and best feedback sources.
- Seeding: the referral loop multiplies signups, it does not create them. The first hundred come from posting into the niche threads where build pain is being discussed (the GTM plan's opportunistic-launch play). The share text on thanks.html is written for exactly that reuse.
- Source analysis: every signup stores first-touch UTM parameters and external referrer in `signup_source`. Before spending effort on a channel, check signups and referral rates per source; a small niche community that converts well beats a broad post that does not.
- Fraud posture: common disposable-email domains are rejected at signup and referral codes are validated by format. Rewards are low-value, so email verification is deliberately deferred; add it if reward value ever grows past nominal (and TODO(team): consider IP rate limiting at that point too).
