// update-paths.js
// Updates output directory paths in agent prompts to be relative to the
// council-of-au repo root instead of the project workspace root.
//
// Changes:
//   semantic_reviewer: semantic-review/ (unchanged - already relative, but add mkdir note)
//   andrei:            tests/screenshots/ (unchanged - already relative, but add mkdir note)
//   adam:              tests/specs/ (unchanged - already relative, but add mkdir note)
//
// The KEY change: all three agents now include an explicit instruction to
// treat these paths as relative to the COUNCIL-OF-AU REPO ROOT, not the
// project workspace. Agents should cd to the council root before writing.

const fs = require('fs');
const base = 'E:/VSC/council-of-au/agents/';

function update(agentName, replacements) {
  const path = base + agentName + '.json';
  const j = JSON.parse(fs.readFileSync(path, 'utf8'));
  let p = j.prompt;
  for (const [from, to] of replacements) {
    if (!p.includes(from)) {
      console.warn(agentName + ': could not find: ' + from.substring(0, 60));
      continue;
    }
    p = p.split(from).join(to);
  }
  j.prompt = p;
  fs.writeFileSync(path, JSON.stringify(j, null, 2), 'utf8');
  // verify
  JSON.parse(fs.readFileSync(path, 'utf8'));
  console.log(agentName + ': updated OK');
}

// ── semantic_reviewer ────────────────────────────────────────────────────────
update('semantic_reviewer', [
  [
    'After Phase 7, write the full review report to:\n`semantic-review/YYYY-MM-DD-HHMMSS-<feature-slug>.md`',
    'After Phase 7, write the full review report to:\n`semantic-review/YYYY-MM-DD-HHMMSS-<feature-slug>.md`\n\nThis path is relative to the COUNCIL-OF-AU REPO ROOT (E:/VSC/council-of-au/ or equivalent).\nNot the project workspace. Run `mkdir -p semantic-review` from the council root before writing if needed.'
  ]
]);

// ── andrei ───────────────────────────────────────────────────────────────────
update('andrei', [
  [
    'browser_take_screenshot scale="css" filename="tests/screenshots/<route>-mobile.png"',
    'browser_take_screenshot scale="css" filename="tests/screenshots/<route>-mobile.png"'
  ],
  // The path instructions section
  [
    '### 4e - Screenshot guardrails\n- Always scale="css". Never fullPage=true.\n- If screenshot returns "8000 pixels" error: stop, switch to browser_snapshot, do not retry.',
    '### 4e - Screenshot guardrails\n- Always scale="css". Never fullPage=true.\n- If screenshot returns "8000 pixels" error: stop, switch to browser_snapshot, do not retry.\n- Screenshot path `tests/screenshots/` is relative to the COUNCIL-OF-AU REPO ROOT, not the project workspace.\n- Run `mkdir -p tests/screenshots` from the council root before the first screenshot if needed.'
  ]
]);

// ── adam ─────────────────────────────────────────────────────────────────────
update('adam', [
  [
    'Before writing a new spec, ensure the `tests/specs/` directory exists. Run via shell: `mkdir -p tests/specs` (Mac/Linux) or `New-Item -ItemType Directory -Force -Path tests/specs` (Windows). The write tool does not create missing parent directories - the write will silently fail if the directory is absent.',
    'Spec files live in the COUNCIL-OF-AU REPO ROOT under `tests/specs/`. This is NOT the project workspace - it is the council-of-au directory itself (e.g. E:/VSC/council-of-au/tests/specs/).\nBefore writing a new spec, ensure the directory exists: run `mkdir -p tests/specs` from the council root (Mac/Linux) or `New-Item -ItemType Directory -Force -Path tests/specs` (Windows). The directory is pre-created in the repo so this should only be needed on a fresh clone.'
  ]
]);

console.log('Done.');
