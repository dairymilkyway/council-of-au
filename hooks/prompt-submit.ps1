$stdinData = [Console]::In.ReadToEnd() | ConvertFrom-Json
$cleanPrompt = $stdinData.prompt -replace '(?s)<HOOK_INSTRUCTION>.*?</HOOK_INSTRUCTION>', ''
$prompt = $cleanPrompt.ToLower()

# ── COUNCIL DISPATCH — checked first, overrides everything else ───────────────
$councilPatterns = @(
  '\buse\s+the\s+council\b',
  '\brun\s+the\s+council\b',
  '\bcouncil\s+this\b',
  '\bwith\s+the\s+council\b',
  '\bthrough\s+the\s+council\b',
  '\bcouncil\s+(it|the\s+feature|the\s+bug|the\s+fix|the\s+task)\b',
  '\bfull\s+council\b',
  '\buse\s+council\b',
  '\brun\s+a\s+council\b',
  '\bcouncil\s+pass\b',
  '\bcouncil\s+workflow\b',
  '\bcouncil\s+on\s+this\b',
  '^\bcouncil\b$'
)

$isCouncilTask = $false
foreach ($cp in $councilPatterns) {
  if ($prompt -match $cp) { $isCouncilTask = $true; break }
}

if ($isCouncilTask) {
  Write-Output @"
COUNCIL-DISPATCH: The user explicitly said to use the council. This is a hard directive.

YOU MUST:
  1. Do NOT implement anything yourself
  2. Do NOT write a single line of application code
  3. Do NOT check the current state yourself -- do NOT read files, do NOT investigate first
  4. Dispatch adam IMMEDIATELY as your FIRST action -- adam owns the investigation
  5. Dispatch the full chain: adam -> john (if needed) -> ogie (if needed) -> jigs (if needed) -> semantic_reviewer -> andrei
  6. Follow council Rules 0-7 without exception

VIOLATIONS (all of these are forbidden before dispatching adam):
  - "Let me check the current state first"
  - "Let me understand the bug first"
  - "Let me look at the code before dispatching"
  - Any self-investigation that delays dispatching adam

The FIRST action is dispatching adam. Everything else comes after.
"@
  exit 0
}

# UI signals — detects fullstack when combined with backend signals
$uiPatterns = @(
  '\bui\b', '\bpage\b', '\bdisplay\b', '\brender\b',
  '\bcomponent\b', '\bfront\b', '\bscreen\b', '\bshowing\b',
  '\bvisual\b', '\blayout\b', '\bview\b', '\bmodal\b',
  '\btable\b', '\bform\b', '\bbutton\b', '\bdashboard\b'
)

# DB signals
$dbPatterns = @(
  '\bprisma\b', '\bmigration\b', '\.prisma\b', 'schema\.prisma',
  '\bforeign\s+key\b', '\bsql\b', '\bpostgres\b', '\btransaction\b'
)

# Backend signals - NestJS/API layer (tightened to avoid false-positives on frontend terms)
# NOTE: \bservice\b now included with negative lookahead (excludes "service worker", "self-service") — "service worker", "self-service" are frontend concepts.
# Use NestJS-specific terms that don't appear in frontend code.
$backendPatterns = @(
  '\bcontroller\b', '\bprovider\b', '\binterceptor\b',
  '\bpipe\b', '\bdto\b', '\bendpoint\b', '\brest\s+api\b',
  '\bnestjs\b', '\bbackend\b',
  '\bmiddleware\b', '\bvalidation\b', '\bpayload\b',
  '\bnot logged\b', '\bnot saved\b', '\bnot recorded\b', '\bnot persisted\b',
  '\bnot appearing\b', '\bnot showing in\b', '\bmissing from\b',
  '\baudit\b', '\brecord not\b', '\bdata not\b',
  '\b@nestjs\b', '\b@injectable\b', '\b@controller\b', '\b@module\b',
  '\bprisma\s+service\b', '\bnest\s+service\b', '\bapi\s+endpoint\b',
  '\bservice(?!\s+worker\b)\b',
  '\bguard\b', '\bauth\s+guard\b', '\bjwt\b', '\bbearer\b',
  '\bapproval\s+(not|fails|fail|broken|button)\b',
  '\bsubmit\s+(not|fails|fail|broken|button)\b',
  '\bsave\s+(not|fails|fail|broken|button)\b',
  '\bapprove\s+(not|fails|fail|broken|button)\b',
  '\bconfirm\s+(not|fails|fail|broken|button)\b'
)

