// fix-andrei-screenshot-paths.js
// Updates Step 4a in andrei's prompt so the filename= values use the
// absolute path from council.config.json instead of a relative path.
// Also adds the config-read step right before the screenshot block.

const fs = require('fs');
const os = require('os');
const path = require('path');

const repoFile = path.join(__dirname, '..', 'agents', 'andrei.json');
const j = JSON.parse(fs.readFileSync(repoFile, 'utf8'));

const FIND = `### 4a - Baseline render (3 breakpoints)

\`\`\`
browser_resize width=375 height=812
browser_navigate -> frontend URL + route
browser_take_screenshot scale="css" filename="tests/screenshots/<route>-mobile.png"

browser_resize width=768 height=1024
browser_take_screenshot scale="css" filename="tests/screenshots/<route>-tablet.png"

browser_resize width=1280 height=900
browser_take_screenshot scale="css" filename="tests/screenshots/<route>-desktop.png"
\`\`\``;

const REPLACE = `### 4a - Baseline render (3 breakpoints)

Before taking any screenshot, resolve the screenshots directory:
\`\`\`
# Read council config to get absolute screenshots path
cat ~/.kiro/council.config.json   (Mac/Linux)
Get-Content $env:USERPROFILE\\.kiro\\council.config.json   (Windows)
# Use the value of outputDirs.screenshots
# Example: E:\\VSC\\council-of-au\\tests\\screenshots
\`\`\`

Then use that absolute path in every filename= argument:
\`\`\`
browser_resize width=375 height=812
browser_navigate -> frontend URL + route
browser_take_screenshot scale="css" filename="<outputDirs.screenshots>/<route>-mobile.png"

browser_resize width=768 height=1024
browser_take_screenshot scale="css" filename="<outputDirs.screenshots>/<route>-tablet.png"

browser_resize width=1280 height=900
browser_take_screenshot scale="css" filename="<outputDirs.screenshots>/<route>-desktop.png"
\`\`\`

Replace <outputDirs.screenshots> with the actual absolute path from council.config.json.
Never use a relative path like "tests/screenshots/" - it will land in the project workspace.`;

if (!j.prompt.includes(FIND)) {
  console.error('FIND text not matched in andrei prompt');
  process.exit(1);
}

j.prompt = j.prompt.split(FIND).join(REPLACE);

fs.writeFileSync(repoFile, JSON.stringify(j, null, 2), 'utf8');

// Validate
JSON.parse(fs.readFileSync(repoFile, 'utf8'));
console.log('andrei.json updated OK');

// Also update global
const globalFile = path.join(os.homedir(), '.kiro', 'agents', 'andrei.json');
const jGlobal = JSON.parse(fs.readFileSync(globalFile, 'utf8'));
jGlobal.prompt = jGlobal.prompt.split(FIND).join(REPLACE);
fs.writeFileSync(globalFile, JSON.stringify(jGlobal, null, 2), 'utf8');
JSON.parse(fs.readFileSync(globalFile, 'utf8'));
console.log('~/.kiro/agents/andrei.json updated OK');
