---
description: Full workflow for implementing a new feature from requirements to done.
---

# /new-feature

Use this workflow when starting any new feature. It guides from requirements through
implementation, testing, and documentation.

---

## Step 1 — Load context

Read `.opencode/context.md` and `.opencode/memory.md`.
Verify the feature does not conflict with any recorded decision.

---

## Step 2 — Clarify before starting

Ask the user **one** clarifying question if any of these are unknown:

- What is the user-facing outcome? (What can a user do after this that they couldn't before?)
- Are there acceptance criteria or edge cases the user has in mind?
- Does this feature have a deadline or dependency on another feature?

If nothing is ambiguous, skip this step and proceed.

---

## Step 3 — Plan (output a written plan before writing code)

Produce a short plan with:

- **What changes**: list of files/modules affected
- **Data model**: any new tables, columns, or schema changes needed
- **API surface**: new or modified endpoints/events
- **Subagents needed**: which subagents will be invoked and in what order
- **Open questions**: any decision points that may need input before proceeding

Present the plan to the user. Wait for approval or adjustments before continuing.

---

## Step 4 — Implement (invoke subagents in dependency order)

Typical order — adjust based on the feature:

1. **database** — schema changes and migrations first (other subagents depend on it)
2. **backend** — business logic and API layer
3. **edge** — if any edge device behavior is involved
4. **distributed** — if sync or cross-node coordination is involved
5. **frontend** — UI consuming the backend
6. **security** — review if the feature involves auth, user data, or external input

Each subagent runs to completion before the next is invoked.
If a subagent reports a blocker, resolve it before continuing down the chain.

---

## Step 5 — QA

Invoke **qa** subagent with:

- What was built
- Which checklist to run (`checklists/new-feature.md`)
- Any known edge cases from Step 2

Wait for QA report. If verdict is FAIL, send failing items back to the responsible
subagent for fixes, then re-run QA on the affected parts.

---

## Step 6 — Documentation

Invoke **documentation** subagent to:

- Update or create the relevant README section
- Document any new API endpoints
- Add inline comments for non-obvious logic

---

## Step 7 — Close

- Update `context.md` if the feature changes the active development area.
- If any architectural decision was made during implementation, update `memory.md`.
- Report to the user: what was built, what was decided, and any follow-up items.

---

## Abort criteria

Stop and escalate to the user if:

- A decision is needed that contradicts something in `memory.md`
- A dependency on an external service or API is not yet in place
- The scope expanded significantly beyond the original plan
