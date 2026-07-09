---
description: Structured workflow for diagnosing and fixing a bug, from reproduction to verified fix.
---

# /fix-bug

Use this workflow for any reported bug. The goal is to find the root cause before
writing a single line of fix — never patch symptoms.

---

## Step 1 — Load context

Read `.opencode/context.md`. Understand which part of the system the bug affects.

---

## Step 2 — Reproduce

Before diagnosing, confirm the bug is reproducible:

- What are the exact steps to reproduce?
- What is the expected behavior?
- What is the actual behavior?
- Is it consistent or intermittent?

If reproduction steps are unclear, ask the user for them before proceeding.
A bug that cannot be reproduced cannot be reliably fixed.

---

## Step 3 — Diagnose (root cause, not symptom)

Search the codebase for the relevant code path. Trace from the symptom back to the origin:

```text
Symptom (what the user sees)
    ↓
Entry point (route handler, event listener, UI action)
    ↓
Service/business logic
    ↓
Data layer / external integration
    ↓
Root cause
```

Common root causes to check:

- Missing input validation (unexpected input reaches logic that assumes valid data)
- Off-by-one or boundary condition
- Race condition or async issue (promise not awaited, concurrent writes)
- Wrong assumption about data shape (null where not expected, wrong type)
- Missing error handling (exception swallowed, leaving state inconsistent)
- Stale cache or data (reading from local when remote has newer state)

**Do not write a fix until the root cause is identified and stated explicitly.**

---

## Step 4 — Write a failing test first

Before fixing, write a test that:

1. Reproduces the bug (test fails with the current code)
2. Will pass after the fix

This ensures the bug does not regress. Place the test in the correct test file
following `standards/testing.md`.

---

## Step 5 — Fix

Invoke the appropriate subagent(s) based on where the root cause lives:

- Root cause in data layer → **database**
- Root cause in server logic → **backend**
- Root cause in edge device logic → **edge**
- Root cause in UI → **frontend**
- Root cause in sync/event logic → **distributed**

Provide the subagent with: the root cause, the failing test, and the expected fix.

---

## Step 6 — Verify

After the fix:

1. Confirm the failing test from Step 4 now passes.
2. Invoke **qa** to run the relevant checklist and check for regressions.
3. Grep for similar patterns elsewhere in the codebase — the same bug may exist in other places.

```bash
# Example: if the bug was missing null check on order.tableId
grep -rn "order\.tableId" src/
```

---

## Step 7 — Document and close

- Write a commit message that describes the root cause, not the symptom:
  `fix(orders): handle null tableId when voiding takeout orders`
  not: `fix: bug in order voiding`
- If the bug reveals a gap in `standards/` or `checklists/`, add it.
- If the root cause was an architectural assumption that was wrong, update `memory.md`.
- Report to the user: what the root cause was, what was fixed, and what test covers it.
