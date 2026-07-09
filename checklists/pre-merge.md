# Pre-Merge Checklist

Run this checklist on every PR before merging. The QA subagent runs this automatically
at the end of `/new-feature` and `/review`. A single unchecked item is a merge blocker
unless explicitly accepted with a reason.

---

## Code quality

- [ ] No `any` types introduced (TypeScript strict)
- [ ] No non-null assertions (`!`) without proof they are safe
- [ ] No commented-out code
- [ ] No `console.log`, `console.error`, or `console.warn` (use the project logger)
- [ ] No TODO comments without a linked issue reference
- [ ] Function length is reasonable (no function doing more than one thing)
- [ ] No hardcoded strings that should be constants or config values

## Naming and structure

- [ ] File names follow `standards/naming.md`
- [ ] Variable and function names follow `standards/naming.md`
- [ ] New files are placed in the correct directory (service in services/, repo in repositories/, etc.)
- [ ] No circular dependencies introduced

## Error handling

- [ ] No empty catch blocks (`catch (e) {}`)
- [ ] Errors thrown are typed `AppError` subclasses, not raw `new Error()`
- [ ] User-facing error messages are human-readable and do not expose internals
- [ ] All async functions have error handling (try/catch or propagation)

## Testing

- [ ] New business logic has unit tests
- [ ] Bug fixes have a regression test
- [ ] All existing tests pass
- [ ] Tests follow the Arrange / Act / Assert pattern
- [ ] Tests cover at least one error path, not only the happy path

## Security

- [ ] No secrets or credentials in code or test files
- [ ] External inputs are validated before use
- [ ] Authorization checked for any endpoint that accesses or modifies user data
- [ ] No sensitive data (passwords, tokens, PII) in logs or API responses

## Database (if applicable)

- [ ] Schema changes are in a migration (not applied directly)
- [ ] Migration is backwards-compatible with the current deployed version
- [ ] New queries use parameterized statements (no string concatenation)
- [ ] Indexes created for new columns used in WHERE/JOIN/ORDER BY

## Documentation

- [ ] New public API endpoints are documented
- [ ] New environment variables are added to `.env.example`
- [ ] Non-obvious logic has explanatory comments
- [ ] README updated if setup steps changed

## PR hygiene

- [ ] PR description is filled in (not empty)
- [ ] Commit messages follow `standards/git.md`
- [ ] Branch is up to date with `main` (no outdated merge conflicts)
- [ ] No unrelated changes mixed into this PR

---

## Waiver format

If an item is intentionally skipped, document it:

```text
[ ] WAIVED: [checklist item] — [reason] — accepted by: [who]
```

Waivers must be visible in the PR description, not hidden in a comment.