# Bug/fix/verify signals
$bugPatterns = @(
  '\bbug\b', '\bfix\b', '\bbroken\b', '\bnot working\b',
  '\bdoesn.t work\b', '\bissue\b', '\bregression\b',
  '\bwrong\b', '\bincorrect\b', '\bunexpected\b',
  '\bnot showing\b', '\bnot displaying\b', '\bnot loading\b',
  '\bnot saving\b', '\bnot saved\b', '\bnot updating\b', '\bnot updated\b', '\bnot returning\b',
  '\bnot logged\b', '\bnot recorded\b', '\bnot persisted\b',
  '\bnot appearing\b', '\bmissing from\b', '\bnot populate\b',
  '\berror\b', '\bfailing\b', '\bfailed\b', '\bcrash\b'
)

# Rubber-duck signals - plan/design review, pre-flight second opinion, mid-implementation check
# Matches: review requests, "does this look right?", "any issues?", design decisions, approach questions
$rubberDuckPatterns = @(
  '\breview\b', '\bcritique\b', '\bsecond opinion\b',
  '\bdoes this look\b', '\bdoes this make sense\b', '\bdoes this approach\b',
  '\bany issues\b', '\bany problems\b', '\bany concerns\b', '\bany flaws\b',
  '\bcheck my\b', '\bcheck this\b', '\blook at my\b', '\blook over\b',
  '\bwhat do you think\b', '\bthoughts on\b', '\bfeedback on\b',
  '\bpre.?flight\b', '\bbefore (i|we) implement\b', '\bbefore (i|we) build\b',
  '\bwhat.?s wrong with\b', '\bwhy (is|would|might|could) this\b',
  '\bwill this work\b', '\bshould (i|we) (use|do|go with|try)\b',
  '\bbetter approach\b', '\bbetter way\b', '\bdownside\b', '\btrade.?offs?\b',
  '\bpitfall\b', '\bgotcha\b',
  '\bam i missing\b', '\bhave i missed\b', '\bsomething (i.m|i am) missing\b',
  '\bsanity check\b', '\bsound right\b', '\blook right\b', '\bmake sense\b'
)

$isUiSignal = $false
foreach ($p in $uiPatterns) {
  if ($prompt -match $p) { $isUiSignal = $true; break }
}

$isDbTask = $false
foreach ($p in $dbPatterns) {
  if ($prompt -match $p) { $isDbTask = $true; break }
}

$isBackendTask = $false
foreach ($p in $backendPatterns) {
  if ($prompt -match $p) { $isBackendTask = $true; break }
}

$isBugTask = $false
foreach ($p in $bugPatterns) {
  if ($prompt -match $p) { $isBugTask = $true; break }
}

$isRubberDuckTask = $false
foreach ($p in $rubberDuckPatterns) {
  if ($prompt -match $p) { $isRubberDuckTask = $true; break }
}

# Andrei dispatch signals — MUST be evaluated here with all other booleans
# so that the $isBugTask -and -not $isAndreiTask guard works correctly below
$andreiPatterns = @(
  '\bverif(y|ication|ied)\b',
  '\bqa\b',
  '\bplaywright\b',
  '\ba11y\b',
  '\baccessibility\s+(test|check|scan)\b',
  '\btest\s+(this|it|the\s+feature|the\s+implementation)\b',
  '\bdoes\s+(this|it)\s+work\b',
  '\bcheck\s+(if|that|whether)\s+.{3,}(works|correct|passing)\b',
  '\brun\s+(the\s+)?(tests|playwright|a11y|accessibility)\b',
  '\bvalidate\s+(the\s+)?(feature|implementation|endpoint|ui)\b',
  '\bis\s+(this|it)\s+(working|correct|passing)\b',
  '\bpass(ing|es)?\s+(the\s+)?tests\b',
  '\bregression\s+(test|check)\b',
  '\bsmoke\s+test\b',
  '\bend.to.end\s+test\b',
  '\bacceptance\s+(test|criteria)\b'
)

