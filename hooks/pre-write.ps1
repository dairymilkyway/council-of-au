$stdinData = [Console]::In.ReadToEnd() | ConvertFrom-Json
$path = ""
if ($stdinData.tool_input.path) { $path = $stdinData.tool_input.path }

$markerDir  = Join-Path $stdinData.cwd '.kiro/hooks'
$firstWrite = Join-Path $markerDir '.session-first-write'
$output     = ""

# -- Gate 1: Plan-first reminder on first write of session ---------------------
# Only fires once per session.
# Exception: writing to tests/specs/ is the plan deliverable itself.
if (-not (Test-Path $firstWrite)) {
  New-Item -Path $firstWrite -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
  if ($path -notmatch 'tests[/\\]specs[/\\].*\.md$' -and $path -notmatch '(^|[/\\])semantic-review[/\\]') {
    $output += @"
PLAN-GATE: This is the first file write of this session.
Before writing, confirm ONE of the following:
  (A) A plan / spec was presented in chat and acknowledged -- proceed.
  (B) This change is single-line trivial (qualifies for the Ponytail exception) -- proceed.
  (C) Neither -- STOP. Present the plan first, then write.
Do NOT proceed with option (C). If in doubt, choose (A) and state the plan inline.

"@
  }
}

# -- Gate 2: Skill-load reminder based on file type ---------------------------
# PROJECT-SPECIFIC: Update these three path patterns for each new project.
# Everything else in this file is portable as-is.
#   $isFrontend  -- matches frontend source files
#   $isBackend   -- matches backend source files
#   $isComponent -- matches UI component/library files (subset of frontend)
#
# Default patterns below work for a standard frontend/ + backend/ monorepo layout.
# Adjust the regexes in the section marked "CONFIGURE FOR YOUR PROJECT" if your
# project uses different directory names.

# CONFIGURE FOR YOUR PROJECT: update these three lines
$isFrontend  = $path -match '\.(tsx|jsx)$' -or $path -match '(frontend[/\\]src[/\\])'
$isBackend   = $path -match '(backend[/\\]src[/\\].*\.(ts)$)'
$isComponent = $path -match '([/\\]components[/\\]|[/\\]ui-library[/\\]).*\.(tsx)$'

if ($isFrontend -and -not $isComponent) {
  $output += @"
SKILL-GATE (frontend): Writing to a React/TypeScript file.
Required skills: react-typescript, vercel-react-best-practices, frontend-ui-engineering.
If these were NOT loaded via disclose_context earlier this turn, load them NOW before this write proceeds.

"@
}

if ($isComponent) {
  $output += @"
SKILL-GATE (component): Writing to a UI component file.
Required skills: react-typescript, vercel-react-best-practices, frontend-ui-engineering, building-components.
If these were NOT loaded via disclose_context earlier this turn, load them NOW.

"@
}

if ($isBackend) {
  $output += @"
SKILL-GATE (backend): Writing to a backend source file.
Required skills: backend-patterns, nodejs-backend-patterns, nestjs-best-practices.
If these were NOT loaded via disclose_context earlier this turn, load them NOW.

"@
}

# -- Gate 3: Ban enforcement - project-configurable anti-patterns --------------
# CONFIGURE FOR YOUR PROJECT: add/remove bans as needed.
# Each ban checks the new file content and fires if the pattern matches.
# Add a justification comment near the banned line to override.

$newContent = ""
if ($stdinData.tool_input.content) { $newContent = $stdinData.tool_input.content }
elseif ($stdinData.tool_input.new_str) { $newContent = $stdinData.tool_input.new_str }
elseif ($stdinData.tool_input.text)    { $newContent = $stdinData.tool_input.text }

if ($newContent -ne "") {
  # Ban: Cross-feature imports (frontend only)
  # Features must only import from shared/. Adjust the regex if your shared dir has a different name.
  if ($isFrontend -and $newContent -match "from\s+[`'`"]\.\./((?!shared)[^/`'`"\s]+)/") {
    $matched = $Matches[0]
    if ($newContent -notmatch 'no-cross-feature-import\s+justification:') {
      $output += @"
BAN-BLOCKED (no-cross-feature-import): Cross-feature imports are banned.
  Match: $matched
  Rule: Features must only import from 'shared/'. Import from the correct shared module instead.
  Override: add comment "// no-cross-feature-import justification: <reason>" near the import.

"@
    }
  }

  # Ban: Global state libraries (frontend only)
  # Remove any library that your project explicitly allows.
  if ($isFrontend -and $newContent -match "from\s+[`'`"](@reduxjs/toolkit|react-redux|zustand|jotai|recoil)[`'`"]") {
    if ($newContent -notmatch 'no-global-state\s+justification:') {
      $output += @"
BAN-BLOCKED (no-global-state): Global state libraries are banned.
  Rule: State lives in ViewModel hooks or context only.
  Override: add comment "// no-global-state justification: <reason>" near the import.

"@
    }
  }
}

if ($output -ne "") {
  Write-Output $output
}
exit 0
