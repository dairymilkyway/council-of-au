---
title: QA bug verification workflow
inclusion: always
---

# QA Bug Verification Workflow

**On-demand, not pre-made.** When a bug is reported, I fix it and verify it live.
No spec files are written upfront - only after a fix, and only if the bug is
worth locking in as a regression guard.

---

## Andrei is the QA authority

For any non-trivial verification task, dispatch the **andrei** agent. Andrei runs the full god-mode stack:
- TypeScript compile check
- Unit tests on changed files
- Auth boundary tests (401 unauthenticated, 403 wrong role, cross-employee isolation)
- API endpoint tests with boundary value probing
- Playwright UI verification (3 breakpoints, auth-injected, error/empty state forcing)
- Accessibility scan
- DB state verification
- Regression sweep on adjacent features
- Business logic correctness check
- 12-dimension qa-audit
- Regression test writing after bug fixes
- Risk scoring on every verdict

Dispatch andrei when the user says "verify this", "QA this", "run the tests", "does this work", or after any non-trivial implementation.

---

## Frontend Bug Loop (dev/kiro direct - quick fixes only)

### When reported
You describe it naturally:
> "The modal backdrop click isn't closing it"
> "Dropdown stays open after selecting"
> "ConfirmAction button not disabled while submitting"

I will:
1. Read the relevant source file(s)
2. Fix the code
3. `tsc --noEmit --project frontend/tsconfig.app.json` - zero errors
4. Playwright MCP: authenticate, navigate, screenshot, interact, screenshot, console check
5. Report back with screenshot evidence

### Playwright auth (ALWAYS before navigating)

Before navigating to any route, inject the auth token or the page will redirect to /login:

```
Step 1 - Get token:
POST http://localhost:3000/api/v1/auth/login
body: { "email": "superadmin@diwa.hris.local", "password": "DiwaPhase1!" }

Step 2 - Set browser origin:
browser_navigate -> http://localhost:5173

Step 3 - Inject token:
browser_evaluate -> sessionStorage.setItem('rbac-auth-token', 'TOKEN_HERE')

Step 4 - Navigate to target route:
browser_navigate -> http://localhost:5173/<route>
```

### Screenshot guardrail - MUST follow every time
- Always pass `scale: "css"` to `browser_take_screenshot`. Never omit it.
- Always pass `filename: "tests/screenshots/<route>-<descriptor>.png"` - never let screenshots land in the workspace root.
- Never pass `fullPage: true`. Viewport-only screenshots are always sufficient.
- If a screenshot call returns the **"image dimensions exceed 8000 pixels"** error,
  **stop immediately** - do NOT retry the screenshot. Switch to `browser_snapshot`
  (accessibility tree) for the remaining verification steps instead.
- Do not loop or retry screenshot calls more than once.

### Playwright MCP sequence
```
browser_navigate -> http://localhost:5173/<route>  (after auth inject above)
browser_take_screenshot  scale="css"  filename="tests/screenshots/<route>-baseline.png"
browser_click / browser_type                   (reproduce)
browser_take_screenshot  scale="css"  filename="tests/screenshots/<route>-after-fix.png"
browser_console_messages                       (no JS errors)
```

For accessibility behavior:
```
browser_evaluate  → check aria-expanded, aria-selected via DOM
browser_press_key → Tab, Escape, ArrowDown
browser_take_screenshot  scale="css"
```

If any screenshot fails with the 8000 px error, use `browser_snapshot` instead
and continue — do not retry or loop.

### After verification passes
- `"write the spec"` → I write `tests/regression/<component>-<slug>.spec.ts`
- `"skip the spec"` → move on

### Frontend regression spec template
```typescript
// tests/regression/<component>-<slug>.spec.ts
import { test, expect } from '@playwright/test';

test('regression: <exact description of what broke>', async ({ page }) => {
  await page.goto('/<route>');
  await page.click('...');
  await expect(page.locator('...')).toBeVisible();
});
```
Run: `npx playwright test --grep "<slug>"` from root `e:\VSC\Happy`

---

## Backend Bug Loop

### When reported
> "The auth guard is returning 401 for valid tokens"
> "Leave balance endpoint returning wrong data"
> "ConfirmAction approval not saving to DB"

I will:
1. Read the relevant controller/service/guard file(s)
2. Fix the code
3. `npx tsc --noEmit` in `backend/` — zero errors
4. `cd backend && npm run test:unit -- --testPathPattern=<affected-file>`
5. `npm run api:test` — hit the endpoint, verify response shape/status
6. `@postgres MCP` if DB state needs confirming
7. Report back with test output + response evidence

### After verification passes
- `"write the spec"` → I write the appropriate spec:
  - Unit-level: `backend/src/<module>/<service>.spec.ts`
  - E2E-level: `backend/test/e2e/<module>-<slug>.e2e-spec.ts`
- `"skip the spec"` → move on

### Backend regression spec templates

**Unit (service/guard logic):**
```typescript
// backend/src/<module>/<service>.spec.ts
describe('<ServiceName>', () => {
  it('regression: <what broke>', async () => {
    // arrange
    // act
    // assert
  });
});
```

**E2E (endpoint behavior):**
```typescript
// backend/test/e2e/<module>-<slug>.e2e-spec.ts
describe('<endpoint>', () => {
  it('regression: <what broke>', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/<route>')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(response.body).toMatchObject({ ... });
  });
});
```

Run unit: `cd backend && npm run test:unit`
Run e2e: `cd backend && npm run test:e2e`

---

## Running the full test suites

### Frontend a11y suite (root)
```bash
cd frontend && npm run dev    # dev server first
# then from root:
npm run test:a11y             # WCAG scan all routes
npm run test:regression       # all regression specs
npm run test:report           # HTML report
```

### Backend test suite
```bash
cd backend
npm run test:unit             # all unit tests
npm run test:e2e              # all e2e tests
npm run test:all              # everything
```

---

## Component checklists (frontend verification reference)

### Modal / Dialog / Drawer / ConfirmAction
- Opens on trigger, closes on x / Escape / backdrop
- Focus trapped inside while open, returns to trigger on close
- Body scroll locked while open

### Dropdown / Menu / Combobox / Select
- Opens on click, closes on outside click / Escape / selection
- Keyboard: ArrowDown/Up navigates

### Tabs / Accordion
- Active state changes on click
- Keyboard navigation works
- Disabled items non-interactive

### Form inputs
- Controlled value updates on change
- Error state shows helper text
- Disabled prevents interaction

### Pagination / Stepper / Breadcrumb
- Navigation correct, boundaries disabled
- Current item indicated via aria-current

### Package Test (import surface)
- Route: `/ui-library/package-test`
- No white-screen, no console errors
- All 20+ TestSection headings visible