$isAndreiTask = $false
foreach ($p in $andreiPatterns) {
  if ($prompt -match $p) { $isAndreiTask = $true; break }
}

# Feature intake signals — vague/high-level feature requests that need scoping
$featureIntakePatterns = @(
  '\bmake\s+(me\s+)?a\s+feature\b',
  '\badd\s+.{3,}\s+(to|into)\s+(the\s+)?(app|system|project|page|module)\b',
  '\bbuild\s+(me\s+)?(a\s+)?(feature|page|module|screen|flow)\b',
  '\bi\s+want\s+.{3,}\s+(feature|functionality|capability|ability)\b',
  '\bimplement\s+(a\s+)?(feature|functionality)\b',
  '\bcreate\s+(a\s+)?(new\s+)?(feature|page|module|flow|screen)\b',
  '\bnew\s+feature\b',
  '\bfeature\s+(request|for|about)\b'
)

$isFeatureIntake = $false
foreach ($p in $featureIntakePatterns) {
  if ($prompt -match $p) { $isFeatureIntake = $true; break }
}

$output = "PONYTAIL: Apply lazy-senior-dev rules to all files touched by this task. No unrelated refactors.`n"
$output += "TODO-LIST: If you have tasks, call todo_list list NOW before proceeding. If Task N not found errors occur, do NOT retry. Call list, recreate the task list with already-done tasks marked complete, then continue.`n"

if ($isDbTask) {
  $output += "DB-TASK: This task involves database/Prisma work. Use @postgres MCP to verify queries, check schema, validate indexes where relevant.`n"
} elseif ($isBackendTask) {
  $output += "BACKEND-TASK: NestJS/API work. Do NOT invoke PostgreSQL MCP unless schema or query verification is needed.`n"
} else {
  $output += "UI-TASK: Do NOT invoke PostgreSQL MCP. This is pure frontend/logic work.`n"
}

if ($isBugTask -and -not $isAndreiTask) {
  if (($isDbTask -or $isBackendTask) -and $isUiSignal) {
    $output += "BUG-TASK (fullstack): Both layers affected. Run in order: (1) npx tsc --noEmit in both frontend/ and backend/, (2) npm run test:unit in backend/ for affected service, (3) npm run api:test to verify endpoint response, (4) @postgres MCP to confirm DB state if data is involved, (5) Playwright MCP to verify the UI layer reflects the fix. Dev server must be running at localhost:5173 or 5174. SCREENSHOT RULES: always pass scale=css, never fullPage=true. If a screenshot fails with '8000 pixels' error, stop immediately - use browser_snapshot instead. Do NOT retry or loop.`n"
  } elseif ($isDbTask) {
    $output += "BUG-TASK (db): After fixing, run: (1) npx tsc --noEmit in backend/, (2) npm run test:unit for affected service, (3) npm run api:test to verify endpoint, (4) @postgres MCP to confirm DB state is correct.`n"
  } elseif ($isBackendTask) {
    $output += "BUG-TASK (backend): After fixing, follow the backend QA loop: (1) npx tsc --noEmit in backend/, (2) npm run test:unit --testPathPattern=<affected-file> in backend/, (3) npm run api:test to hit the endpoint and verify response, (4) if data is involved use @postgres MCP to confirm DB state.`n"
  } else {
    $output += "BUG-TASK (frontend): After fixing, follow the QA loop: (1) tsc --noEmit check, (2) Playwright MCP: navigate to route, screenshot baseline, interact to reproduce, screenshot result, check console. Dev server must be running at localhost:5173 or 5174. SCREENSHOT RULES: always pass scale=css, never fullPage=true. If a screenshot fails with '8000 pixels' error, stop immediately - use browser_snapshot instead. Do NOT retry or loop.`n"
  }
}

