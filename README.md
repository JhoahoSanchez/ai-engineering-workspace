# AI Engineering Workspace

An AI-orchestrated development team template for [opencode](https://opencode.ai). Provides a complete multi-agent system where an architect agent decomposes tasks and delegates to specialized subagents, all supervised by a human.

## What this is

This workspace turns opencode into a structured development team. Instead of a single AI assistant, you get:

- **Architect** — receives tasks, decomposes them, delegates to subagents, consolidates results
- **9 specialized subagents** — backend, database, frontend, edge, distributed, devops, security, QA, documentation
- **Enforced standards** — coding, naming, error handling, security, testing, git, logging, documentation
- **Templates and checklists** — reusable boilerplate and quality gates
- **Workflows** — orchestrated sequences for common development tasks

The human stays in control. The architect asks before making non-trivial decisions, and all work goes through a QA checkpoint before delivery.

## Quick start

### 1. Bootstrap a new project

Tell the architect:

```text
/bootstrap
```

This walks through filling in `.opencode/context.md` (tech stack, architecture, constraints) and recording initial decisions in `.opencode/memory.md`.

### 2. Work on features

```text
/new-feature: implement the order voiding flow
```

The architect plans the work, invokes subagents in dependency order (database → backend → edge → frontend → security → QA), and reports back when done.

### 3. Fix bugs

```text
/fix-bug: orders with null tableId crash when voiding
```

Root cause analysis first, then a failing test, then the fix. Never patches symptoms.

### 4. Plan before coding

```text
/plan: design the offline print queue architecture
```

Produces a written plan with options, a recommendation, and implementation steps. No code is written until the plan is approved.

### 5. Review and release

```text
/review    → structured code review report
/release   → version bump, changelog, tag, deploy
```

## Workspace structure

```text
.opencode/
  context.md              → active project state (fill this in first)
  memory.md               → architectural decisions (architect-only)
  agent/
    architect.md          → primary orchestrator
    subagents/            → 9 specialist agents

architecture/             → high-level design patterns
standards/                → mandatory conventions
knowledge/                → domain and technology references
templates/                → executable boilerplate
checklists/               → quality gates
workflows/                → end-to-end orchestration flows
```

## How it works

```text
User → Architect → Subagents → QA → User
```

1. User gives a task to the architect
2. Architect reads `context.md` + `memory.md` to understand the project
3. Architect decomposes the task and delegates to subagents in dependency order
4. Each subagent loads only the standards and knowledge it needs
5. QA validates the output against the relevant checklist
6. Architect reports results and updates memory/context if decisions were made

### Subagents

| Agent           | Role                                                  |
| --------------- | ----------------------------------------------------- |
| `backend`       | Server logic, REST APIs, business rules, integrations |
| `database`      | Schema design, migrations, queries, indexes           |
| `devops`        | CI/CD, infrastructure, deployment, env config         |
| `distributed`   | Sync between nodes, conflict resolution, events       |
| `documentation` | READMEs, API docs, inline comments, changelogs        |
| `edge`          | Offline-first logic, local device code, hardware      |
| `frontend`      | UI components, composables, state, user flows         |
| `qa`            | Test execution, checklists, validation                |
| `security`      | Auth audits, input validation, secrets, deps          |

### Workflows

| Workflow       | Use when                                   |
| -------------- | ------------------------------------------ |
| `/bootstrap`   | Starting a new project from scratch        |
| `/plan`        | Designing a solution before implementation |
| `/new-feature` | Implementing a new feature end-to-end      |
| `/fix-bug`     | Diagnosing and fixing a bug                |
| `/review`      | Code review before merging                 |
| `/release`     | Shipping to production                     |

### Standards

All standards in `standards/` are mandatory. Subagents must comply or escalate to the architect. Key standards:

- `coding.md` — TypeScript strict mode, no `any`, function length, module structure
- `naming.md` — files, variables, API endpoints, database columns
- `error-handling.md` — typed `AppError` subclasses, no silent catches
- `security.md` — input validation, auth, secrets, injection prevention
- `testing.md` — what to test, test structure, coverage expectations
- `git.md` — branch naming, commit messages, workflow
- `logging.md` — structured logging, what to log, what not to log
- `documentation.md` — README structure, API docs, inline comments

## Principles

- **Context is king** — every agent reads `context.md` before acting. Never assume.
- **Load only what you need** — agents load only the standards and knowledge relevant to their task.
- **Memory is permanent** — decisions in `memory.md` are final. Don't re-discuss without explicit request.
- **Templates before code** — check `templates/` before writing new files from scratch.
- **QA is mandatory** — every feature passes through the QA subagent before delivery.
- **Human in the loop** — the architect asks before making non-trivial decisions.
