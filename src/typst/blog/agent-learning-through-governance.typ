#import "_template.typ": *
#show: post.with(
  title: "agent learning through governance",
  description: "a review of Davis et al 2026, and a comparison to qproj + d3r",
  date: datetime(year: 2026, month: 11, day: 2),
  tags: ("ai", "quell", "d3r"),
  aliases: none,
  draft: false,
  cover: none,
)

== Cheap Code, Costly Judgment

#media(
  "/media/2026-10-30-on-process/hero.png",
  caption: "Screenshot of the paper. Click to view on arxiv.",
  linked: "https://arxiv.org/pdf/2607.01087",
)

Discovered 10/29/2026

https://arxiv.org/pdf/2607.01087

https://github.com/davisjam/model-based-agentic-software-engineering

#divider()

A friend of mine visited me recently. He's a software engineer and a former PhD
student in computer science. For the past few months he's been in Bali; then, as
soon as the plane made landfall, he decided to bike across America. Needless to
say he's missed the last few months of development in the software scene. During
his visit, among the other million things we talked about, he showed me this
paper. I thought it was pretty interesting and I promised him I'd respond to it,
so here we are :)

The point of this blog post is to compare the paper's process and theory to the
way I've been articulating my own work since I switched to vibe coding full
time. I'll give my take on the paper before giving an overview of d3r, my agent
workflow, and diving into an example of the paper's failure → governance
pipeline in my own work.

== The paper

The process outlined in this paper is pretty much aligned with the way that I
work, though perhaps a bit better articulated. The main idea is this: The
authors want to find a middle ground between fully tokenmaxxed vibe-coded
garbage slop ("velocity-centric development", II.B.1) and overwrought human review for small
code changes ("oversight-centric development", II.B.2). Their middle-ground is
_governance-centrality,_ (II.B.3) which they more or less consider to be a
heavily linted, pre-commit-hooked, tested, and documented codebase. I think they
take this to a bit of an extreme -- they end up with "88 contemporaneous filed
notes, 420 KLOC of production code, and 1.16 MLOC of tests, lints, supporting
documentation, and agent tooling". What an unbalanced codebase!! -- But
nonetheless the theory they get out of it is quite useful. I want to focus on
that part, more than the actual codebase they produced. They write,

#quote(block: true, attribution: [@davisCheapCodeCostly2026, §I])[
  [governance-centric development's] central process is _failure → governance:_ agentic velocity exposes
  structural failure classes, engineering judgment interprets those failures,
  and new governance mechanisms encode that judgment into the engineering
  environment to constrain subsequent agent work. [...]
  In this account, the scarce human work is not implementation-level review, but
  recognizing which failures reveal missing governance and converting them into
  architecture and controls.
]

This means the human stays in the loop. So the human's job moves from writing
the code directly to oversight of the architecture and development process as a
whole. Explicitly, reading the code is _not_ a necessary aspect of this. That
might give some folks a big yuck, and it certainly isn't good for every use.
If you're writing something genuinely new, something where the architecture doesn't
have an existing pattern, then you're going to need substantial oversight until the
model can understand what you're doing. For the paper, they wrote about creating

a SAAS app which applies WCAG standards to slide-shows and PDFs. This has a very
clear acceptance criteria and is focused on making the product as quickly as possible
without it being a terrible, unmaintainable piece of work. I'll talk #link("#xaif-failure-governance")[below] about
some experimental work where the acceptance criteria wasn't clear, but once it was
the development process became about automation. The key to this automation is

a clear specification of the architecture, accessible across sessions to agents.
Agents are always new to the codebase, so giving them context for what they're working
on is the highest priority. And what's better, it is possible to strictly define this
with #link("https://en.wikipedia.org/wiki/Model-based_systems_engineering")[model-based systems engineering] (MBSE).

The classic retort to this is the slippery slope argument. Once you're strictly
defining your model, aren't you just writing code? And yes, UML and SysLang
_are_ programming languages. But, they exist at a higher level of abstraction.

Consider this the shift from the software engineer as the man on the factory
floor to software engineer as the man designing the factory. I mean this in the
literal sense: the planner does not build the product, but only lays out the
plans, often to very precise specifications. The blueprint is not the same as
the product itself -- we aren't living in a Borges story -- the goal is to lay
out the idea and to provide the high-level specifications so that the automated
process can do its work. The goal with governance-oriented vibe coding is to

