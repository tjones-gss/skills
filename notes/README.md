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

### Principles (reusable as-is — drop into any project's context)

- **[reference/AGENTS.md](./reference/AGENTS.md)** — the four principles as terse
  **rules** (Think Before Coding · Simplicity First · Surgical Changes · Goal-Driven
  Execution). The short, enforceable version.
- **[reference/EXAMPLES.md](./reference/EXAMPLES.md)** — the same four principles as
  **worked wrong/right code pairs**. Source material the `/overcheck` rubric is built on.

### Nethum's orchestration system

- **[reference/orchestrate-stack/](./reference/orchestrate-stack/)** — the unpacked
  `orchestrate-share` bundle (his authored parts): the `/orchestrate` skill,
  `never-guess`, the design/refactor/simplify **directors**, the `quickreview` agent
  + `/lreview` command, `/ref`, and a `README` with install + prerequisites
  (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, the `superpowers` plugin). The three
  third-party design skills it ships (anti-slop/impeccable/design-taste-frontend)
  were intentionally not vendored — they're published deps his stack invokes.
- **[reference/johndavis.md](./reference/johndavis.md)** — the autonomous
  "proxy manager" (`/johndavis`) layered on top of orchestrate: hands-off,
  decide-by-impact escalation, flat named-teammate roster, sensitivity-driven
  cadence, a preflight hard gate, and a headless `claude -p` child for roadmap research.
- **[reference/johndavis-usage/](./reference/johndavis-usage/)** — Nethum's own
  account (Teams screenshots + `transcript.md`) of how he runs johndavis: the
  research→roadmap `/workflow` pipeline, the `ToManager` folder (charter /
  project-overview / roadmap-status), and a **real `charter.md` example**.

> `/ref` lives in `orchestrate-stack/commands/ref.md` — installable as a command,
> but GSS-specific (needs the GSS MCP servers connected).
> Still missing from what Nethum's shared: `jdorchestrate` and `/auq` (referenced by
> johndavis, not in the orchestrate bundle).

## Why these live here

The skills in this repo encode judgment; these notes are where that judgment came
from. Keeping them together means the *why* travels with the *what*.
