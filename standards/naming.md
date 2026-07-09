# Naming Conventions

Consistent naming reduces cognitive load. These rules are not negotiable.

---

## TypeScript / JavaScript

| Construct                | Convention                                 | Example                                    |
| ------------------------ | ------------------------------------------ | ------------------------------------------ |
| Variables                | camelCase                                  | `orderTotal`, `isLoading`                  |
| Functions                | camelCase, verb-first                      | `calculateTotal()`, `fetchOrders()`        |
| Constants (module-level) | SCREAMING_SNAKE_CASE                       | `MAX_RETRY_ATTEMPTS`, `DEFAULT_TIMEOUT_MS` |
| Classes                  | PascalCase                                 | `OrderService`, `PrintQueue`               |
| Interfaces               | PascalCase, no `I` prefix                  | `Order`, `PrintJob`, `SyncEvent`           |
| Type aliases             | PascalCase                                 | `OrderStatus`, `EventPayload`              |
| Enums                    | PascalCase for enum, PascalCase for values | `OrderStatus.Pending`                      |
| Boolean variables        | `is`, `has`, `can`, `should` prefix        | `isLoading`, `hasError`, `canPrint`        |

---

## Files and folders

| Content               | Convention                        | Example                                |
| --------------------- | --------------------------------- | -------------------------------------- |
| Vue components        | PascalCase                        | `OrderCard.vue`, `PrinterStatus.vue`   |
| Composables           | camelCase, `use` prefix           | `useOrders.ts`, `usePrinter.ts`        |
| Pinia stores          | camelCase, `use` + `Store` suffix | `useOrderStore.ts`                     |
| Services              | camelCase, domain noun            | `orderService.ts`, `printerService.ts` |
| Utilities             | camelCase, descriptive            | `formatCurrency.ts`, `dateUtils.ts`    |
| Types/interfaces file | camelCase or PascalCase           | `order.types.ts`, `OrderTypes.ts`      |
| Backend routes        | kebab-case                        | `order-items.routes.ts`                |
| Database repositories | camelCase + `Repository`          | `orderRepository.ts`                   |
| Tests                 | same as file under test + `.test` | `orderService.test.ts`                 |
| Configs               | kebab-case                        | `vite.config.ts`, `drizzle.config.ts`  |

---

## REST API endpoints

Pattern: `/api/v1/{resource}/{id?}/{sub-resource?}`

- Resources are **plural nouns**: `/orders`, `/items`, `/printers`
- IDs in the path: `/orders/:orderId/items/:itemId`
- Actions that are not CRUD: use a verb sub-path: `POST /orders/:orderId/void`
- No verbs in resource names: ❌ `/getOrders`, ✅ `GET /orders`

```text
GET    /api/v1/orders              → list orders
POST   /api/v1/orders              → create order
GET    /api/v1/orders/:orderId     → get one order
PATCH  /api/v1/orders/:orderId     → update order
DELETE /api/v1/orders/:orderId     → delete order
POST   /api/v1/orders/:orderId/void        → void order (non-CRUD action)
GET    /api/v1/orders/:orderId/items       → list items in order
POST   /api/v1/orders/:orderId/items       → add item to order
```

---

## Database

| Construct       | Convention                               | Example                                 |
| --------------- | ---------------------------------------- | --------------------------------------- |
| Tables          | snake_case, plural                       | `orders`, `order_items`, `sync_queue`   |
| Columns         | snake_case                               | `created_at`, `unit_price`, `tenant_id` |
| Primary key     | always `id`                              | `id TEXT PRIMARY KEY`                   |
| Foreign keys    | `{referenced_table_singular}_id`         | `order_id`, `tenant_id`                 |
| Timestamps      | `created_at`, `updated_at`, `deleted_at` | Unix ms integer                         |
| Boolean columns | `is_` prefix                             | `is_active`, `is_synced`                |
| Index names     | `idx_{table}_{column(s)}`                | `idx_orders_tenant_id`                  |

---

## Vue components

- Component names are **multi-word** to avoid conflicts with HTML elements.
  ❌ `Order.vue` → ✅ `OrderCard.vue` or `OrderDetail.vue`
- Props named from the **parent's perspective**: `order` not `currentOrder`.
- Event names: kebab-case, past tense. ❌ `update` → ✅ `item-added`, `order-voided`.
- Slots named for their purpose: `default`, `header`, `footer`, `empty`.
