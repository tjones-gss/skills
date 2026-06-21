# /overcheck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `/overcheck`, a user-global Claude Code slash command that reviews the current uncommitted diff for four anti-overengineering patterns and reports only high-confidence findings.

**Architecture:** A single skill file at `~/.claude/skills/overcheck/SKILL.md`. It runs with `context: fork` so the whole review (diff capture + rubric reasoning) happens in a forked context and only the final report returns to the main session — the diff never pollutes main context. Because the fork *is* the reviewer and writes the user-facing report directly, there is **no separate dispatched subagent and no JSON round-trip** (a deliberate simplification of the spec's two-process framing; the spec's intent — isolated review, clean context — is fully met). Detection lives entirely in the skill's rubric prose; the skill carries no parsing or app code.

**Tech Stack:** Markdown + YAML frontmatter (Claude Code skill format), git, bash (git-bash on Windows). No build step, no runtime dependencies.

## Global Constraints

Copied verbatim from the spec; every task implicitly includes these.

- **On-demand only.** Frontmatter MUST set `disable-model-invocation: true` — the skill fires only on an explicit `/overcheck`, never auto-triggers. No hooks, no pre-commit.
- **Flag only. Never edit code.** No auto-fix in v1.
- **Only the four patterns.** Premature abstraction, speculative features, drive-by changes, unverifiable "done". Nothing else (correctness/security belong to `/code-review`).
- **HIGH-confidence findings only.** Low/med are never surfaced, not even as counts.
- **Confidence is a promotion bar, not a feeling.** Every finding defaults to MED and must be argued up to HIGH with a one-line `why high` that rules out the innocent explanation. Can't write it → stays MED → not shown.
- **Intent from the request, never the commit message** (a commit says what was *done*; trusting it launders drive-bys). Mark intent `[explicit]` or `[inferred]`; when inferred, print the reduced-confidence disclosure.
- **Crying wolf on clean code is the worst outcome.** When in doubt, stay silent.
- **Platform:** Windows; git-bash available. Commands must be bash-compatible.

## File Structure

- Create: `~/.claude/skills/overcheck/SKILL.md` — the entire tool (frontmatter + orchestration prose + rubric + report format).
- Create: `WORK-GSS/docs/superpowers/fixtures/overcheck/setup-fixture.sh` — helper that builds a throwaway git repo from a before/after pair so a fixture can be reviewed via the real `git diff HEAD` path.
- Create: `WORK-GSS/docs/superpowers/fixtures/overcheck/<name>.before` + `<name>.after` — six fixture pairs.
- Create: `WORK-GSS/docs/superpowers/fixtures/overcheck/EXPECTED.md` — the oracle: per-fixture intent + expected verdict.