create a balancing point between extreme reliability (requiring intense
oversight) and extreme velocity, where the velocity is slightly slower but the
product is quite reliable. It is a balancing act between limited human oversight
budgets and limited tolerance for failure.

The goal with all of this is to produce a product that is both more reliable
_and_ cheaper than hand-written code alone could produce.

#quote(
  block: true,
  attribution: [@davisCheapCodeCostly2026, §VII.B.2],
)[_The same speed that can cause agentic technical debt can also make quality-improving changes more affordable and visible._]

We've seen this enough in the wild that I don't feel like it's necessary to
defend it anymore. Agentic coding can produce higher quality software more quickly.
The question is _how_ to do so. So let's dig into the model.

When do we add governance, before failure (_ex-ante_) or after (_ex-post_)? The

paper suggests _both._ It takes this to be something a novel approach, though
this seems pretty obvious to me. (Sometimes the most important thing is to

articulate the obvious.) These days, when models do something you don't expect,
it's more often _your fault_ than the model's. This has not always been true, so
I understand skepticism here, but over the past 6 months there has been a
qualitative shift in the quality of model output. And at the very least, that is
the proposition which this article wants to raise. The solution to this is
stronger governance in the form of skills, `AGENTS.md` constraints, linters, etc.
And notably, this architectural governance can transfer between projects. This
much is pretty obvious from the proliferation of agent skills and the entire
model context protocol. But each project needs its own governance, which is

often overlooked. The difference between the model offered in this repository
and the status quo up until now is that the authors highly recommend committing
this governance, including documentation, logs, skills, and agent deployment
strategies.

As a solo developer, I think that's quite nice. However, I worry about how this
scales out to teams. The paper itself was written about a single project by a
single man, meaning it hasn't had the chance to attempt to scale to larger
teams. I'd be curious to see how team projects use this sort of process. High
velocity projects mean changes in governance can come with large changes in the
output produced, on the order of thousands of lines of code. So I would hardly
say we're past the age of peer review, though again the focus is less on code
quality and more on process quality.

A criticism of this though: There is a HUGE amount of non-production code being
committed to this project. The vast majority of it is LLM-generated
self-direction / guidance / governance in the form of documentation. The size of
the product blows out a model's context window (common), meaning each agent
needs to have a very specific scope. Perhaps this is the trade-off between a
highly-autonomous system (which Davis' is) and a system with more human
oversight and less governance. There certainly doesn't seem to be any strong
cut-off between velocity-centric and oversight-centric codebases -- perhaps
governance-centric is just a convenient term for the goldilocks zone between the
two extremes.

Tightly-scoped agent contexts is an issue we had _before_ LLMs too. In human
teams, individuals have very specific tasks. Capitalism works because we
hyper-specialize -- this one is not just a software engineer, but specifically a
front-end web developer with a focus on React, or a systems developer working on
the Linux kernel with no knowledge of web dev at all. The career of the software
developer in an industrial setting is to be the minuscule gear which makes the
watch tick. But no longer! Instead of focusing on a specific domain, a software
developer can now expand their scope to be a specialist in architecture for a
specific domain, rather than a specific subset of that domain. And architectural
knowledge from one domain often transfers to another. The entire idea of
architectural knowledge is to abstract over the implementation details to see
how the systems fit together. Once you know how to do it in one domain, you
replace the parts but keep the knowledge. It's category theory for software
engineering.

An additional benefit, if you are skeptical of AI consciousness. There is no
problem with treating LLMs as cogs in the machine.
#link("/blog/notes-on-vibe-coding#taylorism-fordism")[Taylorism-Fordism for the
  age of LLMs.] In a way we're _de-Taylorizing_ our workplaces by moving our
position from the individual worker to the petite bourgeois. Just think, for only
\$100/mo you too can own a piece of the means of (digital) production! (And
perhaps in a more physical sense once custom hardware printers get off the
ground.)#footnote[I hope I make myself clear: This is not a revolution in any meaningful sense.
  The tech companies still own the data centers and the factories used to build
  the hardware, thus the means of production. Rental of such hardware / compute
  time is tantamount to renting digital labor. As mentioned this is a shift from
  worker to petite bourgeois, not a seizure in any meaningful sense of the word.
  As long as the people do not own the material means, they own nothing. If anything,
  the increased displacement of workers through this additional layer of automation is
  a step backwards, a further entrenchment of the mechanical at the expense of biological.
  I do hold out hope that this may lead to more people producing software, and eventually
  with 3D printing and bespoke PCB fabs, we may actually seize some means. Though again,
  the revolution must be global and total if it is to succeed at all: from the miners
  to the designers.
]

