# Documentation Standards

---

## What needs documentation

### Always document

- Public API endpoints (path, method, auth, request/response shape, error codes)
- Non-obvious business rules or domain decisions (link to `memory.md` if applicable)
- Environment variables (in `.env.example` with description for each)
- Setup steps (in `README.md` of each package)
- Database schema decisions that are not self-explanatory

### Document with inline comments

- Complex algorithms or non-obvious logic
- Workarounds for library bugs (with issue link)
- Performance-critical sections and why they are optimized that way

### Do NOT document

- What the code obviously does (`// increment counter` above `count++`)
- Temporary code — remove it instead of commenting it out
- The same thing twice — pick one authoritative place

---

## README structure

Every package/service has a `README.md` with:

```markdown
# [Package Name]

[One-sentence description]

## Requirements

[Node version, dependencies, environment]

## Setup

[Step-by-step to run locally]

## Environment variables

[Table: variable | required | default | description]

## Scripts

[pnpm dev, pnpm build, pnpm test, etc.]

## Architecture

[Link to relevant files in architecture/ if applicable]
```

---

## API documentation

Document every endpoint in a consistent format:

````markdown
### POST /api/v1/orders/:orderId/void

Voids an open order. Cannot void a closed or already-voided order.

**Auth**: Bearer token (operator role required)

**Path params**

- `orderId` (string, UUID) — the order to void

**Request body**

```json
{
  "reason": "Customer cancelled", // required, string
  "operatorId": "uuid" // required, string UUID
}
```
````

**Responses**

- `200` — order voided successfully `{ orderId, status: "voided", voidedAt }`
- `400` — validation error `{ error: { code: "VALIDATION_ERROR", message } }`
- `404` — order not found
- `409` — order is not in a voidable state

````

---

## Code comments

```typescript
// ✅ Explains WHY, not WHAT
// We use created_at ordering here instead of sequence to avoid gaps
// when events arrive out of order from multiple devices.
const pending = db.prepare(`
  SELECT * FROM sync_queue
  WHERE synced_at IS NULL
  ORDER BY created_at ASC
  LIMIT 50
`).all()

// ❌ Explains what the code already says
// Get all unsynced events ordered by creation time, limit 50
const pending = db.prepare(...).all()
````
