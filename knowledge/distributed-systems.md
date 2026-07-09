# Distributed Systems Patterns

Relevant patterns for a cloud-edge system with offline-first edge devices.

---

## CAP theorem in this system

This system prioritizes **Availability + Partition Tolerance** over Consistency.

- Edge devices must operate during network partition (offline).
- Consistency is achieved eventually, via the sync protocol.
- This is a deliberate trade-off — see `memory.md` for the recorded decision.

**Consequence**: brief inconsistencies between edge and cloud are expected and acceptable.
For example, two devices may briefly show different stock counts. Design the UI
to reflect this — show "last synced at" rather than pretending data is live.

---

## Eventual consistency

The system converges to a consistent state once all events are synced.
Key design rule: **every operation must be expressible as an idempotent event**.

If replaying the same event twice produces the same final state, the system is safe
to retry. If it does not, you have a bug.

```typescript
// ✅ Idempotent: applying this event twice is safe
{ type: 'order.status.set', payload: { orderId, status: 'closed', closedAt } }

// ❌ Not idempotent: applying twice doubles the discount
{ type: 'order.discount.applied', payload: { orderId, discountAmount: 10 } }
```

Model state as "set to X" (idempotent), not "add X to current value" (not idempotent).

---

## Clock skew

Edge device clocks can be wrong (no NTP, drifted clock, user-set time).
Design to tolerate ±5 minutes of clock skew.

- Use `occurredAt` from the device clock only for ordering events within one device.
- Do not rely on `occurredAt` for ordering events across devices — use the cloud receipt timestamp.
- For display purposes, show the device's recorded time (that's what the operator expects).
- For conflict resolution, the cloud applies events in the order received, with
  `occurredAt` as a tiebreaker within the same entity.

---

## Idempotency keys

Every operation that mutates state must carry a UUID. The server uses this UUID
as an idempotency key: if the same UUID is received twice, the second is a no-op.

```typescript
// Client generates UUID before sending
const operationId = crypto.randomUUID();

// Server checks before processing
const existing = db
  .prepare("SELECT id FROM processed_events WHERE id = ?")
  .get(operationId);

if (existing) return { status: "already_processed" };

// Process and mark as done in the same transaction
db.transaction(() => {
  processEvent(event);
  db.prepare(
    "INSERT INTO processed_events (id, processed_at) VALUES (?, ?)",
  ).run(operationId, Date.now());
})();
```

---

## Retry budget

Not all failures are worth retrying. Classify before retrying:

| Error type               | Retry?                  | Why                             |
| ------------------------ | ----------------------- | ------------------------------- |
| Network timeout          | Yes                     | Transient                       |
| Server 5xx               | Yes (with backoff)      | Transient server error          |
| Server 429 (rate limit)  | Yes (after Retry-After) | Instructed to retry             |
| Server 400 (bad request) | No                      | Client bug, retrying won't help |
| Server 409 (conflict)    | No                      | Requires human resolution       |
| Server 404               | No                      | Resource doesn't exist          |

---

## Split-brain scenarios

A "split-brain" occurs when two devices make conflicting changes to the same entity offline.
Example: two cashiers void the same order on different devices while offline.

Resolution strategy (by entity — also documented in `architecture/offline-first.md`):

- **Orders**: the first event to reach the cloud wins. The second is rejected with a 409.
  The device receives the rejection and shows the operator the current server state.
- **Menu prices**: cloud always wins. Edge cache is overwritten on sync.
- **Never**: silently discard either event without notifying the operator.
