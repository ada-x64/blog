# Voice guide — application prose

Derived from `cover-letters/*.typ`, `resume/resume.typ`, and the underlying personal voice
in `../src/typst/blog/` (used as a source of temperament, **not** as a style to copy
directly — the blog is looser, funnier, and more political than anything that belongs in an
application).

## The person behind the prose

Senior software engineer, ~7 years, Lawrence KS. Rust / Python / TypeScript. Systems,
developer tooling, build infrastructure, agent harnesses, front-end and data platforms.
BA Philosophy (honors) and BA Mathematics — this is an asset she names deliberately, as
first-principles reasoning and the ability to translate formal requirements into prose,
never as a quirky aside. Self-taught as an engineer. Trans; she does not disclose this in
application materials unless she explicitly asks for it.

Her temperament, which should survive translation into professional register:
**precise, candid, systems-minded, allergic to hype, generous about other people's work,
and willing to say "I haven't done that" in a plain sentence.**

## Register

Professional, warm, and unusually concrete. Not stiff, not chummy.

- **First person, active voice, past tense for completed work, present for current.**
  "I owned the front end." "I use specification-driven agent workflows."
- **Lead with the strongest evidence, never with a disclaimer or a pleasantry.** The best
  openers state the thesis in the first sentence: *"I am applying for the Architect-Level
  Full-Stack Engineer role because vQuip is looking for more than someone who uses AI for
  code completion."* Only the oldest letter (open-sesame) opens with "I hope this letter
  finds you well" — that is the weakest opening in the corpus. Don't reproduce it.
- **Concrete nouns and numbers over adjectives.** 17 repositories. 58 incompatibilities,
  36 closed in two months. First enterprise customer. Shipped in six months. Ahead of
  schedule and under budget. If a number isn't in the evidence, don't reach for one.
- **Sentences are medium-length and load-bearing.** Lists inside a sentence are fine and
  characteristic: "its C++/Rust engine, Python library, network protocols, and enterprise
  infrastructure." Avoid the three-adjective marketing cadence.
- **Em dashes and semicolons are welcome; exclamation points are not** (one at the very end
  of an older letter is the outer limit). No emoji, no profanity, no jokes-at-length.
  A single dry turn of phrase per letter is plenty: *"the best prompt is no prompt at all,"*
  *"Good context is what separates a functional agent from a hallucination engine."*
- **No self-deprecation and no swagger.** She describes scope, safeguards, and results.

## Cover letter shape

Four to six paragraphs, roughly:

1. **Thesis.** Why this role, stated as a claim about the *problem*, not about her feelings.
   Optionally open on a principle she's earned the right to state, then attach it to a
   named artifact (the `noodle.typ` opening is the best example of this move).
2. **Primary evidence.** The one or two most relevant projects, with personal ownership
   made explicit: what the system did, what she designed, what shipped, what it cost or
   saved. Name the repo and link it when public.
3. **Secondary / transferable evidence.** A different domain that proves the same
   underlying competence. She likes to name the competence explicitly: "the underlying
   problems are familiar: understanding how data moves through distributed components,
   designing interfaces that support many integrations rather than one special case."
4. **The gap, if there is one.** One sentence, unhedged, immediately followed by the closest
   real evidence and a fast-learning precedent (Disney+ embedded Rust; OpenSesame SCORM).
5. **What she would actually do there.** The strongest letters end with a concrete plan or
   a stated stake — a modeled workflow, an approach to their migration, a reason the
   mission matters to her. Not "I would welcome the opportunity to leverage my skills."
   The one acceptable stock closer is a short "I would welcome the opportunity to build
   that system." after a concrete plan.

## Résumé bullet shape

`Verb + artifact + mechanism + consequence.` Present the design decision, not just the task.

Good, from the current résumé:

- "Designed and developed zutils, a cross-platform Python build SDK that replaced
  repository-specific scripts with standardized interfaces for dependency resolution,
  Docker-based cross-compilation, testing, and release packaging across 17 repositories."
- "Partitioned agent context by role: routing agents read the workflow contract, while
  single-input agents are denied it, since context beyond an agent's inputs invites
  scope drift."
- "Joined a project that was stalled and over budget; unblocked the team on Rust and
  developed a clear production strategy, shipping the final build within 6 months."

Notice: the *why* is inside the bullet. She justifies architecture in a subordinate clause
("since context beyond an agent's inputs invites scope drift"). Keep that habit — it is the
single most distinctive thing about her résumé.

Bullets are 1–4 lines, no periods omitted, no leading buzzword strings, no "responsible for."

## Subject-matter positions she actually holds

Getting these wrong reads as ghostwritten:

- **AI/agents:** prompts are engineering artifacts subject to testing, acceptance criteria,
  and audit; deterministic code beats prose whenever a constraint must be guaranteed;
  transcripts are evidence; humans review. She is neither an AI evangelist nor an abstainer.
  Never describe her as "using AI for code completion" as the main claim.
- **Systems:** separation of concerns, single responsibility, interfaces that serve many
  integrations rather than one special case, correctness and failure behavior over speed.
- **Probabilistic extraction** should supply evidence and confidence, not silently become
  the source of truth.
- **Teaching and documentation** are part of engineering work; she unblocks teams and
  writes the docs, and she says so.
- **Philosophy and mathematics** sharpen formal reasoning and written translation between
  specification and implementation.

## Do / Don't

**Do**
- Open on the problem or a principle, and land the first concrete artifact by sentence three.
- Name repos, standards, protocols, and tools precisely (SCORM, POSIX/VFS, gRPC, Kerberos,
  Kafka, CPython, Playwright, zod, Bevy).
- Distinguish *owned*, *contributed to*, *designed*, and *prototyped*.
- State a gap once, plainly, then move.
- Mirror the company's vocabulary only where it genuinely maps to her experience.
- End with something she would do for them.

**Don't**
- No "I am excited to inform you," "I hope this letter finds you well," "passionate,"
  "results-driven," "fast-paced environment," "leverage," "synergy," "wear many hats."
- No LLM cadence: "In today's landscape," "It's important to note," "Let's dive in,"
  "In conclusion," triadic adjective lists, or a rhetorical question as a paragraph opener.
- No blog-voice bleed: no lowercase headings, no profanity, no emoji, no political framing,
  no personal or medical disclosure, no jokes about being broke, no footnote tangents.
- No inflating personal projects into production experience, and no merging two projects
  into one tidy anecdote.
- No metrics that don't appear in `summary.md`, the résumé, or `github-history.toml`.
- No apology, no "although I lack," no begging, no explanation of employment gaps unless
  she asks for one.
