# WebSocket Architecture

## Role of WebSockets in this system

WebSockets are used for **cloud-to-edge push only**: the cloud pushes configuration
updates (menu changes, price changes, feature flags) to connected edge devices in real time.

WebSockets are NOT used for edge-to-cloud data upload — that goes through the sync REST API.
WebSockets are NOT the primary data path — the edge works without them.

---

## Connection model

Each edge device opens one persistent WebSocket connection to the cloud on startup.
The connection is identified by `deviceId` and authenticated via the device token.

```text
wss://api.example.com/device/ws?token=<device-token>
```

On reconnect, the device sends its last received sequence number so the cloud
can replay any missed messages.

---

## Message format

```typescript
interface WSMessage {
  seq: number; // monotonic sequence number, per-tenant
  type: string; // message type
  payload: unknown;
}
```

---

## Message types (cloud → edge)

| Type             | Trigger                        | Edge action                                        |
| ---------------- | ------------------------------ | -------------------------------------------------- |
| `menu.updated`   | Back-office menu change        | Re-fetch menu from local sync, update SQLite cache |
| `price.updated`  | Price change                   | Update local price table                           |
| `config.updated` | Feature flag or setting change | Reload config from cloud                           |
| `device.ping`    | Heartbeat from cloud           | Respond with `device.pong`                         |
| `force.sync`     | Manual sync trigger            | Flush sync queue immediately                       |

---

## Reconnection strategy

- On disconnect: wait 1s, then reconnect.
- On repeated failures: exponential backoff (2s, 4s, 8s... up to 60s).
- While disconnected: edge continues operating normally (offline-first).
- On reconnect: send `last_seq` so cloud can replay missed messages.

```typescript
// Reconnect loop pseudocode
async function connectWithBackoff(attempt: number) {
  const delay = Math.min(1000 * 2 ** attempt, 60_000);
  await sleep(delay);
  return connect();
}
```

---

## Edge-side handling

The WebSocket listener on the edge device:

1. Receives a message.
2. Validates the `seq` (reject if out of order, request replay if gap detected).
3. Dispatches to the appropriate local handler based on `type`.
4. Stores the new `last_seq` in SQLite for reconnect continuity.

Handlers must not block the WebSocket listener — queue heavy operations.
