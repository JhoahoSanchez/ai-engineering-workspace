# Event-Driven Architecture

## Why events

Operations on the edge device are modeled as immutable events, not state mutations.
This enables: offline queuing, audit trail, replay, and conflict resolution.
The current state of an order is derived from its event history.

---

## Event structure

All events share a common envelope:

```typescript
interface DomainEvent {
  id: string; // UUID v4
  type: string; // namespaced: 'domain.entity.action'
  tenantId: string;
  deviceId: string;
  occurredAt: number; // Unix ms — when the action happened on the device
  syncedAt?: number; // Unix ms — when cloud confirmed receipt (null if pending)
  payload: unknown; // event-specific data
  version: number; // schema version, starts at 1
}
```

---

## Event naming convention

Format: `{domain}.{entity}.{past-tense-verb}`

```text
order.created
order.item.added
order.item.removed
order.item.modified
order.voided
order.paid
order.closed
printer.job.queued
printer.job.printed
printer.job.failed
sync.batch.uploaded
sync.batch.confirmed
```

---

## Event catalog (core domain)

### `order.created`

```typescript
{ tableId: string | null, operatorId: string, type: 'dine-in' | 'takeout' | 'delivery' }
```

### `order.item.added`

```typescript
{ orderId: string, itemId: string, quantity: number, unitPrice: number, modifiers: string[] }
```

### `order.paid`

```typescript
{ orderId: string, method: 'cash' | 'card' | 'other', amount: number, tip: number }
```

### `order.voided`

```typescript
{ orderId: string, reason: string, operatorId: string }
```

---

## Event flow

```text
User action
    ↓
Validate locally (business rules)
    ↓
Write event to sync_queue (SQLite transaction)
Apply state change to local tables (same transaction)
    ↓
Trigger UI update (reactive store)
    ↓
Background: upload event batch to cloud
    ↓
Cloud: validate, apply, confirm
```

Events are written and state is applied in the same SQLite transaction.
Either both succeed or neither does — there is no partial state.

---

## Idempotency

Cloud endpoints that receive events must be idempotent.
Use the event `id` as an idempotency key.
Receiving the same event twice (due to retry) must produce the same result.

```text
POST /sync/events
Body: { events: DomainEvent[] }
Response: { confirmed: string[], rejected: { id: string, reason: string }[] }
```

---

## Versioning

When an event's payload structure changes:

1. Increment `version` on the new schema.
2. Cloud must handle both the old and new version during the transition period.
3. Document the migration in `memory.md`.
4. Never change a field's meaning — add new fields, deprecate old ones.
