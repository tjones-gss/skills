# Nethum Weerasinghe — Agentic Programming Notes

> Living doc of useful conversations with **Nethum Weerasinghe** (`nweerasinghe@gssmail.com`), a fellow GSS intern who's strong on agentic / Claude Code workflows. Purpose: learn from what he's doing and reuse his techniques.
> Compiled 2026-06-17 from Teams (1:1 DM, intern group chat, and the R&D *Community-AI Insights* channel). Update as new conversations happen.

## Who he is / how he works
- Intern in the P&E / R&D org; GitHub: `nweerasinghe-gss`. Works in the GSS internal-tools repos (e.g. `GlobalShopSolutions-InternalTools`, `tad-database-service`).
- Deep into **long-running autonomous agent setups** — "agent teams" + loops that run solo for hours and produce near-finished output from a single prompt.
- Heavy, deliberate model user — literally setting aside a paycheck for Fable usage; thinks hard about token economics (see below).
- Generous about sharing artifacts — drops his skills/commands/docs into the R&D *Community-AI Insights* SharePoint channel for everyone.

---

## Key techniques & ideas (what to learn from him)

### 1. Token / context discipline is his #1 theme
- **Don't auto-load everything.** "Make sure all your agents aren't loading every tool, skill, mcp, etc." — load **lazily, only as needed** ("it's called lazy load"). This is the single thing he repeats most.
- His verification loops were initially **very token-hungry**; he iterated specifically to cut that. After trimming a skill + reducing the verification loop, it became "very solid and doesn't eat tokens."
- Usage-window math (Claude Code 5-hour windows): the subscription price is fixed regardless of whether you finish a window at 50% or 90%, so **ideal usage is consistently hitting 90%+ every 5 hours** — i.e. fill the window, don't leave capacity on the table.

### 2. Lean skills (the `SKILL.md` he shared, ~50–70 lines)
- Trimmed the skill down hard; **made sure skills weren't auto-loading**; slightly reduced the verification loop.
- Result: short, solid, low-token. A skill should be a thin orchestrator that *calls* other agents/commands rather than carrying everything inline.
- (File shared in our 1:1 on 2026-06-08: `SKILL.md` on his OneDrive → *Microsoft Teams Chat Files/SKILL.md*. Ask him for the agents/commands it calls.)

### 3. Agent teams + verification loops for long autonomous runs
- Runs "agent teams and loops" with **lots of verification steps** so bugs get caught *as they happen* — the point is to avoid a final product that's "seconds away from melting" after hours of solo running.
- Tradeoff he's actively solving: verification = quality but burns tokens; he's tuning the balance and trying to **get results faster** via the agent-team structure.
- Got a high-quality frontend "(close to) with just one prompt and it running for a couple hours."

### 4. Sub-agent orchestration facts he confirmed (2026-06-16, 🔥-reacted)
- Sub-agents spawned **with the Agent tool or as general-purpose agents can themselves spawn sub-agents** (nested).
- **Sub-agents can talk to each other**, not just back to the main agent.
- This requires the **`SendMessage`** setting turned on in Claude Code. By default an agent can only ever receive **one** message — `SendMessage` is what unlocks ongoing agent-to-agent communication.

### 5. Plan-first workflow for small changes (high hit rate)
- For small changes he tells the model to: **"first investigate with codegraph, then return its approach to solve, then I approve it"** before it touches anything.
- Reports it "hasn't missed yet." Cheap, reliable pattern: investigate → propose → human-approve → execute.

### 6. Worktrees + teams
- Has been experimenting with **git worktrees + agent teams** together (isolated workspaces per agent/task). (Promised a deeper writeup — follow up for details.)

