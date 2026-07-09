# New Feature — Definition of Done

Use this checklist at the end of `/new-feature` to confirm a feature is complete.
QA runs this before reporting back to the architect.

---

## Functional completeness

- [ ] All acceptance criteria from the feature plan are met
- [ ] Happy path works end-to-end (UI → API → DB → response)
- [ ] All error states are handled and displayed appropriately
- [ ] Edge cases identified during planning are handled
- [ ] Feature degrades gracefully if a dependency (network, hardware, etc.) is unavailable

## Implementation quality

- [ ] Pre-merge checklist passes (`checklists/pre-merge.md`)
- [ ] Business logic lives in the service layer, not in route handlers or UI components
- [ ] No direct database access from the API layer or UI layer
- [ ] No new tech debt introduced without a corresponding tracked issue

## Tests

- [ ] Unit tests cover the core business logic and its error paths
- [ ] At least one integration or end-to-end test covers the happy path
- [ ] All existing tests still pass (no regressions)

## Documentation

- [ ] New API endpoints are documented (if applicable)
- [ ] New environment variables are in `.env.example`
- [ ] `context.md` is updated if the feature changes the active development area
- [ ] Any architectural decisions made during implementation are recorded in `memory.md`

## UX (if the feature has a UI)

- [ ] Loading state shown while data is being fetched
- [ ] Error state shown with a human-readable message (not a raw API error)
- [ ] Empty state handled (no blank/broken UI when there is no data)
- [ ] Feature is accessible: keyboard navigable, labels present, meaningful focus management

## Non-functional

- [ ] No observable performance regression on the critical path
- [ ] Feature does not break existing features (regression test or manual smoke test)
- [ ] Logging is in place for key operations (create, update, delete, error)

---

## Sign-off

When all items are checked (or waived with a reason), the QA subagent reports:

```text
Feature: [feature name]
Verdict: DONE / NOT DONE

Unchecked items: [list or "none"]
Waivers: [list with reason or "none"]
```
