# skills

Personal [Claude Code](https://claude.com/claude-code) skills — small, focused
slash commands and capabilities, each self-contained and installable into
`~/.claude/skills/`.

## Skills

| Skill | What it does |
|-------|--------------|
| [`overcheck`](./skills/overcheck) | `/overcheck` — reviews your uncommitted diff for overengineering (premature abstraction, speculative features, drive-by changes, unverifiable "done") and reports only high-confidence findings. |

## Install

Symlink every skill in this repo into your Claude Code skills directory:

```bash
./install.sh
```

This links `skills/<name>` → `~/.claude/skills/<name>`, so edits in the repo are
live immediately. Override the destination with `CLAUDE_SKILLS_DIR=/path ./install.sh`.
On Windows, run from Git Bash (symlinks need Developer Mode; the script falls back
to copying if linking isn't permitted).

Each skill is invoked by its directory name — e.g. `skills/overcheck/` →
`/overcheck`.

## Repository layout

```
skills/
├── README.md            # this file — index + install
├── install.sh           # links skills/* into ~/.claude/skills/
└── skills/
    └── <skill-name>/
        ├── SKILL.md      # required — the skill (YAML frontmatter + instructions)
        ├── README.md     # recommended — usage and examples
        ├── design.md     # optional — design rationale / spec
        └── fixtures/     # optional — test fixtures + a setup helper
```

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: <skill-name>
   description: <one line — when should this trigger?>
   ---
   ```
   The directory name becomes the `/<skill-name>` invocation.
2. Add `disable-model-invocation: true` if it should run **only** on explicit
   invocation (not auto-trigger).
3. A minimal skill is just `SKILL.md`. For anything non-trivial, add a `README.md`,
   and — following the `overcheck` example — a `design.md` and `fixtures/` so the
   skill is documented and testable.
4. Add a row to the **Skills** table above.
5. `./install.sh` to link it locally.

## Conventions

- **Keep skills lean.** A skill is a thin set of instructions, not an application.
  Prefer one clear job per skill.
- **Be explicit about triggering.** The `description` is how the skill is matched;
  use `disable-model-invocation: true` for on-demand-only tools.
- **Document and test the non-trivial ones.** `overcheck` is the reference standard.
