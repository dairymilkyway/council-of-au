---
title: Skill auto-load rules
inclusion: always
---

# Skill Auto-Load Rules

Automatically determine which skills to load based on the implementation scope and task type before creating the implementation plan.

## Always-On Skills (load before anything else)

These skills apply to **every task, every agent, every session** — no trigger needed:

1. `i-have-adhd` — Shape every response for an ADHD reader: lead with the action, number steps, restate state, suppress tangents, specific time estimates, make wins visible. Rules stay on unless the user says "stop adhd mode".

Load `i-have-adhd` automatically at the start of every session. It is not conditional on task type.

---

## Planning Workflow

For every task:

1. Load `i-have-adhd` (always-on — no condition required).
2. Analyze the request.
3. Detect affected layers and task type (frontend, backend, QA/audit, or a combination).
4. Load all applicable task-scoped skills (no user confirmation needed).
5. Create the implementation plan only after all applicable skills are loaded.
6. Follow the loaded skills throughout the entire implementation.
7. If `qa-audit` is active, conclude with a structured audit summary.

---

## Frontend Changes

If the task modifies any frontend code, load in this order:

1. `react-typescript`
2. `vercel-react-best-practices`
3. `frontend-ui-engineering`
4. `better-typography`

If the task additionally involves **UI polish, interactions, animations, hover states, shadows, icons, or micro-interactions**, also load:

5. `better-ui`

**Anti-slop enforcement (always active for frontend tasks):**
Anti-slop rules (R-01 to R-38) are baked directly into jigs, andrei, and semantic_reviewer. No separate skill load is needed. When jigs builds any UI, it runs the Delivery Gate before reporting done. When andrei verifies, it runs the 4-block anti-slop gate. When semantic_reviewer reviews a frontend diff, it scans for slop violations and reports them as `[ANTI-SLOP] R-XX` findings. The rules reference `frontend/DESIGN.md` automatically.

Frontend scope includes (not limited to):
React components, pages, views, hooks, forms, tables, dialogs, UI/UX, styling, routing, state management, TypeScript frontend code, frontend tests, frontend bug fixes, frontend refactoring, frontend performance improvements.

---

## Backend Changes

If the task modifies any backend code, load in this order:

1. `backend-patterns`
2. `nodejs-backend-patterns`
3. `nestjs-best-practices`

Backend scope includes (not limited to):
Controllers, services, modules, DTOs, entities, Prisma, database, repositories, guards, middleware, interceptors, authentication, authorization, APIs, validation, backend tests, backend bug fixes, backend refactoring, backend performance improvements.

---

## Full-Stack Changes

If both frontend and backend are modified, load frontend skills first, then backend skills:

1. `react-typescript`
2. `vercel-react-best-practices`
3. `frontend-ui-engineering`
4. `backend-patterns`
5. `nodejs-backend-patterns`
6. `nestjs-best-practices`

The implementation plan must not be created until all applicable skills are loaded.

---

## QA / Audit Tasks

If the task is focused on reviewing, validating, auditing, or investigating code rather than implementing new functionality, load:

1. `qa-audit`

QA/Audit scope includes (not limited to):
Code review, QA validation, audit, technical review, root cause analysis, bug investigation, regression analysis, requirement validation, API validation, architecture review, performance review, security review, accessibility review, maintainability review, risk assessment, pre-merge review, pull request review, verifying a completed implementation, validating acceptance criteria.

No implementation skills are required unless code modifications are also requested.

---

## Combined: Implementation + Audit

If the task both modifies code and requests verification or review, load implementation skills first, then `qa-audit`:

**Frontend + Audit:**
1. `react-typescript`
2. `vercel-react-best-practices`
3. `frontend-ui-engineering`
4. `qa-audit`

**Backend + Audit:**
1. `backend-patterns`
2. `nodejs-backend-patterns`
3. `nestjs-best-practices`
4. `qa-audit`

**Full-Stack + Audit:**
1. `react-typescript`
2. `vercel-react-best-practices`
3. `frontend-ui-engineering`
4. `backend-patterns`
5. `nodejs-backend-patterns`
6. `nestjs-best-practices`
7. `qa-audit`

This ordering ensures implementation guidance is applied before the completed work is evaluated.

---

## QA Skill Responsibilities

When `qa-audit` is active, behave as a senior software reviewer and evaluate the following dimensions:

**Correctness:** Requirement coverage, edge cases, logic errors, regression risks.

**Architecture:** Project conventions, separation of concerns, simplicity, unnecessary abstractions, maintainability.

