---
name: a-team-application
description: Evaluates A.Team mission fit and drafts concise, evidence-grounded answers for the recurring mission-fit field and role-specific application questions. Use when reviewing or applying to an A.Team mission.
---

# A.Team Application

Use this skill for A.Team mission applications. Optimize for a human reviewer assembling a small client shortlist, not for generic keyword coverage.

Read [references/a-team.md](references/a-team.md) when platform context or application strategy is relevant.

## Gather evidence first

1. Parse the mission description into outcomes, core requirements, preferred experience, availability, location, and compensation.
2. Read the candidate's current résumé and any supplied career summary before drafting. In a repository, look for sources such as `summary.md` rather than assuming the résumé is exhaustive.
3. When available, use a structured GitHub history or portfolio inventory such as `github-history.toml` to find relevant projects and measurable public evidence. Use the summary as an index, query only relevant repository or career-context entries, and inspect source repositories when implementation details matter.
4. Read prior cover letters only as secondary evidence. They may be stale or contain unsupported associations between a technology and a project.
5. Treat candidate corrections as first-hand evidence, while flagging contradictions that affect the answer.

Maintain these evidence boundaries:

- A general skills list proves familiarity, not use on a named project.
- Repository ownership, a fork, issue participation, and authored production contributions are different kinds of evidence.
- Upstream stars, repository size, and total project activity are not the candidate's outcomes.
- GitHub counts are evidence indicators, not a complete career history; private work, deleted repositories, non-default branches, and unlinked commit identities may be absent.
- Never merge separate projects into a fictional single example. Say that the requested experience spans multiple systems when that is true.

## Decide whether to apply

Assess direct evidence for the role's central responsibilities, not just language overlap. Classify relevant experience as:

- direct production experience;
- adjacent or transferable experience;
- personal project or prototype experience;
- no experience.

Recommend against applying when several core screening requirements lack direct evidence, especially when the custom question explicitly asks for measurable results in those areas. If another role on the same mission is materially stronger, recommend it briefly.

Do not disguise a foundational gap as a minor tool gap. Conversely, do not underrate transferable framework experience when the candidate has owned the underlying product or systems problem.

## Draft the application fields

A.Team commonly presents these as separate fields unless the user says otherwise:

1. **How are your skills and experience relevant to this mission?**
2. **A role-specific evidence question.**

Respect stated character limits. Unless asked otherwise, target roughly 700–1,500 characters per field and make each answer skimmable in under a minute.

### Mission-fit response

1. State the strongest alignment with the mission's actual outcome.
2. Give two or three concrete examples showing personal ownership and results.
3. Connect those examples to what the company needs built.
4. Mention a material gap only when accuracy requires it, then identify the nearest transferable evidence.

Avoid generic claims. Prefer specific scope and supported outcomes such as repositories standardized, users served, tests added, delivery time, defects resolved, or commercial impact.

### Custom evidence response

Answer the question literally and early. Include:

- what the system or product did;
- what the candidate personally owned;
- architecture and technology decisions relevant to the prompt;
- correctness, testing, failure handling, deployment, or review practices;
- one or two defensible measurable results.

If no exact example exists, say so in one sentence and present the closest relevant experience. Keep distinct examples distinct.

For AI questions, distinguish among:

- an AI-powered product or backend;
- AI-assisted engineering of a non-AI product;
- agent infrastructure or orchestration.

Strong AI evidence explains specifications, context, evaluation, failure modes, deterministic safeguards, human review, cost or retry controls, and lessons from observed failures—not merely use of an AI coding assistant.

## Style

- Lead with the strongest evidence, not a disclaimer.
- Use short paragraphs and concrete nouns.
- Prefer outcomes and scale over adjectives.
- Use mission vocabulary only when it accurately maps to experience.
- Do not repeat the same résumé paragraph in both fields: establish fit in the first and prove the requested example in the second.
- Be candid about missing domain or framework experience without dwelling on it.
- Never call experimental work production experience.
- Do not volunteer subjective doubts about code quality; describe scope, maturity, safeguards, and results accurately.
- Do not draft or edit a cover letter unless requested.

## Final verification

Before returning answers, check that:

- every named technology is tied to the correct project;
- every metric is supported by supplied evidence;
- terms such as “owned,” “built,” “production,” and “architected” are justified;
- custom questions are answered directly;
- separate fields remain separate unless the user says they share one field;
- each answer is within the character limit;
- the prose can be skimmed in under a minute.
