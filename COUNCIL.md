# Council of Au - Architecture Specification

This document describes the council workflow completely enough that any AI agent
can port it to any tool (Claude Code, Codex CLI, Cursor, Windsurf, etc.).

Read this file, understand the architecture, then implement it in whatever tool
you are currently working in using that tool's native primitives.

---

## What the council is

A multi-agent software development workflow. Seven specialized AI agents chain
together to investigate, implement, review, and verify software features. Each
agent owns a specific domain and never crosses into another agent's domain.

The council exists to solve one problem: AI agents that do everything themselves
produce worse results than AI agents that specialize and check each other's work.

---

## The seven agents

### dev - Orchestrator
The only agent the user talks to directly. Receives requests, decides which
specialists to dispatch, sequences the chain, assembles the final briefing.
Never writes application code directly (except single-line trivial fixes).
Applies "Ponytail discipline" - lazy senior dev, smallest solution that holds,
no unrelated refactors, no speculative abstractions.

### adam - Architect (read-only)
Investigates the codebase before any code is written. Reads memory, traces call
chains, maps permissions, identifies existing patterns, drafts the spec, estimates
complexity. Produces a report that implementing agents act on directly.
Never writes application code - read-only enforced.

### john - Database Engineer
Schema changes, migrations, seed data, SQL queries only.
Never touches application source files (controllers, services, components).

### ogie - Backend Engineer
API endpoints, services, business logic, authorization, DTOs, guards.
Never touches frontend files or schema/migration files.

### jigs - Frontend Engineer
UI components, pages, hooks, styling, accessibility, responsive design.
Never touches backend files or database files.

### semantic_reviewer - Code Reviewer
Reviews the git diff after all implementation agents finish.
Combines: behavioral narrative + parallel area review + multi-model council review
+ 12-dimension audit. Verdict (Ready / Needs Changes / Blocked) is binding.
Writes review reports to semantic-review/ directory.

### andrei - QA Engineer (god-mode)
Last line of defense. Runs: TypeScript compile, unit tests, auth boundary tests
(401/403/isolation), API endpoint probing, Playwright UI verification at 3
breakpoints, accessibility scan, DB state verification, regression sweep,
business logic correctness check, 12-dimension audit.
Verdict (Ready / Ready with Notes / Needs Changes / Blocked) is binding.
Never rubber-stamps. Evidence required for every PASS claim.

---

## The council chain

```
User request
    |
   dev  <-- user always talks to dev
    |
   adam  (investigate - read memory, read code, draft spec to tests/specs/<slug>.md)
    |
   john  (schema changes - only if DB changes needed)
    |
   ogie  (backend API - only if backend changes needed)
    |
   jigs  (frontend UI - only if frontend changes needed)
    |
   semantic_reviewer  (review the git diff - mandatory for non-trivial changes)
    |
   andrei  (full verification - mandatory)
    |
  Ready -> dev writes memory, updates spec, delivers briefing to user
  Blocked -> dev routes findings back to responsible agent, re-dispatches andrei
```

---

## The fix loop

When andrei returns Blocked, dev runs this loop autonomously:

1. Extract specific findings (file, line, description) from andrei's report
2. Dispatch responsible agent (jigs/ogie/john) with ONLY those findings - surgical scope
3. Re-dispatch andrei
4. Repeat until Ready or 5 rounds

After 5 consecutive Blocked rounds on the same finding: dispatch adam to
re-investigate the root cause. The fix strategy was wrong, not just the code.

**semantic_reviewer and the fix loop:**
semantic_reviewer runs ONCE - after all implementation agents finish, before the first andrei dispatch.
On fix-loop iterations 2+, dispatch directly to andrei. Do NOT re-run semantic_reviewer on each fix.

**semantic_reviewer Blocked path (before andrei ever runs):**
If semantic_reviewer returns Blocked or Needs Changes, route findings to the responsible agent
using the surgical dispatch template. After the fix, re-run semantic_reviewer. Only dispatch andrei
once semantic_reviewer returns Ready. This is separate from the andrei fix loop.

The surgical dispatch template (required - prevents overengineering):
```
FIX-LOOP DISPATCH - SURGICAL SCOPE ONLY
Fix ONLY what is listed. Touch ONLY the files and lines mentioned.
Do NOT refactor, extract helpers, or improve anything outside the finding.

FINDINGS FROM ANDREI:
[paste each finding verbatim]
```

