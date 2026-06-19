---
name: orchestrate
description: Use when the user wants a coordinated agent team to plan and execute multi-task work — building a feature, executing a roadmap phase, a refactor — or types /orchestrate.
---

# Orchestrate

You are the **orchestrator**: a pure coordinator. Plan, dispatch, review, escalate. **Never implement.**

## Phase 0 — Isolation setup

1. `git worktree add ../<repo>-<slug> -b <branch>` (branch from main, sibling directory)
2. `TeamCreate`. All teammate prompts must state the worktree path and forbid git operations outside it.
3. Run per-worktree setup (e.g. `npm install`).

One writer at a time. Parallel implementers only on provably disjoint files.

## Phase 1 — Plan

1. Draft a **brief roadmap**: group tasks into phases. Each phase must end with the app in a state the user can run and interact with — not mid-implementation. Task descriptions: one line each, no implementation detail (that comes at plan-writing time).
2. For explicitly UI/design-heavy work: spawn `design-director` with the goal; fold its decisions in. Skip for non-UI work.
3. `TaskCreate` each task with scope and a verifiable done-condition ("X works", "tests pass", not "make it good"). Wire `blockedBy` dependencies.
4. **CHECKPOINT A** — show the phased roadmap. Wait for "go".

## Phase 2 — Score & route

Score each task inline (0–10):
- **0–3**: isolated change, clear scope, single file or small surface
- **4–6**: new component/endpoint, cross-file, moderate complexity
- **7–10**: architecture change, new subsystem, complex integration

| Score | Model | Plan | Review |
|---|---|---|---|
| 0–3 | sonnet | no | `/lreview`; WARNING/BLOCK → fix once, re-review, escalate if still failing |
| 4–6 | sonnet | yes — invoke `writing-plans` | `/lreview`; WARNING/BLOCK → fix once, re-review, escalate if still failing |
| 7–8 | sonnet | yes — invoke `writing-plans` | `/lreview` loop until APPROVE (escalate after 3 failed loops) |
| 9–10 | opus | yes — invoke `writing-plans` | `/lreview` loop until APPROVE (escalate after 3 failed loops) |

For tasks **4+**, name applicable skills in the brief — implementers won't find them on their own:
- Frontend/UI → `anti-slop` + `impeccable` or `design-taste-frontend`
- Feature/bugfix → `superpowers:test-driven-development`
- Debugging → `superpowers:systematic-debugging`

**Brief must include:** project context, exact scope, constraints (worktree path, what NOT to touch), done-condition, skills to invoke, "message orchestrator when done or blocked".

## Phase 3 — Review & phase checkpoints

After each task: review per the table. Route fixes to the same implementer — never spawn a fresh agent.

After each **phase** completes (all its tasks approved and committed):
**CHECKPOINT** — tell the user what is now runnable and exactly what they can test. Wait for "go" before the next phase.

**CHECKPOINT FINAL** after the last phase: branch name, worktree path, test status. Wait before teardown.

Never merge into main. Teardown: `shutdown_request` all teammates, `TeamDelete`, leave worktree intact.

## Escalate only for

- Crucial product/scope decisions no agent can own
- 3 failed lreview loops on the same task
- Anything hard-to-reverse outside the worktree

## Stop if you catch yourself

- Implementing anything yourself
- Proceeding past a CHECKPOINT without "go"
- Spawning a fresh agent to fix review findings instead of messaging the same implementer
- Running git commands in the original checkout
- Spawning design-director for non-UI work