### 7. Countering Claude's overengineering — `EXAMPLES.md`
- Maintains an **`EXAMPLES.md` of overengineering examples paired with their more elegant alternative**, fed to Claude Code to get simpler solutions more consistently. A few-shot "do this, not that" doc for taste/simplicity.
- Shared in *Community-AI Insights* (2026-06-01). **Full content recovered — see the appendix below.** Worth adopting + extending with our own examples.
- It's organized around **four principles** (implies a companion principles/CLAUDE.md doc he feeds alongside it):
  1. **Think Before Coding** — surface hidden assumptions (scope, format, fields, volume) and ask, instead of silently picking one interpretation of a vague request ("make search faster" → response-time vs throughput vs perceived-speed).
  2. **Simplicity First** — no strategy-pattern/abstraction or speculative flags (`merge`/`validate`/`notify`) for what's currently a one-liner. Add complexity only when the requirement actually arrives.
  3. **Surgical Changes** — fix only the lines that fix the reported bug. No drive-by refactors, added type hints, quote-style changes, or docstrings the user didn't ask for. **Match the existing style** (quotes, spacing, return patterns).
  4. **Goal-Driven Execution** — define verifiable success criteria; reproduce-with-a-test first, then make it pass, then check regressions. Incremental + independently verifiable steps over one 300-line commit.
- **Key insight he lands on:** the overcomplicated versions aren't "wrong" — they follow real patterns. The problem is **timing**: adding complexity *before it's needed* makes code harder to understand/test and buggier. *"Good code solves today's problem simply, not tomorrow's problem prematurely."*

---

## Artifact: `/ref` slash command (his best one — full text below)
Shared 2026-06-17 in *Community-AI Insights* as `ref.md`. A reference-lookup slash command that fans out across **every** GSS knowledge source (Beacon/Helpjuice, Teams, email, SharePoint, Notion, mcp-intelligence + all proxy backends) and returns one **cited** synthesized answer. Saves a ton of manual MCP calls hunting for tribal knowledge.

**Why it's good (patterns to steal):**
- "Search broadly, fetch deeply" — search tools return truncated previews, so always deep-fetch full content of strong hits before trusting them.
- **Fan out in parallel** — fire all relevant searches in one message, not source-by-source.
- **Be selective, not exhaustive-by-reflex** — 200+ tools available; pick the ones that plausibly hold the answer rather than hitting all of them. But *always* include the hidden human sources (Teams/email/SharePoint/Notion) because that's the whole point.
- **Cite every claim** with source + date; flag anything >12 months as possibly stale; surface conflicts and prefer the more recent; distinguish found-vs-inferred.
- Tiered source map: Tier 1 curated (Beacon, mcp-intelligence brain incl. `intel_who_knows_about`), Tier 2 hidden-human (M365 + Notion), Tier 3 systems-of-record via `call_proxy_tool` (internal-platform-docs, issue-maint-mcp, bug-triage-pack, cobol-codebase, testarchitect, gab-commands, feature-toggles, log-parser, clinic-utilities).
- Escalate to parallel subagents (one per source cluster) only when breadth warrants; otherwise inline parallel tool calls.

<details>
<summary>Full <code>ref.md</code> source</summary>

