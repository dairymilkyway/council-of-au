$stdinData = [Console]::In.ReadToEnd() | ConvertFrom-Json
$path = ""
if ($stdinData.tool_input.path) { $path = $stdinData.tool_input.path }

# Compute a per-project temp dir so markers never land inside the project workspace
$cwdBytes  = [System.Text.Encoding]::UTF8.GetBytes($stdinData.cwd)
$cwdHash   = ([System.Security.Cryptography.MD5]::Create().ComputeHash($cwdBytes) | ForEach-Object { $_.ToString('x2') }) -join ''
$markerDir = Join-Path $env:TEMP "kiro-markers\$cwdHash"

# -- PROJECT CONFIGURATION ----------------------------------------------------
# Update these patterns when using this workflow on a new project.
# Everything else in this file is portable as-is.

# Backend source: files that require DB verification after write
$isBackend = $path -match '(backend[/\\]src[/\\]|backend[/\\]prisma[/\\]|\.prisma$|prisma[/\\]migrations[/\\])'

# Frontend source: files that need a TypeScript check reminder after write
$isFrontendSource = $path -match 'frontend[/\\]src[/\\].*\.(tsx?|ts)$'

# Memory-worthy: files whose changes are worth persisting to the memory MCP
$isMemoryWorthy = $path -match '(
  \.service\.ts$|
  \.guard\.ts$|
  \.controller\.ts$|
  \.module\.ts$|
  \.dto\.ts$|
  schema\.prisma$|
  memory\.jsonl$|
  tests[/\\]specs[/\\].*\.md$|
  semantic-review[/\\].*\.md$|
  [/\\]shared[/\\]components[/\\]|
  [/\\]shared[/\\]models[/\\]|
  [/\\]shared[/\\]config[/\\]permissions
)' -replace '\r?\n\s*', ''

# -- END PROJECT CONFIGURATION -------------------------------------------------

$output = "PONYTAIL: Verify this change is minimal and scoped to the task.`n"

if ($isFrontendSource) {
  $output += "TSC-REMINDER: TypeScript file written. Run the project's tsc check (see AGENTS.md) before reporting done.`n"
}

if ($isBackend) {
  $markerFile = Join-Path $markerDir '.session-db-touch'
  New-Item -Path $markerDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
  Add-Content -Path $markerFile -Value $path -ErrorAction SilentlyContinue
  $output += "DB-FILE-MODIFIED: $path - Verify against PostgreSQL MCP: check schema consistency, migration safety, query correctness.`n"
} else {
  $output += "NON-DB-FILE: Skip PostgreSQL MCP verification.`n"
}

if ($isMemoryWorthy) {
  $output += "MEMORY-HINT: $path was modified. If this introduced a new API fact, bug fix, or architecture decision worth knowing next session, save it to the memory MCP now via add_observations or create_entities.`n"
}

Write-Output $output
exit 0