We've been sliding into the "human judgment thesis," the natural complement to
the "engineering governance thesis" which I've articulated at the start of this
section.

#quote(block: true, attribution: [@davisCheapCodeCostly2026, §VI.B.4])[
  *(a) The engineering governance thesis*: Agentic velocity is possible, but is
  sustainable only when governance is relocated into the engineering
  environment rather than resting on human review. [...]

  *(b) The human judgment thesis:* When implementation becomes abundant, human work
  shifts toward problem framing, abstraction discovery, architectural judgment,
  and governance. [...]

  *Synthesis:* Together, the theses are duals: governance makes velocity
  sustainable, and judgment determines which governance should exist. Agents'
  current implementation capabilities do not supply the structural
  interpretation needed to convert recurring failures into durable governance.
]

I believe this is quite similar to Grant Sanderson's observation that
mathematics is shifting toward theory-building rather than calculation. I've
#link("/blog/terrain-4#reflections-on-method")[discussed this elsewhere], but
long story short I think this is a huge win for STEM. For me, as a philosopher,
theory-building has always been the whole point. Crunching the numbers (writing
the code, calculating the syllogism), while an enjoyable activity and a
necessary part of the craft of theory-building (software engineering,
philosophizing), has never been the _point._ The applied mathematician wants to
get something done. The theoretical mathematician wants to marvel in the beauty
of the universe. Perhaps the technical mathematician just wants the joy of
getting lost in the puzzle. This is a net loss for them, I have to admit, and
that is sad. But the puzzle-solving isn't going away. It's always possible to
learn these skills the same way it's possible and necessary to learn how to do
arithmetic even though we have calculators.

Overall, I think the Davis paper is quite useful as an articulation of the
emerging best-practices for agentic development. I think the material codebase
could be improved in myriad ways, but the theoretical basis it proposes is
well-articulated, and as I'll show below, it follows what I've seen elsewhere.

== My process

Okay, that about sums up my feelings on the paper itself. Now let's talk about ME !!! :D

I'm between jobs right now (#link("mailto:ada@cubething.dev")[hire me!]), so
I've had plenty of time to work on my game project. The game I want to make
relies on some natural language processing, specifically argument mining from
turn-based natural conversation. This isn't a super well-studied field, so there
aren't a lot of tools available for me to #strike[steal] use for my project. In
order to make any progress, I've had to start spiking out an NLP pipeline. I'll
write more about it once I've got more solid results, but I wanted to note the
similarities in my overall flow with the paper discussed above.

=== The Metarepo

First of all, I have something I call a metarepo. This is my overall project
repository, where I keep agent context, notes, etc. It's designed to capture the
organization-level flow. For my game project, I created the
#link("https://github.com/cubething-qproj")[qproj github org,] which hosts all
the repositories, and the corresponding
#link("https://github.com/cubething-qproj/workspace")[workspace metarepo]. This
metarepo flow can be used wherever you need to work across many repositories. I
came up with it #link("/blog/nanvix")[while working on contract at Microsoft.]
It's inspired by tools like Bazel, nix, and
#link("https://github.com/alajmo/mani")[mani,] but bespoke per-org and
simplified.

The structure of qproj's metarepo can be broken down into three intermingled
layers. First, there's the production code, which I've split between the

libraries and binaries. Each project get its own git repo. They're designed to
be independent. Nothing in the bin, lib, or misc folders (introduced below) gets
committed to the metarepo.

```sh
├── bin
│   ├── quell
│   └── vn-jun-26
├── lib
│   ├── q_cam
│   ├── q_proc
│   ├── q_query_lang
│   ├── q_screens
│   ├── q_shell
│   ├── q_term
│   └── q_test_harness
├── misc
│   ├── dev
│   ├── forks
│   ├── infra
│   └── labs
```