```markdown
---
description: Thoroughly research a specific question across ALL GSS knowledge sources — Beacon, Teams chats, email, SharePoint, Notion, and every mcp-intelligence backend — then synthesize one cited answer.
argument-hint: <the specific thing you want to learn / find>
---

Research the following as thoroughly as the sources allow, then give one synthesized, **cited** answer.

Question: $ARGUMENTS

This is a **reference lookup**, not a coding task. The user is trying to learn something specific about Global Shop Solutions (GSS) that may only live in tribal knowledge — a Teams thread, an email, a SharePoint doc, a Notion page, an internal doc server, or an issue's history. Public/training knowledge is the fallback, never the first answer.

## Operating rules

- **Search broadly, fetch deeply.** Most search tools return truncated previews — once you find a strong hit, fetch its full content before you trust it.
- **Fan out in parallel.** Fire the relevant searches across sources in a single message (multiple tool calls at once); don't go source-by-source serially.
- **Be selective, not exhaustive-by-reflex.** There are 200+ tools available — pick the sources that plausibly hold the answer for *this* question rather than hitting all of them. But always include the "hidden" human sources (Teams, email, SharePoint, Notion) since those are the whole point of this command.
- **Cite every claim** with its source and, where available, its `lastUpdated` / date. Flag anything older than ~12 months as possibly stale.
- **Surface conflicts** — if two sources disagree, say so and prefer the more recent one rather than silently picking.
- **Distinguish found-vs-inferred.** Mark clearly what came from a GSS source vs. what is your own general knowledge filling a gap.

## Source map — search these

Decide relevance per question; the human/tribal sources are always in scope.

### Tier 1 — Curated knowledge (start here)
- **Beacon (Helpjuice)** — official product/support docs + teammate tribal knowledge.
  - `search` (broad: `limit` 5–10), then `get_article` / `get_knowledge` for full text; `search_and_fetch` when one hit clearly answers it; `find_similar` to widen.
- **mcp-intelligence brain** — `intel_query_knowledge`, `intel_search_docs`, `intel_query_brain`, and `intel_who_knows_about` (to find *who* knows a topic).

### Tier 2 — Hidden human sources (the reason this command exists — always check)
- **Microsoft 365**
  - `chat_message_search` → **Teams chats** (highest-value hidden source — undocumented decisions live here).
  - `outlook_email_search` → email threads.
  - `sharepoint_search` + `sharepoint_folder_search` → SharePoint docs/sites.
  - `outlook_calendar_search` → meetings (context / who-was-involved).
  - `read_resource` → pull full content of any hit above.
- **Notion** — `notion-search`, then `notion-fetch`; `notion-query-meeting-notes` for decisions captured in meeting notes.

### Tier 3 — System-of-record backends (via mcp-intelligence `call_proxy_tool`)
Use `call_proxy_tool(server, tool, args)`; `list_proxy_tools(server=...)` to see a server's tools.
- **internal-platform-docs** — `search_docs` / `get_topic`: internal platform/tooling docs.
- **issue-maint-mcp** — `search_issues`, `get_issue`: issue/project history, CLI steps, decisions, conversions.
- **bug-triage-pack** — `gh_search_code` / `gh_get_*` (GitHub) and `sw_*` (Service Web calls) for "has this come up before?"
- **cobol-codebase** — `search_cobol_code`, `get_program_summary`, `get_call_graph`: how the COBOL core actually behaves.
- **testarchitect** — `ta_search_test_scripts`, `ta_find_tests_by_*`: how a feature is exercised/verified.
- **gab-commands** — `search_gab_commands`, `get_gab_command_details`: GAB syntax/semantics.
- **feature-toggles** — `search_feature_toggles`, `list_customer_assignments`: what's gated and for whom.
- **log-parser**, **clinic-utilities** — only when the question is log- or clinic-specific.

> Note: proxy **book-of-armaments** mirrors Beacon's KB — don't double-count it; prefer Beacon's richer tools.

## Procedure

1. **Scope** — restate what's actually being asked in one line; name which sources you'll hit and why.
2. **Fan out** — parallel searches across the chosen Tier 1/2/3 sources.
3. **Deep-fetch** — pull full content of the top 2–3 hits per source that look on-target.
4. **Cross-reference** — reconcile across sources; note agreement, conflict, and recency.
5. **Answer** — lead with the direct answer, then supporting detail. Every claim cited.
6. **Gaps** — if a source clearly *should* have had it but didn't, say so; if you learned something durable that wasn't in Beacon, **offer to capture it** via `add_knowledge`.

For an especially broad or deep question, consider escalating to parallel subagents (one per source cluster) — but only if the question's breadth warrants it; default to inline parallel tool calls.

## Output shape

\`\`\`
**Answer:** <direct, specific answer>

**Detail:** <supporting explanation, only as much as needed>

**Sources:**
- [Beacon] <title> (updated <date>) — <what it contributed>
- [Teams] <thread/people> (<date>) — ...
- [SharePoint/Notion/issue/...] ...

**Confidence & gaps:** <found vs. inferred; conflicts; staleness; what wasn't found>
\`\`\`

If a needed source is locked (returns only `authenticate`), say so and ask before triggering its auth flow.
```
</details>

---

