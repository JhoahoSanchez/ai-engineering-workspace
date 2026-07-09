# Security Standards

---

## Input validation

All external input is validated before use. "External" means: HTTP request bodies,
query params, headers, WebSocket messages, sync event payloads, file contents.

Use Zod on both frontend and backend for runtime validation:

```typescript
const CreateOrderSchema = z.object({
  tableId: z.string().uuid().nullable(),
  type: z.enum(["dine-in", "takeout", "delivery"]),
});

// In route handler — validate before touching business logic
const input = CreateOrderSchema.safeParse(req.body);
if (!input.success)
  throw new ValidationError("Invalid input", input.error.flatten());
```

---

## Authentication and authorization

- All API endpoints require authentication unless explicitly public (e.g., health check).
- Use short-lived JWT access tokens + refresh tokens. Never long-lived tokens.
- Device tokens for edge devices are long-lived but scoped and revocable.
- Authorization check happens in the service layer, not just the route:
  verify that the authenticated tenant/user has access to the requested resource.

```typescript
// ✅ explicit authorization in service
async function getOrder(id: string, tenantId: string): Promise<Order> {
  const order = await orderRepository.findById(id);
  if (!order) throw new NotFoundError("Order", id);
  if (order.tenantId !== tenantId) throw new ForbiddenError(); // not just 404
  return order;
}
```

---

## Secrets management

- Secrets live in environment variables, never hardcoded or in source control.
- `.env` files are in `.gitignore`. Provide `.env.example` with placeholder values.
- In production, use AWS Secrets Manager or SSM Parameter Store.
- Rotate secrets if accidentally committed. Assume it is compromised immediately.

---

## SQL injection prevention

- Use parameterized queries or a query builder. Never string-concatenate SQL.
- The ORM/query builder (see `context.md`) handles this automatically — do not bypass it.

```typescript
// ✅
db.prepare("SELECT * FROM orders WHERE id = ? AND tenant_id = ?").get(
  id,
  tenantId,
);

// ❌ Never do this
db.exec(`SELECT * FROM orders WHERE id = '${id}'`);
```

---

## Sensitive data

- Never log passwords, tokens, full payment data (see `standards/logging.md`).
- Do not return sensitive fields from API responses unless explicitly needed.
  (e.g., password hashes should never appear in any response object)
- Store passwords with bcrypt (cost factor ≥ 12). Never MD5, SHA1, or plain text.

---

## HTTPS

- All network communication is HTTPS/WSS. No plain HTTP in production.
- Set security headers: `Content-Security-Policy`, `X-Content-Type-Options`,
  `X-Frame-Options`, `Strict-Transport-Security`.

---

## Dependency security

- Run `pnpm audit` before each release. Fix high/critical findings.
- Keep dependencies up to date — stale deps are a security risk.
- Do not install packages from untrusted sources or with very few downloads.