**Frontend:** React best practices, hook correctness, state ownership, rendering efficiency, accessibility, responsive behavior, loading/empty/error states.

**Backend:** NestJS best practices, dependency injection, DTO validation, error handling, authorization, authentication, module boundaries, transaction handling.

**Database:** Query efficiency, N+1 queries, missing indexes, transactions, pagination, data consistency.

**Security:** Input validation, authorization, authentication, sensitive data exposure, injection vulnerabilities.

**Performance:** Duplicate API calls, over-fetching, caching opportunities, expensive rendering, unnecessary computations.

**Maintainability:** Naming, readability, testability, complexity, duplicate logic, technical debt.

---

## Audit Deliverable

Whenever `qa-audit` is loaded, conclude the review with a structured summary:

- **Overall Status**
- **Severity** (None / Low / Medium / High / Critical)
- **Findings**
- **Recommendations**
- **Risk Assessment**
- **Merge Readiness** (Ready / Ready with Changes / Not Ready)

---

## Component Design and Implementation Tasks

If the task materially involves designing, building, or evaluating UI components, load:

1. `building-components`

Load `building-components` when the task specifically concerns:

- Creating a new UI component (primitive, form control, overlay, navigation, data display)
- Redesigning or refactoring an existing component
- Building component variants or extensions
- Designing a composable component API
- Component-library architecture decisions
- Component interaction patterns and accessibility
- Reusable UI primitives
- Component documentation
- Component gallery work
- Design-system component implementation
- Evaluating whether something should be a component, and how it should be composed

**Do NOT load** `building-components` for:

- General frontend page work that does not involve component design decisions
- Backend, database, API, or infrastructure work
- Performance audits unrelated to component architecture
- General TypeScript debugging
- Simple styling or text/content changes
- Tasks where the word "UI", "design", or "frontend" appears but the work is not materially about component construction or architecture

**Load order when combined with other skills:**

- Component work + frontend: load `react-typescript`, `vercel-react-best-practices`, `frontend-ui-engineering`, then `building-components`, then `better-ui`
- Component work + audit: load `building-components`, then `qa-audit`
- Component work + full-stack: load all frontend skills, then `building-components`, then `better-ui`, then backend skills

`building-components` supplements the project's existing design system and `DESIGN.md`. It does not override project-specific requirements. Prefer the simplest implementation that satisfies the task.

---

## Visual and UI Design Tasks

If the task materially involves visual design direction, aesthetic decisions, typography, layout, or making UI feel intentional and distinctive — not just implemented — load:

1. `frontend-design`
2. `better-ui`
3. `better-typography`
4. `impeccable`

Load `impeccable` when the task involves ANY of these:
- Designing, redesigning, polishing, or critiquing a frontend interface
- **Creating a new page, view, component, or UI surface** — even if not explicitly asked to polish
- Making UI feel less "AI-generated" or more distinctive
- UI audit (`/impeccable audit`), polish pass (`/impeccable polish`), typography fix (`/impeccable typeset`)
- Removing AI slop patterns detected during review
- Visual iteration in the browser (`/impeccable live`)
- Any task where "this looks generic / templated / bland" is the problem

When `impeccable` is loaded, jigs MUST:
1. Run `node .kiro/skills/impeccable/scripts/context.mjs` once at session start (loads PRODUCT.md, DESIGN.md, surface brief)
2. Use the appropriate command from the Commands table in the SKILL.md
3. Run the detector after UI edits: `npx impeccable detect <path>` to catch anti-patterns before reporting done

Load `frontend-design` when the task specifically concerns:

- Establishing or improving the visual character of a UI
- Typography pairing and type scale decisions
- Color palette and visual hierarchy
- Layout composition and spatial design
- Making UI feel distinctive rather than templated
- Design direction for new pages, features, or components where aesthetics are the primary concern
- Redesigning existing UI with a clear visual improvement goal
- Any task where "what should this look like?" is the core question

**Do NOT load** `frontend-design` for:

- Tasks where the visual direction is already established and the work is implementation only
- Backend, database, API, or infrastructure work
- Performance, accessibility, or interaction audits (use `qa-audit` instead)
- Component API design (use `building-components` instead)
- General bug fixes or refactors without a design intent
- Tasks that mention "design" only incidentally

**Load order when combined with other skills:**

- Visual design + component work: load `frontend-design`, then `building-components`
- Visual design + frontend implementation: load `frontend-design`, then `react-typescript`, `vercel-react-best-practices`, `frontend-ui-engineering`
- Visual design + audit: load `frontend-design`, then `qa-audit`