## Other shared artifacts (locations + extraction status)
All in the R&D *Community-AI Insights* SharePoint folder unless noted (drive `b!Q6Ca…rO`, folder item `016ZW5GDHROQ3ISTVCINGZQOM3W4XQB533`):
- **`ref.md`** ✅ recovered — the `/ref` research command (full text above). item `016ZW5GDBT5NQDIQ3DQ5F2MKV3DQPFZ7I6`.
- **`EXAMPLES.md`** ✅ recovered — overengineering → elegant pairs (full text in appendix). item `016ZW5GDBQSMC2GW3XJFEIEL3IJMV7SNON`.
- **`SKILL.md` (his lean ~50–70 line skill)** ❌ **not reachable.** It lives only on his **personal OneDrive** (`…/personal/nweerasinghe_gssmail_com/Documents/Microsoft Teams Chat Files/SKILL.md`), shared once as a Teams attachment on 2026-06-08. The M365 connector can't enumerate his OneDrive (root listing returns empty = permission boundary), and a Teams "reference" attachment exposes only a share URL, not a resolvable drive item id. **→ Ask Nethum to drop it in the Community-AI Insights channel** (then it's pullable like the others). Note: a `SKILL.md` *does* exist in that channel but it's a different author's DevExpress-dashboard-XML skill, not his.
- **`AI_Skills_Neuron.zip`**, **`claude-code.zip`**, **`cobol-mcp-server 1.zip`**, **`premortem-brain-2026-05-03.html`**, **`Loop paragraph.loop`**, plus setup guides (`mcp-intelligence-setup.md`, `github-mcp-setup.md`, `mcp-artifacts-guide.md`) — also in that folder, mixed authorship. Browse if useful; not confirmed as Nethum's.

### Extraction notes (how to reach SharePoint files via the M365 MCP)
- The connector surface is just **search + `read_resource`** — there is **no** OneDrive/"shared-with-me"/folder-children tool, and **`WebFetch` can't open SharePoint URLs** (no auth session).
- `sharepoint_search`/`sharepoint_folder_search` are **unreliable / fuzzily-indexed** — `EXAMPLES.md` returned *nothing* by name or content even though it was sitting in the folder. **Don't trust a "no results" as "doesn't exist."**
- The reliable path is to **list the folder directly**: `read_resource` on `file:///{driveId}/root` lists a drive's top folders → grab the target folder's item id → `read_resource` on `file:///{driveId}/{folderItemId}` lists its files with ids → `read_resource` each file. That's how `EXAMPLES.md` was recovered after search failed.
- A user's OneDrive driveId can be discovered incidentally (a fuzzy folder search surfaced one of Nethum's files), and `drive:///users/{aadUserId}` returns their drive root URI — but **enumeration still requires permission**; for Nethum it's blocked.

