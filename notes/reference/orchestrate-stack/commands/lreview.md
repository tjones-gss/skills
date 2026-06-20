---
description: Lightweight review — runs the quickreview agent over the current diff (or given scope) and reports its verdict
argument-hint: [optional scope/files — defaults to the unstaged git diff]
---

Run a focused code review by dispatching the **`quickreview`** agent over recently-completed work. This is the lightweight counterpart to `/scrutinize`: a single expert reviewer, no multi-lens fan-out.

Scope: $ARGUMENTS
If empty, the agent reviews the unstaged git diff by default. If it names files, a PR, or a focus area, pass that to the agent as its scope.

Steps:
1. Invoke the `quickreview` agent (the Agent tool with `subagent_type: quickreview`), telling it exactly what to review (the unstaged diff by default, or the scope above).
2. Relay the agent's findings and its **Review Summary table + Verdict (APPROVE / WARNING / BLOCK)** back to me. Don't add a second, redundant review of your own — surface the agent's output, and only add a brief note if something needs my attention or the scope was ambiguous.
