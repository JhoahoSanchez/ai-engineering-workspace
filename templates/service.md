# Service / Module Template

A service encapsulates business logic for one domain concept.
It sits between the API layer (routes/controllers) and the data layer (repositories).

Adapt the syntax to the language and framework in `context.md`.
The pattern is the same regardless of framework.

---

## Structure

```text
src/
  [domain]/
    [domain].service.ts      ← business logic (this template)
    [domain].repository.ts   ← data access
    [domain].types.ts        ← shared types/interfaces
    [domain].service.test.ts ← unit tests for the service
```

---

## Template (TypeScript — adapt as needed)

```typescript
// [domain].service.ts
//
// Responsibilities:
//   - [List what this service owns, one line each]
//   - ...
//
// Does NOT:
//   - [List what it explicitly delegates or excludes]
//   - ...

import { [DomainEntity], [CreateInput], [UpdateInput] } from './[domain].types'
import { [Domain]Repository } from './[domain].repository'
import { NotFoundError, ConflictError, ValidationError } from '../errors/AppError'
import { logger } from '../lib/logger'

export class [Domain]Service {
  constructor(
    private readonly repo: [Domain]Repository,
    // Add other dependencies here (other services, external clients)
  ) {}

  async getById(id: string, tenantId: string): Promise<[DomainEntity]> {
    const entity = await this.repo.findById(id, tenantId)
    if (!entity) throw new NotFoundError('[Domain]', id)
    return entity
  }

  async list(tenantId: string, filters?: Partial<[DomainEntity]>): Promise<[DomainEntity][]> {
    return this.repo.findAll(tenantId, filters)
  }

  async create(input: [CreateInput], tenantId: string): Promise<[DomainEntity]> {
    // 1. Validate business rules (not just types — those were validated at the API layer)
    await this.assertCanCreate(input, tenantId)

    // 2. Build the entity
    const entity: [DomainEntity] = {
      id: crypto.randomUUID(),
      tenantId,
      ...input,
      createdAt: Date.now(),
      updatedAt: Date.now(),
    }

    // 3. Persist
    await this.repo.insert(entity)

    logger.info({ tenantId, [domain]Id: entity.id }, '[Domain] created')
    return entity
  }

  async update(id: string, input: [UpdateInput], tenantId: string): Promise<[DomainEntity]> {
    const existing = await this.getById(id, tenantId)

    // Validate business rules for update
    await this.assertCanUpdate(existing, input)

    const updated: [DomainEntity] = {
      ...existing,
      ...input,
      updatedAt: Date.now(),
    }

    await this.repo.update(updated)
    return updated
  }

  async delete(id: string, tenantId: string): Promise<void> {
    const existing = await this.getById(id, tenantId)
    await this.assertCanDelete(existing)
    await this.repo.delete(id, tenantId)
    logger.info({ tenantId, [domain]Id: id }, '[Domain] deleted')
  }

  // --- Private business rule validators ---

  private async assertCanCreate(input: [CreateInput], tenantId: string): Promise<void> {
    // Example: check uniqueness constraint
    // const existing = await this.repo.findByName(input.name, tenantId)
    // if (existing) throw new ConflictError(`A [domain] named '${input.name}' already exists`)
  }

  private async assertCanUpdate(existing: [DomainEntity], input: [UpdateInput]): Promise<void> {
    // Example: check status transitions
    // if (existing.status === 'closed') throw new ConflictError('Cannot update a closed [domain]')
  }

  private async assertCanDelete(existing: [DomainEntity]): Promise<void> {
    // Example: check dependencies
    // const deps = await this.repo.countDependents(existing.id)
    // if (deps > 0) throw new ConflictError('Cannot delete: has active dependents')
  }
}
```

---

## Checklist before shipping a new service

- [ ] Service has a single domain responsibility (not two things joined by "and")
- [ ] All methods take `tenantId` and enforce tenant isolation
- [ ] Business rule validators are private and named `assertCan*`
- [ ] No database queries inside the service — all data access through the repository
- [ ] Logs on create, update, delete with `tenantId` and entity `id`
- [ ] Corresponding `*.service.test.ts` covers all public methods and error paths
