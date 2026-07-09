# Coding Standards

Stack: TypeScript, Node.js (backend), Vue 3 (frontend).
These rules apply to all code in this project. No exceptions without a note in `memory.md`.

---

## TypeScript

- **Strict mode on**. `tsconfig.json` must have `"strict": true`.
- **No `any`**. If the type is genuinely unknown, use `unknown` and narrow it with a type guard.
- **No non-null assertions** (`!`) unless you can prove the value cannot be null at that point.
  Prefer explicit null checks.
- **Explicit return types** on all exported functions and class methods.
- **Type imports**: use `import type { Foo }` when importing only a type.

```typescript
// ✅
export function calculateTotal(items: OrderItem[]): number {
  return items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
}

// ❌
export function calculateTotal(items: any) {
  return items.reduce(
    (sum: any, item: any) => sum + item.unitPrice * item.quantity,
    0,
  );
}
```

---

## Functions and modules

- **One responsibility per function**. If you need "and" to describe what a function does, split it.
- **Pure functions where possible**. Side effects are explicit, not hidden.
- **Max function length: ~40 lines**. If it's longer, it's doing too much.
- **No magic numbers**. Extract constants with meaningful names.
- **Early returns** over deeply nested if/else.

```typescript
// ✅ early return
function applyDiscount(order: Order, code: string): number {
  if (!code) return order.total;
  const discount = findDiscount(code);
  if (!discount) return order.total;
  return order.total * (1 - discount.rate);
}

// ❌ nested
function applyDiscount(order: Order, code: string): number {
  if (code) {
    const discount = findDiscount(code);
    if (discount) {
      return order.total * (1 - discount.rate);
    } else {
      return order.total;
    }
  } else {
    return order.total;
  }
}
```

---

## Backend-specific (Node.js)

- **No callback-style async**. Use async/await everywhere.
- **Service layer**: business logic lives in `services/`, not in route handlers.
- **Repository/DAO layer**: database access lives in `repositories/` or `db/`, not in services.
- **Route handlers are thin**: parse → validate → call service → return response.
- **Environment variables** are accessed only through a typed config module, not `process.env` inline.

```typescript
// ✅ typed config
// config.ts
export const config = {
  port: parseInt(process.env.PORT ?? "3000", 10),
  dbPath: process.env.DB_PATH ?? "./data/app.db",
};

// anywhere else
import { config } from "./config";
```

---

## Frontend-specific (Vue 3)

- **Composition API only** (`<script setup>`). No Options API in new code.
- **Data fetching in composables**, not in components.
- **Pinia actions for async**, not mutations or getters.
- **No direct store state mutation from components** — use actions.
- **v-model on components**: define with `defineModel()` (Vue 3.4+) or explicit prop + emit pair.

---

## General

- **No `console.log` in committed code**. Use the project logger (see `standards/logging.md`).
- **No commented-out code**. Delete it; git history exists.
- **No TODOs without a ticket/issue reference**. `// TODO(#123): fix this` is OK. `// TODO: fix this` is not.
- **Imports ordered**: external packages first, then internal modules, then relative imports.
  Use a linter rule to enforce this automatically.