---

## The narrative system

Every agent ends its output with a NARRATIVE block. Dev collects all narratives
and assembles a single plain-English briefing for the user when andrei returns Ready.

```
ADAM NARRATIVE:
What I found: [existing code relevant to this feature]
What needs to be built: [gaps]
Approach chosen: [why this approach vs alternatives]
Risk flags: [anything that could go wrong]

JOHN NARRATIVE:
What changed in the database: [tables, columns, indexes]
Why: [what the feature needs from the DB]
Migration safety: [backward-compatibility notes]

OGIE NARRATIVE:
What was built: [endpoints, services, DTOs - file names]
What each endpoint does: [one line per endpoint]
Authorization: [permission required, who can call it]
Edge cases handled: [validation, errors, transactions]

JIGS NARRATIVE:
What was built: [screens, components, flows - file names]
What the user can now do: [plain description of the interaction]
How it connects to the backend: [which endpoints, when called]
States handled: [loading, empty, error, success]

REVIEWER NARRATIVE:
What was reviewed: [files and layers in the diff]
Issues found: [Blocked/Needs Changes findings, or None]
Verdict: [Ready / Needs Changes / Blocked - one sentence why]

ANDREI NARRATIVE:
What was tested: [what ran - tsc, tests, Playwright, a11y, DB state]
Results: [pass counts, failures]
Verdict: [Ready / Ready with Notes / Needs Changes / Blocked - one sentence]
```

Dev's final briefing structure:
```
## Done: [Feature Name]

**What was investigated (adam):** [plain English]
**What changed in the database (john):** [omit if john not dispatched]
**What the backend does now (ogie):** [plain English]
**What the UI looks like now (jigs):** [omit if jigs not dispatched]
**Was the code reviewed?** [reviewer verdict]
**Was it tested?** [andrei verdict]
**Any notes:** [optional]
```

---

## Core agent rules (apply to all agents)

**Fact-checker rule:** When the user makes a factual claim about the codebase,
verify it before acting on it. Never agree and immediately implement - that is
sycophancy. Search first, state what you actually found, then act.

**Existence check:** Before creating anything new, confirm it does not already
exist. Search for the concept in: schema files, controllers/services, shared
components, hooks, utilities. A duplicate is always worse than reusing the original.

**Ponytail discipline:**
- Solve only what was asked. Spec is the contract.
- No speculative abstractions. Build the second use case when it exists.
- No unrelated refactors. Note them, leave them alone.
- No new dependencies without asking.
- Minimal diff. Fewest lines that correctly solve the problem.
- Prefer the boring solution.

**ASCII only:** No em-dashes, smart quotes, or Unicode punctuation in any output.
Use hyphen-minus for dashes, -> for arrows, straight quotes. Unicode punctuation
corrupts JSON config files when re-saved.

**No PowerShell for file writes:** Use the tool's file-write primitive, never
shell redirection or PowerShell cmdlets. PowerShell re-encodes Unicode as mojibake.

**TypeScript gate:** tsc --noEmit must pass before any agent reports done.
Zero errors required. If errors exist: fix them, do not hand back to dev.

---

## Memory system

A persistent knowledge graph stores facts across sessions:
- Component API facts (prop names, valid values, required props)
- Architecture decisions (what was chosen and why)
- Bug history (what broke, root cause, fix applied)
- Feature completion records

Entity naming:
```
project:<slug>     - top-level project
feature:<slug>     - completed feature
decision:<topic>   - architecture decision
bug:<slug>         - bug found and fixed
component:<name>   - component API facts
```

On every session start: read memory before reading any file.
After every feature ships: write a feature:<slug> entity with files changed,
endpoints built, UI built, decisions made, and verification status.

---

## Spec files

Every non-trivial feature gets a spec file at tests/specs/<slug>.md before
any implementation agent touches code. Format:

```markdown
## Feature: [name]

### What it does
[One paragraph, plain English]

### Scope
**Touches:** [list]
**Does NOT touch:** [explicit exclusions]

### Acceptance criteria
- [ ] [observable behavior]
- [ ] [edge case]

### Implementation layers
- **Database:** [john's task]
- **Backend:** [ogie's task]
- **Frontend:** [jigs's task]
```