`frontend-design` provides aesthetic direction and design judgment. It is always subordinate to explicit project design decisions in `DESIGN.md` and any established UHRIS visual language. Use it to inform judgment, not to override existing decisions.

---

## Design Review and Second-Opinion Tasks

If the task involves reviewing a plan, design, or implementation for correctness and catching issues before they compound, load:

1. `rubber-duck`

Load `rubber-duck` when the task specifically concerns:

- Reviewing a plan before implementing it ("does this approach make sense?")
- Getting a second opinion on a design decision or architecture choice
- Sanity-checking an implementation mid-progress
- Identifying potential issues, pitfalls, or trade-offs the author may have missed
- Pre-flight checks before writing code on a non-trivial change
- Any prompt containing: review, critique, second opinion, "does this look right", "any issues", "sanity check", "will this work", "better approach", "what could go wrong", "am I missing anything"

**Do NOT load** `rubber-duck` for:

- Standard implementation tasks with no explicit review request
- Bug fixes where the problem and fix are already clear
- Tasks where the user is asking for implementation, not critique
- QA audits of completed code (use `qa-audit` instead)

**Load order when combined with other skills:**

- Design review + frontend: load implementation skills first, then `rubber-duck` at the end
- Design review + backend: load implementation skills first, then `rubber-duck` at the end
- Design review only (no implementation): load `rubber-duck` alone

`rubber-duck` launches a critic subagent with a complementary model (Claude Opus 4.7 when running on Sonnet) to provide an outside perspective. It categorizes findings as Blocking, Non-Blocking, or Suggestion. It does NOT comment on style, formatting, or trivial matters.

---

## Plan Review Tasks

If the task involves reviewing an implementation plan before coding starts, load:

1. `review-plan`

Load `review-plan` when the task specifically concerns:

- "Review the plan", "check my plan", "is this plan ready", "any issues with this approach"
- After a plan has been produced but before implementation begins
- Stress-testing feasibility, sequencing, completeness, and scope

`review-plan` fans out parallel subagents across: Completeness, Grounding, Sequencing, Scope, Verification, Risk.

**Do NOT load** `review-plan` for standard implementation tasks with no explicit plan-review request.

---

## Post-Implementation Code Review Tasks

If the task involves reviewing completed code before pushing or merging, load:

1. `review-areas`

Load `review-areas` when the task specifically concerns:

- "Review my code", "code quality check", "review before pushing", "in-depth review"
- After implementing a non-trivial feature or bug fix
- Pre-merge quality gate

`review-areas` fans out parallel subagents across: Correctness, Tests, Security, Performance, Product.

**Do NOT load** `review-areas` for: planning tasks, explaining existing code, or simple bug fixes where the change is already verified.

---

## Prompt Engineering Tasks

If the task involves writing, fixing, improving, or adapting a prompt for an AI tool, load:

1. `prompt-master`

Load `prompt-master` when the task specifically concerns:

- "Write me a prompt for [tool]"
- "Fix this prompt / improve this prompt"
- "I need a prompt for Claude Code / Cursor / Midjourney / etc."
- "Help me write a better prompt"
- "Adapt this prompt for [different tool]"
- Breaking down or decompiling an existing prompt

**Do NOT load** `prompt-master` for:

- General coding or implementation tasks
- Tasks where you are building something, not writing a prompt
- Feature requests, bug fixes, or code reviews

---

If a task initially targets one layer but expands to include another during implementation or review:

- Detect the new scope automatically.
- Immediately load any newly applicable skills.
- Continue using guidance from all loaded skills.
- Do not ask for confirmation.

---

## Feature Intake Tasks

If the user's request is a vague or high-level feature request that needs scoping before implementation, load:

1. `feature-intake`

Load `feature-intake` when the task specifically concerns:

- "Make a feature for X", "add X to the app", "build X", "I want X functionality"
- Any request where the scope, requirements, or acceptance criteria are not yet defined
- Any request that would benefit from clarifying questions before a single file is touched

**Do NOT load** `feature-intake` for:

- Bug fixes where the problem is already clear
- Refactors with a defined scope
- Small changes where the intent is unambiguous
- Tasks that already include a spec or acceptance criteria

`feature-intake` reads memory and codebase context first, then asks targeted clarifying questions, then produces a spec and dispatches to the right agent(s). No code is written until consensus is reached.

---

## Skill Locations

Skills are installed in `.kiro/skills/` in this workspace:

