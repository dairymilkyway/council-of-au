---
title: Persistent memory discipline
inclusion: always
---

# Memory MCP - Session Discipline

A persistent knowledge graph is available via the `memory` MCP server.
Storage: `.kiro/memory.jsonl` in the active workspace root.

## On every session start

Before doing anything else, call `search_nodes` with a topic keyword relevant
to the current task. This is faster than `read_graph` and keeps context focused.

Use `read_graph` only when:
- You are disoriented (no task context, fresh session after `/clear`)
- You need a full project map to decide where to start

`read_graph` dumps all 40+ entities. On a focused task it floods context with
irrelevant facts. Default to `search_nodes` first.

## What to save

Write to memory whenever any of the following are discovered or decided:

**Component API facts**
- Prop names that differ from common expectations (e.g. `icon` not `children`, `onValueChange` not `onChange`)
- Prop types that are surprising (e.g. `OtpInput.value` is `string[]`)
- Valid variant/tone values for any component
- Components that require non-obvious required props

**Build & tooling facts**
- Which tsconfig to use for which check
- Build commands and their purpose
- Known working configs (vite, rollup, package.json fields)

**Architecture decisions**
- Why a specific approach was chosen and what was rejected
- Constraints that must not be violated

**Bugs and regressions found**
- Specific issues discovered during audits, even after fixing
- Pattern: what broke, root cause, how it was fixed

**Project preferences**
- Coding style choices specific to this project
- Things the developer has explicitly approved or rejected

## Entity naming convention

```
project:<slug>             -- top-level project entity, e.g. project:my-app
component:<name>           -- e.g. component:IconButton
package:<name>             -- e.g. package:my-ui-lib
decision:<topic>           -- e.g. decision:peer-deps
bug:<short-slug>           -- e.g. bug:auth-redirect-loop
feature:<slug>             -- completed feature, e.g. feature:employee-onboarding
```

## When to save

Save proactively after:
- Any audit that reveals new API facts
- Any bug fix where the root cause is non-obvious
- Any architecture or config decision the developer approves
- Any time the developer says "remember that" or "save that"
- Any time post-write hook fires a MEMORY-HINT signal

**Do NOT wait to be asked.** If something is worth knowing next session, save it now silently.

## Trigger phrase

If the developer says "save to memory", "remember this", or "update memory",
immediately write the relevant entities/observations to the graph.
