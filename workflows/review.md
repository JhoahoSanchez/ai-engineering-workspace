---
description: >
  Full code review of a branch, PR, or set of changes. Covers standards compliance,
  correctness, security, and test coverage. Produces a structured review report.
---

# /review

Use this workflow to review code before merging. Can be triggered by the user
("review this PR") or called automatically at the end of `/new-feature`.

---

## Step 1 — Scope the review

Identify what is being reviewed:

- Which files changed? (`git diff main...HEAD --name-only` or as specified by the user)
- What is the intent of the changes? (feature, fix, refactor, dependency update)
- Is there a linked plan or issue to review against?

If the scope is unclear, ask before proceeding.

---

## Step 2 — Correctness review

Read the changed files. For each logical change, verify:

- Does the implementation match the stated intent?
- Are all code paths handled (including error paths)?
- Are there off-by-one errors, boundary conditions, or race conditions?
- Does it handle the edge cases expected for this domain?
- Is any new dependency introduced? If so, is it necessary and trustworthy?

---

## Step 3 — Standards compliance

Check against the relevant standards:

- `standards/coding.md` — TypeScript strictness, function size, module structure
- `standards/naming.md` — files, variables, endpoints, database columns
- `standards/error-handling.md` — typed errors, no silent catches, user-safe messages
- `standards/logging.md` — no console.log, structured logs, sensitive data not logged
- `standards/git.md` — commit messages, branch naming

Flag violations by file and line. Do not approve with unresolved standards violations.

---

## Step 4 — Security review (for security-sensitive changes)

Invoke the **security** subagent if the changes involve:

- Authentication or authorization logic
- Input handling from external sources
- User data storage or transmission
- New dependencies
- Infrastructure or environment changes

For routine changes (internal refactors, UI copy, test additions), skip this step.

---

## Step 5 — Test coverage

Verify:

- New business logic has corresponding tests
- Bug fixes have a regression test
- Tests follow `standards/testing.md` (behavior-focused, not implementation-focused)
- All existing tests pass

Run the test suite if `bash` is available:

```bash
pnpm test  # or the test command from context.md
```

---

## Step 6 — Produce the review report

```markdown
## Code Review — [branch or PR name]

**Reviewed**: [date]
**Files changed**: [count]
**Intent**: [what the changes are supposed to do]

### Correctness

- [x] Implementation matches intent
- [x] Error paths handled
- [ ] Race condition on concurrent order updates — see file:line

### Standards

- [x] Naming conventions followed
- [ ] `orderService.ts:45` — silent catch, should propagate error

### Security

- [Skipped — no security-sensitive changes]
- OR: [Delegated to security subagent — see security report]

### Tests

- [x] New logic has tests
- [x] Existing tests pass
- [ ] Missing regression test for the null tableId case

### Verdict

**APPROVED** / **APPROVED WITH MINOR COMMENTS** / **CHANGES REQUESTED**

### Required changes (if CHANGES REQUESTED)

1. [specific required change]
```

---

## Step 7 — Follow-up

If the verdict is CHANGES REQUESTED:

- Route required fixes to the appropriate subagent
- Re-run only the sections of the review affected by the fixes
- Do not re-review unchanged sections

If the verdict is APPROVED:

- Inform the user the PR is ready to merge
- Run `/release` if this was the last change before a release
