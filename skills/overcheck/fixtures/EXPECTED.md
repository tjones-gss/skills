# Overcheck fixture oracle

The dominant failure mode is false positives, so five of six fixtures must come
back **clean**. A run passes when `kitchen-sink` flags all four patterns AND every
clean fixture produces zero findings. Any false positive on a clean fixture is a
bug to fix in the rubric (`../SKILL.md`), never a fixture to weaken.

| Fixture | Intent | Expected |
|---|---|---|
| kitchen-sink | fix the crash when email is missing | FLAG all 4: premature abstraction, speculative features, drive-by, unverifiable-done |
| surgical | fix the crash when email is missing | CLEAN |
| refactor-was-task | refactor the discount branching to be data-driven | CLEAN (the refactor was the task) |
| no-test-repo | fix total to account for quantity | CLEAN (no test dir → unverifiable must not fire) |
| test-seam | make build_report testable without a live DB | CLEAN (justified test seam) |
| autoformat | run the formatter on util.py | CLEAN (formatting was the task) |

## How to run

```bash
cd "$(bash setup-fixture.sh <fixture>)"
# then in Claude Code:  /overcheck "<intent from the table>"
```

## Verification log

- _(record dated passing runs here)_
