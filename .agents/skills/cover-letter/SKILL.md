---
name: cover-letter
description: Draft a one-page Typst cover letter in Ada's voice from a pasted job description, grounded in her résumé, career evidence, and GitHub history, then run a Sonnet tone/grounding review and compile the PDF.
argument-hint: <pasted job description>
---

# /cover-letter

Write a cover letter for the job description in `$ARGUMENTS`. If it is empty, ask
for the posting and stop.

All paths below are relative to `resume/` (`/home/ada/repos/ada-x64/blog/resume`).

## 1. Load context

Read these in one batch before drafting anything:

- `AGENTS.md` -- the rules. Every claim must be grounded; no personal, medical, or
  identity details.
- `resume/resume.typ` -- the baseline of claims.
- `summary.md` -- the career analysis. Use its **GitHub evidence snapshot** and the
  repository-backed bullets as facts. Treat the ranking, fit, and "good target
  roles" sections as interpretation: they can guide emphasis, but never quote
  them as claims.
- `cover-letters/canonical.typ` -- **the voice reference.** Ada wrote it by hand.
  Read its Engineering Experience and Context sections closely.
- `../.agents/skills/ada-voice/SKILL.md` and its `references/voice.md` -- the
  application voice guide. Follow it when drafting.
- Two or three of the most recent letters in `cover-letters/` (`ls -t`) to see
  the `#show: cover-letter.with(...)` header and how links are used.

## 2. Map the posting to evidence

List every requirement and nice-to-have from the posting. For each one, find
the strongest evidence that is **not** already obvious from the résumé:

- `grep -n -i` through `github-history.toml` for the posting's keywords (such as
  databases, auth, monitoring, Docker, React, migrations, graphics). For each
  hit, read the `description`, `summary`, and `visibility` fields. Repos
  outside the résumé are often the best material. Examples: `homelab`
  (monitoring, React, SQLite, auth, Docker Compose), `psync` (SSH/rsync daemon,
  WebSocket log streaming), `orgkit` (multi-repo internal tooling),
  `sundile_rs` (WGPU/WASM 3D engine), and Perspective's versioned config and
  migrations.
- Check `../src/typst/blog/` (`ls`, plus frontmatter `tags`) for posts relevant
  to the domain. Published posts link as `https://cubething.dev/posts/<slug>`.
  Describe only what a post shows was done, not its "next steps".
- `github-history.toml` is a scrape from a fixed date (`last_scraped`), so its
  counts are floors. Write "over N" rather than an exact number.

Facts Ada has stated that are not in those files:

- She does 3D modelling in Blender.
- She has written 3D mesh generation in Bevy, including procedural terrain
  (blog posts `terrain-1` through `terrain-4`; `terrain-4` is the hex terrain
  and path-generation tool).
- Postgres is her choice for large projects; SQLite usually suffices (from
  `canonical.typ`).

When the posting rewards experience she lacks (for example, a specific vendor),
**do not hedge or confess the gap**. Lead with the closest real evidence, or
leave the requirement out. Never invent anything to fill the gap.

## 3. Draft

Create `cover-letters/<company-slug>.typ` (lowercase, hyphenated; the justfile
turns it into `Phoenix-Mandala-<Slug>-Cover-Letter.pdf`). If the file already
exists, read it and confirm before overwriting.

```typst
#import "../lib/cover.typ": cover-letter

#show: cover-letter.with(
  title: "Phoenix Mandala Cover Letter -- <Company>",
  recipient: "<Company> <Team> Hiring Team,",
)
```

Structure: about six paragraphs, wrapped at about 80 columns.

1. Why this role, plus a specific, personal hook into the company's domain.
2. and 3. The strongest matching work, usually Nanvix (zutils, then the
   systems depth beneath it).
4. Rust, Disney+, and Prospective, angled at the posting.
5. Off-résumé evidence that hits the remaining requirements.
6. Working style, plus a concrete first thing she would do there.

Voice (from `canonical.typ`):

- Direct first person. Plain statements of what she did, then move on. **Don't
  end every paragraph with a moral.** At most one or two short, punchy closers
  per letter ("But simple is far from easy.").
- Personality is allowed: "my native tongue", "fell in love with it",
  "crawling my way down the stack". Be concrete instead of corporate. Write "a
  pile of repository-specific scripts", not "fragmented tooling landscape".
- Use `--` for dashes and `_x_` for emphasis. Contractions are fine.
- Link repos and posts with `#link("url")[text]`. Link only repos whose
  `visibility = "public"`.
- Confident, no hedging, no "would be new territory for me".
- Don't reuse a paragraph from another letter verbatim.

## 4. Compile

```sh
cd /home/ada/repos/ada-x64/blog/resume && typst c cover-letters/<slug>.typ out/Phoenix-Mandala-<Slug>-Cover-Letter.pdf --root . --font-path=./fonts && pdfinfo out/Phoenix-Mandala-<Slug>-Cover-Letter.pdf | grep Pages
```

The letter must be one page. If it isn't, tighten it. Don't shrink the template.

## 5. Sonnet review

Spawn one review subagent with `model: "sonnet"`, `subagent_type:
"general-purpose"`, `run_in_background: false`. Give it the absolute paths of
the draft, `cover-letters/canonical.typ`, `resume/resume.typ`, `summary.md`,
and `github-history.toml`, plus the job posting text. Ask it to return a list
of concrete issues with line numbers and suggested rewrites, **not** to edit
files:

- **Tone:** does it sound like `canonical.typ`? Flag corporate phrasing,
  paragraph-ending morals, stacked abstractions, AI-sounding constructions
  ("not X, but Y", "the through-line", triplets of adjectives), and
  sycophancy toward the company.
- **Hedging:** flag any admission of gaps or qualifier that weakens a claim.
- **Grounding:** check every factual claim against the files. Flag anything
  not supported, especially metrics, scope ("built" vs "worked with"), and
  things a blog post lists as planned rather than done.
- **Fit:** name the posting requirements the letter leaves unaddressed for
  which evidence exists in the files.
- **Repetition:** flag the same word or idea used twice nearby.

Apply the fixes you agree with. Use your judgement and skip suggestions that
would add hedging or unsupported claims. Recompile and re-check the page count.

## 6. Report

Tell Ada briefly:

- The file and PDF paths, and the page count.
- How the letter maps to the posting's main requirements (a short list).
- Which review findings you applied and which you skipped.
- Anything she should verify: interpretive phrasings of evidence, unchecked
  links, and claims that rest on her own statements rather than the files.