## Follow-ups to ask Nethum
- **Re-share his lean `SKILL.md` to the Community-AI Insights channel** (only artifact I couldn't pull), plus the agents/commands it calls (he offered).
- The **four-principles / CLAUDE.md** doc that `EXAMPLES.md` pairs with ("demonstrating the four principles").
- His worktrees + agent-teams setup details + how he's making the team faster.
- Current shape of his verification loop after the token-trimming pass.

---

## Appendix: full `EXAMPLES.md` (his anti-overengineering doc)
> Recovered 2026-06-17 from *Community-AI Insights*. Four principles, each with a wrong/right code pair. Drop this (or a trimmed version) into a project's context to keep Claude's solutions simple and surgical.

<details>
<summary>Full <code>EXAMPLES.md</code> source</summary>

````markdown
# Examples

Real-world code examples demonstrating the four principles. Each example shows what LLMs commonly do wrong and how to fix it.

---

## 1. Think Before Coding

### Example 1: Hidden Assumptions
**User Request:** "Add a feature to export user data"
- ❌ LLM silently assumes it should export ALL users, picks a file location, picks which fields (some sensitive), and hardcodes CSV fieldnames without checking the data structure.
- ✅ Surface the assumptions and ask: **Scope** (all vs filtered — privacy), **Format** (browser download? background job + email? API endpoint?), **Fields** (which, any sensitive?), **Volume** (affects approach). Then propose the simplest path (paginated JSON endpoint) and ask preference.

### Example 2: Multiple Interpretations
**User Request:** "Make the search faster"
- ❌ LLM silently adds caching + indexes + async in 200 lines.
- ✅ Distinguish the meanings and quote effort/impact: **response time** (indexes, cache ~2h), **throughput / more concurrent** (async, pooling ~4h), **perceived speed / UX** (partial results, progressive load ~3h). State the current ~500ms baseline and ask which matters.

## 2. Simplicity First

### Example 1: Over-abstraction — "Add a function to calculate discount"
- ❌ `DiscountStrategy(ABC)` + `PercentageDiscount`/`FixedDiscount` + `DiscountConfig` dataclass + `DiscountCalculator` — 30+ lines of setup for a multiply.
- ✅ `def calculate_discount(amount, percent): return amount * (percent / 100)`. Add complexity only when multiple discount types are actually required — refactor then.

### Example 2: Speculative Features — "Save user preferences to database"
- ❌ `PreferenceManager` with injected cache/validator and `merge`/`validate`/`notify` flags + a notify method nobody asked for.
- ✅ `def save_preferences(db, user_id, preferences): db.execute("UPDATE users SET preferences = ? WHERE id = ?", (json.dumps(preferences), user_id))`. Add caching/validation/merging later if/when needed.

## 3. Surgical Changes

### Example 1: Drive-by Refactoring — "Fix the bug where empty emails crash the validator"
- ❌ Also "improves" email validation, adds username length/alnum checks nobody asked for, rewrites comments, adds a docstring.
- ✅ Change only the lines that handle the empty-email case (`email = user_data.get('email', '')`; guard `not email or not email.strip()`). Leave everything else alone.

### Example 2: Style Drift — "Add logging to the upload function"
- ❌ Switches `'` → `"`, adds type hints + docstring, reformats whitespace, changes the boolean return logic — all while "adding logging."
- ✅ Add the logger + `logger.info/error/exception` calls and nothing else. **Match existing style:** single quotes, no type hints, existing boolean pattern, spacing.

## 4. Goal-Driven Execution

### Example 1: Vague vs. Verifiable — "Fix the authentication system"
- ❌ "I'll review the code, identify issues, make improvements, test" — no success criteria.
- ✅ Pin the specific issue (e.g. "old sessions stay valid after password change") and lay out a plan where **each step has a Verify**: write failing test → implement invalidation → edge cases (multiple/concurrent sessions) → full-suite regression green.

### Example 2: Multi-Step with Verification — "Add rate limiting to the API"
- ❌ Full Redis + multiple strategies + config + monitoring in one 300-line commit, no verification steps.
- ✅ Incremental, each independently verifiable/deployable: (1) basic in-memory limit on one endpoint (test: 11th request → 429) → (2) extract to middleware (all endpoints, old tests pass) → (3) Redis backend (survives restart, shared across instances) → (4) per-endpoint config.

### Example 3: Test-First Verification — "The sorting breaks when there are duplicate scores"
- ❌ Immediately rewrites the sort without reproducing.
- ✅ First write a test that reproduces the non-deterministic ordering, confirm it fails, then fix with a stable sort key `(-x['score'], x['name'])`, confirm it passes consistently.

---

## Anti-Patterns Summary
| Principle | Anti-Pattern | Fix |
|-----------|-------------|-----|
| Think Before Coding | Silently assumes file format, fields, scope | List assumptions explicitly, ask for clarification |
| Simplicity First | Strategy pattern for single discount calculation | One function until complexity is actually needed |
| Surgical Changes | Reformats quotes, adds type hints while fixing bug | Only change lines that fix the reported issue |
| Goal-Driven | "I'll review and improve the code" | "Write test for bug X → make it pass → verify no regressions" |

## Key Insight
The "overcomplicated" examples aren't obviously wrong — they follow design patterns and best practices. The problem is **timing**: they add complexity before it's needed, which makes code harder to understand, buggier, slower to implement, and harder to test. The simple versions are easier to understand/implement/test and **can be refactored later when complexity is actually needed**.

**Good code is code that solves today's problem simply, not tomorrow's problem prematurely.**
````
</details>
