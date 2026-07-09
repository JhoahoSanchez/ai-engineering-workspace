# Git Standards

---

## Branch naming

```text
{type}/{short-description}

Types:
  feat/     → new feature
  fix/      → bug fix
  chore/    → maintenance, dependencies, config
  refactor/ → code change with no behavior change
  docs/     → documentation only
  test/     → test-only changes
  hotfix/   → urgent production fix

Examples:
  feat/offline-print-queue
  fix/sync-retry-backoff
  chore/update-dependencies
  hotfix/receipt-total-rounding
```

---

## Commit messages

Format: `{type}({scope}): {description}`

- **type**: same types as branches (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`)
- **scope**: affected module in parentheses — `(orders)`, `(printer)`, `(sync)`, `(auth)`
- **description**: imperative mood, lowercase, no period. Describe _what_ it does, not _how_.

```text
✅ feat(orders): add void order endpoint
✅ fix(printer): retry failed jobs after reconnect
✅ chore(deps): update better-sqlite3 to 9.4.0
✅ refactor(sync): extract upload logic into dedicated service

❌ Added void order
❌ Fixed bug
❌ WIP
❌ feat(orders): Added void order endpoint.
```

For breaking changes, add `!` after the type: `feat(api)!: change sync event envelope format`

---

## Workflow

```text
main          → always deployable, protected
  └── feat/X  → development branch
        └── (commits)
              → PR to main
              → code review (by you, or by QA subagent checklist)
              → squash merge to main
```

- Never commit directly to `main`.
- One feature/fix per branch. If you need to fix something unrelated, open a separate branch.
- Branches are short-lived: open PR within 1–2 days of starting, merge within the week.

---

## Commit discipline

- **Atomic commits**: each commit represents one logical change that could be reverted independently.
- **No "WIP" commits on main**: squash before merging.
- **No secrets or credentials** in commits — ever. Use environment variables.
- Run `git diff --staged` before committing. Review what you're actually committing.

---

## Tagging releases

```text
v{major}.{minor}.{patch}

v1.0.0    → first production release
v1.1.0    → new feature
v1.1.1    → bug fix
v2.0.0    → breaking change
```

Tag on main after a successful deployment. Annotated tags with a short changelog:

```bash
git tag -a v1.1.0 -m "feat: offline print queue, fix: sync retry backoff"
```
