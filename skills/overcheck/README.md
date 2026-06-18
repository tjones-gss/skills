# overcheck

A `/overcheck` slash command that reviews your **current uncommitted diff** for
overengineering and reports only high-confidence findings. It makes the
"simplicity first / surgical changes" discipline self-enforcing — a habit you can
run on any diff instead of a doc you have to remember.

It is the **convergent** counterpart to `/premortem`: premortem widens (imagine
how a plan fails); overcheck narrows (flag what you shouldn't have built).

## What it checks

Four anti-patterns, ordered by false-positive danger, each with carve-outs so it
stays quiet on legitimate code:

1. **Unverifiable "done"** — non-trivial logic/bugfix with no test in a repo that
   clearly tests this kind of code. (Never fires on config/docs/logs or test-less repos.)
2. **Premature abstraction** — interface/factory/strategy for a single use. (Not a
   test seam, framework contract, long-arg collapse, or existing local pattern.)
3. **Drive-by changes** — edits outside the task. (Not tool-enforced formatting or
   mechanically-required ripples, and not when the refactor *was* the task.)
4. **Speculative features** — params/flags/endpoints nobody asked for.

Only **HIGH-confidence** findings are shown — each must clear a promotion bar and
carry a one-line `why high` that rules out the innocent explanation.

## Usage

```
/overcheck                         # infers your intent from the conversation/branch
/overcheck fix the empty-email crash   # explicit intent = strongest results
```

Pass an explicit intent when you can: three of the four checks need to know what
you were *actually asked to do*, and an explicit intent unlocks full strength.

### Example output

```
Overcheck — intent: "fix the crash when email is missing"  [explicit]
Scope: 1 file, +14/-3 (uncommitted)

⚠ 2 findings (high confidence)

1. Speculative features · validate.py:9
   Added strict/locale/notify params; the fix only needed the empty-email guard.
   Simpler: drop the extra params.
   Why high: none are referenced by the fix or implied by the intent.

2. Premature abstraction · validate.py:2-8
   EmailRule/BasicEmailRule introduced for a single call site.
   Simpler: inline the `'@' in email` check.
   Why high: one caller, one impl, no test seam, no existing rule pattern in the repo.
```

Clean diffs report `✓ Clean — no overengineering found.`

## Behaviour notes

- **On-demand only** (`disable-model-invocation: true`) — never auto-fires.
- **Flag only** — never edits your code.
- **Runs in a forked context** (`context: fork`) — the diff stays out of your main
  session; only the report comes back.

## Develop / test

Fixtures live in [`fixtures/`](./fixtures). Build a throwaway repo from any fixture
and run the command against it:

```bash
cd "$(bash fixtures/setup-fixture.sh surgical)"
# then in Claude Code:  /overcheck "fix the crash when email is missing"
# expect: ✓ Clean
```

See [`fixtures/EXPECTED.md`](./fixtures/EXPECTED.md) for the full oracle and
[`design.md`](./design.md) for the design rationale.
