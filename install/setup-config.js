#!/usr/bin/env node
// setup-config.js
// Writes ~/.kiro/council.config.json with the path to this council-of-au repo.
// Run from inside the cloned repo directory: node install/setup-config.js
//
// This config file is read by agents at runtime so they know where to write:
//   - tests/specs/        (spec files)
//   - tests/screenshots/  (andrei screenshots)
//   - semantic-review/    (semantic_reviewer reports)
//
// Run this once after cloning. Re-run if you move the repo.

const fs = require('fs');
const path = require('path');
const os = require('os');

// The council root is the parent of the install/ directory (i.e. repo root)
const councilRoot = path.resolve(__dirname, '..');
const kiroDir = path.join(os.homedir(), '.kiro');
const configPath = path.join(kiroDir, 'council.config.json');

if (!fs.existsSync(kiroDir)) {
  fs.mkdirSync(kiroDir, { recursive: true });
}

const config = {
  councilRoot: councilRoot,
  outputDirs: {
    specs:       path.join(councilRoot, 'tests', 'specs'),
    screenshots: path.join(councilRoot, 'tests', 'screenshots'),
    reviews:     path.join(councilRoot, 'semantic-review')
  }
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8');

console.log('Written: ' + configPath);
console.log('Council root: ' + councilRoot);
console.log('');
console.log('Output directories:');
console.log('  specs:       ' + config.outputDirs.specs);
console.log('  screenshots: ' + config.outputDirs.screenshots);
console.log('  reviews:     ' + config.outputDirs.reviews);
