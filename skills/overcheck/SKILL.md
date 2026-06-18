---
name: overcheck
description: Review the current uncommitted git diff for the four anti-overengineering patterns (premature abstraction, speculative features, drive-by changes, unverifiable "done") and report only high-confidence findings. Use ONLY when the user explicitly runs /overcheck.
argument-hint: "[optional: one-line intent]"
disable-model-invocation: true
context: fork
agent: general-purpose
---

You are reviewing a code diff for **overengineering only** — nothing else.
Report **only HIGH-confidence findings**. Crying wolf on clean code is the worst
possible outcome: when in doubt, say nothing.

## Step 1 — Resolve the intent (what was the author actually asked to do?)

- If `$ARGUMENTS` is non-empty, the intent is exactly `$ARGUMENTS`. Mark it `[explicit]`.
- Otherwise, infer the intent from the recent conversation, the PR/branch description,
  or the branch name. **Never treat the commit message as proof of what was asked** —
  a commit says what was *done*, so trusting it would hide a drive-by change. Mark
  the inferred intent `[inferred]`.

## Step 2 — Capture the diff

Run: `git diff HEAD`

- If git reports this is not a repository: output exactly
  `Not a git repo — run /overcheck inside a project (or pass a path).` and STOP.
- If the diff is empty: output exactly `Nothing uncommitted to check.` and STOP.
- Before reviewing, ignore changes to generated/vendored files: lockfiles
  (`package-lock.json`, `yarn.lock`, `poetry.lock`, `*.lock`), `dist/`, `build/`,
  `node_modules/`, and minified/generated assets. If only such files changed, treat
  it as an empty diff and STOP with `Nothing reviewable (only generated files changed).`

## Step 3 — Review against the rubric (overengineering only)

Evaluate the diff against the four patterns below, in this order (most
false-positive-prone first). Each pattern lists carve-outs that must NOT be
flagged. Start every candidate finding at **MED** and only promote to **HIGH** if
you can satisfy the promotion bar in Step 3.5.

### A. Unverifiable "done" (strictest — easiest to get wrong)
Flag ONLY if ALL THREE hold:
1. the diff adds non-trivial branching/edge-case logic OR claims to fix a specific bug; AND
2. the repo already has an established test pattern for this kind of code — you can
   point to an existing sibling test file that should have received a case; AND
3. no test, assertion, or stated manual-verification step accompanies the change.
**Never flag:** pure config/docs/copy, log/telemetry lines, prototype/spike work, or
any repo with no test directory at all. If you cannot name a sibling test file that
*should* exist, this is at most MED → not shown.

### B. Premature abstraction
Flag an interface / base class / strategy / factory / config object introduced for a
**single** current use.
**Carve-outs (force MED, i.e. do not show):** it creates a test/mocking seam
(dependency injection), implements an existing framework/interface contract, collapses
a long parameter list, or mirrors a pattern already used elsewhere in the repo.
Promote to HIGH only when it has exactly one caller, one implementation, no test seam,
and no local precedent.

### C. Drive-by changes
Flag edits outside the stated intent: reformatting, renames, type hints, comment/quote
churn unrelated to the goal.
**Carve-outs:** suppress changes that are plausibly tool-enforced (consistent
repo-wide formatting/import-order an autoformatter would produce) or mechanically
required by the core edit (e.g. a rename that must ripple). If the formatting/refactor
*was itself the stated intent*, it is not a drive-by.

### D. Speculative features
Flag params / flags / branches / endpoints not required by the stated intent
("just in case"). **Carve-out:** capability the stated intent actually implies.

## Step 3.5 — Confidence promotion bar (HIGH only is shown)

A finding is HIGH only if you can satisfy ALL of:
- you cite the exact changed lines (file:line),
- you name a concrete simpler alternative,
- you explicitly rule out the pattern's carve-outs, and
- for B/C/D (intent-dependent): the verdict holds regardless of which *plausible*
  reading of the intent is correct.
Write a one-line **`why high`** that names and dismisses the most likely innocent
explanation. If you cannot write that sentence honestly, the finding stays MED.

**Intent reduced-confidence rule:** if the intent is `[inferred]`, hold B/C/D to an
even higher bar — only promote when the verdict is intent-independent — and include
the reduced-confidence note in the report header (Step 4).

## Step 4 — Output the report

Header (always):
```
Overcheck — intent: "<intent>"  [explicit|inferred]
Scope: <N> files, +<adds>/-<dels> (uncommitted)
```
If intent is `[inferred]`, add this line to the header:
```
Note: intent inferred — speculative/drive-by/unverifiable checks ran in
reduced-confidence mode. Pass an explicit intent for full strength.
```

If there are HIGH findings, list each as:
```
<n>. <Pattern> · <file>:<line>
   <one-line why it's overengineered>
   Simpler: <one-line simpler alternative>
   Why high: <one line ruling out the innocent explanation>
```
Cap the list at the top 10 by confidence; if more remain, end with
`… N more high-confidence findings omitted.` Never show MED/LOW, not even as counts.

If there are no HIGH findings, output exactly:
```
✓ Clean — no overengineering found. Intent: "<intent>" [explicit|inferred]
Checked: <N> files (uncommitted).
```
Do not edit any code. Reporting is the only side effect.
