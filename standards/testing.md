# Testing Standards

---

## What to test

### Must test

- Business logic in service functions (all branches, including error paths)
- Utility functions with non-trivial logic
- API endpoint contracts (correct status codes, response shape, validation errors)
- Sync and event handling logic
- Conflict resolution logic
- Print queue state transitions

### Should test

- Composables with non-trivial logic
- Pinia store actions that involve async operations or complex state transitions
- Database repository functions (with a real test SQLite DB, not mocks)

### Do not test

- Vue component rendering and DOM structure (unless it is a critical interactive flow)
- Framework internals (Vue's reactivity, Pinia's reactivity)
- Simple getters that just return a value
- Config files

---

## Test structure

Use the Arrange / Act / Assert pattern. Name tests with a clear behavioral description.

```typescript
// ✅
describe("OrderService.voidOrder", () => {
  it("marks the order as voided and emits a void event", async () => {
    // Arrange
    const order = await createTestOrder({ status: "open" });

    // Act
    await orderService.voidOrder(order.id, {
      reason: "Customer cancelled",
      operatorId: "op-1",
    });

    // Assert
    const updated = await orderRepository.findById(order.id);
    expect(updated.status).toBe("voided");
    expect(syncQueue.lastEvent().type).toBe("order.voided");
  });

  it("throws ConflictError if order is already closed", async () => {
    const order = await createTestOrder({ status: "closed" });
    await expect(
      orderService.voidOrder(order.id, { reason: "test", operatorId: "op-1" }),
    ).rejects.toThrow(ConflictError);
  });
});
```

---

## Test database

Backend tests use a real SQLite in-memory database (`:memory:`).
Never mock the database layer — test against real SQLite.
Never use the production database or a shared test database.

```typescript
// test setup
beforeEach(() => {
  db = createDb(":memory:");
  runMigrations(db);
});

afterEach(() => {
  db.close();
});
```

---

## Coverage expectations

| Layer                | Target                               |
| -------------------- | ------------------------------------ |
| Service functions    | 80%+ branch coverage                 |
| Repository functions | 70%+                                 |
| API endpoints        | All happy paths + common error paths |
| Composables (Vue)    | 60%+ for non-trivial ones            |

Coverage is a guide, not a goal. 80% coverage on the wrong tests is worse
than 50% coverage on the right tests.

---

## Tools

- **Test runner**: <!-- Vitest (recommended — works for both Node and Vue) -->
- **Assertions**: Vitest's built-in (`expect`)
- **HTTP testing**: Supertest (for Express endpoints)
- **Vue component testing**: Vue Test Utils + Vitest
- **Factories**: write simple factory functions for test data, no heavy fixtures

---

## Running tests

```bash
# All tests
pnpm test

# Watch mode
pnpm test:watch

# Coverage report
pnpm test:coverage
```

Tests must pass before any PR is merged. A failing test is a blocker, not a warning.
