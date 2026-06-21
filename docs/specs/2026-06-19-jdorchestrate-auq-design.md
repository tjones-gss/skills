# `jdorchestrate` + `/auq` — completing the johndavis concept

**Status:** Design (pending implementation plan)
**Date:** 2026-06-19
**Author:** Travis Jones (with Claude)

## Purpose

The `johndavis` skill (in `notes/reference/johndavis.md`) references two skills that
Nethum never shared: **`jdorchestrate`** (johndavis's own orchestrator) and **`/auq`**
(the preflight interview that produces its required inputs). This spec reconstructs
both **faithfully** from the artifacts we have, so the johndavis system is whole and
runnable.

These are **our authored reconstruction** — they go in the repo's `skills/` dir
(alongside `overcheck`), NOT in `notes/reference/` (which stays a faithful copy of
what Nethum actually shared). Each file states, in a comment, that it's a
reconstruction completing the johndavis concept.

## Source artifacts (the de-facto spec)

- `notes/reference/johndavis.md` — names both skills and their exact roles.
- `notes/reference/orchestrate-stack/skills/orchestrate/SKILL.md` — the sibling
  `jdorchestrate` derives from.
- `notes/reference/orchestrate-stack/skills/never-guess/SKILL.md` — injected into briefs.
- `notes/reference/orchestrate-stack/agents/{design,refactor,simplify}-director.md`,
  `quickreview.md`; `commands/lreview.md` — referenced by the orchestrator.
- `notes/reference/johndavis-usage/transcript.md` — the `ToManager` folder
  (`charter` / `project-overview` / `roadmap-status`) and a real `charter.md` example.

## Decisions (settled in brainstorming)

- **jdorchestrate = thin derivative of `orchestrate`.** Keep its structure and scoring
  matrix verbatim; change only the documented deltas. (Not a rewrite, not a merged
  parameterized skill — johndavis explicitly says run jdorchestrate, *not* the
  standalone orchestrate.)
- **`/auq` = interview-only.** Draws out the missing inputs and writes them; never
  builds the roadmap (that's johndavis Phase 0a). Interviews only for the inputs that
  are actually missing.
- Both authored as **skills** (invoked `/jdorchestrate`, `/auq`); install via the
  repo's existing `install.sh`.

---

## Component 1 — `jdorchestrate`

**File:** `skills/jdorchestrate/SKILL.md`

A near-clone of `orchestrate` that changes only these deltas. The skill body should
explicitly say "identical to `orchestrate` except for the deltas below" so the diff
stays auditable, then restate the phases with the deltas folded in.

| Aspect | `orchestrate` | `jdorchestrate` |
|---|---|---|
| Teammates | `TeamCreate` (a team) | **flat roster of named teammates** spawned directly (Agent tool, `name` + `SendMessage`); **no nested team lead** |
| Phase gates | `CHECKPOINT` → wait for "go" each phase | **autonomous** — post a progress update and proceed; no go-gates |
| Briefs | name applicable skills | same, **plus inject `never-guess` into every brief** |
| Reports to | the user | **johndavis** (which escalates to the user per its Decision Protocol) |
| Escalation | crucial decision / 3 failed `/lreview` loops / hard-to-reverse | same triggers, routed **up to johndavis by impact**, not surfaced as a user checkpoint |

**Kept verbatim from `orchestrate`:** Phase 0 worktree isolation (`git worktree add
../<repo>-<slug> -b <branch>`, one writer at a time, parallel only on disjoint files);
the Phase 2 **0–10 scoring matrix** (model = sonnet ≤8 / opus 9–10; plan via
`writing-plans` for 4+; review via `/lreview` — once for low tiers, loop-until-APPROVE
for high, escalate after 3 failed loops); naming applicable skills in briefs for 4+
tasks; route fixes to the **same** implementer; never merge to main; teardown
(`shutdown_request` teammates, leave worktree intact).

**Resulting phase outline:**
- **Phase 0 — isolation:** worktree (same). Spawn teammates as a flat named roster
  directly (no `TeamCreate`/team lead).
- **Phase 1 — plan:** brief phased roadmap, each phase ending runnable; directors for
  UI work. **No CHECKPOINT A** — post the roadmap and proceed.
- **Phase 2 — score & route:** the scoring matrix verbatim; **inject `never-guess`**
  into every brief alongside the named skills.
- **Phase 3 — review:** `/lreview` per tier; route fixes to the same implementer. At
  phase boundaries **post a progress update and continue** (no wait-for-go). Final:
  report state to johndavis.
- **Teardown:** same as orchestrate.

**Stop-if-you-catch-yourself** (adapted from orchestrate): implementing code yourself;
spawning a nested team lead instead of a flat named roster; waiting for "go" at a phase
boundary; omitting `never-guess` from a brief; spawning a fresh agent to fix review
findings instead of messaging the same implementer; running git outside the worktree.

---

## Component 2 — `/auq`

**File:** `skills/auq/SKILL.md` (invoked `/auq`)

The preflight interview johndavis runs when a required input is missing. Single
purpose: interview → write the missing input file(s) to the `ToManager` folder →
hand back.

**Flow:**
1. **Locate the `ToManager` folder** — ask for its path, or default to `./ToManager/`
   (create if absent). **Detect which of the three files exist** and interview ONLY
   for the missing ones.
2. **Interview, one question at a time, multiple-choice where possible** (never-guess
   flavored — draw it out, don't assume). Per missing file:
   - **`overview.md`** — a brief project/goal statement + a pointer to the detailed
     spec (e.g. an Obsidian path) if one exists.
   - **`charter.md`** — the **sensitivity level** (High / Medium / Low), plus mandate
     essentials mirrored from the real example: scope (in / out, "do not invent"),
     constraints / do-not-touch, who-to-contact for external actions, the
     done-condition, and the two hand-back conditions.
   - **`roadmap-status.md`** — "Does a fleshed-out roadmap already exist?" If **yes**,
     record its path; if **no**, write `none — run Phase 0a`. Records status only;
     never builds the roadmap.
3. **Write** the missing file(s) to the `ToManager` folder following the structure
   johndavis expects (Preflight table + charter example), then **echo a summary** of
   what was written and where.
4. **Hand back to johndavis** — do not start work, spawn teammates, create a worktree,
   or build a roadmap.

**Boundaries (what `/auq` is NOT):** no roadmap generation, no worktree, no teammates,
no code. Interview → write the 3 inputs → return.

**Templates:** the skill carries a short skeleton for each of the three files (headings
johndavis reads), so the written files are consistently shaped. The `charter.md`
skeleton mirrors the example: Mandate / Scope (in+out) / Autonomy (sensitivity +
hand-back conditions) / Definition of done.

---

## Placement & install

```
skills/
  jdorchestrate/SKILL.md   ← our reconstruction (frontmatter: name jdorchestrate)
  auq/SKILL.md             ← our reconstruction (frontmatter: name auq)
```

- Installed via the repo's existing `install.sh` (links `skills/*` → `~/.claude/skills/`).
- A top-of-file comment in each marks it "reconstruction completing Nethum's johndavis
  concept; johndavis/orchestrate are his."
- README index updated to list both under the skills table, noting they complete the
  johndavis system (which also needs the `orchestrate-stack` pieces installed +
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).

## Dependencies (for the system to actually run — install concern, not design)

`jdorchestrate` references `never-guess`, the directors, `quickreview`/`/lreview`, and
`superpowers:writing-plans`. Those live in `notes/reference/orchestrate-stack/` (and
the superpowers plugin); running johndavis end-to-end means installing them too. The
two skills here complete the *authoring* gap; a full install is documented separately.

## Testing

These are prompt-driven skills with side effects (spawning teammates, writing files),
so "tests" are lightweight behavioral checks:

1. **`/auq` happy path** — in a temp dir with no `ToManager/`, run `/auq`; expect it to
   interview for all three, then write `ToManager/{charter,overview,roadmap-status}.md`
   with the expected headings.
2. **`/auq` partial** — pre-create `overview.md`; run `/auq`; expect it to interview
   ONLY for charter + roadmap-status and not overwrite the existing overview.
3. **`/auq` boundary** — confirm it does NOT create a worktree, spawn agents, or build a
   roadmap (roadmap-status with no existing roadmap = `none — run Phase 0a`).
4. **`jdorchestrate` diff audit** — diff against `orchestrate`; confirm the ONLY
   behavioral changes are the five deltas in the table (flat roster, no checkpoints,
   never-guess injection, reports-to-johndavis, impact escalation) — nothing else drifted.
5. **`jdorchestrate` dry plan** — on a tiny 2-task feature, confirm Phase 1 produces a
   phased roadmap and proceeds without waiting for "go", and briefs include never-guess.

Full multi-agent execution is validated opportunistically on a real build, not as a
gating test (expensive, experimental runtime).

## Open questions / notes

- `jdorchestrate` is authored as a standalone skill faithful to orchestrate; if Nethum
  later shares his real one, diff and reconcile.
- `/auq` default `ToManager/` location is a guess; johndavis points at a per-project
  folder, so the path is asked at runtime.
