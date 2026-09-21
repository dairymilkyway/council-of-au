// fix-playwright-mcp.js
// Adds --output-dir to the Playwright MCP server config so its internal
// .playwright-mcp session files go to the council-of-au folder instead
// of the project workspace.

const fs = require('fs');
const os = require('os');
const path = require('path');

const settingsPath = path.join(os.homedir(), '.kiro', 'settings', 'mcp.json');
const councilRoot = 'E:\\VSC\\council-of-au';
const outputDir = path.join(councilRoot, 'tests', 'screenshots');

// Read with BOM stripping
let raw = fs.readFileSync(settingsPath, 'utf8');
if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);

const j = JSON.parse(raw);

if (!j.mcpServers || !j.mcpServers.playwright) {
  console.error('No playwright MCP server found in ' + settingsPath);
  process.exit(1);
}

// Update args to include --output-dir
j.mcpServers.playwright.args = [
  '-y',
  '@playwright/mcp@latest',
  '--output-dir',
  outputDir
];

fs.writeFileSync(settingsPath, JSON.stringify(j, null, 2), 'utf8');
console.log('Updated: ' + settingsPath);
console.log('Playwright MCP output-dir: ' + outputDir);
console.log('\nResult:');
console.log(JSON.stringify(j.mcpServers.playwright, null, 2));
