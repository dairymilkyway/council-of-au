$stdinData   = [Console]::In.ReadToEnd() | ConvertFrom-Json
$markerDir   = Join-Path $stdinData.cwd '.kiro/hooks'
$dbMarker    = Join-Path $markerDir '.session-db-touch'
$writeMarker = Join-Path $markerDir '.session-first-write'

# Clear stale markers from prior session
if (Test-Path $dbMarker)    { Remove-Item $dbMarker    -Force -ErrorAction SilentlyContinue }
if (Test-Path $writeMarker) { Remove-Item $writeMarker -Force -ErrorAction SilentlyContinue }

Write-Output @"
=== SESSION START - MANDATORY FIRST ACTIONS ===

STEP 1 - CALL todo_list list RIGHT NOW (before anything else):
  todo_list: { "command": "list" }

  If the list is empty but you are mid-feature, recreate it immediately
  and complete the already-done tasks before continuing work.

STEP 2 - CALL read_graph on the memory MCP to restore context.
  This gives you: features in progress, architecture decisions, component API
  facts, bug history, and what was built in prior sessions.

AGENT-OWNERSHIP REMINDER:
  If resuming a council where a specialist (jigs/ogie/john/andrei/semantic_reviewer) was mid-task:
  RE-DISPATCH the specialist - do NOT complete the task yourself.
  Dev is the orchestrator. Specialists own their domains.
  A dropped andrei session = re-dispatch andrei. Never run Playwright or tsc as dev.

STEP 3 - IF MEMORY RETURNED NOTHING OR IS STALE:
  Scan tests/specs/ for any .md files - these are in-progress feature specs.
  If found, read the spec, check which implementation layers are done,
  recreate the todo_list from where work stopped, and continue the council chain.
  Do NOT start over or orchestrate everything yourself - check the spec first.

TODO-LIST RULES (prevent Task N not found errors):
  - NEVER call todo_list create more than once per session.
    Calling create again WIPES the existing list and resets IDs.
    If you already created a list, only use complete and add.
  - Complete tasks IMMEDIATELY after doing the work - do not save up completions.
    If you did tasks 1, 2, 3 in one pass, complete all three right now:
      todo_list complete ["1", "2", "3"]
      context_update: "Brief summary of what was done"
  - context_update is REQUIRED. Empty string = silent failure = task stays incomplete.
  - Task IDs are STRINGS: ["1"] not [1]

MEMORY-PRIME: For today's task, call search_nodes with a topic keyword
  instead of read_graph. read_graph dumps all entities - use it only when you are disoriented
  or resuming from a session clear with no known task context.

=== END SESSION START ===
"@
exit 0