if ($isRubberDuckTask) {
  $output += "RUBBER-DUCK: This task involves reviewing a plan, design, or implementation. Load the rubber-duck skill via disclose_context('rubber-duck') before responding. Use it to run a critic subagent that catches issues before they compound. Best used: after planning but before writing code, or when reviewing partial progress.`n"
}

if ($isFeatureIntake) {
  $output += "FEATURE-INTAKE: This is a vague or high-level feature request. Load the feature-intake skill via disclose_context('feature-intake') BEFORE doing anything else. Read memory and codebase context silently, ask targeted clarifying questions, reach consensus on a spec, then dispatch to the right agent(s). DO NOT write any code until consensus is reached.`n"
}

# Prompt engineering signals
$promptMasterPatterns = @(
  '\bwrite\s+(me\s+)?(a\s+)?prompt\b',
  '\bfix\s+(this|my)\s+prompt\b',
  '\bimprove\s+(this|my)\s+prompt\b',
  '\bbetter\s+prompt\b',
  '\bprompt\s+for\s+(claude|cursor|midjourney|gpt|copilot|stable\s+diffusion|devin|bolt|v0)\b',
  '\badapt\s+(this\s+)?prompt\b',
  '\bprompt\s+master\b',
  '/prompt-master'
)

$isPromptMaster = $false
foreach ($p in $promptMasterPatterns) {
  if ($prompt -match $p) { $isPromptMaster = $true; break }
}

if ($isPromptMaster) {
  $output += "PROMPT-MASTER: This task involves writing or improving a prompt for an AI tool. Load the prompt-master skill via disclose_context('prompt-master') before responding. It will detect the target tool, extract intent, ask at most 3 clarifying questions, and produce an optimized ready-to-paste prompt.`n"
}

# Review signals — post-implementation code review before pushing/merging
$reviewAreasPatterns = @(
  '\breview\s+(my\s+)?(code|changes|implementation|pr|pull\s+request)\b',
  '\bcode\s+(quality|review)\b',
  '\bbefore\s+(i\s+)?(push|merge|commit)\b',
  '\bin.?depth\s+review\b',
  '\bpre.?merge\b',
  '\bready\s+to\s+(push|merge|ship)\b'
)
$isReviewAreas = $false
foreach ($p in $reviewAreasPatterns) {
  if ($prompt -match $p) { $isReviewAreas = $true; break }
}

# Review-plan signals — plan stress-testing before implementation starts
$reviewPlanPatterns = @(
  '\breview\s+(the\s+|my\s+|this\s+)?plan\b',
  '\bcheck\s+(my\s+|the\s+)?plan\b',
  '\bis\s+(this\s+|the\s+)?plan\s+ready\b',
  '\bstress.?test\s+(the\s+)?plan\b',
  '\bany\s+issues\s+with\s+(this|my)\s+(approach|plan|design)\b'
)
$isReviewPlan = $false
foreach ($p in $reviewPlanPatterns) {
  if ($prompt -match $p) { $isReviewPlan = $true; break }
}

# QA audit signals — explicit audit/validation requests
# NOTE: bare \baudit\b is intentionally absent — "audit log feature", "audit trail" are
# backend domain concepts that would false-positive here. Only trigger on qualified phrases.
$qaAuditPatterns = @(
  '\bqa\s+(check|review|validation)\b',
  '\bvalidate\s+(the\s+)?(implementation|feature|changes)\b',
  '\bsecurity\s+(review|audit|check)\b',
  '\bperformance\s+(review|audit|check)\b',
  '\baccessibility\s+(review|audit|check)\b',
  '\bcode\s+audit\b',
  '\brun\s+(a\s+)?(full\s+)?audit\b'
)
$isQaAudit = $false
foreach ($p in $qaAuditPatterns) {
  if ($prompt -match $p) { $isQaAudit = $true; break }
}

if ($isReviewAreas -and -not $isRubberDuckTask) {
  $output += "REVIEW-AREAS: This looks like a post-implementation code review request. Load the review-areas skill via disclose_context('review-areas') to fan out parallel subagents across Correctness, Tests, Security, Performance, and Product areas.`n"
}

