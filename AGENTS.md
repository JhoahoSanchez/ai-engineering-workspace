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
  context.md       → active project state (stack, phase, recent decisions)
  memory.md        → architectural decisions already made and their rationale (do not re-discuss)
  agent/
    architect.md   → primary agent, orchestrator
    subagents/     → specialists invoked by the architect

architecture/      → high-level design patterns and decisions
standards/         → mandatory conventions (coding, naming, git, testing...)
knowledge/         → domain knowledge and technology-specific references
templates/         → executable boilerplate, not prose
checklists/        → quality gates QA verifies before closing tasks
skills/            → reusable invocable capabilities across projects
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
