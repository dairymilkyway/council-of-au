---
name: review-areas
description: "In-depth code review that fans out parallel subagents across review areas — CRITICAL after non-trivial development. USE FOR: 'in-depth review', 'code quality check', 'review correctness, tests, security, performance', 'review before pushing'. DO NOT USE FOR: 'plan a new implementation', 'explain how existing code works'."
---

# Skill: Review Areas

Fan out parallel read-only subagents, each assigned a different review area, then synthesize the highest-signal findings. This surfaces issues that a single-pass review misses because each subagent goes deep on its area instead of skimming everything.

## Review Areas

Pick 2–4 areas based on the nature of the change. Not every review needs all areas — match the areas to the risk profile.

| Area | When to include | Focus |
|------|----------------|-------|
| **Correctness** | Always | Logic errors, type safety, race conditions, null/undefined paths, unsafe casts, wrong behavior |
| **Tests** | When tests exist or should exist | Run tests, check failing/missing coverage, validate assertions match intent |
| **Security** | Auth, input handling, data flow changes | Input validation, auth checks, injection, data exposure, permission bypasses |
| **Performance** | DB queries, hot paths, async changes | N+1 queries, unnecessary allocations, blocking patterns, missing indexes |
| **Product** | UI, UX, or user-facing behavior changes | UX implications, feature completeness, accessibility gaps, edge case handling |

## Workflow

### 1 — Scope

Run `git diff main --stat` to see what changed. If on a branch, diff against main. Build a concise change summary before fanning out.

The summary should include:
1. **Intent** — what the change is trying to accomplish.
2. **Changed files** — each file path with a one-line description of what changed.
3. **Risk areas** — anything risky: auth changes, DB queries, API surface changes, permission checks.
4. **How to inspect** — branch/commit info so subagents can use their tools.

Keep the summary under ~50 lines. Subagents get better results reading code in context than scanning a wall of diff.

### 2 — Fan Out

Launch 2–4 parallel subagents. Each gets a self-contained prompt with its area, the change summary, and the return format below. Each subagent works in isolation — do not share findings before synthesis.

**Area Prompt:**
```
You are a focused code review subagent. Your area is: {AREA}

## What changed
{change summary: intent, changed files with one-line descriptions, risk areas}

## How to inspect
{branch/commit info}

Focus on: {FOCUS}

Use your tools to read the changed files, check diagnostics. Read functions end-to-end. Trace inputs through branches and error paths. Check callers when contracts change.

Rules:
- Stay read-only. Do not edit files.
- Only flag issues that would block a PR — things that break, regress, or expose a concrete vulnerability.
- Do not report issues outside your area.
- Do not suggest code edits — describe the problem and why it matters.
- Check loaded workspace instructions (AGENTS.md, steering files) before flagging standard violations.
- Keep your response short. No preamble, no style commentary.

Return format:

**Area**: {AREA}

**Findings** (0–5 items, severity order):
- [file:line] One-sentence description. Why it matters.

If nothing blocks approval: "No blocking issues found in {AREA}."
```

### 3 — Synthesize

When all subagents return:
1. Deduplicate findings that overlap across areas.
2. Order by severity: breaking > wrong behavior > security > missing coverage > performance > product.
3. Apply the signal filter — drop anything that wouldn't block a PR.
4. If no blocking issues survive, say so and mention any meaningful testing gaps.

## Signal Filter

Keep only findings a senior engineer would block a PR for:
- Will fail to compile, type-check, or produce wrong results
- Clear violation of workspace coding standards (AGENTS.md rules)
- Security vulnerability with a concrete exploit path
- Missing error handling that causes silent failures
- Missing permission check / authorization gap

Drop: style preferences, linter-catchable issues, pre-existing problems, speculative concerns.

## Output Shape

**Changes Summary** (50 words max):
What changed, why, and expected impact.

**What's Done Well** (1–3 items):
Acknowledge good patterns worth reinforcing.

**Critical Issues** (0–5 items, severity order):
Each with file references and the area that surfaced it.

**Improvements** (0–5 items):
High-value suggestions that didn't quite reach "blocking" but are worth addressing.

**Verdict**: Ready / Needs Revisions / Blocked — with a specific next step.
