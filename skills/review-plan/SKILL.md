---
name: review-plan
description: "Review an implementation plan before coding starts. It is CRITICAL to review plans before implementation — plans often have gaps, incorrect assumptions, or suboptimal sequencing that are cheaper to catch now than after coding. USE FOR: 'review the plan', 'check my plan', 'is this plan ready', 'any issues with this approach', 'sanity check'. DO NOT USE FOR: standard implementation tasks with no explicit review request."
---

# Skill: Review Plan

Critically review a given implementation plan before any code is written. Fan out parallel read-only subagents, each assigned a different review area, then synthesize the highest-signal findings.

## Review Areas

Pick 2–4 areas based on the plan's complexity and risk profile.

| Area | Focus |
|------|-------|
| **Completeness** | Missing requirements, unaddressed edge cases, gaps between stated goal and proposed steps |
| **Grounding** | Technical soundness — references to nonexistent APIs, incorrect codebase assumptions, wrong file paths, hallucinated functions. Use web search to validate uncertain claims |
| **Sequencing** | Dependency correctness between steps, parallelism opportunities missed, blocking-step identification, optimal ordering |
| **Scope** | Over-engineering, scope creep or under-specification, steps disproportionate to value delivered |
| **Verification** | Are verification steps specific, actionable, and covering the riskiest parts? Missing test strategies |
| **Risk** | Unaddressed failure modes, migration risks, backward compatibility gaps, missing rollback strategy |

## Workflow

### 1 — Locate the Plan

Read the plan from the conversation or a file the user pointed at. If nothing is available, ask the user to present the plan or point at a plan file.

### 2 — Fan Out

Launch 2–5 parallel subagents. Each gets a self-contained prompt with its area, the plan content/location, and the return format.

**Area Prompt:**
```
You are a focused plan-review subagent. Your area is: {AREA}

## The Plan
{plan content or location}

Focus on: {FOCUS}

Use your tools to read the full plan and inspect the codebase to validate the plan's assumptions — check that referenced files, functions, and patterns actually exist. Use web search to validate uncertain API or version claims.

Rules:
- Stay read-only. Do not edit files.
- Only flag issues that would change what a developer actually does or how likely the plan is to succeed.
- Do not report issues outside your area, but do surface unexpected findings within it.
- Do not rewrite the plan — describe the problem and why it matters.
- Keep your response short. No preamble.

Return format:

**Area**: {AREA}

**Findings** (0–5 items, severity order):
- One-sentence description. Why it matters. Evidence from the codebase if applicable.

If the plan is sound for your area: "No issues found in {AREA}."
```

### 3 — Synthesize

When all subagents return:
1. Deduplicate findings that overlap across areas.
2. Order by severity: missing requirements > incorrect assumptions > sequencing errors > scope issues > weak verification > minor risks.
3. Apply the signal filter — drop anything that wouldn't actually cause problems during implementation.

### 4 — Report

**Plan Summary** (30 words max):
What the plan intends to accomplish.

**Blocking Issues** (0–5 items):
Things that will cause implementation to fail, produce wrong results, or miss the goal. Each with the area that surfaced it.

**Improvements** (0–5 items):
High-value suggestions that don't block but make the plan stronger.

**Verdict**: Ready to Implement / Revise First / Blocked — with a specific next step if not ready.

## Signal Filter

Ask: *Does this change what a developer would actually do — or how likely the plan is to succeed?*

Ground every finding in something observable: a file that doesn't exist, an API that behaves differently, a requirement the steps don't cover, a sequence that creates rework.

If a concern is speculative, cosmetic, or unrelated to the plan's goal, leave it out.
