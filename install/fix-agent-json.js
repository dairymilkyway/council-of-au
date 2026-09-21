// fix-agent-json.js - fixes literal control chars and unescaped content in agent JSON prompt values
// Usage: node install/fix-agent-json.js <agent-name>
// Example: node install/fix-agent-json.js jigs
const fs = require('fs');
const agentName = process.argv[2];
if (!agentName) {
  console.error('Usage: node fix-agent-json.js <agent-name>');
  process.exit(1);
}

const path = 'E:/VSC/council-of-au/agents/' + agentName + '.json';
const raw = fs.readFileSync(path, 'utf8');

// The prompt value starts after '"prompt": "' and ends just before '",\n  "model"'
const promptKey = '"prompt": "';
const promptStart = raw.indexOf(promptKey) + promptKey.length;
const promptEnd = raw.indexOf('",\n  "model"');

if (promptStart < promptKey.length || promptEnd < 0) {
  console.error('Could not locate prompt boundaries in ' + path);
  process.exit(1);
}

// Extract the raw (broken) prompt text
const promptRaw = raw.substring(promptStart, promptEnd);

// Build a properly JSON-escaped version using JSON.stringify
const promptEscaped = JSON.stringify(promptRaw).slice(1, -1); // strip outer quotes added by stringify

// Rebuild the file
const before = raw.substring(0, promptStart);
const after = raw.substring(promptEnd); // starts with '",\n  "model"...'
const result = before + promptEscaped + after;

// Validate
try {
  const parsed = JSON.parse(result);
  console.log(agentName + ': Valid JSON. Prompt length: ' + parsed.prompt.length);
  fs.writeFileSync(path, result, 'utf8');
  console.log('Written: ' + path);
} catch (e) {
  console.error(agentName + ': Still invalid: ' + e.message.substring(0, 120));
  process.exit(1);
}