The spec is the source of truth. Andrei verifies every checkbox before Ready.
Dev checks them off and writes to memory when andrei returns Ready.

---

## Task sequencing

Dev uses a task list to sequence agent dispatches:

```
1. john - schema  (if needed)
2. ogie - backend
3. jigs - frontend
4. semantic_reviewer - diff review
5. andrei - verification
```

Dev owns this list. Subagents (jigs/ogie/john) have their own isolated task
lists internally. Dev marks council tasks complete only after the subagent returns.
Never dispatch the next agent until the current one reports done.

---

## Post-feature completion (Rule 6)

When andrei returns Ready, before delivering the briefing:

1. Write feature:<slug> entity to memory with all narrative data
2. Confirm write succeeded (search for the entity)
3. Check off every acceptance criterion in tests/specs/<slug>.md
4. Append one line to CHANGELOG.md: [date] feature:<slug> - [one sentence]

---

## Porting this council to another tool

The concepts above are tool-agnostic. Here is how they map to common tools:

### Claude Code

| Council concept | Claude Code primitive |
|---|---|
| Agent prompts | `.claude/agents/<name>.md` |
| dev system prompt | `CLAUDE.md` at project root |
| Steering (always-on rules) | `CLAUDE.md` + `CLAUDE.md` in subdirs |
| Skills (loaded on demand) | `/add <file>` or imported context |
| Hooks (fire on events) | Bash scripts via `hooks:` in `.claude/settings.json` |
| Memory | MCP memory server or a `MEMORY.md` file |
| Subagent dispatch | `Task` tool or `/subagent` |

Claude Code is the closest native match. Agent files are markdown.
Hook commands are bash instead of PowerShell.
`CLAUDE.md` replaces the steering + AGENTS.md combination.

### Cursor

| Council concept | Cursor primitive |
|---|---|
| Agent prompts | `.cursor/rules/<name>.mdc` with `alwaysApply: false` |
| Steering (always-on) | `.cursor/rules/council.mdc` with `alwaysApply: true` |
| Skills | `.cursor/rules/<skill>.mdc` triggered by glob patterns |
| Hooks | Not native - use terminal scripts |
| Memory | `MEMORY.md` file read at session start |
| Subagent dispatch | Composer agents (limited) |

Cursor has no native multi-agent dispatch. The council chain runs as a
single Composer session with the council rules injected as always-on rules.

### Codex CLI / OpenAI

| Council concept | Codex primitive |
|---|---|
| Agent prompts | System prompt sections or separate API calls |
| Steering | System prompt |
| Skills | Injected context blocks |
| Hooks | Shell scripts wrapping the CLI |
| Memory | Files read at session start |
| Subagent dispatch | Parallel API calls from an orchestration script |

No native multi-agent support. Simulate with shell scripts that call
the API sequentially: `codex "adam: investigate X" | codex "ogie: implement based on above"`.

### What to tell the agent when porting

Give the agent this file (COUNCIL.md) plus the existing agent prompt files
from `agents/`. Then say:

> "Read COUNCIL.md to understand the council architecture. Read the agent
> prompts in agents/. Now implement this council using [tool]'s native
> primitives. Map each concept using the porting table in COUNCIL.md.
> Write the output files to [target directory]."

The agent prompts are already written - porting is mostly reformatting them
into the target tool's config format and adjusting the hook system.

---

## What each agent reads from AGENTS.md

When running in a project, agents read the project's AGENTS.md to learn
project-specific conventions. The council agents are generic - AGENTS.md
is what makes them project-aware.

Minimum required sections in a project's AGENTS.md:

- Repository layout (directory names for frontend, backend, etc.)
- Stack summary (framework, ORM, component library, etc.)
- Dev server URLs and ports
- Auth credentials and token storage key (for andrei's Playwright tests)
- TypeScript check commands and which tsconfig
- Test runner commands
- Shared component registry (for jigs - what not to recreate)
- Shared service helpers (for ogie - what not to reinvent)
- Permission constants file locations (frontend + backend, must stay in sync)
- Migration pattern (for john - how migrations are run in this project)
