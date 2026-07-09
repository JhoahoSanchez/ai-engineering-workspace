# Error Handling

Errors are handled consistently at every layer. No silent failures.

---

## Error classes

Define a base application error class. All domain errors extend it.

```typescript
// errors/AppError.ts
export class AppError extends Error {
  constructor(
    public readonly code: string, // machine-readable, e.g. 'ORDER_NOT_FOUND'
    public readonly message: string, // human-readable
    public readonly statusCode: number = 500,
    public readonly context?: Record<string, unknown>,
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

// Domain-specific errors
export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super("NOT_FOUND", `${resource} with id '${id}' not found`, 404, {
      resource,
      id,
    });
  }
}

export class ValidationError extends AppError {
  constructor(message: string, context?: Record<string, unknown>) {
    super("VALIDATION_ERROR", message, 400, context);
  }
}

export class ConflictError extends AppError {
  constructor(message: string, context?: Record<string, unknown>) {
    super("CONFLICT", message, 409, context);
  }
}
```

---

## Backend: API layer

All routes are wrapped in a central error handler. Individual route handlers do not
construct HTTP error responses — they throw `AppError` subclasses and let the middleware handle it.

```typescript
// Middleware (Express example)
app.use((err: unknown, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        ...(isDev ? { context: err.context } : {}),
      },
    });
  }

  logger.error("Unhandled error", { err, path: req.path });
  return res.status(500).json({
    error: { code: "INTERNAL_ERROR", message: "An unexpected error occurred" },
  });
});
```

Never expose stack traces or internal context to the client in production.

---

## Backend: service and repository layer

```typescript
// ✅ throw typed errors
async function getOrder(id: string, tenantId: string): Promise<Order> {
  const order = await orderRepository.findById(id, tenantId);
  if (!order) throw new NotFoundError("Order", id);
  return order;
}

// ❌ return null and let callers guess
async function getOrder(id: string): Promise<Order | null> {
  return orderRepository.findById(id);
}
```

Use typed errors. Callers can `catch` specific error types and respond appropriately.
Do not return `null` for "not found" — throw `NotFoundError`.

---

## Frontend: API calls

```typescript
// composables/useOrders.ts
const error = ref<string | null>(null);

async function fetchOrder(id: string) {
  error.value = null;
  try {
    order.value = await orderService.getById(id);
  } catch (e) {
    if (e instanceof ApiError && e.statusCode === 404) {
      error.value = "Order not found";
    } else {
      error.value = "Failed to load order. Please try again.";
    }
    logger.warn("fetchOrder failed", { orderId: id, error: e });
  }
}
```

Rules:

- Always reset error state before a new attempt.
- User-facing messages are human-readable, never raw API error strings.
- Log the actual error for debugging; show a simplified message to the user.
- Never let an unhandled promise rejection bubble silently.

---

## Edge device: sync and print errors

Sync errors and print errors are not thrown to the top level — they are stored
as state in the local database (`sync_queue.last_error`, `print_queue.status`).
The UI reads this state and shows appropriate indicators.

Exceptions (pun intended): unrecoverable errors (corrupt DB, out of disk space)
should terminate the process with a clear log message so the OS can restart it.

---

## Rules summary

1. **Never** `catch (e) {}` (empty catch). At minimum, log the error.
2. **Never** expose stack traces or internal error details to the end user.
3. **Always** use typed `AppError` subclasses, not raw `new Error('something failed')`.
4. **Always** handle loading, error, and empty states in UI components.
5. **Always** log errors with enough context to reproduce them (entity IDs, operation, tenant).
