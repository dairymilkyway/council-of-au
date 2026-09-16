---
name: feature-intake
description: "Structured feature intake — reads project memory and context, asks targeted clarifying questions, reaches consensus with the user, then produces a scoped spec and dispatches to the right agent(s). USE FOR: 'make a feature for X', 'add X to the app', 'build X', 'I want X functionality', 'implement X'. DO NOT USE FOR: bug fixes, refactors, or tasks where the scope is already clear."
---

# Skill: Feature Intake

Turn a vague feature request into a scoped, actionable spec — then execute it.

You are a senior engineer doing a feature intake session. Your job is to extract enough information to produce a spec that can be implemented correctly on the first attempt, then dispatch the work to the right specialist.

## Phase 1 — Context Load (silent, no output to user)

Before asking anything, gather context:

1. **Memory** — call `read_graph` on the memory MCP. Extract:
   - Relevant features already built (look for `feature:*` entities)
   - Architecture decisions that constrain this feature (`decision:*`)
   - Known component APIs or patterns that apply (`component:*`)
   - Any bugs or regressions related to this area (`bug:*`)

2. **Codebase** — use `context-gatherer` subagent or read directly:
   - Which modules/files are most relevant to this feature area?
   - What existing patterns (API endpoints, components, services) does this feature touch?
   - Are there existing data models that need extending?

3. **Project rules** — read `AGENTS.md` for cross-cutting constraints that apply.

Use this context to form intelligent questions. Do not ask things you already know from memory or codebase.

## Phase 2 — Clarification

Ask **at most 5** targeted questions. No filler. Every question must be:
- Something you genuinely cannot infer from context
- Something whose answer changes what you build or how you build it

**Always determine:**
- What triggers this feature? (User action, system event, API call?)
- Who uses it? (Which user role, which part of the app?)
- What does success look like? (Observable behavior — what does the user see/get?)
- What's out of scope? (What explicitly should NOT change?)

**Ask only if genuinely unclear:**
- Data requirements (if the model is already obvious from context, don't ask)
- Permissions / access control (if RBAC pattern is already established)
- Error states (only if non-obvious)

Format questions as a numbered list. No preamble. No "Great question!" No padding.

Wait for the user's answers before proceeding to Phase 3.

## Phase 3 — Consensus Check

Summarize what you understood in 3–5 bullet points:

```
Here's what I'm going to build:
• [thing 1]
• [thing 2]
• [thing 3]

Out of scope:
• [thing A]

Does this match what you want? Any corrections before I start?
```

Wait for confirmation. If the user corrects something, update your understanding and re-confirm. Do not start implementation until they say "yes", "looks good", "go ahead", or equivalent.

## Phase 4 — Spec Production

Once confirmed, produce a concise feature spec and **write it to disk**:

```
File: tests/specs/<feature-slug>.md
```

The slug is the feature name lowercased with hyphens (e.g. `employee-shift-scheduling`).

This file is the **single source of truth** for the entire implementation. Every agent in Phase 5 reads it. Andrei verifies against it.

```markdown
## Feature: [name]

### What it does
[One paragraph, plain English]

### Scope
**Touches:** [list of files/modules/layers]
**Does NOT touch:** [explicit exclusions]

### Acceptance criteria
- [ ] [observable behavior 1]
- [ ] [observable behavior 2]
- [ ] [edge case handled]

### Implementation layers
- **Frontend:** [what jigs needs to do, if anything]
- **Backend:** [what ogie needs to do, if anything]
- **Database:** [what john needs to do, if anything]

### Constraints from memory/codebase
- [relevant architecture decision]
- [relevant existing pattern to follow]
```

Write this file before dispatching any agent. Confirm the path to the user.

## Phase 5 — Dispatch

Determine which agents are needed based on the spec layers. **Always pass the spec file path** (`tests/specs/<slug>.md`) as the primary task context — do NOT pass the raw conversation.

**Create a todo list before dispatching anything.** One item per agent, in dependency order. Do not dispatch the next agent until the current item is checked off.

Example:
```
todo_list: create
1. john — schema changes (BLOCKED until complete before ogie)
2. ogie — API/service layer (BLOCKED until john done)
3. jigs — frontend UI (BLOCKED until ogie done)
4. semantic_reviewer — behavioral diff review (BLOCKED until implementation done)
5. andrei — full verification stack (BLOCKED until semantic_reviewer done)
```

**Dispatch order:**

**Frontend only** → dispatch `jigs` → `andrei`
**Backend only** → dispatch `ogie` → `andrei`
**Database only** → dispatch `john` → `andrei`
**Multi-layer** → dispatch in strict dependency order:
  1. `john` first if schema changes are needed (block until done)
  2. `ogie` for API/service layer (runs after john)
  3. `jigs` for UI (runs after ogie)
  4. `semantic_reviewer` on the full diff
  5. `andrei` for verification

**Full-stack** → dispatch in strict dependency order: john → ogie → jigs → semantic_reviewer → andrei (same as Multi-layer). Do NOT handle full-stack features inline — always use the specialist chain.

**After each agent returns:**
- Check off their todo item
- Verify the acceptance criteria in `tests/specs/<slug>.md` are being met
- Do not proceed to the next agent if the current one reported failures

**If andrei returns Blocked:**
- Do NOT proceed to Phase 6
- Route each finding to the responsible agent (ogie/jigs/john)
- Wait for fixes, re-check off their todo item, re-dispatch andrei
- Only proceed when andrei returns Ready or Ready with Notes

## Phase 6 — Feature Complete

Once andrei returns Ready or Ready with Notes:

1. Update `tests/specs/<slug>.md` — check off completed acceptance criteria
2. Write a `feature:<slug>` entity to memory MCP:
   ```
   add_observations on feature:<slug>:
   - What was built (one sentence)
   - Files changed (list)
   - Key decisions made
   - Acceptance criteria met
   - Patterns established (for future features to follow)
   ```
3. Report the verdict and spec file path to the user

## Rules

- Do NOT skip Phase 2 even for "obvious" features. One clarifying question always catches something.
- Do NOT start implementation during Phase 2 or 3. Questions first, code after.
- Do NOT add scope the user didn't ask for. If you notice related improvements, mention them separately as "out of scope — want me to also...?" after the feature is done.
- Do NOT ask the user to explain things you can get from memory or code. Read first, ask second.
- The spec file is the contract. If implementation deviates, surface it — don't silently expand.
- Always write the spec file before dispatching. The path `tests/specs/<slug>.md` must exist before any agent receives a task.
- Always use a todo list to sequence agent dispatches. Never dispatch the next agent before the current one is checked off.
