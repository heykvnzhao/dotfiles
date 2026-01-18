# Repo guidance for agents

This repository contains dotfiles source for agent prompts, skills, AGENTS guidance,
and sync helpers. Most automation is Bash. Some skills include Python or Node.js
helpers.

Note: this repo is public. Avoid committing personal info, secrets, or identifying
credentials.

## Repo layout

- `README.md` lists the supported agent tools.
- `scripts/` holds sync entrypoints and helpers.
- `.shared/` contains prompts, skills, and shared `AGENTS.md` rules.
- `.local/PROFILE.md` is optional personal info used by sync scripts.

Always check for nested `AGENTS.md` files under the directory you edit. The
`.shared/AGENTS.md` file applies to everything in `.shared/`.

## Build, lint, test

There is no formal build system or test runner for the repo. Validation is
script execution and basic shell checks.

### Sync commands

- Run the full sync flow:
  - `./scripts/sync-all-agents.sh`
- Dry run without changes:
  - `./scripts/sync-all-agents.sh --dry-run`
- Show skipped entries:
  - `./scripts/sync-all-agents.sh --verbose`

### Run a single sync script

- Agent skills:
  - `./scripts/sync-agent-skills.sh --dry-run`
- AGENTS.md sync:
  - `./scripts/sync-agents-md.sh --dry-run`
- Prompt sync:
  - `./scripts/sync-agent-prompts.sh --dry-run`
- OpenCode config:
  - `./scripts/sync-opencode-config.sh --dry-run`

### Lint and sanity checks

- Bash syntax check:
  - `bash -n scripts/*.sh`
- ShellCheck (if installed):
  - `shellcheck scripts/*.sh`

## Code style

### Bash scripts

- Use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Prefer `printf` over `echo` for predictable output.
- Quote all variable expansions unless you intentionally want word splitting.
- Use `local` for function scope.
- Prefer `[[ ... ]]` for tests and `case` for option parsing.
- Keep functions small and focused, avoid deep nesting.
- Use arrays for lists (targets, files) rather than space-delimited strings.
- For temporary files, use `mktemp` and clean up promptly.
- Avoid `cd` in scripts, use absolute paths from `SCRIPT_DIR`.
- Use `return` for function exits, `exit` only at script top level.
- Do not swallow errors, check preconditions and fail fast with helpful output.

### Logging and output

- Keep output compact and stable, avoid repeating noise.
- Respect `NO_COLOR` and only colorize when stdout is a TTY.
- Provide clear section headers when running multiple tasks.
- Keep summaries at the end with counts for add, update, skip.
- If adding new output, follow existing table style and alignment.

### Markdown prompts and skills

Prompts under `.shared/prompts` are Markdown with front matter. The sync script
expects:

- A YAML front matter block at the top.
- A `description` key is required.
- Optional keys:
  - `codex.argument-hint`
  - `opencode.agent`
  - `opencode.model`
  - `opencode.subtask` (must be `true` or `false`)

When editing these files:

- Keep front matter keys minimal and valid.
- Keep the body Markdown clean, one blank line after front matter.
- Avoid trailing whitespace.

Skills live under `.shared/skills/<name>/`. Follow existing layout and keep
changes localized to the skill you edit. If a skill includes scripts, mirror
its current style and avoid adding dependencies unless required.

### Python and Node helpers in skills

- Follow the existing file style in the skill directory.
- Prefer the standard library unless a dependency is already used.
- Keep helpers self-contained and avoid global state.

## Naming conventions

- Scripts use kebab case: `sync-agent-prompts.sh`.
- Bash constants use upper snake case: `SCRIPT_DIR`.
- Bash functions use lower snake case: `sync_target`.
- Markdown files use uppercase where expected (`AGENTS.md`, `SKILL.md`).

## Error handling

- Validate inputs early, fail with a clear error message to stderr.
- Use `diff -q` or `diff -qr` for up-to-date checks, avoid noisy diffs.
- When a target is missing, report it once in a summary section.
