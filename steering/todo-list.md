---
title: todo_list tool usage
inclusion: always
---

# todo_list Tool - Correct Usage

> [!WARNING]
> **SERIALIZATION TRAP - READ THIS FIRST**
>
> Every array parameter (`completed_task_ids`, `modified_files`, `tasks`) MUST be a JSON array `[...]`.
> Never pass them as objects `{"0":"...", "1":"..."}` -- that causes **`expected array, received string`**.
>
> ```
> WRONG:  completed_task_ids: {"0": "1", "1": "2"}   <- "expected array, received string"
> RIGHT:  completed_task_ids: ["1", "2"]
>
> WRONG:  modified_files: {"0": "src/file.ts"}        <- same error
> RIGHT:  modified_files: ["src/file.ts"]
>
> WRONG:  tasks: {"0": {"task_description": "..."}}   <- same error on create
> RIGHT:  tasks: [{"task_description": "..."}]
> ```
>
> If you see `expected array, received string` -- rewrite the parameter from `{...}` to `[...]`.

The `todo_list` tool manages the task list shown in the Kiro UI. Tasks will NOT update in the UI unless `complete` is called correctly with all required parameters.

## Why tasks don't update

The `complete` command has two parameters that look optional in the schema but are **required at runtime**:
- `completed_task_ids` -- must be a **JSON array of strings** e.g. `["1", "2"]`. Never an object `{"0":"1"}`. Never numbers `[1, 2]`.
- `context_update` -- must be a **non-empty string**. If empty or missing, the complete call silently fails and the task stays incomplete in the UI.

## Correct complete call

```
todo_list:
  command: "complete"
  completed_task_ids: ["1"]           <- string IDs, not numbers
  context_update: "What was done and any key facts discovered."
  modified_files: ["path/to/file.ts"] <- optional but recommended
```

## Rules

1. **Mark tasks complete IMMEDIATELY** after finishing each one -- not all at once at the end.
2. **Always provide `context_update`** with a meaningful description of what was done. Even one sentence is enough. Never pass an empty string.
3. **Task IDs are strings starting at "1"** -- always pass them as strings: `["1"]`, not `[1]`.
4. **One `complete` call can mark multiple tasks** -- pass all completed IDs in the same array: `["1", "2", "3"]`.
5. **`todo_list` state does not persist across turns or re-dispatches** -- the list resets every time the agent session starts fresh.
6. **Never skip `complete`** -- saying "done" in prose does not update the UI. The tool call is required.
7. **CRITICAL -- Never call `todo_list create` more than once per session.** Calling `create` wipes the entire existing list and resets IDs to start from "1". If you already have a list and try to complete task "3" after a `create` call, it will not exist. Create the list ONCE at the start, then only use `complete` and `add`.

## MANDATORY: Call `list` at the start of every session

**Before doing anything else -- before reading files, before planning, before any tool call -- call `list`.**

```
todo_list:
  command: "list"
```

This tells you whether tasks exist from a previous turn. If the list is empty and you know tasks should exist, follow the recovery procedure below.

## Completing multiple tasks in a multi-step job

When you have 5+ tasks and are doing them sequentially, use this pattern to avoid losing the list:

```
WRONG -- completing one at a time across separate calls:
  todo_list complete ["1"]   <- Task 1 done
  [do more work]
  todo_list complete ["2"]   <- Task 2 done
  [do more work]
  todo_list complete ["3"]   <- "Task 3 not found" <- list got wiped

RIGHT -- complete finished tasks in groups immediately after each batch:
  [do tasks 1 and 2]
  todo_list complete ["1", "2"]   <- mark both done in one call, right now
  [do task 3]
  todo_list complete ["3"]        <- mark done immediately after finishing it
  [do tasks 4 and 5]
  todo_list complete ["4", "5"]   <- mark both done together
```

The key: call `complete` **immediately** after each unit of work. Do not save up completions for the end. The longer you wait, the higher the chance the list is gone.

If you finish all work in one pass, complete everything in a single call:
```
todo_list complete ["1", "2", "3", "4", "5"]
  context_update: "All 5 changes applied. [summary]"
```

## Recovery procedure when "Task N not found"

If `complete` fails with "Task N not found", the list was wiped between turns. Do this immediately:

**Step 1 -- Call `list` to confirm the list is empty.**

**Step 2 -- Do NOT retry `complete` with the same ID. It will fail again.**

**Step 3 -- Recreate the task list** from your knowledge of where you are in the workflow:

```
todo_list:
  command: "create"
  task_list_description: "Resuming: [feature name]"
  tasks:
    - task_description: "done jigs -- already done"
    - task_description: "semantic_reviewer -- behavioral diff review"
    - task_description: "andrei -- full verification"
```

Use a "done" prefix for tasks you know are already done.

**Step 4 -- Complete the already-done tasks immediately:**

```
todo_list:
  command: "complete"
  completed_task_ids: ["1"]
  context_update: "jigs already completed before list was wiped. Resuming from semantic_reviewer."
```

**Step 5 -- Continue from where you were.**

This pattern keeps the UI accurate and avoids the crash loop.

## Council dispatch pattern -- critical

When dev dispatches jigs/ogie/john as subagents, each subagent has its own isolated `todo_list`. Dev's council task list and jigs's internal task list are **completely separate**.

**The rule: dev owns the council list. Specialists own their own work list.**

