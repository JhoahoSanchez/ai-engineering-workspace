# Pull Request Description Template

Copy this into every PR description. Fill in all sections.
A PR without a description is not ready for review.

---

## Template

```markdown
## What

[1–3 sentences: what does this PR do? What is different after it merges?
Focus on the outcome, not the implementation.]

## Why

[Why is this change needed? Link to an issue, user story, or bug report if one exists.
If there is no ticket, explain the motivation in 1–3 sentences.]

## How

[Optional but recommended for non-trivial changes.
Describe the key implementation decisions or approach.
Link to relevant architecture/ or knowledge/ files if helpful.]

## Testing

[How was this tested? Check all that apply:]

- [ ] Unit tests added/updated (run with `pnpm test`)
- [ ] Manual testing — describe what was tested and how
- [ ] Tested on staging
- [ ] No testing needed — explain why

## Screenshots / recordings (if UI change)

[Attach before/after screenshots or a short recording for any visual change.]

## Checklist

- [ ] Code follows `standards/coding.md` and `standards/naming.md`
- [ ] Error handling follows `standards/error-handling.md`
- [ ] No `console.log` in committed code
- [ ] Tests pass locally
- [ ] No new `any` types introduced
- [ ] Sensitive data is not logged or exposed in API responses
- [ ] Database migrations are backwards-compatible (if applicable)
- [ ] Documentation updated (if applicable)

## Migration notes (if applicable)

[Are there any manual steps required when deploying this? e.g.:]

- Run migration: `pnpm db:migrate`
- Set new environment variable: `NEW_VAR=value`
- Clear cache for: [what]
- Coordinate with: [other change or deploy]

## Related

[Links to related PRs, issues, ADRs, or external references]
```

---

## Examples of good vs bad PR titles

```text
✅ feat(orders): add void order endpoint with audit trail
✅ fix(printer): retry failed jobs after printer reconnects
✅ chore(deps): update better-sqlite3 to 9.4.0
✅ refactor(sync): extract upload logic into SyncService

❌ fix bug
❌ WIP
❌ changes
❌ Update files
```
