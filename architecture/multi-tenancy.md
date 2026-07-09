# Multi-Tenancy

## Model

<!-- Fill in the tenancy model once decided. Options below: -->

### Option A — Row-level isolation (shared schema)

All tenants share the same database schema. Every table has a `tenant_id` column.
Every query includes `WHERE tenant_id = ?`. Simpler to operate, harder to guarantee isolation.

### Option B — Schema-per-tenant

Each tenant has their own database schema. Complete isolation, harder to migrate.

### Option C — Database-per-tenant

Each tenant has their own database instance. Maximum isolation, highest cost.

---

## Current decision

<!-- Document which model was chosen and why in memory.md.
     Reference that entry here once made. -->

---

## Tenant identification

On every authenticated request, the tenant is resolved from:

1. The JWT or session token (preferred — tenant is embedded at auth time).
2. Subdomain or custom domain (for web app routing).
3. Device token (for edge devices — each device is registered to one tenant).

---

## Data isolation rules (regardless of model)

- A tenant's data must never appear in another tenant's response.
- Multi-tenant queries always include the tenant scope — no bare SELECT without it.
- Cross-tenant operations are only possible for super-admin role.
- Logging must include `tenantId` on every log line — never log without tenant context.

---

## Tenant provisioning

When a new tenant is created:

- Generate a unique `tenantId` (UUID)
- Seed default configuration (menu categories, tax rates, printer settings)
- Create the first admin user
- Register in the tenant registry

This is a back-office operation, not a self-service flow (unless decided otherwise).
