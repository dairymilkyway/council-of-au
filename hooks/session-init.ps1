$stdinData   = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Compute a per-project temp dir so markers never land inside the project workspace
$cwdBytes  = [System.Text.Encoding]::UTF8.GetBytes($stdinData.cwd)
$cwdHash   = ([System.Security.Cryptography.MD5]::Create().ComputeHash($cwdBytes) | ForEach-Object { $_.ToString('x2') }) -join ''
$markerDir = Join-Path $env:TEMP "kiro-markers\$cwdHash"
$dbMarker    = Join-Path $markerDir '.session-db-touch'
$writeMarker = Join-Path $markerDir '.session-first-write'

# Clear stale markers from prior session
if (Test-Path $dbMarker)    { Remove-Item $dbMarker    -Force -ErrorAction SilentlyContinue }
if (Test-Path $writeMarker) { Remove-Item $writeMarker -Force -ErrorAction SilentlyContinue }

# Detect which agent is spawning
$agentName = ""
if ($stdinData.agentName) { $agentName = $stdinData.agentName.ToLower() }

# Specialists get a scoped init - no orchestration instructions
$specialists = @('jigs', 'ogie', 'john', 'andrei', 'semantic_reviewer', 'adam')
$isSpecialist = $specialists -contains $agentName

if ($isSpecialist) {
  Write-Output @"
=== SESSION START ($agentName) ===

STEP 1 - Call todo_list list to check for an existing task list from this session.

STEP 2 - Call search_nodes on the memory MCP with a topic keyword relevant to
  the task you were given. This restores facts from prior sessions about this
  area of the codebase.
  Use search_nodes, not read_graph. read_graph dumps all entities - too broad.

SCOPE REMINDER: You are $agentName. Stay within your domain.
  - jigs: frontend source tree only. No backend, no schema.
  - ogie: backend source tree only. No frontend, no schema.
  - john: schema, migrations, seed data only. No application source.
  - andrei: verification only. No application code edits.
  - semantic_reviewer: semantic-review/ directory only. No application code edits.
  - adam: read-only. No file writes except the spec file.

=== END SESSION START ===
"@
} else {
  # dev (orchestrator) gets the full init
  Write-Output @"
=== SESSION START - MANDATORY FIRST ACTIONS ===

STEP 1 - CALL todo_list list RIGHT NOW (before anything else):
  todo_list: { "command": "list" }

  If the list is empty but you are mid-feature, recreate it immediately
  and complete the already-done tasks before continuing work.

STEP 2 - CALL search_nodes on the memory MCP with a topic keyword relevant to
  the current task. This restores facts without flooding context with all 40+ entities.
  Use read_graph ONLY when you are fully disoriented (fresh session, no task context,
  after /clear) and search_nodes returns nothing useful.
  Example: search_nodes("employee onboarding") not read_graph.

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

=== END SESSION START ===
"@
}
exit 0
