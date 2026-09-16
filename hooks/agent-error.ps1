# agent-error.ps1 — fires on agentError trigger
# Signals to dev that a mid-council agent crashed so the session can be resumed.

$stdinData = [Console]::In.ReadToEnd()
try { $data = $stdinData | ConvertFrom-Json } catch { $data = $null }

$agentName  = if ($data.agentName)  { $data.agentName }  else { "unknown" }
$errorMsg   = if ($data.error)      { $data.error }       else { "no error details" }
$cwd        = if ($data.cwd)        { $data.cwd }         else { "unknown" }

Write-Output @"

=== AGENT ERROR — COUNCIL INTERRUPTED ===

Agent   : $agentName
Error   : $errorMsg
CWD     : $cwd

RECOVERY STEPS:
  1. Call todo_list list to see what tasks remain.
  2. If the list is empty, scan tests/specs/ for the in-progress spec file.
  3. Recreate the todo_list from where work stopped (mark done tasks complete).
  4. Re-dispatch the failed agent with the same task.
  Do NOT start the council over from scratch.

=== END AGENT ERROR ===
"@
exit 0
