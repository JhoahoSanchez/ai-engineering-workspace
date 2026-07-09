# Logging Standards

---

## Logger

Use a structured logger (e.g., `pino`) on the backend. Never use `console.log` in production paths.
The logger is instantiated once and imported where needed — no inline `console` calls.

```typescript
// lib/logger.ts
import pino from "pino";
export const logger = pino({ level: process.env.LOG_LEVEL ?? "info" });
```

---

## Log levels

| Level   | When to use                                                               |
| ------- | ------------------------------------------------------------------------- |
| `error` | Unexpected failure that requires attention. Ops needs to know.            |
| `warn`  | Something unexpected happened but the system recovered. Worth tracking.   |
| `info`  | Normal significant events: server started, sync completed, job processed. |
| `debug` | Detailed flow for troubleshooting. Off in production, on in dev.          |
| `trace` | Very granular, high-volume. Only for specific debugging sessions.         |

Default level in production: `info`. In development: `debug`.

---

## Structured logs (always include context)

Every log entry must include enough context to understand what happened without
reading surrounding code.

```typescript
// ✅
logger.info({ tenantId, orderId, itemCount }, "Order closed successfully");
logger.error({ tenantId, orderId, err }, "Failed to void order");

// ❌
logger.info("Order closed");
logger.error("Error: " + err.message);
```

**Always include**:

- `tenantId` — which tenant was affected
- Entity ID relevant to the operation (`orderId`, `deviceId`, `jobId`)
- For errors: the full `err` object (pino serializes it correctly)

**Never log**:

- Passwords, tokens, or secrets (even partial)
- Full credit card numbers or PAN
- Personally identifiable information beyond what's needed for debugging

---

## What to log

### Backend

- Request start/end for non-trivial operations (not health checks)
- All errors (error level)
- Sync batch upload: start, count, result
- Print job: queued, sent, result
- Database migration: start and completion

### Edge

- Connectivity state changes (online/offline)
- Sync attempt: start, count of events, result
- Print job: queued, attempt, success/failure
- Printer connection: connect, disconnect, error

### Do not log

- Every database query (too noisy — use `debug` only during development)
- Health check endpoints
- WebSocket heartbeat pings

---

## Log format in production

JSON, one object per line. No pretty-printing. This allows log aggregators
(CloudWatch Logs Insights, Datadog, etc.) to parse and query logs efficiently.

Development: pretty-print is fine for readability.
