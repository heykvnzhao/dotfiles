---
name: open-pr
description: Open pull requests for the current git repo: verify you are not on main/prod, compare your branch to main, commit any pending work, and create a PR (prefer gh). Use when asked to open or create a PR, draft a PR description, or automate the PR workflow for a local git branch.
---

# Open PR

## Overview
Create a pull request from the current branch to main, ensuring the branch is valid, changes are committed, and the PR description follows the required format.

## Workflow

### 1. Verify branch and repo
- Always prepend `GIT_EDITOR=true` to every git command.
- Confirm the current branch and ensure it is not `main` or `prod`:
  - `GIT_EDITOR=true git rev-parse --abbrev-ref HEAD`
  - If branch is `main` or `prod`, stop and explain why you cannot proceed.

### 2. Compare branch against main
- Show what will be in the PR relative to `main`:
  - `GIT_EDITOR=true git fetch origin main` (if origin exists)
  - `GIT_EDITOR=true git log --oneline main..HEAD`
  - `GIT_EDITOR=true git diff --stat main...HEAD`
- If `main` does not exist locally or remotely, stop and ask how to proceed.

### 3. Commit pending work (if any)
- Check for staged/unstaged changes:
  - `GIT_EDITOR=true git status --porcelain`
- If there are changes:
  - Stage everything relevant: `GIT_EDITOR=true git add -A`
  - Ask the user for a commit message if none was provided.
  - Commit: `GIT_EDITOR=true git commit -m "<message>"`
- If there are no changes, proceed.

### 4. Draft PR title and body
Use this exact format:

```
<feature_area>: <Title> (80 characters or less)

<TLDR> (no more than 2 sentences)

<Description>
- 1~3 bullet points explaining what's changing
```

- Keep the title line within 80 characters.
- Ensure TLDR is at most two sentences.
- Provide 1–3 concise bullets.

### 5. Create the PR (prefer gh)
- Check if GitHub CLI is installed: `command -v gh`.
- Ensure the branch is pushed (set upstream if missing):
  - `GIT_EDITOR=true git push -u origin <branch>`
- If `gh` is available, create the PR:
  - `gh pr create --base main --head <branch> --title "<title>" --body "<body>"`
- If `gh` is not available, explain the manual steps to open a PR on the hosting service.

### 6. Respond with the PR link
- Always paste the PR URL in your response so it is clickable.
- If needed, fetch it via:
  - `gh pr view --json url -q .url`