The skill is user-global (works in every project); fixtures live in the workspace (they document/verify the tool, they aren't the tool).

---

### Task 1: Fixture oracle (write the tests first)

Build the verification oracle before the tool, so detection quality is measurable. Each fixture is a `before`/`after` file pair plus an expected verdict. The dominant risk is false positives, so five of six fixtures must come back **clean**.

**Files:**
- Create: `WORK-GSS/docs/superpowers/fixtures/overcheck/setup-fixture.sh`
- Create: `WORK-GSS/docs/superpowers/fixtures/overcheck/{kitchen-sink,surgical,refactor-was-task,no-test-repo,test-seam,autoformat}.{before,after}`
- Create: `WORK-GSS/docs/superpowers/fixtures/overcheck/EXPECTED.md`

**Interfaces:**
- Produces: `setup-fixture.sh <name>` → prints the absolute path of a temp git repo whose working tree holds `<name>.after` as an uncommitted change over a committed `<name>.before`. Consumed by Task 4.

- [ ] **Step 1: Write the fixture setup helper**

Create `setup-fixture.sh`:

```bash
#!/usr/bin/env bash
# Usage: setup-fixture.sh <fixture-name>
# Builds a temp git repo: commits <name>.before, then overwrites with <name>.after
# left UNCOMMITTED, so `git diff HEAD` shows exactly the fixture's change.
set -euo pipefail
name="$1"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
before="$here/$name.before"
after="$here/$name.after"
[ -f "$before" ] || { echo "missing $before" >&2; exit 1; }
[ -f "$after" ]  || { echo "missing $after"  >&2; exit 1; }
repo="$(mktemp -d)"
cd "$repo"
git init -q
git config user.email t@e.st; git config user.name test
# file extension carried by the fixture's first line: "# file: <path>"
target="$(head -1 "$before" | sed 's/^# file: //')"
mkdir -p "$(dirname "$target")"
tail -n +2 "$before" > "$target"
git add -A && git commit -q -m base
tail -n +2 "$after" > "$target"
echo "$repo"
```

- [ ] **Step 2: Write the kitchen-sink fixture (the one true-positive)**

`kitchen-sink.before`:
```
# file: validate.py
def validate_user(user_data):
    if not user_data.get('email'):
        raise ValueError("Email required")
    if '@' not in user_data['email']:
        raise ValueError("Invalid email")
    return True
```

`kitchen-sink.after`:
```
# file: validate.py
from abc import ABC, abstractmethod

class EmailRule(ABC):
    @abstractmethod
    def check(self, email): ...

class BasicEmailRule(EmailRule):
    def check(self, email):
        return '@' in email

def validate_user(user_data, strict=False, locale="en", notify=False):
    """Validate user data."""
    email: str = user_data.get('email', '')
    if not email:
        raise ValueError("Email required")
    if not BasicEmailRule().check(email):
        raise ValueError("Invalid email")
    return True
```
Intent: "fix the crash when email is missing". Plants all four: premature abstraction (`EmailRule`/`BasicEmailRule` for one use), speculative features (`strict`/`locale`/`notify`), drive-by (docstring + `: str` type hint), unverifiable-done (logic change, repo has a test pattern — see Step 7 — and no test added).

- [ ] **Step 3: Write the surgical fixture (clean)**

`surgical.before`:
```
# file: validate.py
def validate_user(user_data):
    if not user_data.get('email'):
        raise ValueError("Email required")
    if '@' not in user_data['email']:
        raise ValueError("Invalid email")
    return True
```
`surgical.after`:
```
# file: validate.py
def validate_user(user_data):
    email = user_data.get('email', '')
    if not email or not email.strip():
        raise ValueError("Email required")
    if '@' not in email:
        raise ValueError("Invalid email")
    return True
```
Intent: "fix the crash when email is missing". Minimal, on-target. Expect: clean.

- [ ] **Step 4: Write the refactor-was-task fixture (clean)**

`refactor-was-task.before`:
```
# file: discount.py
def price(amount, kind):
    if kind == "pct10": return amount * 0.9
    if kind == "pct20": return amount * 0.8
    if kind == "flat5": return max(0, amount - 5)
    return amount
```
`refactor-was-task.after`:
```
# file: discount.py
DISCOUNTS = {"pct10": 0.10, "pct20": 0.20}

def price(amount, kind):
    if kind in DISCOUNTS:
        return amount * (1 - DISCOUNTS[kind])
    if kind == "flat5":
        return max(0, amount - 5)
    return amount
```
Intent: "refactor the discount branching to be data-driven". The change IS the task → drive-by must NOT fire. Expect: clean.

- [ ] **Step 5: Write the no-test-repo fixture (clean)**

`no-test-repo.before`:
```
# file: app.py
def total(items):
    return sum(i["price"] for i in items)
```
`no-test-repo.after`:
```
# file: app.py
def total(items):
    return sum(i["price"] * i.get("qty", 1) for i in items)
```
Intent: "fix total to account for quantity". Real logic change, but the temp repo has **no test directory**, so unverifiable-done must NOT fire. Expect: clean.

- [ ] **Step 6: Write the test-seam fixture (clean)**

`test-seam.before`:
```
# file: report.py
def build_report():
    rows = fetch_rows()
    return render(rows)
```
`test-seam.after`:
```
# file: report.py
def build_report(fetch=None):
    fetch = fetch or fetch_rows
    rows = fetch()
    return render(rows)
```
Intent: "make build_report testable without a live DB". The single-use `fetch` param is a justified test seam → premature-abstraction must NOT fire. Expect: clean.

- [ ] **Step 7: Write the autoformat fixture (clean)**

`autoformat.before`:
```
# file: util.py
def f(a,b):
    return a+b
def g(x):
    return x*2
```
`autoformat.after`:
```
# file: util.py
def f(a, b):
    return a + b


def g(x):
    return x * 2
```
Intent: "run the formatter on util.py". Repo-wide formatting only → drive-by must NOT fire (the formatting *was* the task and is tool-style). Expect: clean.

- [ ] **Step 8: Write the EXPECTED oracle**

Create `EXPECTED.md`:
```markdown
# Overcheck fixture oracle

| Fixture | Intent | Expected |
|---|---|---|
| kitchen-sink | fix the crash when email is missing | FLAG all 4: premature abstraction, speculative features, drive-by, unverifiable-done |
| surgical | fix the crash when email is missing | CLEAN |
| refactor-was-task | refactor the discount branching to be data-driven | CLEAN (the refactor was the task) |
| no-test-repo | fix total to account for quantity | CLEAN (no test dir → unverifiable must not fire) |
| test-seam | make build_report testable without a live DB | CLEAN (justified test seam) |
| autoformat | run the formatter on util.py | CLEAN (formatting was the task) |

A run "passes" when kitchen-sink flags all four AND the five clean fixtures
produce zero findings. Any false positive on a clean fixture is a failure to fix
in the rubric (Task 4), not a fixture to weaken.
```

- [ ] **Step 9: Commit**

```bash
cd "C:/Users/Travis/Desktop/Projects/WORK-GSS"
git -C docs/superpowers init -q 2>/dev/null || true   # workspace root is not a repo; skip if this errors
# If docs is not under any repo, simply skip committing and save the files as-is.
echo "fixtures created"
```
(Workspace root is not a git repo per the spec — if there is no repo to commit to, saving the files is the deliverable; do not `git init` the workspace.)

---

### Task 2: Skill scaffold — frontmatter, intent, diff capture, edge cases

Create the skill with everything *except* the detection rubric, so the mechanics (invocation, intent resolution, diff capture, edge-case exits) can be reviewed independently of detection quality.

**Files:**
- Create: `~/.claude/skills/overcheck/SKILL.md`

**Interfaces:**
- Produces: a `/overcheck [intent]` command that, in the fork, resolves intent, captures the cleaned diff, exits early on no-diff / non-repo, and otherwise hands the diff to the rubric section (added in Task 3).

- [ ] **Step 1: Create the skill file with frontmatter + steps 1–2 (no rubric yet)**

Create `~/.claude/skills/overcheck/SKILL.md`:

````markdown
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

<!-- Task 3 inserts Step 3 (rubric) and Step 4 (report) below this line -->
````

- [ ] **Step 2: Verify it loads and resolves intent + empty diff**

Run in a clean repo (no uncommitted changes):
```bash
cd "$(mktemp -d)" && git init -q && git config user.email t@e.st && git config user.name t && git commit -q --allow-empty -m base
# then in Claude Code:  /overcheck "tidy up"
```
Expected: the command is recognized, intent shows `"tidy up" [explicit]`, and it stops with `Nothing uncommitted to check.`

- [ ] **Step 3: Verify the non-repo exit**

Run `/overcheck` in a non-repo directory (e.g. the WORK-GSS root).
Expected: `Not a git repo — run /overcheck inside a project (or pass a path).`

- [ ] **Step 4: Commit**

Save the skill file. (`~/.claude` is a git repo — commit there.)
```bash
git -C "$HOME/.claude" add skills/overcheck/SKILL.md
git -C "$HOME/.claude" commit -m "feat(overcheck): skill scaffold — intent + diff capture + edge cases"
```

---

### Task 3: Detection rubric, confidence gate, and report format

Add the review brain and the output format to the skill. This is where false-positive discipline lives.

**Files:**
- Modify: `~/.claude/skills/overcheck/SKILL.md` (append Step 3 + Step 4 where Task 2's comment marks the insertion point)

**Interfaces:**
- Consumes: the resolved intent and cleaned diff from Task 2's Steps 1–2.
- Produces: the final terminal report (the only thing returned from the fork to main).

- [ ] **Step 1: Append the rubric (Step 3) to the skill**

Replace the `<!-- Task 3 inserts ... -->` line in `SKILL.md` with:

````markdown
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
````

- [ ] **Step 2: Append the report format (Step 4) to the skill**

Append to `SKILL.md`:

````markdown
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
````

- [ ] **Step 3: Smoke-test on a hand-made overengineered diff**

```bash
cd "$(mktemp -d)" && git init -q && git config user.email t@e.st && git config user.name t
printf 'def add(a,b):\n    return a+b\n' > m.py && git add -A && git commit -q -m base
printf 'from abc import ABC\nclass Adder(ABC):\n    def go(self,a,b): return a+b\ndef add(a,b,fast=False):\n    return Adder().go(a,b)\n' > m.py
# in Claude Code:  /overcheck "no task — just checking output shape"
```
Expected: report header renders; at least the premature-abstraction finding appears with a `Why high:` line; no code is modified.

- [ ] **Step 4: Commit**

```bash
git -C "$HOME/.claude" add skills/overcheck/SKILL.md
git -C "$HOME/.claude" commit -m "feat(overcheck): add rubric, confidence gate, report format"
```

---

### Task 4: Fixture verification and rubric tuning

Run the finished skill against all six fixtures and confirm verdicts match the oracle. Tune the rubric (not the fixtures) on any miss.

**Files:**
- Modify: `~/.claude/skills/overcheck/SKILL.md` (only if a fixture fails)

**Interfaces:**
- Consumes: `setup-fixture.sh` + fixtures + `EXPECTED.md` (Task 1), the finished skill (Tasks 2–3).

- [ ] **Step 1: Run the true-positive fixture**

```bash
cd "$(bash "C:/Users/Travis/Desktop/Projects/WORK-GSS/docs/superpowers/fixtures/overcheck/setup-fixture.sh" kitchen-sink)"
# in Claude Code:  /overcheck "fix the crash when email is missing"
```
Expected: four findings — premature abstraction, speculative features, drive-by, unverifiable-done — each with a `Why high:` line.

- [ ] **Step 2: Run the five clean fixtures**

For each of `surgical`, `refactor-was-task`, `no-test-repo`, `test-seam`, `autoformat`:
```bash
cd "$(bash "C:/Users/Travis/Desktop/Projects/WORK-GSS/docs/superpowers/fixtures/overcheck/setup-fixture.sh" <name>)"
# in Claude Code:  /overcheck "<intent from EXPECTED.md>"
```
Expected: `✓ Clean — no overengineering found.` for all five. Any finding here is a false positive.

- [ ] **Step 3: Tune on failure**

If a clean fixture produced a finding, the corresponding carve-out (Step 3 A–D) is too weak — strengthen that carve-out's wording in `SKILL.md`, re-run Steps 1–2, and confirm the true-positive still flags all four. Do NOT weaken a fixture to make it pass. Repeat until the run passes per `EXPECTED.md`.

- [ ] **Step 4: Record the passing run + commit**

Append a dated "Verification" note to `EXPECTED.md` recording that all six fixtures matched, then:
```bash
git -C "$HOME/.claude" add skills/overcheck/SKILL.md
git -C "$HOME/.claude" commit -m "test(overcheck): rubric passes all six fixtures" || echo "no skill change needed"
```

---

## Self-Review

**Spec coverage:**
- On-demand slash command → Task 2 frontmatter (`disable-model-invocation`). ✓
- Hybrid intent + request-not-commit + inferred disclosure → Task 2 Step 1, Task 3 Steps 1–2. ✓
- Diff scope + clean/non-repo exits + vendored exclusion → Task 2 Step 1. ✓
- `context: fork` clean-context architecture → frontmatter; JSON round-trip intentionally dropped (documented in header + Architecture). ✓
- Four patterns + carve-outs, ordered by FP risk → Task 3 Step 1. ✓
- Confidence promotion bar + `why high` → Task 3 Step 1 (Step 3.5). ✓
- Output format + clean line + cap note + no low/med counts → Task 3 Step 2. ✓
- Test set weighted to false-positive guards (6 fixtures) → Task 1 + Task 4. ✓

**Placeholder scan:** No "TBD"/"handle edge cases"/"similar to Task N"; every fixture, the helper, the full SKILL.md, and all commands are shown literally. ✓

**Type/name consistency:** `setup-fixture.sh <name>` and fixture names match across Tasks 1 and 4; SKILL.md step numbers (1, 2, 3, 3.5, 4) are consistent between Tasks 2 and 3; the `[explicit]`/`[inferred]` markers and `why high` label match between rubric and report. ✓

**Note on git:** the skill is committed to the `~/.claude` repo (which exists); fixtures live under the non-repo workspace and are saved as files only.
