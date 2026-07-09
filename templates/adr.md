# ADR Template — Architectural Decision Record

Use this template when recording a significant architectural decision.
ADRs go into `memory.md` (appended by the architect) or into `docs/decisions/`
as individual files if the project has many of them.

---

## When to write an ADR

Write an ADR whenever a decision:

- Affects more than one subagent's work
- Would be expensive or disruptive to reverse later
- Is non-obvious and might be questioned by a future developer (or agent)
- Resolves a significant trade-off

Do not write an ADR for: minor implementation details, obvious choices,
or decisions that can be trivially reversed.

---

## Template

```markdown
### [YYYY-MM-DD] [Short imperative title — e.g. "Use SQLite as the local store on edge devices"]

**Status**: proposed | accepted | deprecated | superseded by [ADR title]

#### Context

[What situation made this decision necessary?
What constraints, requirements, or forces are at play?
Write 2–5 sentences. Be specific to this project, not generic.]

#### Decision

[What was decided? State it clearly in one or two sentences.
Start with "We will..." or "We have decided to..."]

#### Alternatives considered

[What else was evaluated and why was it not chosen?
At least one alternative. Be honest about the trade-offs.]

| Option          | Why rejected |
| --------------- | ------------ |
| [Alternative A] | [Reason]     |
| [Alternative B] | [Reason]     |

#### Consequences

**Positive**:

- [Benefit 1]
- [Benefit 2]

**Negative / trade-offs accepted**:

- [Known downside 1]
- [Known downside 2]

#### Follow-up actions

- [ ] [Any action items that result from this decision]
```

---

## Example (filled in)

```markdown
### [2024-03-15] Use event sourcing for order state on edge devices

**Status**: accepted

#### Context

Edge devices operate offline for extended periods. We need orders to sync reliably
to the cloud when connectivity is restored. State-based sync creates merge conflicts
when two devices modify the same order offline. We need a sync strategy that handles
concurrent offline modifications without data loss.

#### Decision

We will model all order mutations as immutable domain events stored in a local
sync queue, rather than syncing the order's current state. The cloud derives state
by replaying events in order.

#### Alternatives considered

| Option                               | Why rejected                                                                |
| ------------------------------------ | --------------------------------------------------------------------------- |
| Sync current state (last-write-wins) | Loses data when two devices edit the same order offline                     |
| Operational transforms (OT)          | Too complex for our conflict types; designed for collaborative text editing |
| CRDT                                 | Overkill for our data model; complex to implement correctly                 |

#### Consequences

**Positive**:

- No merge conflicts: each event is independent
- Full audit trail built-in
- Replay enables recovery from bugs

**Negative / trade-offs accepted**:

- More complex query layer (must reconstruct state from events)
- Event schema must be versioned carefully
- Higher storage usage on the edge device

#### Follow-up actions

- [ ] Define the full event catalog in architecture/event-driven.md
- [ ] Implement sync_queue table schema (database subagent)
- [ ] Define conflict resolution policy for concurrent events on the same order
```
