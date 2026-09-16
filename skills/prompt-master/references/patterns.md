# Credit-Killing Patterns Reference

37 patterns that waste tokens and cause re-prompts. Read this file when the user pastes a bad prompt and asks you to fix it, or when diagnosing why a prompt is underperforming.

## Task Patterns

| # | Pattern | Bad Example | Fixed |
|---|---------|------------|-------|
| 1 | **Vague task verb** | "help me with my code" | "Refactor `getUserData()` to use async/await and handle null returns" |
| 2 | **Two tasks in one prompt** | "explain AND rewrite this function" | Split into two prompts |
| 3 | **No success criteria** | "make it better" | "Done when the function passes existing unit tests and handles null input" |
| 4 | **Over-permissive agent** | "do whatever it takes" | Explicit allowed + forbidden actions list |
| 5 | **Emotional task description** | "it's totally broken, fix everything" | "Throws uncaught TypeError on line 43 when user is null" |
| 6 | **Build-the-whole-thing** | "build my entire app" | Break into Prompt 1 (scaffold), Prompt 2 (feature), Prompt 3 (polish) |
| 7 | **Implicit reference** | "now add the other thing we discussed" | Always restate the full task |

## Context Patterns

| # | Pattern | Bad Example | Fixed |
|---|---------|------------|-------|
| 8 | **Assumed prior knowledge** | "continue where we left off" | Include Memory Block with all prior decisions |
| 9 | **No project context** | "write a cover letter" | Include role, company type, experience level |
| 10 | **Forgotten stack** | New prompt contradicts prior tech choice | Always include Memory Block |
| 11 | **Hallucination invite** | "what do experts say about X?" | "Cite only sources you are certain of. If uncertain, say so." |
| 12 | **Undefined audience** | "write something for users" | "Non-technical B2B buyers, decision-maker level" |
| 13 | **No mention of prior failures** | (blank) | "I already tried X and it failed because Y. Do not suggest X." |

## Format Patterns

| # | Pattern | Bad Example | Fixed |
|---|---------|------------|-------|
| 14 | **Missing output format** | "explain this concept" | "3 bullet points, each under 20 words" |
| 15 | **Implicit length** | "write a summary" | "Write a summary in exactly 3 sentences" |
| 16 | **No role assignment** | (blank) | "You are a senior backend engineer specializing in Node.js" |
| 17 | **Vague aesthetic adjectives** | "make it look professional" | "Monochrome palette, 16px base font, 24px line height" |
| 18 | **No negative prompts for image AI** | "a portrait of a woman" | Add: "no watermark, no blur, no extra fingers" |
| 19 | **Prose prompt for Midjourney** | Full descriptive sentence | "subject, style, mood, lighting, --ar 16:9 --v 6" |

## Scope Patterns

| # | Pattern | Bad Example | Fixed |
|---|---------|------------|-------|
| 20 | **No scope boundary** | "fix my app" | "Fix only the login form validation in src/auth.js. Touch nothing else." |
| 21 | **No stack constraints** | "build a React component" | "React 18, TypeScript strict, no external libraries, Tailwind only" |
| 22 | **No stop condition for agents** | "build the whole feature" | Explicit stop conditions + checkpoint output |
| 23 | **No file path for IDE AI** | "update the login function" | "Update handleLogin() in src/pages/Login.tsx only" |
| 24 | **Wrong template for tool** | GPT-style prose used in Cursor | Adapt to File-Scope Template |
| 25 | **Pasting entire codebase** | Full repo context every prompt | Scope to relevant function and file only |

## Reasoning Patterns

| # | Pattern | Bad Example | Fixed |
|---|---------|------------|-------|
| 26 | **No audit contract for logic task** | "which approach is better?" | Request recommendation, assumptions, evidence, and checks |
| 27 | **Requesting hidden reasoning** | "show your chain of thought" | Ask for conclusions, rationale, and verification instead |
| 28 | **Expecting inter-session memory** | "you already know my project" | Always re-provide the Memory Block |
| 29 | **Contradicting prior work** | New prompt ignores earlier architecture | Include Memory Block with established decisions |
| 30 | **No grounding rule for factual tasks** | "summarize what experts say about X" | "Use only information you are highly confident is accurate." |

## Agentic Patterns

| # | Pattern | Bad Example | Fixed |
|---|---------|------------|-------|
| 31 | **No starting state** | "build me a REST API" | "Empty Node.js project, Express installed, src/app.js exists" |
| 32 | **No target state** | "add authentication" | Specific files that must exist when done |
| 33 | **Silent agent** | No progress output | "After each step output: ✅ [what was completed]" |
| 34 | **Unlocked filesystem** | No file restrictions | "Only edit files inside src/. Do not touch package.json or .env." |
| 35 | **No human review trigger** | Agent decides everything | "Stop and ask before deleting files, adding dependencies, or changing schema" |
| 36 | **Vague first turn for agentic model** | "fix the auth bug" with no scope | Use Template M — front-load outcome, context, scope, boundaries, criteria |
| 37 | **Context rot on long sessions** | Repeated corrections leave stale assumptions | Compact around current decisions and state; start fresh for unrelated work |
