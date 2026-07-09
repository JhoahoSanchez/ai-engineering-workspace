# SQLite Sync Patterns

SQLite is the local database on edge devices. This document covers patterns for
reliable local storage and sync queue management.

---

## SQLite setup (better-sqlite3)

Use `better-sqlite3` for synchronous, blocking SQLite access on Node.js.
Synchronous access simplifies transaction management and avoids callback hell.

```typescript
import Database from "better-sqlite3";

export function createDb(path: string): Database.Database {
  const db = new Database(path);

  // Performance settings — always apply these
  db.pragma("journal_mode = WAL"); // write-ahead logging: better concurrency
  db.pragma("foreign_keys = ON"); // enforce FK constraints
  db.pragma("synchronous = NORMAL"); // safe with WAL, faster than FULL
  db.pragma("cache_size = -32000"); // 32MB page cache
  db.pragma("temp_store = MEMORY"); // temp tables in RAM

  return db;
}
```

**WAL mode is mandatory**. Without it, readers block writers and performance degrades.

---

## Transaction pattern

Wrap all multi-step operations in explicit transactions.
`better-sqlite3` has a clean transaction helper:

```typescript
const writeOrderWithEvent = db.transaction((order: Order, event: SyncEvent) => {
  db.prepare(
    `
    INSERT INTO orders (id, tenant_id, status, total, ...) VALUES (?, ?, ?, ?, ...)
  `,
  ).run(order.id, order.tenantId, order.status, order.total);

  db.prepare(
    `
    INSERT INTO sync_queue (id, event_type, payload, created_at)
    VALUES (?, ?, ?, ?)
  `,
  ).run(event.id, event.type, JSON.stringify(event.payload), Date.now());
});

// Call it — either both writes succeed or neither does
writeOrderWithEvent(order, event);
```

Never write to the sync_queue and to the orders table in separate statements outside
a transaction. If one succeeds and the other fails, you have a consistency bug.

---

## Sync queue management

```sql
-- Events awaiting upload
SELECT * FROM sync_queue
WHERE synced_at IS NULL
ORDER BY created_at ASC
LIMIT 50;

-- Mark as synced after cloud confirms
UPDATE sync_queue
SET synced_at = ?, last_error = NULL
WHERE id IN (?, ?, ?);

-- Record failed attempt
UPDATE sync_queue
SET attempts = attempts + 1,
    last_error = ?
WHERE id = ?;

-- Cleanup old synced events (run periodically)
DELETE FROM sync_queue
WHERE synced_at IS NOT NULL
  AND synced_at < ?;  -- older than 7 days
```

---

## Schema migration

Migrations run on app startup, in order, using a version table:

```typescript
const MIGRATIONS = [
  {
    version: 1,
    sql: `
      CREATE TABLE IF NOT EXISTS schema_version (version INTEGER NOT NULL);
      INSERT INTO schema_version VALUES (0);

      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        ...
      );

      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempts INTEGER DEFAULT 0,
        last_error TEXT,
        synced_at INTEGER
      );

      CREATE INDEX idx_sync_queue_pending ON sync_queue(created_at)
        WHERE synced_at IS NULL;
    `,
  },
  // Add new migrations here — never modify existing ones
];

function runMigrations(db: Database.Database): void {
  const current =
    db.prepare("SELECT MAX(version) as v FROM schema_version").get()?.v ?? 0;
  for (const m of MIGRATIONS.filter((m) => m.version > current)) {
    db.exec(m.sql);
    db.prepare("UPDATE schema_version SET version = ?").run(m.version);
  }
}
```

**Never modify an existing migration.** Add a new one. Migrations are append-only.

---

## Useful indexes

```sql
-- Most-queried patterns
CREATE INDEX idx_orders_tenant_status ON orders(tenant_id, status);
CREATE INDEX idx_orders_table ON orders(table_id) WHERE status IN ('open', 'pending-payment');
CREATE INDEX idx_sync_queue_pending ON sync_queue(created_at) WHERE synced_at IS NULL;
CREATE INDEX idx_print_queue_pending ON print_queue(created_at) WHERE status = 'pending';
```

Run `EXPLAIN QUERY PLAN` on slow queries to verify index usage.

---

## Avoiding common SQLite pitfalls

- **Do not share a `Database` instance across threads** (workers). Each worker creates its own.
- **WAL checkpoint**: SQLite auto-checkpoints at 1000 pages. For long-running processes,
  this may cause occasional pauses. Monitor with `PRAGMA wal_checkpoint(PASSIVE)`.
- **Integer timestamps in ms**: store Unix timestamps as INTEGER (ms), not ISO strings.
  Strings are harder to compare and range-query.
- **JSON in TEXT columns**: fine for event payloads where you don't query into the JSON.
  If you need to query JSON fields, use SQLite's `json_extract()` or promote to a column.
