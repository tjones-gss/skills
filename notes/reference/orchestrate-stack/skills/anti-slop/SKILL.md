---
name: anti-slop
description: Use when designing or implementing any UI/frontend surface - concrete rules and a review checklist to avoid recognizable AI-generated design patterns (visual, copy, structural, and code-level slop)
---

# Anti-slop

AI UI converges on the statistical average — shadcn/Tailwind boilerplate, purple
gradients, three-card heroes — because vague intent ("clean", "modern", "make it
pop") samples the high-frequency center of the training data. Slop is a
*uniformity* problem, not a quality problem: competent and indistinguishable.
The cure is explicit, enforced constraints applied dimension by dimension
(type, color, space, motion, content). The rules below are checkable; the
"Instead" section gives the positive move; the checklist gates shipping.

This project's committed system is the concrete instance of these rules: Space
Grotesk (display) + Inter (body) + JetBrains Mono (code); grayscale shell with
color used only to carry meaning; hierarchy from type scale / weight / space,
not boxes; WCAG AA. Where a rule below names a default, this system is how we
satisfy it — Inter is allowed here because it is the *body* partner under a
distinctive display face and a mono, not the lone unconsidered choice.

## Slop tells (NEVER)

### Visual
- NEVER ship a purple/indigo/violet→blue gradient on a hero, CTA, or background.
- NEVER apply one uniform border-radius + one drop-shadow to every surface to
  signal "card". (Committed system: hierarchy from type/space, not boxes.)
- NEVER use a single shadow opacity everywhere (the 0.1-on-everything tell).
- NEVER glassmorphism (frosted blur cards), gratuitous glows, or animated-blob
  backgrounds.
- NEVER use Inter/Roboto/Open Sans/Lato/system-default as the *only*, unpaired
  typeface. (Here: it must sit under Space Grotesk + JetBrains Mono.)
- NEVER use emoji as UI icons or as bullets.
- NEVER stock-photo "diverse team at a laptop in a bright office" or smooth
  plastic 3D illustrations / fake testimonial avatars.
- NEVER a timid, evenly-spread palette; NEVER use color decoratively where it
  carries no meaning. (Here: color = meaning only.)
- NEVER hover states that do nothing, buttons that snap, or the same fade-in on
  every element.

### Copy
- NEVER these words/phrases: delve, unlock, empower, seamless, effortless,
  elevate, supercharge, robust, cutting-edge, best-in-class, game-changing,
  "in today's fast-paced world", "take it to the next level".
- NEVER inflated marketing voice or exclamation marks in product UI.
- NEVER generic headlines ("Build the future", "Your all-in-one platform",
  "Scale without limits") — name the specific thing.
- NEVER cute error microcopy ("Oops! Something went wrong 😅"); state what
  failed and the next action.
- NEVER hedging ("may help", "can potentially") or em-dash-as-rhythm overuse.

### Structural
- NEVER the centered-hero + three-feature-cards-with-icons layout.
- NEVER a grid of identical stat cards / repeated identical card components as
  the primary IA.
- NEVER default to dark-mode dev-tool clone or sidebar+topbar admin template
  unless the task calls for it.
- NEVER ship forms without validation, error states, and required-field marks.

### Code
- NEVER hardcode color/spacing/radius values; they come from tokens.
- NEVER magic numbers (`0.1`, `42`, `13px`) with no named intent.
- NEVER spacing/sizes off an ad-hoc scale — use the defined scale only.
- NEVER deeply nested div soup; use semantic HTML and named components.
- NEVER recreate a helper/token/component that already exists — find and reuse.
- NEVER leave dead CSS / unused classes / orphaned styles behind.

## Instead

- Constrain each dimension explicitly before building: pick exact type faces,
  an exact palette with semantic roles, an exact spacing scale, exact motion
  rules. Specificity is the lever — the more precise, the more distinctive.
- Type: one distinctive display + one body + one mono, used decisively (this
  project's Space Grotesk / Inter / JetBrains Mono). Build a 4–5 step type
  scale and use ONLY those steps; get contrast from 2–3x size/weight jumps, not
  1.2x nudges.
- Color: grayscale shell; introduce a hue ONLY when it carries meaning
  (status, severity, link, selection). One dominant neutral + sharp functional
  accents, not an even rainbow.
- Hierarchy from type scale, weight, and whitespace — treat negative space as a
  deliberate element. Reach for a bordered box only when grouping genuinely
  needs it.
- Asymmetry where earned: vary card size/weight by importance instead of an
  even grid; let the layout reflect the data's real shape.
- Real content: real labels, real data, real screenshots, copy in a real voice.
  No lorem, no placeholder avatars. Specificity reads as authenticity.
- Copy: say the specific thing in a plain, direct voice. Test each line: "would
  a sharp engineer actually say this?" Errors name the cause and the next step.
- Motion with purpose only: communicate a state change, direct attention, or
  express brand — with eased timing. Delete decoration-only animation.
- Tokens are the single source of truth (CSS custom properties / theme): color,
  space, radius, type, shadow. Components consume tokens; nothing hardcoded.
- When unsure of a direction, reference a real named product or cultural
  aesthetic, never an adjective like "clean" or "modern".

## Pre-ship checklist

Run these over your own output before declaring UI work done. Every answer must
be yes (or N/A with reason).

1. Zero purple/violet→blue gradients, glows, glassmorphism, or blob backgrounds?
2. Type uses only the defined faces (Space Grotesk / Inter / JetBrains Mono) and
   only the defined scale steps?
3. Visual hierarchy comes from type/weight/space — not from a uniform
   box+shadow on everything?
4. Every color present carries meaning; the shell is grayscale?
5. No emoji-as-icon, no stock "team at laptop", no plastic 3D, no fake avatars?
6. Layout is NOT centered-hero + three-icon-cards and NOT an undifferentiated
   identical-card grid?
7. Copy contains none of the banned words and no exclamation marks; voice is
   plain and specific?
8. Headlines/labels name the specific thing rather than a generic abstraction?
9. Error/empty/loading states exist, name what happened, and give a next action?
10. Forms have validation, error states, and required-field indication?
11. All color/space/radius/type values come from tokens — zero hardcoded values
    or magic numbers?
12. Spacing and sizing use only the defined scale?
13. Markup is semantic and shallow (no 8+ deep div nesting); no duplicated
    helper/component that already existed?
14. No dead CSS or unused classes left behind?
15. WCAG AA: text contrast passes, focus states visible, keyboard-navigable,
    interactive elements have accessible names?