- `i-have-adhd` ← always-on
- `react-typescript`
- `vercel-react-best-practices`
- `frontend-ui-engineering`
- `building-components`
- `frontend-design`\n- `impeccable`\n- `better-ui`
- `better-typography`
- `rubber-duck`
- `review-plan`
- `review-areas`
- `feature-intake`
- `backend-patterns`
- `nodejs-backend-patterns`
- `nestjs-best-practices`
- `qa-audit`
- `debug`
- `prompt-master`

## QA Agent — Andrei

For full verification of a completed implementation, dispatch to the **andrei** agent rather than loading skills inline. Andrei runs the complete stack:

1. TypeScript check (`tsc --noEmit`)
2. Unit tests for affected files
3. API endpoint tests
4. Playwright UI verification
5. axe accessibility scan
6. PostgreSQL DB state verification
7. Hypothesis-driven debug (via `debug` skill) when a bug can't be diagnosed statically
8. 12-dimension `qa-audit` structured report
9. Final verdict: Ready / Needs Changes / Blocked

**Dispatch andrei when:**
- "verify this feature"
- "QA this"
- "run the tests"
- "does this work?"
- "run playwright / a11y"
- After jigs/ogie/john complete an implementation and you need a full verification pass

**Do NOT dispatch andrei for:**
- Code review of a diff (use `review-areas` instead)
- Pre-implementation plan review (use `review-plan` instead)
- Static code audit without running anything (use `qa-audit` skill directly)


---

## Council Workflow

The full lifecycle every non-trivial feature follows. These rules are enforced in dev.json and feature-intake SKILL.md.

```
feature-intake    (scope the "what" → spec → tests/specs/<slug>.md)
        ↓
adam  (investigate the "how" before any implementation agent touches code)
        ↓
todo_list dispatch sequencer: john → ogie → jigs
        ↓
semantic_reviewer (mandatory behavioral diff review)
        ↓
andrei            (full verification against spec acceptance criteria)
        ↓
Ready  → post-feature memory write (feature:<slug> entity in memory MCP)
Blocked → route findings back to responsible agent, re-dispatch andrei
```

### When to dispatch semantic_reviewer

Run `semantic_reviewer` on the git diff after all implementation agents finish, before andrei. Mandatory for non-trivial changes.

### When to dispatch adam

Before dispatching any implementation agent on code you haven't read in this session. Treat its output as your file reads.

### Spec file convention

- Written by `feature-intake` Phase 4 to `tests/specs/<slug>.md`
- Every specialist agent (jigs/ogie/john) reads it when provided as task context
- andrei verifies every acceptance criteria checkbox against it
- Spec checkboxes are updated and memory is written when andrei returns Ready


---

## Code Review Skills

### council-review — Multi-model code review (install: `council-review`)

**USE FOR:** "review this diff with multiple models", "cross-model review", "get consensus on this change", "review after non-trivial development"
**DO NOT USE FOR:** planning, implementation, explaining existing code

The `council-review` skill dispatches the same diff to three independent models (GPT-5.5, Claude Opus 4.6, GPT-5.3-Codex). Each reviews independently. The orchestrator synthesizes:
- **Consensus findings** — flagged by 2+ models = high confidence
- **Single-model, strongly evidenced** — one model, concrete evidence
- **Contested** — models disagree, surface for caller judgment

Load via: `disclose_context('council-review')`

The `semantic_reviewer` agent loads this automatically in Phase 3 of its workflow.

---

### council-plan — Multi-model implementation planning (install: `council-plan`)

**USE FOR:** "plan with multiple models", "get different perspectives on this approach", "multi-model architecture decision"
**DO NOT USE FOR:** "review a diff", "quick factual question"

The `council-plan` skill dispatches the same task to three independent models. Each independently researches the codebase and proposes an implementation plan. The orchestrator synthesizes:
- **Consensus approach** — what 2+ models agree on = backbone of the plan
- **Alternatives** — different viable approaches with trade-offs
- **Consensus risks** — risks flagged by 2+ models independently

Load via: `disclose_context('council-plan')`

---

## Skill Locations

Skills are installed in `.kiro/skills/` in this workspace:

- `i-have-adhd` ← always-on
- `react-typescript`
- `vercel-react-best-practices`
- `frontend-ui-engineering`
- `building-components`
- `frontend-design`\n- `impeccable`\n- `better-ui`
- `better-typography`
- `rubber-duck`
- `review-plan`
- `review-areas`
- `council-review`
- `council-plan`
- `feature-intake`
- `backend-patterns`
- `nodejs-backend-patterns`
- `nestjs-best-practices`
- `qa-audit`
- `debug`
- `prompt-master`
