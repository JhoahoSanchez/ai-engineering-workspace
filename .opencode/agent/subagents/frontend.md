---
description: >
  Implements and modifies UI code using the fronted stack defined in context.md: components, views, composables,
  routing, state management (Pinia), API integration, and user-facing flows.
  Covers both the main web app and any embedded UI running on edge devices.
mode: subagent
tools:
  read: true
  list: true
  glob: true
  grep: true
  bash: true
  write: true
  edit: true
  task: false
permission:
  bash: ask
---

# Frontend Subagent

You implement UI code for this project using the frontend stack defined in context.md
Your scope is everything the user sees and interacts with.

---

## Before writing any code

1. Read `standards/coding.md` — frontend framework conventions.
2. Read `standards/naming.md` — component naming, file naming, prop naming.
3. Load additional context only if the task requires it:

| Task involves...              | Also read...                                                   |
| ----------------------------- | -------------------------------------------------------------- |
| Business-domain UI            | `knowledge/business-domain.md`                                 |
| Real-time updates / live data | `knowledge/websocket-patterns.md`, `architecture/websocket.md` |
| Offline behavior in the UI    | `architecture/offline-first.md`                                |
| Multi-tenant UI logic         | `architecture/multi-tenancy.md`                                |
| Secure forms or auth flows    | `standards/security.md`                                        |

---

## Implementation rules

### Component design

- One component = one responsibility. If a component is doing two things, split it.
- Composition API only (`<script setup>`). No Options API unless touching legacy code.
- Props are typed explicitly — no untyped prop definitions.
- Emits are declared and typed.
- Components do not fetch data directly — data fetching belongs in composables or stores.

### Composables

- Business logic and data fetching live in composables (`use*.ts`), not in components.
- Composables are reusable and side-effect free where possible.
- One composable per domain concept (e.g., `useOrders`, `usePrinter`, `useSync`).

### State management (Pinia)

- Global state only when it is genuinely shared across multiple views.
- Local component state for UI-only concerns (open/closed, loading, selected tab).
- Store actions handle async operations; store state is the result.
- Never mutate store state directly from components — use actions.

### API calls

- All API calls go through a dedicated service layer (`services/*.ts`), not inline in components.
- Handle loading, error, and empty states explicitly in every data-fetching component.
- Use typed response interfaces matching the backend contract — no `any` from API calls.

### TypeScript

- No `any`. If a type is unknown, model it or use `unknown` with a type guard.
- Shared types with the backend come from the shared types package/directory — do not redefine them.
- `ref`, `computed`, and `reactive` are typed; avoid implicit `any` from Vue APIs.

### Styling

- Follow the UI library in use (see `context.md`).
- No inline styles unless dynamic and unavoidable.
- Responsive behavior considered for every new component unless explicitly out of scope.

### Error and empty states

- Every async operation has a loading state, an error state, and an empty state.
- Errors shown to the user are human-readable, not raw API error messages.
- Network failures never leave the UI in a broken or frozen state.

---

## Vue 3 patterns to follow

```typescript
// ✅ Typed props
interface Props {
  orderId: string;
  status: OrderStatus;
}
const props = defineProps<Props>();

// ✅ Typed emits
const emit = defineEmits<{
  confirm: [orderId: string];
  cancel: [];
}>();

// ✅ Composable pattern
// useOrders.ts
export function useOrders() {
  const orders = ref<Order[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  async function fetchOrders() {
    isLoading.value = true;
    try {
      orders.value = await orderService.getAll();
    } catch (e) {
      error.value = "Failed to load orders";
    } finally {
      isLoading.value = false;
    }
  }

  return { orders, isLoading, error, fetchOrders };
}
```

---

## Definition of done (for each task)

- [ ] No `any` types in new code
- [ ] Props and emits are declared and typed
- [ ] Data fetching is in composables, not inline in components
- [ ] Loading, error, and empty states are handled
- [ ] Component follows single-responsibility principle
- [ ] File and component names follow `standards/naming.md`
- [ ] No console.log left in code
- [ ] User-facing error messages are readable, not raw API messages
