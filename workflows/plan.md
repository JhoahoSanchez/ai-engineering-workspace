---
description: >
  Design and document a solution before writing any code. Use for anything
  non-trivial: new modules, architectural changes, integrations, data model changes.
---

# /plan

Use this workflow when a task requires design decisions before implementation.
The output is a written plan stored in `memory.md` or a decision document —
not a line of code.

Rule: if the plan takes more than 10 minutes to write, it was needed.
If implementation takes more than 2 hours without a plan, the plan was skipped by mistake.

---

## Step 1 — Load context

Read `.opencode/context.md` and `.opencode/memory.md`.
Identify any existing decisions that constrain or inform the design.

---

## Step 2 — Understand the problem

Before designing a solution, state the problem clearly:

- What user or system need does this address?
- What is the current behavior and why is it insufficient?
- What are the success criteria? How will we know the solution works?
- What are the constraints? (performance, timeline, compatibility, cost)

Write this down. If the problem cannot be stated clearly, the design will be wrong.

---

## Step 3 — Research

Read all relevant files before proposing anything:

- Existing code in the area being changed
- Relevant `architecture/` files for patterns already in use
- Relevant `knowledge/` files for technical context
- Similar problems already solved in the codebase

Load only what is relevant. Do not read the entire workspace.

---

## Step 4 — Generate options (at least two)

For any non-trivial decision, generate at least two distinct approaches.
For each option:

- **What**: describe the approach in 2–4 sentences
- **Pros**: what it does well
- **Cons**: what it trades off
- **Fit**: how well it aligns with existing patterns in the project

Do not jump to a conclusion before writing the options.

---

## Step 5 — Recommend and justify

Pick the option that best fits the project context and constraints.
State clearly: "I recommend option X because Y" — not "both approaches have merit".
Vague recommendations are not recommendations.

---

## Step 6 — Write the plan

Produce a written plan with:

```markdown
## Plan: [feature or change name]

**Date**: [date]
**Status**: proposed | approved | in-progress | done

### Problem

[State the problem from Step 2]

### Decision

[The recommended option and its justification]

### Alternatives considered

[Brief summary of other options evaluated and why they were not chosen]

### Implementation steps

1. [Step 1 — what subagent, what they produce]
2. [Step 2 — ...]
   ...

### Open questions

[Anything that still needs input before or during implementation]

### Trade-offs accepted

[Known downsides of the chosen approach]
```

---

## Step 7 — Present and confirm

Present the plan to the user. Wait for explicit approval before any subagent
begins implementation.

If the user approves: record the decision in `memory.md` (if it's architectural),
then proceed with `/new-feature` or the appropriate workflow.

If the user requests changes: revise the plan and re-present.
Do not begin implementation on a plan that has not been approved.
