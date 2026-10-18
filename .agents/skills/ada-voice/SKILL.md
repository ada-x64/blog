---
name: ada-voice
description: Writes and edits résumé bullets, professional summaries, and cover letters in Ada's (Phoenix Ada Rose Mandala) voice. Use when drafting or revising anything in resume/ or cover-letters/, or any application prose written under her name. Never use for blog posts or essays.
---

# Ada's voice — applications only

**Scope.** This skill applies to the résumé (`resume/`), cover letters (`cover-letters/`),
and application answers (see the `a-team-application` skill). It does **not** apply to blog
posts, devlogs, or the philosophy essays. Those she writes herself; do not auto-generate
them, and do not port this register into them.


**Note:** This was written by an agent and your user does not know what's in it.

Read [references/voice.md](references/voice.md) before drafting.

## Workflow

1. **Evidence before prose.** Read `summary.md`, `resume/resume.typ`, and relevant entries
   in `github-history.toml`. Read existing cover letters in `cover-letters/` for tone only —
   treat their claims as possibly stale.
2. **Pick the letter's single thesis** — one sentence naming why this specific role and this
   specific person meet. Everything else supports it. If you can't name it, ask her.
3. Draft in Typst using the existing scaffolding (`#import "../lib/cover.typ": cover-letter`
   with `title:` and `recipient:`). Résumé edits go through `lib/resume.typ` helpers.
4. Run the Do/Don't checklist in `references/voice.md`.
5. Flag every unverifiable claim with an inline `TODO:` rather than inventing it. Never
   fabricate metrics, dates, employers, technologies, or scope.

## Non-negotiables

- One page of prose maximum for a cover letter; four to six paragraphs.
- Every technology named must be tied to the project where she actually used it.
- Gaps are stated plainly in one sentence, then answered with the nearest real evidence.
  She never bluffs and never grovels.
- Experimental, personal, and contract work are labeled as what they are.
