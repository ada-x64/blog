---
name: github-history
description: Refreshes the repository-wide GitHub career inventory and updates summary.md. Use when asked to rescan ada-x64, cubething-qproj, GitHub contributions, repository history, or résumé evidence.
---

# GitHub history

From the repository root:

1. Read `scripts/github-history/README.md`, `resume/resume.typ`, and the current `summary.md`.
2. Run `python scripts/github-history/scrape.py`.
3. Review `scripts/github-history/curated-summaries.toml` against the résumé and fresh repository evidence. Update its profile summary, career associations, significance overrides, and important repository prose. Keep associations conservative and private summaries high-level.
4. Run `python scripts/github-history/generate.py`.
5. Review `github-history.toml`, distinguishing ownership, forks, code contributions, reviews, and issue-only participation. Update the GitHub evidence section of `summary.md` with current totals and major findings without turning it into a repository dump.
6. Never copy secrets or detailed private-repository contents into tracked files.
7. Validate with:
   ```sh
   python -c 'import tomllib; tomllib.load(open("github-history.toml", "rb"))'
   git diff --check
   ```

Preserve the scraper and generator so future refreshes remain reproducible.
