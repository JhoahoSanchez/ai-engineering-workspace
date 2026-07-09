# UI Component Template

A component owns one piece of UI with one responsibility.
Adapt the syntax to the UI framework in `context.md` (Vue, React, Svelte, etc.).
The pattern is the same regardless of framework.

---

## Structure

```text
src/
  components/
    [ComponentName]/
      [ComponentName].vue        ← component (or .tsx, .svelte, etc.)
      [ComponentName].test.ts    ← component tests (if non-trivial interaction)
  composables/                   ← data fetching and shared logic (Vue)
    use[Domain].ts
  stores/                        ← global state
    use[Domain]Store.ts
```

---

## Component responsibility split

| Layer             | Responsibility                             | Technology                |
| ----------------- | ------------------------------------------ | ------------------------- |
| Component         | Render UI, handle user input, show states  | Vue/React/Svelte template |
| Composable / Hook | Data fetching, local state, business logic | `use*.ts`                 |
| Store             | Global shared state, cross-component data  | Pinia / Zustand / etc.    |

**Components do not fetch data directly.** Data comes from a composable or store.
**Composables/hooks do not render UI.** They return state and actions.

---

## Template (Vue 3 Composition API — adapt as needed)

```vue
<!-- [ComponentName].vue -->
<!--
  Responsibility: [one sentence — what this component shows/does]
  Props: [list key props]
  Emits: [list key events]
-->
<script setup lang="ts">
import { computed } from 'vue'
import { use[Domain] } from '@/composables/use[Domain]'

// --- Props ---
interface Props {
  [propName]: [type]
  // Keep props minimal — pass IDs, not whole objects when possible
}
const props = defineProps<Props>()

// --- Emits ---
const emit = defineEmits<{
  [eventName]: [[paramType]]  // e.g. confirm: [id: string]
  cancel: []
}>()

// --- Data (from composable, not fetched here) ---
const { [data], isLoading, error, [action] } = use[Domain](props.[propName])

// --- Derived state ---
const [derivedValue] = computed(() => {
  // derive from data, not compute from props directly
})

// --- Handlers ---
function handle[Action]() {
  [action]()
  emit('[eventName]', [param])
}
</script>

<template>
  <!-- Loading state -->
  <div v-if="isLoading" class="[loading-class]">
    <!-- skeleton or spinner -->
  </div>

  <!-- Error state -->
  <div v-else-if="error" class="[error-class]" role="alert">
    {{ error }}
  </div>

  <!-- Empty state -->
  <div v-else-if="![data] || [data].length === 0" class="[empty-class]">
    <!-- empty state message or illustration -->
  </div>

  <!-- Content -->
  <div v-else>
    <!-- main content here -->
    <button @click="handle[Action]">[Action Label]</button>
  </div>
</template>
```

---

## Composable template

```typescript
// use[Domain].ts
import { ref, computed, onMounted } from 'vue'
import { [domain]Service } from '@/services/[domain].service'
import { logger } from '@/lib/logger'

export function use[Domain](id?: string) {
  const [data] = ref<[Type] | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  async function fetch[Domain]() {
    isLoading.value = true
    error.value = null
    try {
      [data].value = await [domain]Service.getById(id!)
    } catch (e) {
      error.value = 'Failed to load [domain]. Please try again.'
      logger.warn({ [domain]Id: id, error: e }, 'use[Domain]: fetch failed')
    } finally {
      isLoading.value = false
    }
  }

  async function [action](/* params */) {
    try {
      await [domain]Service.[action](/* params */)
      await fetch[Domain]()  // refresh after mutation
    } catch (e) {
      error.value = 'Failed to [action]. Please try again.'
    }
  }

  onMounted(() => {
    if (id) fetch[Domain]()
  })

  return {
    [data],
    isLoading,
    error,
    [action],
    refresh: fetch[Domain],
  }
}
```

---

## Checklist before shipping a new component

- [ ] Component has a single UI responsibility
- [ ] Props are typed; emits are declared and typed
- [ ] Data fetching is in a composable/hook, not inline in the component
- [ ] All three states are handled: loading, error, empty
- [ ] User-facing error messages are human-readable, not raw API errors
- [ ] No `any` types
- [ ] Component name is multi-word (avoids conflict with native HTML elements)
- [ ] No `console.log` in committed code
