# Project Context

> This file is the single source of truth for the active project state.
> Read it at the start of every session. Update it when phase, stack, or focus changes.

---

## Active Project

**Name**: <!-- e.g. RestoPOS -->
**Description**: <!-- One sentence: what does this product do and for whom -->
**Status**: <!-- planning | in-development | beta | production -->
**Last updated**: <!-- YYYY-MM-DD -->

---

## Tech Stack

### Backend

- **Runtime**: Node.js <!-- version, e.g. 20 LTS -->
- **Framework**: <!-- Express | Fastify | Hono -->
- **Language**: TypeScript
- **Database**: SQLite (via better-sqlite3)
- **Query layer**: <!-- Drizzle ORM | raw SQL | Kysely -->
- **Auth**: <!-- JWT | session | none yet -->

### Frontend

- **Framework**: Vue 3 + TypeScript
- **Build tool**: <!-- Vite -->
- **State management**: <!-- Pinia | none yet -->
- **UI library**: <!-- Tailwind | shadcn-vue | none -->
- **Routing**: Vue Router

### Edge / Local Device

- **Runtime**: <!-- Node.js on device | Electron | Tauri -->
- **Local DB**: SQLite
- **Hardware**: <!-- receipt printer model, OS of device -->
- **Connectivity**: <!-- always-on | intermittent | offline-first -->

### Infrastructure

- **Cloud**: AWS
- **Services in use**: <!-- EC2 | Lambda | S3 | etc. -->
- **CI/CD**: <!-- GitHub Actions | none yet -->
- **Tenancy model**: <!-- single-tenant | multi-tenant -->

---

## Current Phase

<!-- Describe what is being actively built RIGHT NOW.
     Be specific: "Implementing the offline print queue and sync mechanism"
     not just "building the app". -->

---

## Active Development Areas

<!-- 2–4 modules or features currently in progress.
     Format: - [module]: [what specifically is being worked on] -->

- Example

---

## Recent Decisions

<!-- The last 3–5 significant technical decisions.
     Older decisions that should never be re-discussed belong in memory.md.
     Format: YYYY-MM-DD: [what was decided and brief reason] -->

- Example desition

---

## Known Issues / Tech Debt

<!-- Problems acknowledged but not yet resolved.
     Format: - [issue]: [why deferred] -->

- Example

---

## Out of Scope (for now)

<!-- Things explicitly decided NOT to build yet.
     Prevents subagents from over-engineering toward future features. -->

-
