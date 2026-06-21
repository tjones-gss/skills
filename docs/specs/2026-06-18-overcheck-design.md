# `/overcheck` — anti-overengineering review command

**Status:** Design (pending implementation plan)
**Date:** 2026-06-18
**Author:** Travis Jones (with Claude)

## Purpose

A lightweight, on-demand slash command that reviews a code diff for the four
anti-overengineering patterns from `nethum-agentic-notes.md` (the `EXAMPLES.md`
principles), and reports only high-confidence findings. It makes the "simplicity
first / surgical changes" working principles *self-enforcing* — turning a doc you
have to remember to read into a check you can run on any diff.

It is deliberately the **convergent** counterpart to `/premortem`: premortem
widens (imagine every way a *plan* fails); overcheck narrows (flag what you
*shouldn't have built* in a diff that already exists). Premortem is heavyweight
and occasional; overcheck is lightweight and routine.

## Non-goals (what we are explicitly NOT building in v1)

- **No auto-trigger / hook.** On-demand only. We do not fire on save or pre-commit
  until we've felt the manual version and wished it were automatic. (YAGNI)
- **No code edits / auto-fix.** Flag only. Seeing the overengineering is ~90% of
  the value, and an auto-fixer would risk committing the exact drive-by sin the
  tool exists to catch. Opt-in patching is a possible v2.
- **No new dimensions beyond the four patterns.** Not a general code reviewer;
  `/code-review` already exists for correctness/security. Overcheck is narrow.
- **No low/medium-confidence findings shown.** Noise kills trust; high bar only.

## Behavior

### Invocation
`/overcheck [optional: one-line intent]`

### Intent resolution (hybrid)
- If the user passes an intent argument, use it verbatim.
- Otherwise infer intent from the **request signal** — recent conversation / PR
  description / branch name. **Do not treat the commit message as proof of what
  was asked**: a commit describes what was *done*, so trusting it would launder a
  drive-by change into "intended" and hide it (a false negative). Commit messages
  are at most weak corroboration.
- Always **state the intent used at the top of the report**, marked `[explicit]`
  or `[inferred]`, so a bad guess is caught.
- When intent is **inferred**, the report says so explicitly and notes that the
  three intent-dependent checks (speculative / drive-by / unverifiable-"done") ran
  in **reduced-confidence mode** — "pass an explicit intent for full strength."
  This single honest disclosure replaces a per-finding downgrade rule: silence
  under inferred intent must not masquerade as a clean bill of health.

### Diff scope
- Default: all uncommitted changes in the current repo — `git diff HEAD`.
- If the working tree is clean: report "nothing uncommitted to check" and exit.
  (Reviewing already-committed ranges is a possible later add, not v1.)
- Exclude generated/vendored files before review: lockfiles, `dist/`,
  `node_modules/`, build output, and similar.

## Architecture

Three components; detection logic lives only in the subagent prompt, not the skill.

1. **`~/.claude/skills/overcheck/SKILL.md`** — thin orchestrator (the slash
   command). Jobs: resolve intent, capture diff, dispatch subagent, relay
   findings, apply the confidence gate. No detection logic. (This mirrors the
   "lean skill / orchestrator that calls out" principle — the tool practices what
   it preaches.) Implemented with Claude Code skill mechanics:
   - directory name `overcheck/` → becomes the `/overcheck` invocation automatically
   - frontmatter: `disable-model-invocation: true` (runs ONLY on explicit
     `/overcheck`, never auto-fires), `context: fork`, `agent: general-purpose`,
     `argument-hint: "[optional: intent]"`
   - optional intent read via `$ARGUMENTS` (handle the empty case = infer)
   - diff captured via `` !`git diff HEAD` `` command injection
2. **Reviewer subagent** (the fork) — runs with a focused prompt: the diff +
   resolved intent + the four-pattern rubric. The (potentially large) diff never
   enters the main session context. **Subagents return text, not structured data**,
   so the prompt explicitly instructs it to return findings as JSON; the
   orchestrator parses that JSON and applies the confidence gate.
   - Kept as a fork (vs. inline) deliberately: in Claude Code this is a one-line
     frontmatter flag, not a hand-built layer — near-zero cost for a real benefit
     (clean main context). This is YAGNI applied honestly: avoid cost-bearing
     speculation, not free wins.
3. **The rubric** — embedded in the subagent prompt, derived from `EXAMPLES.md`.

### Data flow
```
/overcheck [intent?]
  → resolve intent ($ARGUMENTS → use [explicit]; else infer from request [inferred])
  → capture diff (!`git diff HEAD`; clean tree → exit "nothing to check"; strip generated/vendored)
  → dispatch fork subagent(diff, intent, rubric)
  → subagent returns JSON: [{pattern, file, line, why, simpler_alternative, confidence, why_high}]
  → orchestrator drops everything below HIGH; prints report
```

## Detection rubric (the four patterns)

Each pattern has explicit **carve-outs** — legitimate cases that must NOT be
flagged. False positives kill trust, so the carve-outs are first-class, not
footnotes. Patterns are listed in order of false-positive danger (most dangerous
first); the prompt gives the riskiest ones the strictest gates.

### Unverifiable "done" (highest false-positive risk — strict AND-gate)
Flag **only when ALL** hold:
- (a) the diff adds non-trivial branching / edge-case logic, OR claims to fix a
  specific bug; AND
- (b) the repo already has an established test pattern for this kind of code — the
  agent must be able to **name an existing sibling test file** that should have
  received a case; AND
- (c) no test, assertion, or stated manual-verification step accompanies the change.

**Never flag:** pure config / docs / copy changes, log/telemetry lines, prototype
/spike work, or any repo with no test directory at all. If the agent cannot name a
sibling test that *should* exist, this is at most LOW (i.e. not shown).

### Premature abstraction (judgeable from diff alone)
Flag when an interface / base class / strategy / factory / config object is
introduced for a **single** current use.
**Carve-outs (force LOW):** creates a test/mocking seam (DI), implements an
existing framework/interface contract, collapses a long parameter list, or mirrors
a pattern already used elsewhere in the repo. HIGH only when the abstraction has
exactly one caller, one implementation, no test seam, and no local precedent.

### Drive-by changes (intent-dependent)
Flag edits outside the task: reformatting, renames, type hints, comment/quote
churn unrelated to the goal.
**Carve-outs:** suppress changes that are plausibly **tool-enforced** (consistent
repo-wide formatting / import-order that an autoformatter would produce) or
**mechanically required** by the core edit (e.g. a rename that must ripple). Flag
only semantically-unrelated, non-required changes.

### Speculative features (intent-dependent, lowest risk)
Flag params / flags / branches / endpoints not required by the stated task
("just in case"). Carve-out: capability the stated intent actually implies.

### Confidence gate (the load-bearing mechanism — promotion model)
LLM self-rated confidence anchors high, so HIGH is a **promotion bar, not a
feeling**:
- Every finding **defaults to MED**; the agent must *argue it up* to HIGH.
- HIGH requires ALL of: exact diff lines cited; a concrete simpler alternative
  named; the relevant carve-outs explicitly ruled out; and (for intent-dependent
  patterns) the verdict holds regardless of which plausible intent was correct.
- Each finding carries a one-line **`why_high`** that explicitly rules out the most
  likely innocent explanation. If the agent can't write that sentence, it stays MED.
- Only **HIGH** is shown. Low/med are never surfaced — not even as counts.

## Output

Plain terminal report. An empty result is an explicit success, not a non-answer.

```
Overcheck — intent: "fix the empty-email validator crash"  [inferred]
Scope: 3 files, +47/-12 (uncommitted)
Note: intent inferred — speculative/drive-by/unverifiable checks ran in
reduced-confidence mode. Pass an explicit intent for full strength.

⚠ 2 findings (high confidence)

1. Speculative features · server/validate.ts:31
   Added `strict` + `locale` params; the task only needed the empty-email guard.
   Simpler: drop both params, keep the single guard.
   Why high: neither param is referenced by the fix or implied by the intent.

2. Drive-by changes · server/validate.ts:8-19
   Reformatted quotes + added type hints to untouched username logic.
   Simpler: revert those lines; they're unrelated to the fix.
   Why high: lines aren't touched by the email fix and aren't repo-wide autoformat.
```

- Clean result: `✓ Clean — no overengineering found. Intent: "…" [explicit|inferred]`
  plus what was checked.
- Each finding: **pattern · file:line**, one-line *why*, one-line *simpler
  alternative*, and the **`why high`** justification. No code rewrites.
- The header carries the intent + (when inferred) the reduced-confidence note. There
  is no per-pattern "all clear" footer — a single clean line suffices; enumerating
  the patterns was cosmetic.

## Edge cases

- **No diff at all** (clean tree, no HEAD): say so, exit. Don't invent work.
- **Not a git repo** (e.g. run at WORK-GSS root): tell the user to run inside a
  project; offer to check a path if one is passed.
- **Huge diff:** subagent reviews in full (isolated, no main-context cost). If
  there are more HIGH-confidence findings than the display cap, it notes "N more
  high-confidence findings omitted" — never silently truncates. Low/med are never
  surfaced, not even as counts (resolves the earlier inconsistency).
- **Bad inferred intent:** mitigated by the explicit `[inferred]` + reduced-
  confidence header; user re-runs with an explicit intent arg.
- **Generated/vendored files:** excluded before review.

## Testing

Prompt-driven, so "tests" = a small fixture set of saved diffs with known verdicts.
Because the dominant risk is false positives, the suite is weighted toward
"should-stay-silent" cases.

**True positives (each should be flagged):**
1. A diff with one planted instance of **each** pattern → expect each flagged.

**False-positive guards (each should come back clean / NOT flagged):**
2. A genuinely surgical bugfix → clean.
3. A refactor that *was* the stated task → not flagged as drive-by (intent check).
4. A logic bugfix in a repo with **no test suite** → not flagged as unverifiable.
5. A justified single-use interface at a **test seam** → not flagged as premature
   abstraction.
6. An **autoformatter-touched** diff → not flagged as drive-by.

Run by invoking `/overcheck` against each fixture and reviewing the report.
Catches the failure mode that matters most: crying wolf on clean code.

## Expert review

Design reviewed 2026-06-18 by three parallel expert agents (YAGNI/simplicity,
LLM prompt-reliability, Claude Code mechanics). Folded in: strict carve-outs +
AND-gate for "unverifiable done" (top false-positive risk); confidence as a
promotion bar with mandatory `why_high`; intent derived from the request not the
commit; explicit reduced-confidence disclosure replacing the per-finding downgrade;
output simplification + low/med-count fix; skill-mechanics frontmatter
(`disable-model-invocation`, `context: fork`, `$ARGUMENTS`, command injection) and
the subagent JSON-return contract; false-positive-weighted test fixtures. The one
contested call — subagent vs. inline — was resolved in favor of keeping the fork
(one-line cost in Claude Code, real benefit).

## Resolved / notes

- **Spec location:** spec lives in the workspace (`WORK-GSS/docs/...`); the skill
  artifact is user-global (`~/.claude/skills/overcheck/`). This split is fine — the
  spec documents the tool, it isn't the tool.
- **Git commit:** the WORK-GSS root is not a git repo, so the brainstorming step's
  "commit the design doc" is not applicable here; the spec is saved as a file only.
- **Reviewer rubric source:** with `context: fork` the rubric is carried in the
  skill body that the fork runs under (inline in `SKILL.md`), not a separate agent
  file — keeps it to a single artifact.
