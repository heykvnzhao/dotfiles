## About me

Please refer to `.local/PROFILE.md` for information about me.

## Compounding

- If I tell you to "remember" something about me (preferences, bio details, personal workflows, etc.), please update `.local/PROFILE.md` so that memory about me accumulates over time.
- If I tell you to improve the way you work or remember a preference that doesn't contain personal details, update this `AGENTS.md` so that context can compound over time to become a truly self-improving agent.

## General working/thinking preferences

- THINK HARD AND A LOT PLEASE. Do not lose the plot.
- Instead of applying a bandaid, fix things from first principles, find the source and fix it versus applying a cheap bandaid on top.
- If unsure: read more code, documents, or files; if still stuck, ask with short options.
- If there are conflicts/ambiguity: call them out and take the safer path.
- If project or repo-specific guidance conflicts with this file, follow the project or repo guidance first.
- If changes look unrecognized: Assume other agents or the user might land commits mid-run; refresh context before summarizing or editing. If there are issues with continuing, stop and ask.
- No breadcrumbs. If you delete or move code, do not leave a comment in the old place. No "// moved to X", no "relocated". Just remove it. Do describe it back to me in your response though (what changed + why + next check).

## Plan mode preferences

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.

## Coding/development preferences

- Write idiomatic, simple, maintainable code. Always ask yourself if this is the most simple intuitive solution to the problem.
- Prefer small helpers or state-driven flow to keep cyclomatic complexity low when it improves readability.
- Leave each repo better than how you found it. If something is giving a code smell, fix it for the next person.
- Clean up unused code ruthlessly. If a function no longer needs a parameter or a helper is dead, delete it and update the callers instead of letting the junk linger.
- New deps: quick health check (recent releases/commits, adoption).

### Git preferences

- Safe by default: git status/diff/log. Push only when user asks.
- git checkout ok for PR review / explicit request.
- Branch changes require user consent.
- Destructive ops forbidden unless explicit (reset --hard, clean, restore, rm, …).

## Writing preferences

### Avoiding signs of AI writing

#### Core rules

- Write plainly and factually. No puffery, symbolism, or marketing tone.
- No filler or editorializing (“it’s important to note,” “many experts say”).
- Use specifics (names, numbers, facts) or make no claim.
- Vary sentence length; avoid templated cadence.
- Never invent citations or vague attributions.
- Avoid redundancy; don’t restate the same point in different words.
- Avoid canned signposting (“Additionally”, “Moreover”, “Overall”, “In conclusion”).
- Do not include boilerplate/meta disclaimers (e.g., “as an AI language model…”).

#### Structure

- Avoid formulaic patterns:
  - Stock transitions (“moreover,” “furthermore,” “on the other hand”).
  - Contrast templates (“not only X but Y”).
  - Rule-of-three lists by default.

#### Voice & formatting

- No assistant/meta language. Output finished prose only.
- Neutral formatting only; minimal bolding.
- Avoid em dashes (—) unless strictly necessary. Prefer commas, parentheses, or separate sentences.
