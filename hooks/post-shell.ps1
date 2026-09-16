$stdinData = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Extract the result from the shell tool output
# Kiro may deliver the shell output in tool_result.content or tool_result.output depending on version
$result = ""
$success = $true
if ($stdinData.tool_result) {
  if ($stdinData.tool_result.content) { $result = $stdinData.tool_result.content }
  elseif ($stdinData.tool_result.output) { $result = $stdinData.tool_result.output }
  if ($null -ne $stdinData.tool_result.success) { $success = $stdinData.tool_result.success }
} else {
  exit 0
}

$resultLower = $result.ToLower()

# ── TypeScript error detection ────────────────────────────────────────────────
# tsc --noEmit exits with code 1 when there are errors; output contains "error TS"
if ($resultLower -match 'error ts\d+' -or ($success -eq $false -and $resultLower -match 'tsc')) {
  $errorCount = ([regex]::Matches($result, 'error TS\d+')).Count
  Write-Output "TSC-FAIL: TypeScript check produced $errorCount error(s). Fix ALL TypeScript errors before writing more files or proceeding. Do NOT continue past failing types."
  exit 0
}

# ── Test failure detection ────────────────────────────────────────────────────
# Jest: "X failed", "Tests: X failed"
if ($resultLower -match '\d+\s+failed' -or $resultLower -match 'tests:\s+\d+\s+failed') {
  Write-Output "TEST-FAIL: Unit tests are failing. Fix the failing tests before proceeding. Do NOT mark this task complete while tests are red."
  exit 0
}

# Playwright: "X failed" in test output
if ($resultLower -match 'playwright' -and $resultLower -match '\d+\s+failed') {
  Write-Output "PLAYWRIGHT-FAIL: Playwright tests are failing. Review the failure output above before proceeding."
  exit 0
}

# ── Build failure detection ───────────────────────────────────────────────────
if ($success -eq $false -and ($resultLower -match 'npm run build' -or $resultLower -match 'vite build')) {
  Write-Output "BUILD-FAIL: Build failed. Fix build errors before continuing."
  exit 0
}

exit 0
