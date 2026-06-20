# Anti-slop research notes

Sourced findings behind the `anti-slop` skill rules. Each rule in `SKILL.md`
should trace to at least one source here.

## Why AI UI converges (the mechanism)

LLMs generate the statistically average choice when constraints are implicit.
"Modern" / "clean" / "nice" with no operational constraints make the model
reach for the high-frequency center of its training data: shadcn/Tailwind
boilerplate, "modern SaaS landing page" templates. Slop is a *uniformity*
problem, not a *quality* problem — the output is competent and
indistinguishable. The fix is explicit, enforced, honorable constraints:
"#0A0A0A background, no border-radius above 6px, no drop shadows" is something
a model can actually obey; "make it pop" is not.

- https://dev.to/_46ea277e677b888e0cd13/why-every-ai-generated-landing-page-looks-the-same-and-how-to-fix-it-1kmo
- https://www.managed-code.com/blog-post/ai-slop-in-design
- https://www.mindstudio.ai/blog/claude-design-avoid-ai-slop-design-system
- Key takeaway: "AI helps when constraints are explicit and enforced; it hurts
  when they stay implicit, because default aesthetics spread faster than teams
  expect." Specificity is the lever — vague rules produce vague results.

## Visual slop tells (concrete)

Source: https://www.925studios.co/blog/ai-slop-web-design-guide
- Inter paired with a system-sans fallback and no other type choices.
- Purple-to-blue gradient in hero / CTA / background accents ("Purple-to-Blue
  Gradient Syndrome") — omnipresent to the point of meaninglessness.
- Uniform 16px border-radius + 24px padding on every element → flat, no
  hierarchy. Same radius + shadow on everything.
- Hero stock photo: "diverse group looking at a laptop in an impossibly
  well-lit office"; "abstract 3D blobs floating in space."
- AI illustrations: "slightly too smooth, too symmetrical, plastic quality."
- Motion tells: hover states that do nothing, buttons that snap instead of
  ease, the same generic fade-in on every element.

Source: https://prg.sh/ramblings/Why-Your-AI-Keeps-Building-the-Same-Purple-Gradient-Website
- Purple/indigo accents on white. Inter or Roboto "never anything with
  personality." Three features in boxes each with an icon. Rounded corners on
  everything. Subtle shadows at exactly 0.1 opacity.
- Timid, evenly-distributed palettes instead of a dominant color + sharp
  accent. No white space as a design element. No hierarchy beyond "bigger
  text = header."
- Fix: separate the dimensions — specify typography, color, motion, background
  independently. Type contrast via 3x+ size jumps, not 1.5x. Serif+sans
  pairing. CSS variables. Reference a real cultural aesthetic, not "clean."

Source: https://axe-web.com/insights/ai-website-design-sameness/
- "Sea of sameness": same fonts, colors, rounded corners, robotic-but-clean
  layout because the shadcn aesthetic is the statistically most likely answer.
  Looking average silently kills B2B conversion — it signals low effort.

## Copy slop tells (concrete)

Source: https://hastewire.com/blog/ai-words-list-spot-overused-phrases-in-ai-text
- Overused words/phrases: delve into, shed light on, testament to, realm of,
  beacon of, tapestry of, unpack, in today's fast-paced world, in an
  ever-evolving landscape, as we navigate, it's important to note, furthermore,
  moreover, notably, crucially, ultimately, in conclusion, in essence.
- "In today's fast-paced world" appeared in 35% of AI outputs vs 8% human.
- Structural tells: excessive transitions (staccato connector rhythm), passive
  voice ("it is believed that"), uniform sentence length, vague descriptors
  ("revolutionary," "game-changing") without specifics, emotional flatness.

Source: https://www.925studios.co/blog/ai-slop-web-design-guide (copy section)
- AI copy is "grammatically correct, topically relevant, completely
  forgettable." Hedging ("may help," "can potentially"). Generic superlatives
  ("best-in-class," "cutting-edge"). Generic headlines: "Build the future of
  work," "Your all-in-one platform," "Scale without limits."
- Fix / test: rewrite headlines in the founder's voice — "Would our CEO
  actually say this? If no, rewrite." Real headlines are specific: Stripe
  "Financial infrastructure for the internet," Linear "Plan and build
  products." Specificity is the antidote.

## Structural slop tells (concrete)

- Centered hero + three feature cards with icons below (the canonical AI
  layout). Card grids with uniform sizing. Stat-card grids.
- Identical card components repeated. Dark-mode-by-default dev-tool clone.
  Sidebar+topbar admin template as the default chrome.
- Functional gaps that betray template origin: contact form with no
  validation, no error states, no required-field indication; missing ARIA /
  keyboard nav. (prg.sh, 925studios)

## Code-level slop tells (concrete)

Sources:
- https://sizzlecentral.substack.com/p/ai-code-smell-hits-different
- https://medium.com/@abhinav.dobhal/the-end-of-ai-slop-how-ui-ux-pro-max-is-solving-the-design-crisis-in-ai-generated-code-bbc23995f0e0
- https://dev.to/mcsee/code-smell-314-model-collapse-5ckc
- https://dzone.com/articles/code-smells-deeply-nested-code
- Goal is "semantic HTML with named props, typed interfaces, framework
  conventions — not a flat soup of divs."
- AI won't reuse existing helpers/tokens unless told; it recreates similar
  logic per task → duplication + inconsistency. Hardcodes colors/spacing
  instead of ingesting tokens.
- Magic numbers ("42", "0.7", "0.1 opacity") with no named intent.
- Model collapse: repeated unreviewed AI edits → "technically functional but
  semantically hollow code."

## What practitioners recommend instead (synthesis)

- Define explicit, enforced constraints up front, dimension by dimension
  (type, color, space, motion, background) — the more specific, the more
  distinctive.
- One decisive, distinctive type system (a display + body pairing), used
  consistently. Avoid Inter/Roboto/Open Sans as the *only* choice. Real
  examples: Vercel/Geist, Stripe bespoke serif, Linear modified type.
- Semantic color: color signals function (Notion: yellow highlight, blue link,
  red warning). Dominant neutral + sharp accent, not a timid even palette.
- Hierarchy from type scale / weight / space, not from boxes-and-shadows.
- Real content over lorem and stock: real screenshots, real data, real copy in
  a real voice. "Specificity signals authenticity, which AI cannot generate."
- Design tokens / CSS custom properties as the single source of truth; no
  hardcoded values. A spacing scale, used exclusively.
- Reference real, non-AI design sources (named products, cultural aesthetics),
  not adjectives.
- Don't over-correct into noise (parallax + custom cursors + animated bg +
  gradients stacked) — that's a different flavor of slop.
