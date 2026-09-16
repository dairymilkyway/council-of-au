# council-of-au

A self-adapting AI council workflow for Kiro. Seven specialized agents that work together to investigate, implement, review, and verify software features across any full-stack project.

## What it is

A complete council of AI agents designed for Kiro's multi-agent crew system. Each agent is a specialist. They chain together into a workflow that catches bugs before they ship.

```
feature-intake  (scope the "what")
      |
     adam       (investigate the "how" - read-only architect)
      |
     john       (schema/database changes)
      |
     ogie       (backend API, services, business logic)
      |
     jigs       (frontend UI, components, accessibility)
      |
  semantic_reviewer  (behavioral diff review)
      |
    andrei      (full verification - TypeScript, tests, Playwright, a11y, DB)
      |
   dev / you    (orchestrates the whole chain)
```

## How it self-adapts

The agents do not contain project-specific knowledge. Instead, every agent reads two sources at session start:

1. **`AGENTS.md`** at the workspace root (and `frontend/AGENTS.md`, `backend/AGENTS.md`) - your project's conventions, shared components, API patterns, auth credentials, test commands, tsconfig paths, etc.
2. **Memory MCP** - facts discovered in prior sessions (component API details, architecture decisions, bugs found).

This means the same agent configs work on any project that has a well-written `AGENTS.md`.

## Agents

| Agent | Role |
|---|---|
| `dev` | Orchestrator. Dispatches and sequences the other agents. Ponytail (lazy-senior-dev) discipline. |
| `adam` | Read-only architect. Investigates the codebase, reads memory, drafts the spec. Dispatched before any implementation agent on unfamiliar code. |
| `jigs` | Senior frontend engineer. React, TypeScript, accessibility, responsive design. |
| `ogie` | Senior backend engineer. API, services, business logic, authorization. |
| `john` | Senior database engineer. Schema, migrations, seed data, SQL. |
| `semantic_reviewer` | One Above All code reviewer. Behavioral review + parallel area review + multi-model council review + 12-dimension audit. Verdict is binding. |
| `andrei` | God-Mode QA. TypeScript, unit tests, authorization boundary tests, Playwright, a11y, DB state, regression sweep. Last line of defense. |

## Installation

### Step 1 - Update the hook path for your machine

The agent JSON files contain a placeholder path that must be replaced with your
actual global hooks directory before installing:

```
__KIRO_HOOKS_PATH__
```

Run the appropriate command from inside the cloned repo directory:

