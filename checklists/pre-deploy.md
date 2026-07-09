# Pre-Deploy Checklist

Run this before every production deployment. The DevOps subagent runs this
automatically in the `/release` workflow. All items must pass or be explicitly waived.

---

## Code and tests

- [ ] All tests pass on the exact artifact being deployed (not a freshly rebuilt one)
- [ ] No open CRITICAL or HIGH findings from the last security review
- [ ] The `main` branch is the source — not a feature branch or local build

## Database migrations

- [ ] All pending migrations have been tested against a copy of the production schema
- [ ] Migrations are backwards-compatible (old app version can run against the new schema)
- [ ] If NOT backwards-compatible: deployment is coordinated (migrate + deploy atomically)
- [ ] Rollback migration exists or irreversibility is documented and accepted

## Environment and configuration

- [ ] All required environment variables are set in the production environment
- [ ] No secrets are hardcoded or in the artifact (verified by grep if needed)
- [ ] Configuration differences between staging and production are documented and intentional

## Staging verification

- [ ] The feature/fix was deployed to staging and verified
- [ ] Staging ran without critical errors for at least [N hours] before this deploy
- [ ] Any edge cases identified in staging have been resolved

## Rollback plan

- [ ] Previous working artifact version is identified
- [ ] Rollback procedure is documented (which artifact, which migration rollback, which config)
- [ ] Rollback can be executed without running migrations (or migration rollback is tested)
- [ ] Estimated rollback time is acceptable

## Monitoring and alerts

- [ ] Health check endpoint (`/health`) is configured in the load balancer/platform
- [ ] Uptime alert is configured
- [ ] Error rate alert is configured for the deployment target
- [ ] Log ingestion is working (spot-check by running a known operation on staging)

## Communication

- [ ] Any external dependencies (third parties, other services) are aware of the deploy if needed
- [ ] If this deploy requires downtime: stakeholders have been notified

## Post-deploy verification (run immediately after deploy)

- [ ] Health check returns `200` on production
- [ ] At least one critical user flow was manually tested on production
- [ ] Error logs show no unexpected spikes in the first 5 minutes
- [ ] Metrics/dashboards show normal baseline behavior

---

## Emergency deploy (bypassing some items)

In a true emergency (critical production outage), items may be bypassed.
Document every bypassed item and the reason. Conduct a post-mortem within 48 hours.