The projects are managed in a meta-level Cargo workspace. This is the dev
tooling layer. For the shared infrastructure, there's the
#link("https://github.com/cubething-qproj/infra")[infra repo,] which has scripts
for CI across the github organization (maybe some day I'll switch to
#link("https://tangled.org")[tangled...]); "dev" contains things like bespoke
Zed extensions; "labs" contains spikes and experiments; "forks" is
self-explanatory. This is a bevy project, so I've borrowed and extended the
trait tags so the documentation for my libraries is clear. Additionally,
there's a justfile for common tasks, including repository management,
which uses `repos.yml` (gitignored) as its basis.

```sh
├── .cargo
│   └── config.toml
├── docs-rs
│   └── trait-tags.html
├── misc
│   ├── dev
│   ├── forks
│   ├── infra
│   └── labs
├── .zed
│   └── settings.json
├── Cargo.lock
├── Cargo.toml
├── .envrc
├── .gitignore
├── justfile
├── pyrightconfig.json
├── README.md
├── repos.example.yml
└── rust-toolchain.toml
```

Then there's the agent context directories, which includes skills and documentation.

```sh
├── .agents
│   └── skills
│       ├── bevy-queries
│       ├── q-cam -> ../../lib/q_cam/.agents/skills/q-cam
│       ├── q-os
│       ├── q-proc -> ../../lib/q_proc/.agents/skills/q-proc
│       ├── q-query-lang -> ../../lib/q_query_lang/.agents/skills/q-query-lang
│       ├── q-screens -> ../../lib/q_screens/.agents/skills/q-screens
│       ├── q-shell -> ../../lib/q_shell/.agents/skills/q-shell
│       ├── q-term -> ../../lib/q_term/.agents/skills/q-term
│       ├── q-test-harness -> ../../lib/q_test_harness/.agents/skills/q-test-harness
│       └── ...
├── .docs
│   ├── designs
│   │   ├── done
│   │   ├── retired
│   │   └── wont-do
│   ├── plans
│   │   ├── done
│   │   ├── retired
│   │   └── wont-do
│   └── reference
├── AGENTS.md
```

The documentation is, of course, quite helpful for me too. A lot of the time
these documents are reflections on conversations I have with agents (which often
test my assumptions and show me new ways of viewing the problem -- they're very
valuable interlocutors!) And you'll notice that each project repo has its own
skill, as well as a skill (`q-os`) which covers general usage patterns
cross-repo.

In general, the workflow follows the design scheme for
#link("https://github.com/ada-x64/d3r")[d3r,] an agent harness / workflow that I
designed while at Microsoft Research. I'm no longer using that harness as it's
a bit too mechanically restrictive, but the overall flow is extremely useful.
It's a four-step process.

=== Design

The repository linked above has far more context on it, but the idea is pretty
simple. Start by chatting with an agent in order to create a design document.
This goes in .docs/designs/. The design document details the idea behind the
unit of work, whether that's an epic, a story, or a single PR. Designs are more
commonly used for multi-PR work, but some complex changes might need a design on
their own.

=== Delegate

The delegate phase breaks the design down into concrete steps. In d3r, this
entails a subagent delegation plan. Work that can be parallelized _should_ be
(unless you're trying to save tokens, which these days I definitely am). Delegation
means creating implementation plans, recipes for PRs, more or less, that subagents
can follow through without much reasoning effort.

=== Develop

The develop phase takes the recipes and implements them. There are two modes in
d3r: semi-auto and fully-auto. The semi-auto mode is closer to a human-in-the-loop /
high-oversight model. On perilous work, e.g. kernel code, this is worth doing to
ensure the highest quality. It's also quite useful if this is uncharted
territory for agents. This is really useful for creating new governance --
keeping yourself in the loop to watch over progress is like teaching somebody a
new skill. You need to point to the failures as opportunities to learn. These
get cemented in skills as you go along. In this workflow, the delegation work

and any existing skills act as the _ex-ante_ governance, while skills act as
_ex-post_ governance. It's a continuous cycle of improvement. Once agents

have proven themselves to write high-enough quality content, you can switch to
fully-automatic and just let them chug along.

=== Review

#media(
  "https://www.youtube-nocookie.com/embed/cNm4zyUtWj0?si=SWqt6Xe9qLX88VMq",
  caption: "An excellent talk about agent learning via OSRS, where I got the parenthetical example below.",
)

The final stage is review. PRs are drafted and looked over; agents report on
where they struggled and potential process improvements are noted. Sometimes
these improvement suggestions are bunk ("it would improve my process if you just
told me exactly what to do"), but they sometimes offer real insight.

#anchor("xaif-failure-governance")
== xAIF: A Failure → Governance Case Study

#carousel(
  [
    #media(
      "/media/2026-10-30-on-process/xaif-1.png",
      linked: true,
      title: "xAIF viewer showing Aristotle's argument from form -- nothing selected",
    )
  ],
  [
    #media(
      "/media/2026-10-30-on-process/xaif-2.png",
      linked: true,
      title: "xAIF viewer showing Aristotle's argument from form -- RA 57 selected, showing inference types and UI helpers",
    )
  ],
  caption: "xAIF viewer (click to view)",
)