**Windows (PowerShell):**
```powershell
$myHookPath = "$env:USERPROFILE\.kiro\hooks"
Get-ChildItem "agents\*.json" | ForEach-Object {
  (Get-Content $_.FullName -Raw) `
    -replace '__KIRO_HOOKS_PATH__\\', ($myHookPath.Replace('\','\\') + '\\') `
  | Set-Content $_.FullName -NoNewline
}
```

**Mac/Linux (bash):**
```bash
HOOK_PATH="$HOME/.kiro/hooks"
for f in agents/*.json; do
  sed -i "s|__KIRO_HOOKS_PATH__/|$HOOK_PATH/|g" "$f"
done
```

### Step 2 - Copy everything to global

```powershell
# Agents
Copy-Item "council-of-au\agents\*.json" "$env:USERPROFILE\.kiro\agents\" -Force

# Skills
Copy-Item "council-of-au\skills\*" "$env:USERPROFILE\.kiro\skills\" -Recurse -Force

# Steering
Copy-Item "council-of-au\steering\*" "$env:USERPROFILE\.kiro\steering\" -Force

# Hooks
New-Item -Path "$env:USERPROFILE\.kiro\hooks" -ItemType Directory -Force | Out-Null
Copy-Item "council-of-au\hooks\*" "$env:USERPROFILE\.kiro\hooks\" -Force
```

### Step 3 - Set up each project

For each project that uses the council, add a `.kiro/mcp.json`:

**Windows:**
```json
{
  "mcpServers": {
    "memory": {
      "command": "powershell",
      "args": ["-NoProfile", "-File", "C:\\Users\\<YOUR_USERNAME>\\.kiro\\hooks\\mcp-memory.ps1"],
      "env": { "MEMORY_FILE_PATH": "C:\\path\\to\\project\\.kiro\\memory.jsonl" }
    },
    "postgres": {
      "command": "powershell",
      "args": ["-NoProfile", "-File", "C:\\Users\\<YOUR_USERNAME>\\.kiro\\hooks\\mcp-postgres.ps1",
               "postgresql://user:pass@localhost:5432/your_db"]
    }
  }
}
```

**Mac/Linux:**
```json
{
  "mcpServers": {
    "memory": {
      "command": "bash",
      "args": ["/home/<YOUR_USERNAME>/.kiro/hooks/mcp-memory.sh"],
      "env": { "MEMORY_FILE_PATH": "/path/to/project/.kiro/memory.jsonl" }
    },
    "postgres": {
      "command": "bash",
      "args": ["/home/<YOUR_USERNAME>/.kiro/hooks/mcp-postgres.sh",
               "postgresql://user:pass@localhost:5432/your_db"]
    }
  }
}
```

Then write `AGENTS.md` at your project root. See `install/AGENTS.md.template` for required sections.

### Option B: Workspace-local (no global install)

Copy everything into `.kiro/` in your project directly. Hook paths stay as `.kiro/hooks/` relative paths - no username substitution needed.

## Project configuration

Three files need project-specific content:

### `hooks/pre-write.ps1`
Find the section marked `CONFIGURE FOR YOUR PROJECT` and update:
- `$isFrontend` - regex matching frontend source files
- `$isBackend` - regex matching backend source files
- `$isComponent` - regex matching UI component/library files

### `hooks/post-write.ps1`
Find the section marked `PROJECT CONFIGURATION` and update:
- `$isBackend` - regex matching backend source files
- `$isFrontendSource` - regex matching frontend TypeScript files
- `$isMemoryWorthy` - regex matching files worth saving to memory

### `AGENTS.md`
See `install/AGENTS.md.template` for all required sections.

## Council workflow

Normal usage (say "use the council"):

1. `dev` receives the request
2. `dev` dispatches `adam` to investigate (never self-investigates)
3. `adam` reads memory, reads relevant code, drafts spec to `tests/specs/<slug>.md`
4. `dev` dispatches `john` (if DB changes needed)
5. `dev` dispatches `ogie` (if backend changes needed)
6. `dev` dispatches `jigs` (if frontend changes needed)
7. `dev` dispatches `semantic_reviewer` on the git diff
8. `dev` dispatches `andrei` for full verification
9. If andrei returns Blocked: dev routes findings back to responsible agent and re-dispatches andrei
10. When andrei returns Ready: dev writes memory, updates spec, appends to CHANGELOG.md, delivers briefing

## What each agent reads from AGENTS.md

- **adam**: project layout, module directories, shared helper locations, seeder location, permission constants file
- **ogie**: backend module structure, shared read/write helpers, auth decorator pattern, audit pattern, transaction pattern, TSC command
- **john**: migration pattern (prisma migrate dev vs raw SQL), seeder pattern, effective-dating helpers if present
- **jigs**: shared component registry, component library API, data flow pattern (ViewModel/hook/component layers), routing pattern, TSC command
- **andrei**: dev server URL, backend URL, auth credentials, token storage key, base API URL, test runner commands, TSC commands

## Hooks

| Hook | What it does |
|---|---|
| `session-init.ps1` | Fires on agent spawn. Reminds agent to call `todo_list list` and `read_graph` first. |
| `prompt-submit.ps1` | Fires on every user message. Detects council/bug/feature/review signals. Routes to correct skill/agent. |
| `pre-write.ps1` | Fires before every file write. Plan-gate, skill-gate, ban enforcement. |
| `post-write.ps1` | Fires after every file write. TSC reminder, DB marker, memory hint. |
| `pre-shell.ps1` | Fires before every shell command. Blocks destructive patterns, warns on risky commands. |
| `post-shell.ps1` | Fires after every shell command. Detects TSC errors, test failures, build failures. |
| `agent-error.ps1` | Fires on agent crash. Emits recovery instructions. |
| `agent-stop.ps1` | Fires on agent stop. Verify-before-done checklist, memory write reminder. |

## Steering files

| File | Inclusion | Purpose |
|---|---|---|
| `todo-list.md` | always | How to use the `todo_list` tool correctly. Prevents serialization errors. |
| `user-input.md` | always | How to use the `user_input` tool for structured questions. |
| `memory.md` | always | When and what to save to the memory MCP. |
| `skill-autoload.md` | always | Which skills to load automatically based on task type. |
| `qa-verification.md` | always | QA bug verification workflow. |

## Skills required

The agents reference these skills from `.kiro/skills/`:

- `i-have-adhd` - response formatting
- `react-typescript` - React 19 + TypeScript patterns
- `vercel-react-best-practices` - performance best practices
- `frontend-ui-engineering` - production-quality UI
- `building-components` - component design
- `better-ui`, `better-typography`, `frontend-design` - visual quality
- `backend-patterns`, `nodejs-backend-patterns`, `nestjs-best-practices` - backend patterns
- `qa-audit` - 12-dimension audit
- `review-areas` - parallel subagent area review
- `council-review` - multi-model code review
- `debug` - hypothesis-driven bug diagnosis
- `feature-intake` - feature scoping
- `rubber-duck` - pre-implementation review
- `impeccable` - UI anti-slop detection

Install skills from the Kiro skills marketplace or copy them from another workspace.
