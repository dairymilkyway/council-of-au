// patch-dev-postcouncil.js
// Adds a post-council lock to dev.json Bug Path section.
// Once a council has run (spec file exists in tests/specs/ or todo_list was created
// this session), the trivial exception is suspended entirely.

const fs = require('fs');
const path = 'E:/VSC/council-of-au/agents/dev.json';
const j = JSON.parse(fs.readFileSync(path, 'utf8'));

const FIND = `**Step 2 - Trivial exception:**
Single-file, single-line, obviously correct fix (e.g. typo, wrong string constant, missing null check): fix directly, run \`tsc --noEmit\`, done.`;

const REPLACE = `**Post-council lock - NON-NEGOTIABLE:**
If a council ran this session (a spec file exists in tests/specs/, OR a todo_list was created with council tasks this session), the trivial exception is **fully suspended**. There is no single-line fix. There is no "I can see the problem clearly". Route every fix - no matter how small it looks - to the responsible specialist.

Why: after a council, the code was touched by a specialist who understands its full context. Dev self-fixing post-council injects untested code that bypasses jigs/ogie/john's domain knowledge, andrei's verification, and semantic_reviewer's review. Even a one-line fix can break an invariant the specialist set up.

**How to tell if a council ran this session:**
- Check \`todo_list list\` - if council tasks are present or were recently completed
- Check if a spec file exists in the council-of-au \`tests/specs/\` directory

**Post-council fix procedure (no exceptions):**
1. Classify the finding (frontend -> jigs, backend -> ogie, DB -> john, unclear -> adam first)
2. Dispatch the specialist using the SURGICAL DISPATCH TEMPLATE from Rule 5a
3. Re-dispatch andrei after the fix
4. If you are tempted to "just fix this one line yourself" - that is the exact failure mode this rule exists to prevent

**Step 2 - Trivial exception (pre-council only):**
Single-file, single-line, obviously correct fix (e.g. typo, wrong string constant, missing null check): fix directly, run \`tsc --noEmit\`, done.
This exception ONLY applies when no council has run this session.`;

if (!j.prompt.includes('Post-council lock')) {
  j.prompt = j.prompt.split(FIND).join(REPLACE);
  if (!j.prompt.includes('Post-council lock')) {
    console.error('FIND text not matched. Aborting.');
    process.exit(1);
  }
  fs.writeFileSync(path, JSON.stringify(j, null, 2), 'utf8');
  JSON.parse(fs.readFileSync(path, 'utf8')); // validate
  console.log('dev.json: post-council lock added OK');
} else {
  console.log('dev.json: already has post-council lock');
}