I've really been going to town with this workflow on the codebases where the
final code quality doesn't matter that much to me. Specifically in my labs,
where I'm testing out ideas rather than polishing a performance-sensitive
codebase.

As mentioned, I'm spiking an NLP pipeline for natural language argumentation.
There has been _some_ work on this in the past, but most of it has been natural
language inference (NLI), which simply scores whether a posterior statement
follows a prior one. It's not a very precise model. There is current work in
this field happening at the #link("https://arg.tech/")[Centre for Argument
  Technology] (ARG-tech) (#link("https://github.com/arg-tech/")[github]) at the
University of Dundee. They've developed a model for mapping out reasoning called
#link("https://github.com/arg-tech/xaif")[xAIF] (the extended Argument
Interchange Format), which is a JSON schema for defining natural language
arguments. This is based on the Inference Anchoring Theory (IAT), which I
believe the folks at ARG-tech also developed. I'll save the details for a
forthcoming postmortem on the project, as I'm still learning. Their website has
been down lately, so I'm sure there's a lot I'm missing!

This format is quite nice and it captures the structure of argumentation quite nicely,
but it doesn't help _evaluate_ said argumentation. For this I'm experimenting with a strategy
from @hintonEvaluatingReasoningNatural2022, namely a combined strategy from the
Comprehensive Assessment Procedure for Natural Argumentation (CAPNA) and the
Argument Type Identification Procedure (ATIP), which itself is based on the

Period Table of Arguments (PTA). You can read more about the PTA and ATIP on #link("https://periodic-table-of-arguments.org/")[Wageman's website.]

Currently, this has taken the form of a bespoke node-based implementation of the
xAIF format, essentially an augmented rewrite of the
#link("https://github.com/arg-tech/OVA3")[OVA3] tool developed by ARG-Tech to
better match my purposes. This tool is being used to identify argumentation
structure, which is the first step in mechanically evaluating said
argumentation.

Now for the relevant bit: This entire process is about the failure → governance
pipeline. I am essentially training my LLMs to annotate arguments for me. The
process follows typical NLP training: a decently large corpus of gold examples,
followed by training on previously unseen data and evaluation thereof. The goal
is to get an NLP model to read a natural argument and produce an xAIF JSON
document. I have been annotating the arguments myself, using an LLM for review,
and repeating that cycle until I am satisfied with the results. Unfortunately,
the IAT, ATIP, and CAPNA still provide plenty of room for judgment and as of such
are far from a mechanical process. They're steps in that direction, but a _lot_ of
work needs to be done to clarify ambiguities.

The labeling process I describe above produces a document, `judgement-calls.md`,
which an agent skill loads up and refers to when creating new labels. The
process now is largely this: I give the model a snippet to annotate, it does so,
I review it in the xAIF viewer, critique it, and we update the governance
accordingly. I think a clean analogy can be drawn here between having the LLM
produce governance via skills and an NLP pipeline producing a model via training
data. The skill is the output of training, though not embedding; the NLP
training gets cemented in model weights, whereas the LLM / natural language
training gets cemented in governance docs.

Some folks have started experimenting with
#link("https://bsky.app/profile/astrra.space/post/3mxz2gkcmk224")[dynamic model
  embedding], though this is more for personality training than skill
ascertainment. I don't doubt that it could be used for something like this
though. We humans are constantly re-embedding ourselves (our neurons are
constantly changing their shape via neuroplasticity) -- why not do the same
thing for our models? #footnote[
  You know why. (Capitalism.) -- Namely, this would
  be a huge risk for the frontier AI shops, whose entire business model relies on
  closed weights. Astra, in the bsky post above, is using DeepSeek for her
  experiments. Another point for the American century of humiliation.
]

== Conclusion

I think that the Davis paper is pretty good,
and it mirrors what I've been doing this whole time, and what I've seen emerging
from some really smart people. If there's anything to take from my reading it's
this: the space between vibe-coded slop and exhausting oversight is a spectrum
parameterized by the level of automation you want. My example libraries, for
spiking new ideas, require a fair bit more human oversight than Davis' SAAS app,
while my game dev projects, which take existing ideas and implement them, can
rely more on automation since the domain space is more well-defined.

#bibliography(
  "../assets/bib/agent-learning-through-governance.yaml",
  full: true,
  style: "chicago-author-date",
)
