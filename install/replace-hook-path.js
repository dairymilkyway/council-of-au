#!/usr/bin/env node
// replace-hook-path.js
// Run from the repo root: node install/replace-hook-path.js
//
// Replaces __KIRO_HOOKS_PATH__ in all agent JSON files with the user's
// actual global hooks directory path.
//
// SAFE: operates on parsed JSON objects, not raw strings.
// This prevents double-escaping backslashes inside JSON string values.
// Do NOT use raw string replace or PowerShell Set-Content for this.

const fs = require('fs');
const path = require('path');
const os = require('os');

const hookPath = path.join(os.homedir(), '.kiro', 'hooks');
const agentsDir = path.join(__dirname, '..', 'agents');
const globalAgentsDir = path.join(os.homedir(), '.kiro', 'agents');

const files = fs.readdirSync(agentsDir).filter(f => f.endsWith('.json'));

console.log('Hook path: ' + hookPath);
console.log('Patching ' + files.length + ' agent files...\n');

for (const file of files) {
  const repoFile = path.join(agentsDir, file);
  const raw = fs.readFileSync(repoFile, 'utf8');

  // Parse as JSON - repo files have __KIRO_HOOKS_PATH__ placeholder which is valid JSON
  let j;
  try {
    j = JSON.parse(raw);
  } catch (e) {
    console.error('  ' + file + ': parse error - ' + e.message.substring(0, 60));
    continue;
  }

  // Replace placeholder in hook action commands (parsed string values - no escaping issues)
  let changed = false;
  j.hooks = j.hooks.map(hook => {
    if (hook.action && hook.action.command && hook.action.command.includes('__KIRO_HOOKS_PATH__')) {
      hook.action.command = hook.action.command.replace(/__KIRO_HOOKS_PATH__/g, hookPath);
      changed = true;
    }
    return hook;
  });

  if (!changed) {
    console.log('  ' + file + ': no placeholder found (already patched or different format)');
  }

  // Write patched version to global with JSON.stringify (handles backslash escaping correctly)
  if (fs.existsSync(globalAgentsDir)) {
    const globalFile = path.join(globalAgentsDir, file);
    fs.writeFileSync(globalFile, JSON.stringify(j, null, 2), 'utf8');

    // Validate
    try {
      JSON.parse(fs.readFileSync(globalFile, 'utf8'));
      console.log('  ' + file + ': patched and copied to global OK');
    } catch (e) {
      console.error('  ' + file + ': global file invalid after write - ' + e.message.substring(0, 60));
    }
  } else {
    console.log('  ' + file + ': global dir not found, skipping copy');
  }
}

console.log('\nDone.');

// Write council.config.json so agents know where the council root is at runtime
require('./setup-config.js');
