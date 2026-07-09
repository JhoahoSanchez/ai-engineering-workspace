---
description: >
  Initialize the workspace for a new project. Run this once when starting a project
  from scratch. Populates context.md, sets up memory.md, and produces an initial plan.
---

# /bootstrap

Use this workflow once at the start of a new project. It guides through filling in
`context.md`, recording the first architectural decisions in `memory.md`, and
producing an initial implementation plan.

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

Using the answers from Step 1, populate `.opencode/context.md` completely.
Do not leave placeholder comments unfilled. If something is unknown, write
"TBD — decision needed" so it is visible, not hidden behind a placeholder.

---

## Step 3 — Record initial architectural decisions

For each significant technical choice made in Step 1 (database selection, architecture style,
cloud provider, language), write an entry in `.opencode/memory.md`:

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
