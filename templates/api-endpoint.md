# REST API Endpoint Template

Use this template when adding a new endpoint. Adapt the syntax to the framework
in `context.md` (Express, Fastify, Hono, etc.). The pattern is the same.

---

## Pattern

Every route handler follows: **validate → authorize → call service → respond**.
No business logic inside the handler. No database access inside the handler.

```typescript
// [domain].routes.ts
//
// Endpoints:
//   GET    /[domain]s              list
//   POST   /[domain]s              create
//   GET    /[domain]s/:id          get one
//   PATCH  /[domain]s/:id          update
//   DELETE /[domain]s/:id          delete
//   POST   /[domain]s/:id/[action] non-CRUD action

import { Router } from 'express'  // replace with framework from context.md
import { z } from 'zod'
import { [Domain]Service } from './[domain].service'
import { validateBody, validateParams } from '../middleware/validate'
import { requireAuth } from '../middleware/auth'

const router = Router()
const service = new [Domain]Service(/* inject deps */)

// --- Schemas (validate at the edge, before any logic) ---

const CreateSchema = z.object({
  // [field]: z.[type](),
})

const UpdateSchema = z.object({
  // [field]: z.[type]().optional(),
}).strict()

const IdParamSchema = z.object({
  id: z.string().uuid(),
})

// --- Endpoints ---

// GET /[domain]s
router.get('/', requireAuth, async (req, res) => {
  const items = await service.list(req.tenantId)
  res.json({ data: items })
})

// POST /[domain]s
router.post('/', requireAuth, validateBody(CreateSchema), async (req, res) => {
  const item = await service.create(req.body, req.tenantId)
  res.status(201).json({ data: item })
})

// GET /[domain]s/:id
router.get('/:id', requireAuth, validateParams(IdParamSchema), async (req, res) => {
  const item = await service.getById(req.params.id, req.tenantId)
  res.json({ data: item })
})

// PATCH /[domain]s/:id
router.patch('/:id', requireAuth, validateParams(IdParamSchema), validateBody(UpdateSchema), async (req, res) => {
  const item = await service.update(req.params.id, req.body, req.tenantId)
  res.json({ data: item })
})

// DELETE /[domain]s/:id
router.delete('/:id', requireAuth, validateParams(IdParamSchema), async (req, res) => {
  await service.delete(req.params.id, req.tenantId)
  res.status(204).send()
})

export { router as [domain]Router }
```

---

## Response shape convention

Always wrap responses in a `data` key. Errors follow `standards/error-handling.md`.

```typescript
// Success (single entity)
{ "data": { "id": "...", ... } }

// Success (list)
{ "data": [ ... ] }

// Success with pagination
{ "data": [ ... ], "meta": { "total": 100, "page": 1, "pageSize": 20 } }

// Error (handled by central error middleware)
{ "error": { "code": "NOT_FOUND", "message": "Order with id '...' not found" } }
```

---

## Endpoint documentation (fill this in for each new endpoint)

```markdown
### [METHOD] /api/v1/[domain]s[/path]

[One sentence description]

**Auth**: [required role]

**Request**
[Body or params description]

**Responses**
| Status | Meaning |
|---|---|
| 200/201/204 | Success |
| 400 | Validation error |
| 401 | Not authenticated |
| 403 | Not authorized |
| 404 | Not found |
| 409 | Conflict |
```

---

## Checklist before shipping a new endpoint

- [ ] Input validated with a schema before any logic runs
- [ ] Auth middleware applied
- [ ] `tenantId` passed to every service call
- [ ] Response shape follows the project convention
- [ ] HTTP status code is semantically correct
- [ ] Error handling is via `throw AppError` subclass, not manual `res.status(500)`
- [ ] Endpoint is documented
- [ ] At least one integration test covers the happy path and one error case
