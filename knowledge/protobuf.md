# Protobuf Reference

> Protocol Buffers — binary serialization format for structured data.
> Use when JSON payload size is a concern (high event volume, low bandwidth edge devices).

---

## When to use Protobuf vs JSON

| Factor           | JSON                 | Protobuf                           |
| ---------------- | -------------------- | ---------------------------------- |
| Readability      | Human-readable       | Binary, needs tooling              |
| Payload size     | 1× baseline          | ~3–10× smaller                     |
| Parse speed      | Moderate             | Faster                             |
| Schema evolution | Flexible but untyped | Strict but safe with field numbers |
| Tooling          | Universal            | Requires proto compiler            |

**Decision for this project**: default to JSON for all endpoints. Consider Protobuf
only if sync batch sizes exceed 50KB per upload or bandwidth becomes a real cost driver.
Document the switch in `memory.md` if made.

---

## Proto file example

```protobuf
syntax = "proto3";
package pos;

message SyncEvent {
  string id = 1;
  string type = 2;
  string tenant_id = 3;
  string device_id = 4;
  int64 occurred_at = 5;   // Unix ms
  bytes payload = 6;       // JSON-encoded event payload
  int32 version = 7;
}

message SyncBatch {
  string batch_id = 1;
  string device_id = 2;
  repeated SyncEvent events = 3;
}

message SyncResponse {
  repeated string confirmed = 1;
  repeated RejectedEvent rejected = 2;
}

message RejectedEvent {
  string id = 1;
  string reason = 2;
}
```

---

## Node.js setup (protobufjs)

```typescript
import protobuf from 'protobufjs'

const root = await protobuf.load('proto/sync.proto')
const SyncBatch = root.lookupType('pos.SyncBatch')

// Encode
const message = SyncBatch.create({ batchId: '...', events: [...] })
const buffer = SyncBatch.encode(message).finish()

// Decode
const decoded = SyncBatch.decode(buffer)
const obj = SyncBatch.toObject(decoded)
```

---

## Schema evolution rules

- **Never change a field number** — it is the wire identity of that field.
- **Never change a field type** (int32 → int64 is a breaking change).
- **Add new fields** with new field numbers — old clients ignore unknown fields.
- **Deprecate fields** by marking them `reserved` — do not reuse the field number.

```protobuf
message Order {
  string id = 1;
  // reserved 2;  // was: string legacy_id (deprecated 2024-01)
  string tenant_id = 3;
  int64 created_at = 4;
}
```
