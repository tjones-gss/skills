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

```
**Answer:** <direct, specific answer>

**Detail:** <supporting explanation, only as much as needed>

**Sources:**
- [Beacon] <title> (updated <date>) — <what it contributed>
- [Teams] <thread/people> (<date>) — ...
- [SharePoint/Notion/issue/...] ...

**Confidence & gaps:** <found vs. inferred; conflicts; staleness; what wasn't found>
```

If a needed source is locked (returns only `authenticate`), say so and ask before triggering its auth flow.
