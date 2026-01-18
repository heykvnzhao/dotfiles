---
description: Use when you want to clean AI-style prose in a diff, focusing on tone, redundancy, and filler so the writing reads like a concise human edit.
codex.argument-hint:
opencode.agent:
opencode.model:
opencode.subtask:
---
# Remove AI writing slop

Check the diff against main, and remove all AI generated writing slop introduced in this branch.

This includes:

- Em dashes (—), especially decorative ones; rewrite with commas, parentheses, or separate sentences
- Canned transitions and signposting (“Moreover”, “Additionally”, “In conclusion”, “Overall”, “It is important to note”)
- Vague attributions or weasel claims (“experts say”, “research shows”, “it’s widely believed”) without concrete sourcing
- Generic, over-polished, or promotional tone; prefer plain, specific statements
- Repetition and redundancy (restating the same point in slightly different words)
- Meta/boilerplate disclaimers (e.g., “as an AI language model…”) or process talk that doesn’t belong in the document
- Overly symmetrical structure (too many headings/lists) when the doc should be straightforward prose
- Tell-tale word choices that read like filler (“delve”, “tapestry”, “rich heritage”, “crucial/vital role”, “stands as a testament”)

Report at the end with only a 1-3 sentence summary of what you changed.
