# notes

Durable learnings worth keeping next to the skills — what good agentic practice
looks like and where the skills here came from.

## Contents

- **[nethum-agentic-notes.md](./nethum-agentic-notes.md)** — consolidated notes on
  agentic / Claude Code workflows learned from Nethum Weerasinghe (GSS). Covers
  token/context discipline, lean skills, agent teams + verification loops,
  sub-agent orchestration (`SendMessage`), a plan-first workflow, and the four
  anti-overengineering principles. The `/overcheck` skill in this repo is a direct
  descendant of these notes.

- **[reference/EXAMPLES.md](./reference/EXAMPLES.md)** — Nethum's full
  anti-overengineering example doc: four principles (Think Before Coding,
  Simplicity First, Surgical Changes, Goal-Driven Execution), each a wrong/right
  code pair. **Reusable as-is** — drop it into a project's context to keep Claude's
  solutions simple and surgical. (It's the source material the `overcheck` rubric
  is built on; the consolidated notes embed a condensed summary.)

- **[reference/ref.md](./reference/ref.md)** — Nethum's `/ref` multi-source research
  command: fans out across all GSS knowledge sources (Beacon/Helpjuice, Teams,
  email, SharePoint, Notion, mcp-intelligence proxy backends) and returns one cited
  answer. **Installable as a command** — copy into `~/.claude/commands/ref.md` (or
  add as a skill) to use it. GSS-specific.

- **[reference/orchestrate.md](./reference/orchestrate.md)** — Nethum's agent-team
  coordinator skill (`/orchestrate`): worktree isolation → phased roadmap →
  score-and-route by complexity (model/plan/review matrix) → review + checkpoints.
  A pure coordinator that never implements.

- **[reference/johndavis.md](./reference/johndavis.md)** — Nethum's autonomous
  "proxy manager" (`/johndavis`) layered on top of orchestrate: runs hands-off,
  decides-by-impact with an escalation protocol, flat named-teammate roster,
  sensitivity-driven cadence, a preflight hard gate, and a headless `claude -p`
  child for roadmap research. The notes doc's *Update 2026-06-18* section explains
  the ideas worth stealing.

## Why these live here

The skills in this repo encode judgment; these notes are where that judgment came
from. Keeping them together means the *why* travels with the *what*.
