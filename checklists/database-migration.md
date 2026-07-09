# Database Migration Checklist

Run this before any migration is merged and before it is applied to production.
Migrations are the highest-risk type of change — they are often irreversible.

---

## Before writing the migration

- [ ] The schema change is driven by a clear application need (not speculative)
- [ ] The change has been reviewed against `architecture/` for consistency with the data model
- [ ] The migration approach is the least destructive option (add vs modify vs delete)

## Migration correctness

- [ ] Migration runs successfully on a clean database from scratch
- [ ] Migration runs successfully on a database with realistic existing data
- [ ] Migration is idempotent where possible (safe to run twice)
- [ ] Naming follows `standards/naming.md` (table names, column names, index names)
- [ ] All new NOT NULL columns have a default value (or the migration backfills data before adding constraint)
- [ ] Foreign key constraints are correctly defined
- [ ] Indexes are created for new FK columns and common query patterns

## Backwards compatibility

- [ ] The new schema can be read by the **current production application** without errors
      (so the app can stay running while the migration runs)
- [ ] If NOT backwards compatible: document the coordinated deploy procedure
- [ ] Old application code will not break on the new schema until the app is updated

## Rollback

- [ ] A rollback migration is written and tested
- [ ] Rollback has been tested by: running the migration → rollback → migration again
- [ ] If rollback is irreversible (data loss): this is explicitly documented and accepted

## Performance

- [ ] Large table migrations (> 100k rows) are done with a non-locking strategy
      (add column with default, backfill in batches, then add constraint)
- [ ] Index creation on large tables uses `CREATE INDEX CONCURRENTLY` (or equivalent)
      to avoid locking
- [ ] Migration run time is estimated and acceptable for the maintenance window

## Data integrity

- [ ] No data is silently deleted by this migration (or deletion is intentional and documented)
- [ ] Data type changes do not cause silent truncation or precision loss
- [ ] All existing data satisfies new constraints after the migration runs

## Post-migration verification

- [ ] After running on staging: query the affected tables and verify data looks correct
- [ ] After running on production: spot-check affected data
- [ ] Application smoke test passes against the new schema
