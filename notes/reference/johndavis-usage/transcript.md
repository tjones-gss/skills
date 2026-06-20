# johndavis — usage, from Nethum (Teams chat screenshots, 2026-06-18)

Transcribed from the three screenshots in this folder. This is Nethum explaining,
in his own words, how he actually runs `johndavis` day to day — the missing "how
to use it" that pairs with the `johndavis` skill itself.

## image-7-workflow.png — the pipeline he feeds johndavis

> "also you should pass it a very detailed spec + roadmap before letting it automate.
>
> Say you get a task from a person I would then run **workflow with 4 sonnet agents
> to research** and come up with implementation ideas, potential roadblocks,
> workarounds, things to ask my supervisors, look through internal docs for useful
> information; then have **4 more sonnet agents debate, scrutinize, criticize and
> revise** the spec information that the previous sonnet agents sent; then have **2
> opus agents stress test, debate and then synthesize** the information; then **1
> more opus agent** to run a finally pass and break the detailed and by now very long
> synthesis into digestible organized parts.
>
> Then you can pass the task and the spec again through that same loop and get a
> **super detailed roadmap**.
>
> Then you can pass the 2 to the manager.
>
> I also have a **charter.md** that tells the manager how hands-off he can be along
> with some other information.
>
> so i been running johndavis and pointing him at a **ToManager folder** that has the
> information he needs to execute without asking me any questions"

The `ToManager` folder he points johndavis at contains three files:
- `charter`
- `project-overview`
- `roadmap-status`

> "if I dont pass these 3 to him then he doesn't execute and asks me for them — he
> does have the ability to make his own roadmap through the same workflow i described
> earlier"

(These three map exactly to the johndavis Preflight HARD GATE: `charter.md`,
`overview.md`, `roadmap-status.md`. The "make his own roadmap" path is johndavis
Phase 0a — the headless `claude -p` child running the bounded research workflow.)

## image-8-charter-example.png + image-9-charter-autonomy.png — a real charter.md

Title: **"Charter — johndavis mandate for the next DAM refactor wave"**
> "Your standing orders from Nethum. The Decision Protocol in the johndavis skill is
> *how* you behave generally; this is *what* you're authorized to do here."

**Mandate (excerpt):** Refactor the CRUD data-access managers for the next batch of
objects into the **descriptor pattern**, emulating already-merged exemplars
(Account / Shipment / Invoice) + the descriptor patterns/structure "Annora supplied."
Objects in scope given as a table — each object = the triplet
`<Obj>DataAccessManager.vb` + `<Obj>LoadDataAccessManager.vb` + `<Obj>sLoadDataAccessManager.vb`:

| ObjectId | Namespace.Object | Managers folder | Notes |
|---|---|---|---|
| 2 | Inventory.Part | `Managers/Inventory/` | |
| 21 | Manufacturing.Bom.Bom | `Managers/Manufacturing.Bom/` | |
| 71 | Sales.SalesOrder | `Managers/Sales/` | |
| 1285 | Manufacturing.WorkcenterCalendarV3 | `Managers/Manufacturing/` | Worst object — likely a nightmare. Give it a solo team + extended brief. |

- **Out of scope until Nethum clears it:** `Manufacturing.Bom.BomExplosion` (ObjectId 904) — doesn't exist in the tree; awaiting Annora. "Do **not** invent it."
- Build each object in its **own git worktree**.

**Autonomy — run the management fully hands-off:**
- Manage end-to-end without check-ins. Plan, dispatch, `/lreview` every teammate's code, integrate. No phase go-gates.
- **You do NOT stop to report progress.** Only two reasons to hand back to Nethum:
  1. **Ready to merge an object** into `nethum/dam-refactor-integrate` — post the merge package and await go-ahead for the merge itself.
  2. **A pressing question or hard blocker** — something irreversible, external, or unresolvable by you (see Decision Protocol).
- Everything between those two points — worktree setup, drafting, testing, review loops, fixes — is yours to run autonomously.
- **Never write code yourself** — manage and review only. Inject `never-guess` into every teammate brief.

**Definition of done (per object) — byte-for-byte or it isn't done:**
- All three managers converted to the descriptor pattern, exposed signatures preserved (additive-only vs `GSSEO/DataAccess/FROZEN-SIGNATURES.md`).
- **Rigorous golden-SQL verification** against the control group is mandatory and non-negotiable. The emitted SQL must be **byte-identical (MD5-intact)** to the control output — never "close", never "functionally equivalent". Run with `TestCategory=GoldenSQL` — never `GoldenCapture`. Add/extend fixtures under `Tests/ObjectTests/GoldenSQL/Fixtures/` for each object, covering every CRUD + Load path.

### Why this example matters
It's a concrete, real charter showing the *what-you're-authorized-to-do* layer that
sits on top of the johndavis skill's general behavior: scope table, explicit
out-of-scope ("do not invent it"), per-object worktree isolation, a precise
done-condition (byte-identical golden SQL), and the exact two hand-back conditions.
A good template for writing your own `charter.md`.
