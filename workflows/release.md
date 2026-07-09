---
description: >
  Prepares and executes a release: version bump, changelog, tagging, and deployment
  coordination. Run after all features for a release are merged to main.
---

# /release

Use this workflow to cut a release. Never release directly from a feature branch.
Release from `main` only, after all changes have been reviewed and merged.

---

## Step 1 — Verify release readiness

Before doing anything:

- Confirm all planned features for this release are merged to `main`.
- Confirm there are no failing tests on `main`.
- Confirm staging has been running the release candidate without issues.
- Confirm no open CRITICAL or HIGH security findings.

If any of the above is not true, stop and report to the user.

---

## Step 2 — Determine the version number

Use semantic versioning: `MAJOR.MINOR.PATCH`

| What changed                                       | Bump  |
| -------------------------------------------------- | ----- |
| Breaking change (API, data model, removed feature) | MAJOR |
| New feature, backwards-compatible                  | MINOR |
| Bug fix only                                       | PATCH |

Read `CHANGELOG.md` and the commits since the last tag to determine the correct bump.

```bash
# Last release tag
git describe --tags --abbrev=0

# Commits since last release
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

---

## Step 3 — Update CHANGELOG.md

Move all entries under `[Unreleased]` to a new version section:

```markdown
## [1.2.0] - YYYY-MM-DD

### Added

- [list of new features]

### Fixed

- [list of fixes]

### Changed / Deprecated / Removed / Security

- [as applicable]
```

Leave the `[Unreleased]` section empty for the next cycle.

---

## Step 4 — Run the pre-deploy checklist

Run `checklists/pre-deploy.md` explicitly. All items must pass before tagging.

---

## Step 5 — Tag the release

```bash
git tag -a v{VERSION} -m "Release v{VERSION}

{2–5 line summary of what changed}"

git push origin v{VERSION}
```

---

## Step 6 — Deploy to production

Invoke **devops** subagent with:

- The version being deployed
- The deployment target
- Any migration or config changes required

The devops subagent coordinates the actual deployment.
Do not mark the release as complete until production deployment is confirmed healthy.

---

## Step 7 — Post-release

- Confirm the health check endpoint returns 200 on production.
- Check error logs for the first 10 minutes after deployment.
- Update `context.md` with the new version and any change in active development areas.
- Report to the user: version released, what's in it, and production health status.

---

## Rollback procedure

If production shows critical errors after deployment:

1. Invoke **devops** subagent to redeploy the previous version tag.
2. If a database migration was run: assess whether it is backwards-compatible with the old code.
   If not, the rollback is more complex — escalate to the user immediately.
3. Open a bug report with the failure details before doing anything else.
