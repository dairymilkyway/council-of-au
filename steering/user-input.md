---
title: user_input tool usage
inclusion: always
---

# user_input Tool — Structured Questions with Choices

When you need to ask the user a question, use the `user_input` tool instead of plain text. This presents the question properly in the Kiro UI and allows selectable choices.

## When to use

- Clarifying questions during feature intake
- Asking for confirmation before a significant action
- Offering options when the answer set is known
- Any time you need user input to proceed

## Basic usage — free text question

```
user_input:
  question: "**What should happen when the user doesn't have permission?**"
```

## With choices — preferred when answer set is known

```
user_input:
  question: "**Which approach do you want for the empty state?**"
  options:
    - "Show a placeholder message with a CTA button"
    - "Hide the section entirely"
    - "Show a skeleton loader until data arrives"
```

## With rich options (title + description)

```
user_input:
  question: "**How should andrei handle a Blocked verdict?**"
  options:
    - title: "Auto-fix loop"
      description: "Dev routes findings back to jigs/ogie automatically and re-runs andrei"
      recommended: true
    - title: "Pause and report"
      description: "Stop and show the findings to the user before proceeding"
    - title: "Skip verification"
      description: "Mark as done anyway (not recommended)"
```

## Rules

1. **Always use `user_input` tool for questions** — never ask questions in plain prose that the user must read and type a response to.
2. **Provide `options` whenever the answer set is predictable** — options appear as clickable buttons; the user can still type a free-text answer if none fit.
3. **One question per `user_input` call** — do not bundle multiple questions.
4. **Format the question in bold** (`**question text**`) so it stands out in the UI.
5. **Mark one option as `recommended: true`** when there is a clear best choice.
6. **Use `subOptions`** for follow-up preferences that only apply when a specific option is chosen.
7. **Wait for the response** before proceeding — do not assume the user picked a specific option.