if ($isReviewPlan) {
  $output += "REVIEW-PLAN: This looks like a plan review request. Load the review-plan skill via disclose_context('review-plan') to stress-test the plan across Completeness, Grounding, Sequencing, Scope, Verification, and Risk before any code is written.`n"
}

if ($isQaAudit) {
  $output += "QA-AUDIT: This looks like a validation or audit request. Load the qa-audit skill via disclose_context('qa-audit') to perform a structured review across correctness, architecture, security, performance, and maintainability dimensions.`n"
}

if ($isAndreiTask -and -not $isQaAudit -and -not $isRubberDuckTask) {
  $output += "ANDREI-DISPATCH: This looks like a verification or QA request. Dispatch to the andrei agent for the full verification stack: TypeScript check, unit tests, endpoint tests, Playwright UI verification, axe a11y scan, DB state validation, and 12-dimension code audit.`n"
  $output += "SEMANTIC-REVIEWER-GATE: Before dispatching andrei, confirm semantic_reviewer has already run on the diff this session. If not, dispatch semantic_reviewer FIRST, then andrei. semantic_reviewer catches logic/security/architecture issues that andrei's runtime tests cannot.`n"
}

# Post-council correction detection
# Fires when: spec files exist in the council specs dir (council ran previously)
# AND the prompt sounds like a correction/complaint rather than a new council trigger
$councilSpecsDir = ""
$councilConfigPath = Join-Path $env:USERPROFILE ".kiro\council.config.json"
if (Test-Path $councilConfigPath) {
  try {
    $councilConfig = Get-Content $councilConfigPath -Raw | ConvertFrom-Json
    $councilSpecsDir = $councilConfig.outputDirs.specs
  } catch { }
}

$hasSpecFiles = $false
if ($councilSpecsDir -and (Test-Path $councilSpecsDir)) {
  $specFiles = Get-ChildItem $councilSpecsDir -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne ".gitkeep" }
  $hasSpecFiles = $specFiles -and $specFiles.Count -gt 0
}

$postCouncilCorrectionPatterns = @(
  '\bstill\s+(broken|wrong|not\s+working|failing|off)\b',
  '\b(its|it.s|the)\s+(still|not|wrong|broken)\b',
  '\b(button|form|modal|table|page|screen|field|input|dropdown|error|data|endpoint|api|response)\s+(is\s+)?(wrong|broken|missing|not|still|off)\b',
  '\bnot\s+(saving|loading|showing|working|displaying|updating|returning|appearing)\b',
  '\bshould\s+(be|show|display|return|save|load|work)\b',
  '\bsupposed\s+to\b',
  '\b(something|this|that)\s+is\s+(still\s+)?(wrong|off|broken|not\s+right)\b',
  '\b(fix|change|update|correct)\s+(this|the|it|that)\b',
  '\bwhy\s+(is|does|isn.t|doesn.t)\b',
  '\bnot\s+right\b'
)

$isPostCouncilCorrection = $false
if (-not $isCouncilTask) {
  foreach ($pcp in $postCouncilCorrectionPatterns) {
    if ($prompt -match $pcp) { $isPostCouncilCorrection = $true; break }
  }
}

if ($isPostCouncilCorrection -and $hasSpecFiles) {
  $output += @"
POST-COUNCIL-LOCK: A council has previously run (spec files detected in council tests/specs/). The trivial exception is SUSPENDED.

Do NOT self-fix. Do NOT write a single line of application code.

Classify the finding and dispatch the right specialist:
  - Frontend (UI, button, form, style, React) -> dispatch jigs
  - Backend (API, data, endpoint, service)    -> dispatch ogie
  - Database (schema, migration, seed)        -> dispatch john
  - Cause unclear                             -> dispatch adam first

Use the SURGICAL DISPATCH TEMPLATE from Rule 5a. After the specialist fixes it, re-dispatch andrei.
"@
}

Write-Output $output
exit 0
