# dotfiles

This repo contains the source of truth for agent prompts, skills, AGENTS.md files, and other configuration details. It also contains sync scripts that helps keep local configs consistent.

## Currently supported agent tools for syncing

| Tool        | AGENTS.MD | Agent Skills | Prompts/Commands | Specific configs |
| ----------- | --------- | ------------ | ---------------- | ---------------- |
| OpenCode    | ✅        | ✅           | ✅               | ✅               |
| Claude Code | ✅        | ✅           | ❌               | ❌               |
| Codex       | ✅        | ✅           | ✅               | ❌               |
| Kiro        | ✅        | ✅           | ✅               | ❌               |
| Gemini CLI  | ✅        | ✅           | ❌               | ❌               |
| Antigravity | ✅        | ✅           | ❌               | ❌               |

## Repo layout

- `.shared/`: global prompts, skills, and AGENTS guidance that can be shared amongst tools
- `.codex/`, `.kiro/`, `.config/opencode`: tool specific configurations that cannot be shared
- `scripts/`: sync helpers for prompts, skills, and configs

## Usage (minimal)

Run the bash scripts in `scripts/` when you want to sync local configs. Start with `scripts/sync-all-agents.sh` to sync prompts, skills, AGENTS guidance, etc.
