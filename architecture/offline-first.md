# Offline-First Architecture

## Core principle

The edge device (POS terminal) must operate fully without network connectivity.
Cloud availability is a bonus, not a requirement for core operations.
Sync to the cloud happens opportunistically when connectivity is restored.

---

## Data flow

```text
[User action on edge]
      ↓
[Write to local SQLite immediately]  ← operation completes here, no waiting
      ↓
[Add to outbound sync queue]
      ↓
[Background sync worker]  ← runs on connectivity, retries on failure
      ↓
[Cloud backend]  ← receives events, applies to cloud DB
      ↓
[Inbound sync]  ← cloud pushes updates back to edge (price changes, menu updates)
```

---

## SQLite as primary store

The local SQLite database is the source of truth for the edge device.
It contains a complete working copy of all data the device needs to operate:

- Menu items and prices (synced from cloud)
- Open orders and their status
- Print queue (tickets pending print)
- Sync queue (events pending upload)

The device does not make API calls to read data during normal operation.
It only reads from local SQLite.

---

## Sync queue design

Every write operation on the edge device produces an event in the `sync_queue` table:

```sql
CREATE TABLE sync_queue (
  id          TEXT PRIMARY KEY,      -- UUID
  event_type  TEXT NOT NULL,         -- e.g. 'order.created', 'order.item.added'
  payload     TEXT NOT NULL,         -- JSON blob
  created_at  INTEGER NOT NULL,      -- Unix timestamp (ms)
  attempts    INTEGER DEFAULT 0,
  last_error  TEXT,
  synced_at   INTEGER                -- NULL until confirmed by cloud
);
```

The sync worker:

1. Queries `WHERE synced_at IS NULL ORDER BY created_at ASC`
2. POSTs events to the cloud in batches (max 50 per batch)
3. On success: marks `synced_at = now()`
4. On failure: increments `attempts`, stores `last_error`, backs off exponentially
5. After 10 failed attempts: flags for manual review, does not delete

---

## Conflict resolution strategy

When the cloud receives an event from the edge, it may conflict with a cloud-side change.
Resolution rules (decided once, applied consistently — see `memory.md`):

- **Orders**: edge wins. An order created offline is always valid.
- **Menu prices**: cloud wins. Price changes from the back office override local cache.
- **Inventory**: last-write-wins with timestamp comparison.
- **Structural conflicts** (e.g., deleted item referenced in an order): log conflict,
  preserve the order, flag for operator review — never silently discard an order.

---

## Connectivity detection

Do not rely on `navigator.onLine` or OS-level signals alone — they are unreliable.
Use a heartbeat: a lightweight ping to the cloud every 30 seconds.
Store connectivity state in a local in-memory flag updated by the heartbeat result.
The UI uses this flag to show connectivity status to the operator.

---

## What NOT to do

- Do not block user actions on network responses. User writes to SQLite, done.
- Do not use optimistic UI that rolls back on failure — the local write is the truth.
- Do not retry failed syncs indefinitely with no backoff — use exponential backoff with a cap.
- Do not sync the entire table on reconnect — sync only the queue of unsynced events.
