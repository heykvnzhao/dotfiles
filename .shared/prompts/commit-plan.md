---
description: Use when you need to review git changes, propose logical commit groups, and draft Conventional Commit messages.
codex.argument-hint:
opencode.agent:
opencode.model:
opencode.subtask:
---
# Plan git commits

Review all staged and unstaged changes. Identify untracked files, ignored files, and anything that should not be committed.

Propose a clean set of commit groups that are logically related and minimal. Explain which files belong to each commit and why. If there are dependencies between commits, order them.

Draft a Conventional Commit message for each commit. Format: <type>[optional scope][optional !]: <description>. Use the smallest sensible scope; omit scope if unclear. Use feat for new features, fix for bug fixes. Other allowed types include build, chore, ci, docs, style, refactor, perf, test, and revert. If there are breaking changes, mark with ! before the colon or add a BREAKING CHANGE: footer. Use body and footers only when needed; footers follow git-trailer style (Token: value).

If anything is ambiguous, ask short, direct questions with options. If files should be removed or ignored, say so explicitly.

End with a short summary and a clear question for next steps (stage/commit/push).