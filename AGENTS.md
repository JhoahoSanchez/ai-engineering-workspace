# AI Engineering Workspace

This workspace is an AI-orchestrated development team supervised by a human.
The primary agent is `architect`. Every agent or subagent invoked in this workspace
must follow the rules defined here before taking any action.

---

## Rule 0 — Active project context

**The current project context lives in `.opencode/context.md`.**

Every agent (primary or subagent) must read `.opencode/context.md` before responding
or executing any task. Never assume the stack, state, or current decisions —
read them from there.

---

## Workspace map

```text
.opencode/
  context.md              → active project state (stack, phase, recent decisions)
  memory.md               → architectural decisions already made and their rationale (do not re-discuss)
  agent/
    architect.md          → primary agent, orchestrator
    subagents/            → specialists invoked by the architect
      backend.md          → server logic, REST APIs, business rules, integrations
      database.md         → schemas, migrations, queries, data modeling
      devops.md           → CI/CD, infrastructure, deployment, env config
      distributed.md      → sync, conflict resolution, event ordering, idempotency
      documentation.md    → READMEs, API docs, inline comments, changelogs
      edge.md             → offline-first logic, local device code, hardware integration
      frontend.md         → UI components, composables, state management, user flows
      qa.md               → checklists, test execution, edge case discovery, validation
      security.md         → auth audits, input validation, secrets, dependency checks

architecture/             → high-level design patterns and decisions
standards/                → mandatory conventions (coding, naming, git, testing...)
knowledge/                → domain knowledge and technology-specific references
templates/                → executable boilerplate, not prose
checklists/               → quality gates QA verifies before closing tasks
workflows/                → end-to-end orchestration flows (bootstrap, feature, bugfix...)
```

---

## Context loading principle

**Load only what the current task requires.** Do not preemptively load all of
`standards/`, `knowledge/`, or `architecture/`.

Each agent/subagent loads only the files relevant to its role and the specific
task at hand. Instructions on what to load are defined in each agent's own prompt.

---

## Universal rules (apply to every agent)

1. Never fabricate technical information. When uncertain, read the relevant file
   in `knowledge/` or escalate to the architect.
2. Never write to `memory.md` directly. Only the architect writes there,
   at the end of a task when a decision needs to be persisted.
3. Before writing any code, check whether a relevant template exists in `templates/`.
4. Standards in `standards/` are not suggestions: they are mandatory.
   If a subagent cannot comply with one, it must report this to the architect before proceeding.
5. No subagent escalates directly to the user. Everything goes through the architect,
   who decides whether the situation warrants interrupting human supervision.

---

## Orchestration flow

The following diagram shows how work moves through the workspace, from user input
to a completed, verified deliverable.

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                            USER INPUT                                    │
│  (feature request, bug report, question, or task)                        │
└───────────────────────────────┬──────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                         ARCHITECT AGENT                                   │
│                                                                          │
│  1. Read context.md + memory.md (startup protocol)                       │
│  2. Understand the task (Step 1)                                         │
│  3. Load specific context from architecture/, knowledge/, standards/     │
│  4. Decompose into subtasks with assigned subagents (Step 3)             │
│  5. Delegate in dependency order                                         │
│  6. Monitor execution, resolve blockers                                  │
│  7. Consolidate results, run QA checklist                                │
│  8. Update memory.md / context.md if decisions were made                  │
│  9. Report to user                                                       │
└──────┬───────────┬───────────┬───────────┬───────────┬───────────────────┘
       │           │           │           │           │
       ▼           ▼           ▼           ▼           ▼
┌──────────┐┌──────────┐┌──────────┐┌──────────┐┌──────────┐
│ database ││ backend  ││ frontend ││   edge   ││distributed│
│          ││          ││          ││          ││          │
│ schemas  ││ APIs     ││ UI       ││ offline  ││ sync     │
│ migrates ││ services ││ compos.  ││ local DB ││ conflicts│
│ indexes  ││ routes   ││ stores   ││ hardware ││ events   │
└──────────┘└──────────┘└──────────┘└──────────┘└──────────┘
       │           │           │           │           │
       └───────────┴───────────┴───────────┴───────────┘
                                │
                                ▼
                    ┌───────────────────┐
                    │    QA SUBAGENT     │
                    │                    │
                    │  Run checklist     │
                    │  Verify tests pass │
                    │  Check standards   │
                    │  Report PASS/FAIL  │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
              ┌──────────┐      ┌──────────────┐
              │ PASS     │      │ FAIL         │
              │          │      │              │
              │ Report   │      │ Send fixes   │
              │ to user  │      │ back to      │
              │          │      │ subagent,    │
              └──────────┘      │ re-run QA    │
                                └──────────────┘
```

---

## Workflow reference

Workflows are orchestrated sequences that the architect follows for common tasks.
Each workflow is a standalone document in `workflows/` that can be loaded on demand.

| Workflow       | Trigger                  | What it produces                                                            |
| -------------- | ------------------------ | --------------------------------------------------------------------------- |
| `/bootstrap`   | New project from scratch | Filled `context.md`, initial `memory.md`, milestone plan                    |
| `/plan`        | Non-trivial design task  | Written plan with options, decision, and implementation steps               |
| `/new-feature` | Feature implementation   | Working feature with tests, docs, and QA pass                               |
| `/fix-bug`     | Bug report               | Root cause identified, fix applied, regression test added                   |
| `/review`      | Code review request      | Structured review report with correctness, standards, and security findings |
| `/release`     | Ship to production       | Version bump, changelog, tag, deployment, production health check           |

### Typical lifecycle of a feature

```text
/bootstrap  →  /plan  →  /new-feature  →  /review  →  /release
   ↑                    ↑                  ↑
   │ (first time)       │ (per feature)    │ (before merge)
   │                    │                  │
   └────────────────────┴──────────────────┘
            (repeat for each feature)
```

---

## Subagent routing quick reference

| Subagent        | When to invoke                                   | Key files to load                                               |
| --------------- | ------------------------------------------------ | --------------------------------------------------------------- |
| `backend`       | Server logic, APIs, business rules, integrations | `standards/coding.md`, `standards/error-handling.md`            |
| `database`      | Schema design, migrations, queries, indexes      | `standards/naming.md`, relevant `architecture/`                 |
| `devops`        | CI/CD, infrastructure, deployment, env config    | `standards/security.md`, `standards/logging.md`                 |
| `distributed`   | Sync between nodes, conflict resolution, events  | `architecture/event-driven.md`, `architecture/offline-first.md` |
| `documentation` | READMEs, API docs, inline comments, changelogs   | `standards/documentation.md`                                    |
| `edge`          | Offline-first logic, local device code, hardware | `architecture/offline-first.md`, `architecture/printer.md`      |
| `frontend`      | UI components, composables, state, user flows    | `standards/coding.md`, `standards/naming.md`                    |
| `qa`            | Test execution, checklists, validation           | `checklists/pre-merge.md`, `checklists/new-feature.md`          |
| `security`      | Auth audits, input validation, secrets, deps     | `standards/security.md`, `checklists/security-review.md`        |
