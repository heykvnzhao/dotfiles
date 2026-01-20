---
name: coding-best-practices
description: General coding principles for writing clean, maintainable code. Triggers on any development work, code reviews, refactoring, or when adding dependencies. For frontend/React code, also apply web-ui-best-practices and react-best-practices.
---

# Coding Best Practices

## Related Skills

- **Frontend code**: Also apply `web-ui-best-practices`
- **React code**: Also apply `react-best-practices`

## Core Principles

### Fix Root Causes

- Fix from first principles; find the source instead of applying bandaids
- If a fix feels like a workaround, it probably is—dig deeper

### Simplicity

- Write idiomatic, simple, maintainable code
- Prefer the most straightforward solution to the problem
- Prefer small helpers or state-driven flow to keep cyclomatic complexity low

### Clean Up Ruthlessly

- Leave each repo better than you found it
- Delete unused code immediately—don't let junk linger
- If a function no longer needs a parameter, remove it and update callers
- If a helper is dead, delete it

### No Breadcrumbs

- When deleting or moving code, do not leave comments in the old location
- No `// moved to X`, no `// relocated`—just remove it
- Describe changes in your response, not in the code

## Dependencies

Before adding a new dependency:
- Quick health check: recent releases/commits?
- Reasonable adoption/community?
- Actively maintained?
- Does it solve a problem we can't easily solve ourselves?

## When Unsure

1. Read more code, documents, or files
2. If still stuck, ask with short options
3. If there are conflicts or ambiguity, call them out and take the safer path

## Context Awareness

- If project or repo-specific guidance conflicts with these rules, follow project guidance first
- Assume other agents or the user might land commits mid-run; refresh context before summarizing or editing
- If changes look unrecognized and continuing is problematic, stop and ask