```
dev creates council list:
  [ ] 1. jigs -- implement design
  [ ] 2. semantic_reviewer -- review diff
  [ ] 3. andrei -- verify

dev dispatches jigs (subagent)
  -> jigs creates ITS OWN todo list for its implementation steps
  -> jigs completes its own tasks internally
  -> jigs returns result to dev

dev marks ITS council task complete AFTER jigs returns:
  todo_list complete: ["1"]
  context_update: "jigs finished. Layout updated, TSC clean."

dev dispatches semantic_reviewer...
```

**Never try to complete a council task from inside a subagent.** Only dev can complete items on Dev's list.

## Create a todo list

```
todo_list:
  command: "create"
  task_list_description: "Brief description of the overall goal"
  tasks:
    - task_description: "First step"
      details: "Optional — extra context about this task visible on expand"
    - task_description: "Second step"
    - task_description: "Third step"
```

**`task_list_description` matters** -- this is what appears in the `/todo view` and `/todo resume` menus when users browse their todo lists. Write something recognizable: `"Feature: employee self-service profile edit"` not `"tasks"`.

**`details`** is an optional field per task. Use it for extra context about what the task involves — not required, but useful for complex multi-step tasks so the developer can expand and read what each task entails without reading the whole plan.

## CRITICAL: `tasks` must be a JSON array -- never an object

The single most common failure when creating a task list:

```
WRONG -- tasks as an object with string keys (causes "expected array, received string"):
  tasks: {"0": {"task_description": "First step"}, "1": {"task_description": "Second step"}}

WRONG -- tasks as numbered object:
  tasks: {0: {task_description: "First"}, 1: {task_description: "Second"}}

RIGHT -- tasks as a proper JSON array:
  tasks: [{"task_description": "First step"}, {"task_description": "Second step"}]
```

The same rule applies to `completed_task_ids` and `modified_files` -- they must always be arrays, never objects:

```
WRONG:  completed_task_ids: {"0": "1", "1": "2"}
RIGHT:  completed_task_ids: ["1", "2"]

WRONG:  modified_files: {"0": "src/file.ts"}
RIGHT:  modified_files: ["src/file.ts"]
```

If you ever get "expected array, received string" -- the parameter was passed as an object. Fix by rewriting it as `[...]` not `{...}`.

## Adding tasks to an existing list

Use `add` to append new tasks without recreating the list:

```
todo_list:
  command: "add"
  tasks:
    - task_description: "New task discovered mid-work"
    - task_description: "Another follow-up item"
```

**Never call `create` again** to add tasks -- it wipes the entire list. Only use `add`.

## Removing tasks from a list

Use `remove` to delete tasks that are no longer needed:

```
todo_list:
  command: "remove"
  task_ids: ["3", "4"]
```

Use `remove` when a planned task becomes irrelevant (e.g. a layer was not needed after investigation). Do not leave tasks that will never be completed -- they mislead context.

## What `context_update` and `modified_files` are stored as

These are not just UI metadata -- they are **persisted to disk** in `.kiro/cli-todo-lists/<timestamp-id>.json` alongside the task completion status.

**`context_update`** -- stored per completed task. Kiro reads these when a user runs `/todo resume` to understand where work stopped and what was decided. Write it like a handoff note:

```
GOOD:  "Added POST /api/v1/pis/me/profile-edit-request endpoint. JWT employeeId required.
        Tests: 7/7 pass. TSC clean. ogie done."

BAD:   "done"
BAD:   "completed step 2"
```

**`modified_files`** -- stored as a list of file paths changed during this task. Shown in the resume menu so the developer can see what changed. Include all files you touched:

```
modified_files: [
  "backend/src/modules/pis/pis.controller.ts",
  "backend/src/modules/pis/pis.service.ts",
  "backend/src/modules/pis/dto/create-self-edit.dto.ts"
]
```

## Known limitations (from official docs)

- Cannot manually edit the JSON files in `.kiro/cli-todo-lists/` -- Kiro must make all changes via the tool.
- Cannot merge or split TODO lists.
- Cannot reorder tasks after creation. Plan the order before calling `create`.
- Task IDs are always sequential integers starting at "1" -- they cannot be arbitrary strings.
- No priority, details, subtasks, or dependency fields on tasks.

## User-facing `/todo` commands (for reference)

These are commands the **human user** runs in the Kiro terminal, not the agent. Useful to know when coordinating cross-session recovery:

| Command | What it does |
|---|---|
| `/todo view` | Browse all lists with completion status (done or in-progress with count) |
| `/todo resume` | Interactive menu to reload a list into the current session |
| `/todo clear-finished` | Remove all fully-completed lists from storage |
| `/todo delete` | Delete one list (interactive) or all lists (`--all`) |

**Cross-session recovery scenario:** If a user starts a new Kiro session and `todo_list list` returns empty, they can type `/todo resume` to reload the previous list -- then the agent picks up from where it left off.

## Full command reference

| Command | Required params | Optional params |
|---|---|---|
| `list` | (none) | -- |
| `create` | `task_list_description` (string), `tasks` (array of `{task_description, details?}`) | -- |
| `complete` | `completed_task_ids` (string array), `context_update` (string) | `modified_files` (string array) |
| `add` | `tasks` (array of `{task_description, details?}`) | -- |
| `remove` | `task_ids` (string array) | -- |