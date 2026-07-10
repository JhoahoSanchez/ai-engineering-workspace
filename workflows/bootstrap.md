---
description: >
  Initialize the workspace for a new project. Run this once when starting a project
  from scratch. Populates context.md, sets up memory.md, and produces an initial plan.
---

# /bootstrap

Use this workflow once at the start of a new project. It guides through filling in
`context.md`, recording the first architectural decisions in `memory.md`, and
producing an initial implementation plan.

An optional helper script (`.opencode/init.sh`) can accelerate Steps 2–3 by
auto-detecting project files and prompting interactively. If the user prefers
a conversational approach, fill in the fields manually as described below.

---

## Step 1 — Gather project information

Ask the user for the following. Collect all answers before proceeding
(ask as a single structured message, not one question at a time):

1. **Project name and description** — one sentence on what it does and for whom.
2. **Tech stack** — language, framework, database, cloud provider. If not decided, say so.
3. **Architecture style** — monolith, microservices, offline-first, SaaS, mobile, etc.
4. **First milestone** — what is the smallest thing that needs to work first?
5. **Known constraints** — budget, timeline, must-use technologies, must-avoid technologies.
6. **What already exists** — is this from scratch or are there existing files/services?

---

## Step 2 — Fill in context.md

Two options (choose one):

**Option A — Interactive script (recommended for CLI users):**
Run `bash .opencode/init.sh`. It will:

- Detect existing project files (`package.json`, `Dockerfile`, etc.) and pre-fill defaults.
- Prompt through every section of `context.md`.
- Optionally seed `memory.md` with the first architectural decision.
- Leave any unknown field as `TBD — decision needed` (no hidden placeholders).

After the script finishes, review the output and adjust any fields.

**Option B — Manual (use when the user prefers conversation):**
Populate `.opencode/context.md` directly using the answers from Step 1.
Do not leave placeholder comments unfilled. If something is unknown, write
"TBD — decision needed" so it is visible, not hidden behind a placeholder.

---

## Step 3 — Record initial architectural decisions

If you used Option A in Step 2 (the `init.sh` script), a first decision may
already be in `memory.md`. Review it and fix any inaccuracies.

For each significant technical choice made in Step 1 (database selection,
architecture style, cloud provider, language), write (or verify) an entry in
`.opencode/memory.md`:

```markdown
### [YYYY-MM-DD] [Decision title]

**Decision**: [what was chosen]
**Rationale**: [why this, not alternatives]
**Alternatives considered**: [what else was evaluated]
**Trade-offs accepted**: [known downsides]
```

If a decision was not made yet (stack is undecided), do not invent one —
flag it as an open question.

---

## Step 4 — Identify open decisions

List every significant technical decision that has NOT yet been made.
For each one, describe:

- What needs to be decided
- What information is needed to make the decision
- Whether it blocks the first milestone or can be deferred

Present the list to the user. Decisions that block the first milestone must be resolved
before implementation begins. Deferred decisions go into `context.md` under "Open decisions".

---

## Step 5 — Draft the initial implementation plan

Using `/plan`, produce a plan for the first milestone only.
Do not plan beyond the first milestone — scope grows as the project progresses.

The plan should cover:

- What will exist when the milestone is done
- Which subagents will be needed and in what order
- What templates from `templates/` are relevant as starting points
- Estimated sequence of tasks

---

## Step 6 — Confirm and start

Present the completed `context.md`, the recorded decisions, and the milestone plan
to the user for confirmation.

On confirmation: update `context.md` status to `in-development` and begin
the first task from the milestone plan using `/new-feature`.
