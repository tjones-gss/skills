# Orchestrate — shared bundle

A coordinated multi-agent workflow for Claude Code. `/orchestrate` plans multi-task work,
isolates it in a git worktree, spawns named teammates to implement in parallel, reviews each
change, and runs autonomously to completion. The orchestrator never writes code itself — it
coordinates.

## What's in this bundle

```
skills/
  orchestrate/            ← the main skill
  never-guess/            ← resolve-or-escalate-with-findings discipline (injected into every brief)
  anti-slop/              ← UI/frontend brief (anti AI-slop rules)
  impeccable/             ← UI/frontend brief (design quality)
  design-taste-frontend/  ← UI/frontend brief (alt direction)
agents/
  design-director.md      ← UI/design decisions (Phase 1)
  refactor-director.md    ← refactor analysis + plan
  simplify-director.md    ← simplification analysis + plan
  quickreview.md          ← single-reviewer agent used by /lreview
commands/
  lreview.md              ← /lreview — runs quickreview over a diff
  ref.md                  ← /ref — GSS-only research lookup (see note)
```

## Install

Copy the three folders into your Claude Code config dir (merge, don't overwrite unrelated files):

```bash
cp -r skills/*   ~/.claude/skills/
cp -r agents/*   ~/.claude/agents/
cp -r commands/* ~/.claude/commands/
```

Restart Claude Code so it picks up the new skills/agents/commands.

## Prerequisites (REQUIRED — it won't work without these)

1. **Enable agent teams.** Multi-agent teammates + the `SendMessage` tool are experimental and
   **off by default**. Add this to `~/.claude/settings.json`, then restart:

   ```json
   { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
   ```

   Without it, no teammates spawn and `SendMessage` is unavailable — orchestrate cannot run.

2. **Install the `superpowers` plugin.** Orchestrate references three skills that live in it —
   `writing-plans`, `test-driven-development`, `systematic-debugging`. Install via `/plugin`
   (claude-plugins-official → superpowers). They are NOT bundled here on purpose (stay upstream).

3. **codebase-memory / code-graph (optional).** Briefs may reference codebase search; any
   code-graph MCP works, none is required for the core flow.

## Note on `/ref` (GSS-internal)

`/ref` researches across GSS knowledge sources — Beacon, Teams, SharePoint, Notion, and the
mcp-intelligence backends. It only works if those **GSS MCP servers are connected** to your
Claude Code. Outside GSS it's inert — orchestrate falls back to normal codebase/web research.
Drop `commands/ref.md` if you don't have GSS MCP access.

## How to use

```
/orchestrate <describe the multi-task work>
```

- Pure refactor / simplify requests route to the `refactor-director` / `simplify-director`
  agents inline (Phase 1 plan → scored routing).
- UI/design work pulls in `design-director` + the anti-slop/impeccable/design-taste briefs.
- Every task is scored 0–10 → model + plan + `/lreview` gate chosen per tier.
- Runs autonomously; only interrupts you for a review that can't pass, an un-ownable
  product decision, or a hard-to-reverse action outside the worktree.

## Teardown caveat

On teardown the orchestrator sends `shutdown_request` to teammates, but in-process teammates
ack and go idle rather than fully terminating — they (and the statusline chips) clear only when
you **exit/restart the session**. This is current Claude Code behavior, not a bug in the skill.

## Excluded on purpose

- `contrarian` agent — orchestrate explicitly never spawns it.
- `superpowers` skills — reference via plugin install (see prerequisites).
