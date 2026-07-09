# Synchronization

> For the offline-first design, see `architecture/offline-first.md`.
> This file covers the sync protocol between edge and cloud in detail.

---

## Sync directions

### Edge → Cloud (upload)

Events generated on the edge device are uploaded to the cloud in batches.
This is the primary sync direction — all user actions originate on the edge.

### Cloud → Edge (download)

Configuration updates (menu, prices, settings) are pushed from cloud to edge.
Delivered via WebSocket (see `architecture/websocket.md`) or pulled on reconnect.

---

## Upload protocol

```text
POST /sync/events
Authorization: Bearer <device-token>
Content-Type: application/json

{
  "deviceId": "uuid",
  "batchId": "uuid",          // unique per upload attempt
  "events": [DomainEvent]     // max 50 per batch
}

Response 200:
{
  "confirmed": ["event-id-1", "event-id-2"],
  "rejected": [{ "id": "event-id-3", "reason": "..." }]
}
```

After a successful response:

- Confirmed events: mark `synced_at = now()` in `sync_queue`.
- Rejected events: mark with error, do not retry without operator action.

---

## Download / catch-up protocol

On reconnect (or on demand), the edge requests missed updates:

```text
GET /sync/updates?since=<last_seq>&deviceId=<id>
Authorization: Bearer <device-token>

Response 200:
{
  "updates": [{ seq: number, type: string, payload: unknown }],
  "currentSeq": number
}
```

The edge applies updates in `seq` order and stores `currentSeq` locally.

---

## Retry and backoff

| Scenario                  | Behavior                                |
| ------------------------- | --------------------------------------- |
| Network unavailable       | Queue locally, retry when online        |
| Server 5xx                | Exponential backoff: 5s, 15s, 45s, 120s |
| Server 4xx (client error) | Do not retry, flag for manual review    |
| Timeout                   | Treat as network failure, retry         |

Maximum backoff cap: 5 minutes. After 10 consecutive failures: alert operator in UI.

---

## Ordering guarantees

Events within a device are uploaded in `created_at` order — strict FIFO per device.
The cloud applies events from different devices using `occurredAt` timestamps,
with conflict resolution per entity type (see `architecture/event-driven.md`).
