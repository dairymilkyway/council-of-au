$stdinData = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Compute a per-project temp dir so markers never land inside the project workspace
$cwdBytes  = [System.Text.Encoding]::UTF8.GetBytes($stdinData.cwd)
$cwdHash   = ([System.Security.Cryptography.MD5]::Create().ComputeHash($cwdBytes) | ForEach-Object { $_.ToString('x2') }) -join ''
$markerDir = Join-Path $env:TEMP "kiro-markers\$cwdHash"
$markerFile = Join-Path $markerDir '.session-db-touch'

$output = "VERIFY BEFORE DONE:`n- Ponytail: minimal diff, no unrelated changes`n- Build: npx tsc --noEmit passes`n"

if (Test-Path $markerFile) {
  $dbFiles = Get-Content $markerFile -ErrorAction SilentlyContinue
  if ($dbFiles -and $dbFiles.Count -gt 0) {
    $fileList = ($dbFiles | Where-Object { $_ -ne "" }) -join ', '
    $output += "- DB: Migration/query/schema verified via PostgreSQL MCP (files: $fileList)`n"
    $output += "TODO-LIST-CHECKPOINT: Call todo_list list now. If tasks are still open, complete them before this session ends. If the list is empty but work was done, use the recovery procedure in todo-list.md.`n"
  } else {
    # Marker file exists but is empty — DB files were touched but content wasn't written
    $output += "- DB: DB-file marker exists but is empty. If any Prisma/schema files were changed, verify via PostgreSQL MCP.`n"
  }
} else {
  $output += "- DB: Not applicable (no DB code changed)`n"
}


# Memory write reminder
$memoryFile = Join-Path $stdinData.cwd '.kiro/memory.jsonl'
if (Test-Path $memoryFile) {
  $memoryAge = (Get-Date) - (Get-Item $memoryFile).LastWriteTime
  if ($memoryAge.TotalMinutes -gt 30 -or (Test-Path $markerFile)) {
    $output += "MEMORY-WRITE-REMINDER: memory.jsonl has not been updated in 30+ minutes. If this session produced new facts, decisions, or completed features, write them to the memory MCP now.
"
  }
}

# Semantic-review unread report check
# Use council.config.json to find the correct reviews directory (not the project cwd)
$councilConfigPath = Join-Path $env:USERPROFILE '.kiro\council.config.json'
$srDir = if (Test-Path $councilConfigPath) {
  try {
    $councilConfig = Get-Content $councilConfigPath -Raw | ConvertFrom-Json
    $councilConfig.outputDirs.reviews
  } catch {
    Join-Path $stdinData.cwd 'semantic-review'
  }
} else {
  Join-Path $stdinData.cwd 'semantic-review'
}
if (Test-Path $srDir) {
  $recentReports = Get-ChildItem $srDir -Filter '*.md' -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) } |
    Select-Object -ExpandProperty Name
  if ($recentReports) {
    $reportList = $recentReports -join ', '
    $output += "SEMANTIC-REVIEW-UNREAD: Recent review report(s) found in semantic-review/: $reportList. If dev has not yet acted on these findings, read them before ending this session. Unread Blocked findings will be lost.
"
  }
}

Write-Output $output
exit 0
