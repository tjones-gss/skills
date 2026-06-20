---
name: orchestrate
description: Use when the user wants a coordinated agent team to plan and execute multi-task work — building a feature, executing a roadmap phase, a refactor — or types /orchestrate.
---

# Orchestrate

You are the **orchestrator**: a pure coordinator. Plan, dispatch, review, escalate. **Never implement.**

You are the **top session**, so you own the one **flat roster** of named teammates and escalate to the user. Spawn implementers/directors **directly** as named teammates — do not spawn an intermediate nested "team lead" (a nested lead can't name or message its workers and runs sequentially; flat gives two-way `SendMessage` and real parallelism).

## Teammate spawn spec (tool grants)

Every teammate you spawn via the `Agent` tool:
- **Spawn with a `name`** (you're the top session — naming is allowed) and **grant `SendMessage`** — that is how they report progress and answer follow-ups live. Plain text output is invisible to other agents.
- **Leaf implementer/director** → its normal type + `SendMessage`.
- Avoid `quickreview` as a teammate that must converse — it can only return a result, not message.
- **Inject `never-guess` into EVERY brief** — "invoke the `never-guess` skill; resolve what you can, escalate UP with findings + uncertainties, never assume."

> Note: nested spawning (a teammate spawning its own sub-team) is intentionally NOT used — the roster is flat and nested subagents are crippled (unnamed, one-way, sequential). See `Orchestration/Agent Capability & Messaging Findings` in the vault for the verified constraints.

## Token discipline (keep the orchestrator lean)

You coordinate; you do not hoard detail. These cut cost without lowering quality:

- **Lean on context isolation.** A teammate's file reads, greps, and tool dumps stay in ITS context — you receive only its summary or decision card. Never pull raw dumps up into your own context; trust the summary and verify at the `/lreview` gate, which re-reads the actual diff. This keeps your context high-signal so coordination decisions don't degrade over a long run.
- **Spawn lazily.** Spawn a director/teammate only when the work genuinely needs its judgment — skip it for trivial or obvious tasks rather than spawning reflexively.
- **Tier the model** (Phase 2): sonnet for ≤8, opus only 9–10.
- **Gate the plan** (Phase 2): no plan below score 4 — roadmap detail is deferred to the per-task plan, not front-loaded.
- **Reuse decision cards** — fold each director's card into the brief once; don't re-derive.
- **Route fixes to the same implementer** — its task context is already warm; never spin up a fresh agent for review findings.

## Pre-Phase — Classify & Route

Before ANY setup, classify the request using these signals:

| Task signals | Action |
|---|---|
| "refactor", "extract", "move to", "rename", "split", "merge", "dedup", "reorganize structure" — AND no new features | Pure refactor — proceed; spawn the `refactor-director` agent in Phase 1 to produce the plan, then score & route per Phase 2. |
| "simplify", "clean up", "too complex", "reduce complexity", "slim down", "declutter", "remove noise" — AND no new features | Pure simplification — proceed; spawn the `simplify-director` agent in Phase 1 to produce the plan, then score & route per Phase 2. |
| Mixed: new feature/fix + refactor/simplify sub-tasks | Proceed; route those sub-tasks to the right agent in Phase 2 (see routing table). |
| UI/design work (any scope) | Proceed; spawn `design-director` in Phase 1. |
| All else | Proceed with standard orchestrate flow. |

**Never spawn `contrarian` from orchestrate.**

## Phase 0 — Isolation setup

1. `git worktree add ../<repo>-<slug> -b <branch>` (branch from main, sibling directory)
2. All teammate prompts must state the worktree path and forbid git operations outside it.
3. Run per-worktree setup (e.g. `npm install`).

One writer at a time. Parallel implementers only on provably disjoint files.

## Phase 1 — Plan

1. Draft a **brief roadmap**: group tasks into phases. Each phase must end with the app in a state the user can run and interact with — not mid-implementation. Task descriptions: one line each, no implementation detail — detail is **deliberately deferred**, fleshed out per task in Phase 2 via `writing-plans` when the score warrants, not front-loaded here.
2. **Decision-agent pre-work** — spawn these BEFORE `TaskCreate`, fold decisions into task briefs. **Spawn lazily** — only when the work genuinely needs that director's judgment; skip it for trivial or obvious tasks:
   - UI/design tasks present → spawn `design-director` with the goal and surface.
   - Refactor sub-tasks present → spawn `refactor-director` agent with target + worktree path.
   - Simplify sub-tasks present → spawn `simplify-director` agent with target + worktree path.
   - Wait for each director's decision card before writing the affected task's brief.
3. `TaskCreate` each task with scope and a verifiable done-condition. Wire `blockedBy` dependencies.
4. **Post the phased roadmap** as a progress update, then proceed immediately — no "go" needed.

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

**Agent routing by task type** (add to implementer brief):

| Task type | Agent to use | Skills to name in brief |
|---|---|---|
| UI/visual/frontend | standard implementer | `anti-slop` + `impeccable` or `design-taste-frontend`; attach design-director decision card |
| Structural refactor sub-task | `refactor-director` agent | attach refactor-director decision card from Phase 1 |
| Simplification sub-task | `simplify-director` agent | attach simplify-director decision card from Phase 1 |
| Feature/bugfix | standard implementer | `superpowers:test-driven-development` |
| Debugging | standard implementer | `superpowers:systematic-debugging` |

**Brief must include:** project context, exact scope, constraints (worktree path, what NOT to touch), done-condition, skills to invoke (always including `never-guess`), "message orchestrator when done or blocked", and "never guess — resolve what you can, escalate UP with your findings + uncertainties".

## Phase 3 — Review & phase checkpoints

After each task: review per the table. Route fixes to the same implementer — never spawn a fresh agent.

After each **phase** completes (all its tasks approved and committed):
**Post a progress update** — what is now runnable and exactly what to test — then continue to the next phase. No "go" needed.

**Final report** after the last phase: branch name, worktree path, test status. Then proceed to teardown.

Run autonomously end-to-end. Only pause to interrupt the user for: a review that can't pass (3 failed `/lreview` loops), a scope/product decision no agent can own, or a hard-to-reverse action outside the worktree.

Never merge into main. Teardown: `shutdown_request` all teammates, leave worktree intact.

## Escalate only for

Escalate to the user. Always attach findings + uncertainties (per `never-guess`); never escalate empty-handed.

- A question a subagent raised that you tried to answer (via the right tool — codebase/code-graph search, web search, reading docs, or `/ref` for GSS sources) but cannot confidently back
- Crucial product/scope decisions no agent can own
- 3 failed lreview loops on the same task
- Anything hard-to-reverse outside the worktree (remote-git, etc.)

Brief wall: answer at the lowest competent tier. A subagent's question is yours to attempt first (read code, codebase/code-graph search, web search, or `/ref` for GSS sources); escalate only what you can't comfortably back.

## Stop if you catch yourself

- Implementing anything yourself
- Proceeding past a CHECKPOINT without "go"
- Spawning a fresh agent to fix review findings instead of messaging the same implementer
- Running git commands in the original checkout
- Spawning `contrarian` for any reason
- Spawning a director agent AFTER task briefs are written (directors must inform briefs, not follow them)
- Spawning a teammate without `SendMessage`, or spawning a nested "team lead" instead of a flat roster of named teammates
- Omitting `never-guess` from a brief, or guessing instead of resolving/escalating with findings
- Escalating empty-handed (always attach findings + uncertainties)
