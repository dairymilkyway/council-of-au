// update-output-paths.js
// Updates adam, andrei, and semantic_reviewer prompts to read
// ~/.kiro/council.config.json to resolve the council root before writing
// to specs, screenshots, or semantic-review directories.

const fs = require('fs');
const os = require('os');
const base = 'E:/VSC/council-of-au/agents/';

function updatePrompt(agentName, find, replace) {
  const path = base + agentName + '.json';
  const j = JSON.parse(fs.readFileSync(path, 'utf8'));
  if (!j.prompt.includes(find)) {
    console.warn(agentName + ': could not find target text');
    return;
  }
  j.prompt = j.prompt.split(find).join(replace);
  fs.writeFileSync(path, JSON.stringify(j, null, 2), 'utf8');
  JSON.parse(fs.readFileSync(path, 'utf8')); // validate
  console.log(agentName + ': updated OK');
}

const CONFIG_READ_INSTRUCTION = `Before writing, resolve the output path:
1. Read \`~/.kiro/council.config.json\` via the shell tool:
   \`cat ~/.kiro/council.config.json\` (Mac/Linux) or \`Get-Content $env:USERPROFILE\\.kiro\\council.config.json\` (Windows)
2. Use the path from \`outputDirs.reviews\` (or \`outputDirs.specs\` / \`outputDirs.screenshots\` as appropriate).
3. If the config file is missing, run \`node install/setup-config.js\` from the council-of-au repo root first.`;

// ── adam: spec path ──────────────────────────────────────────────────────────
updatePrompt('adam',
  'Spec files live in the COUNCIL-OF-AU REPO ROOT under `tests/specs/`. This is NOT the project workspace - it is the council-of-au directory itself (e.g. E:/VSC/council-of-au/tests/specs/).\nBefore writing a new spec, ensure the directory exists: run `mkdir -p tests/specs` from the council root (Mac/Linux) or `New-Item -ItemType Directory -Force -Path tests/specs` (Windows). The directory is pre-created in the repo so this should only be needed on a fresh clone.',
  `Spec files live in the COUNCIL-OF-AU REPO ROOT under \`tests/specs/\` - NOT in the project workspace.\n${CONFIG_READ_INSTRUCTION.replace('outputDirs.reviews', 'outputDirs.specs')}\nThe directory is pre-created in the repo. The absolute path is stored in \`council.config.json\` as \`outputDirs.specs\`.`
);

// ── andrei: screenshot path ──────────────────────────────────────────────────
updatePrompt('andrei',
  '- Screenshot path `tests/screenshots/` is relative to the COUNCIL-OF-AU REPO ROOT, not the project workspace.\n- Run `mkdir -p tests/screenshots` from the council root before the first screenshot if needed.',
  `- Screenshots go to the COUNCIL-OF-AU REPO ROOT \`tests/screenshots/\` - NOT the project workspace.\n- ${CONFIG_READ_INSTRUCTION.replace('outputDirs.reviews', 'outputDirs.screenshots')}\n- The absolute path is in \`council.config.json\` as \`outputDirs.screenshots\`.`
);

// ── semantic_reviewer: report path ───────────────────────────────────────────
updatePrompt('semantic_reviewer',
  'This path is relative to the COUNCIL-OF-AU REPO ROOT (E:/VSC/council-of-au/ or equivalent).\nNot the project workspace. Run `mkdir -p semantic-review` from the council root before writing if needed.',
  `This path is in the COUNCIL-OF-AU REPO ROOT - NOT the project workspace.\n${CONFIG_READ_INSTRUCTION}\nThe absolute path is in \`council.config.json\` as \`outputDirs.reviews\`.`
);

console.log('Done.');
