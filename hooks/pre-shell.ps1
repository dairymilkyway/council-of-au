$stdinData = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Extract the command being run
$cmd = ""
if ($stdinData.tool_input.command) { $cmd = $stdinData.tool_input.command }
if ($stdinData.tool_input.cmd)     { $cmd = $stdinData.tool_input.cmd }
$cmdLower = $cmd.ToLower().Trim()

# Hard-block: destructive patterns — require explicit user approval
$blocklist = @(
  'rm\s+-rf?\s+/',
  'rm\s+-rf?\s+\.',
  'rm\s+--force',
  'rmdir\s+/s',
  'del\s+/[sf]',
  'format\s+[a-z]:',
  'rd\s+/s',
  'git\s+push\s+.*--force',
  'git\s+push\s+.*-f\b',
  'git\s+reset\s+--hard',
  'git\s+clean\s+-[ffdx]*d',
  'git\s+branch\s+-[dD]\s+main',
  'git\s+branch\s+-[dD]\s+master',
  'git\s+rebase\s+.*--force',
  'drop\s+database',
  'drop\s+table',
  'drop\s+schema',
  'truncate\s+table',
  'delete\s+from\s+',
  'prisma\s+migrate\s+reset',
  'prisma\s+db\s+push\s+.*--force-reset',
  'kill\s+-9\s+1\b',
  '\bshutdown\b',
  '\breboot\b',
  'taskkill\s+/f\s+/im',
  'npm\s+publish\s+.*--force',
  'npm\s+unpublish',
  'npx\s+.*--yes\s+rm'
)

$blocked = $false
$matchedPattern = ""
foreach ($pattern in $blocklist) {
  if ($cmdLower -match $pattern) {
    $blocked = $true
    $matchedPattern = $pattern
    break
  }
}

if ($blocked) {
  Write-Output "SHELL-BLOCKED: This command matches a destructive pattern and requires explicit user approval."
  Write-Output "Command:  $cmd"
  Write-Output "Pattern:  $matchedPattern"
  Write-Output "STOP and ask the user before running this command."
  exit 1
}


# Shell-write ban: writing source files via shell bypasses pre-write ban rules
$shellWritePatterns = @(
  'Out-File\s+.*\.(ts|tsx|js|jsx|prisma)\b',
  'Set-Content\s+.*\.(ts|tsx|js|jsx|prisma)\b',
  'Tee-Object\s+.*\.(ts|tsx|js|jsx|prisma)\b',
  '>\s+.*\.(ts|tsx|js|jsx|prisma)\b'
)

foreach (\$swp in \$shellWritePatterns) {
  if (\$cmdLower -match \$swp) {
    Write-Output "SHELL-WRITE-BLOCKED: Writing source files via shell bypasses pre-write ban rules. Use the write tool for source file writes."
    exit 1
  }
}

# Git hygiene soft-warns
if ($cmdLower -match "git\s+add\s+(-a|--all|\.)") {
  Write-Output "GIT-NOTE: git add -A stages everything. Prefer staging specific files to avoid committing unrelated changes."
}
if ($cmdLower -match "git\s+commit\s+.*\bmain\b") {
  Write-Output "GIT-NOTE: Committing directly to main detected. Prefer a feature branch."
}

# Soft-warn patterns — proceed but flag prominently
$warnPatterns = @(
  'npm\s+install\s+[^-]',
  'npx\s+prisma\s+migrate\s+dev',
  'git\s+commit',
  'git\s+push\b',
  'npm\s+run\s+build',
  'npm\s+run\s+test:e2e'
)

foreach ($pattern in $warnPatterns) {
  if ($cmdLower -match $pattern) {
    Write-Output "SHELL-NOTE: Running: $cmd (soft-warn pattern '$pattern' matched - proceed, but log this action)"
    break
  }
}

exit 0
