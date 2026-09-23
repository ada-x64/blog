#import "_template.typ": *
#show: post.with(
  title: "a crater for a kernel",
  description: "how I keep a fleet of downstreams building while the kernel underneath them moves",
  tags: ("nanvix", "ci", "devtools", "ai"),
  aliases: none,
  draft: true,
  cover: none,
)

// Diagram helpers. Boxes carry their own light fill and dark text, and
// everything else is a mid-tone grey, so the SVG reads in both themes.
#let ink = rgb("#483d8b")
#let muted = rgb("#8a8a8a")
#let node(body, fill: rgb("#f0f8ff")) = box(
  fill: fill,
  stroke: 0.6pt + ink,
  radius: 3pt,
  inset: (x: 6pt, y: 4pt),
  text(size: 9pt, fill: black, body),
)
#let upstream-fill = rgb("#e6e6fa")
#let user-fill = rgb("#f0fff0")
#let down = text(size: 11pt, fill: muted)[↓]
#let note(body) = text(size: 8pt, fill: muted, body)
#let diagram(body) = html.elem(
  "div",
  attrs: (
    style: "width: fit-content; max-width: 100%; margin: auto; overflow-x: auto;",
  ),
)[#html.frame(body)]

This is a write-up of how I work on Nanvix: one kernel, one build system, one CI system, and a fleet of ported libraries that all have to keep building while the ground moves under them. It's part architecture doc, part devlog. Most of it grew by accident, so I'm writing it down before I forget which accidents turned out to be load-bearing.

// The blog compiles as one bundle, so an unscoped outline would list every
// post's headings. Bound it to this post with the markers below.
#metadata(none) <crater-for-a-kernel-start>
#outline(
  title: [contents],
  target: heading
    .where(level: 2)
    .after(<crater-for-a-kernel-start>)
    .before(<crater-for-a-kernel-end>),
)

== how this started
<how-this-started>
I came onto #link("https://github.com/nanvix/nanvix")[Nanvix] as a contractor for Microsoft Research. Nanvix is a microkernel written in Rust, built for sandboxed execution. The job, as scoped, was two things: a build system for the libraries being ported onto the kernel (#link("https://github.com/nanvix/zutils")[`zutils`]) and a package ecosystem on top of GitHub Actions to build, test, and ship them (#link("https://github.com/nanvix/workflows")[`workflows`]).

Those ported libraries are the _downstreams._ They start with the unglamorous C stuff - zlib, openssl, xz, sqlite - and end with CPython, packaged as `nanvix-python`, which #link("https://github.com/microsoft/mxc")[MXC] consumes. That last link is the reason any of this matters. If `nanvix-python` doesn't build, the thing people actually use doesn't ship.

It turned out the build system wasn't the hard part. The hard part was keeping every downstream working while upstream kept changing. The kernel changes, `zutils` grows a feature, a workflow gets refactored, and the question is always the same: _what did this break, and where?_

If you've spent time around Rust you might know #link("https://github.com/rust-lang/crater")[crater]: before a compiler change lands, run it against the whole crates.io ecosystem and see what falls over. What I ended up building is a small, hand-rolled crater for a kernel. Before an upstream change ships, run the fleet against it. The rest of this post is the machinery that makes that cheap enough to actually do - on CI, and on my laptop.

I've since moved from CI work onto the kernel itself, but I still live inside this setup every day.

== the lay of the land
<the-lay-of-the-land>
There are three core repos:

- *`nanvix`* is the kernel. It has its own build system (`./z build -- …`) and is _not_ a zutils consumer.
- *`zutils`* is the build tooling, a Python package. Every downstream subclasses its `ZScript` base class.
- *`workflows`* holds the reusable CI workflow, the update bots, and `consumer-registry.json`.

Everything else is a downstream. They form a dependency chain: compression and crypto libraries at the bottom, then libxml2 and sqlite, then libxslt, lxml, CPython, and finally `nanvix-python`.

The tiers weren't there at first. Early on, downstreams just shipped whenever they were ready - there weren't enough of them depending on _each other_ for ordering to matter. Tiers showed up later, once the chains got deep enough that building lxml against a libxml2 that hadn't caught up yet was a waste of a CI run.

All of this lives in one file. `consumer-registry.json` lists every downstream, its tier, which updates it accepts, and which toolchain it builds with. The nightly schedule is derived from it, the update bots read it, and so do my local scripts. If a repo isn't in the registry, as far as the fleet is concerned it doesn't exist.#footnote[`posix-tests` is the one exception I keep checked out locally. It isn't in the registry, so none of the fleet tooling touches it.]

On the host side we build on Linux, where the toolchain lives in Docker, and on Windows. The guest is x86 on microvm, tested across three process modes (multi-process, single-process, and standalone) and two memory sizes (128 and 256 MB). Hyperlight was an early target and is no longer supported.

#let tier-row(label, repos, fill: rgb("#f0f8ff")) = (
  align(right + horizon, note(label)),
  align(center + horizon, stack(
    dir: ltr,
    spacing: 4pt,
    ..repos.map(r => node(raw(r), fill: fill)),
  )),
)
#let arrow-row = ([], align(center, down))

#figure(
  kind: image,
  caption: [The fleet, by tier. Each tier builds against everything above it.],
  diagram(grid(
    columns: 2,
    column-gutter: 10pt,
    row-gutter: 4pt,
    ..tier-row(
      "upstream",
      ("nanvix", "zutils", "workflows"),
      fill: upstream-fill,
    ),
    ..arrow-row,
    ..tier-row("tier 1", (
      "busybox",
      "zlib",
      "bzip2",
      "openssl",
      "quickjs",
      "libffi",
      "xz",
    )),
    ..arrow-row,
    ..tier-row("tier 2", ("libxml2", "sqlite")),
    ..arrow-row,
    ..tier-row("tier 3", ("libxslt",)),
    ..arrow-row,
    ..tier-row("tier 4", ("lxml",)),
    ..arrow-row,
    ..tier-row("tier 5", ("cpython",)),
    ..arrow-row,
    ..tier-row("tier 6", ("nanvix-python",)),
    ..arrow-row,
    ..tier-row("end user", ("MXC",), fill: user-fill),
  )),
)

== one contract for every repo: the `./z` lifecycle
<the-z-lifecycle>
Every downstream answers to the same verbs:

```sh
./z setup     # fetch the Nanvix sysroot and toolchain
./z build     # cross-compile
./z test      # run the test suite on the guest
./z release   # package a release tarball
```

(Plus `benchmark` and `clean`, which do what they say.) Under the hood, each verb is a method on the repo's `ZScript` subclass in `.nanvix/z.py`. A downstream overrides the ones it needs and inherits the rest.

#figure(caption: "A typical downstream, trimmed.")[
  ```bash
  zlib/
  ├── .github/workflows/nanvix-ci.yml   # thin caller, see below
  ├── .nanvix/
  │   ├── z.py            # the ZScript subclass
  │   ├── nanvix.toml     # what to build against
  │   ├── nanvix.lock     # pinned, and mandatory
  │   └── venv/           # created by the bootstrap
  ├── .zutils-version     # pinned zutils version
  ├── z                   # dispatches to one of these two:
  ├── z.sh
  └── z.ps1
  ```
]

The bootstrap wrappers are the part nobody thinks about, which is the point. `z` works out which platform it's on and hands off to `z.sh` or `z.ps1`, which create `.nanvix/venv` with the pinned zutils version if it isn't already there. Clone a repo, type `./z build`, and it works.

Whatever I'd change about the implementation (and #link("/blog/notes-on-vibe-coding.html")[I've listed some of it]), the contract is the part that paid for itself. There are three kinds of client for these verbs: me, CI, and the agents. They all use the same interface. A fleet-wide test stops being a project and becomes a `for` loop: run the lifecycle everywhere, and see what's red.

== how changes flow through the fleet
<how-changes-flow>
Each downstream's CI is a thin caller of one reusable workflow:

#figure(caption: ".github/workflows/nanvix-ci.yml, trimmed.")[
  ```yaml
  on:
    schedule:
      - cron: "0 9 * * *"   # tier 1
    push:
      branches: ["nanvix/**"]
    pull_request:
      branches: ["nanvix/**"]

  jobs:
    ci:
      uses: nanvix/workflows/.github/workflows/nanvix-ci.yml@v3.0.6
      with:
        platforms: '["microvm"]'
        process-modes: '["standalone"]'
        memory-sizes: '["256mb"]'
        windows-test: true
  ```
]

The real logic lives in `workflows`: build, a Windows test leg, benchmarks, release, a Windows release, and auto-merge. Each caller picks its slice of the platform, process-mode, and memory-size matrix. Downstream branches live under `nanvix/**`, so a port stays cleanly separated from the upstream project it forked from.

The fleet moves on a schedule. Tier 1 runs nightly at 09:00 UTC, tier 2 at 10:00, and so on down to tier 6 at 14:00, giving each tier an hour to settle before the next one builds on it. When `nanvix` or `zutils` cuts a release, the updater bots open PRs on `automation/update-nanvix-version` or `automation/update-zutils-version` in each downstream that accepts that update. Those PRs auto-merge when CI is green. Once the final tier is current, it signals `nanvix/distro`.

I did want to get one thing right about the bots: the job that edits a repo shouldn't be the job holding the keys. So an update happens in two halves. A job with no credentials works out the change and produces a patch, and a separate publisher applies it using a GitHub App token that is scoped to that one consumer. Nothing that runs the downstream's build ever holds a token that can push.

#let step(body, fill: rgb("#f0f8ff")) = node(body, fill: fill)
#figure(
  kind: image,
  caption: [One upstream release, walking down the fleet.],
  diagram(stack(
    dir: ttb,
    spacing: 5pt,
    align(center, step(
      fill: upstream-fill,
    )[`nanvix` or `zutils` cuts a release]),
    align(center, down),
    align(center, step[tier _N_ updater wakes up (nightly cron)]),
    align(center, down),
    align(center, step[credential-free job builds a patch]),
    align(center, down),
    align(center, step[scoped publisher opens an `automation/…` PR]),
    align(center, down),
    align(center, step[`nanvix-ci.yml` runs the matrix]),
    align(center, down),
    align(center, step[green: auto-merge and release]),
    align(center, note[an hour later, tier _N_ + 1 picks it up]),
    align(center, down),
    align(center, step(
      fill: user-fill,
    )[last tier current: dispatch to `nanvix/distro`]),
  )),
)

== the local workspace: many repos treated like a monorepo
<the-local-workspace>
This is the idea the rest of the workflow depends on: *the org directory makes many repos behave like one monorepo.* Every repo in the org is checked out side by side under `~/repos/nanvix`, and everything that needs to see the fleet - scripts, hooks, agents - assumes that layout.

#figure(caption: "~/repos/nanvix, trimmed.")[
  ```bash
  ~/repos/nanvix/              # not a git repo
  ├── .config/                 # ...but this one is
  │   ├── AGENTS.md
  │   ├── justfile
  │   ├── consumer-registry.json
  │   ├── githooks/
  │   ├── scripts/             # nanvix-scripts
  │   └── .pi/                 # agents and skills
  ├── justfile -> .config/justfile
  ├── nanvix/
  ├── workflows/
  ├── zutils/
  │   ├── .bare/               # bare clone
  │   ├── .git                 # "gitdir: ./.bare"
  │   ├── .envrc               # DEFAULT_BRANCH=dev
  │   ├── AGENTS.md -> ../.config/AGENTS.md
  │   └── worktrees/
  │       ├── active/
  │       ├── default/
  │       └── feat/…
  ├── zlib/
  └── …
  ```
]

The org directory itself isn't a git repo; `.config` is. `just sync` makes the rest of it true. For each repo in the registry, it creates a bare clone in `.bare/`, symlinks the shared config (`AGENTS.md`, `pyrightconfig.json` and friends) into place, writes the repo's `DEFAULT_BRANCH` into `.envrc`, and installs the pre-push hook. One edit in `.config` lands everywhere.

Each repo is a bare clone with worktrees hanging off it. `worktrees/default` tracks the default branch, and `worktrees/active` is whatever I'm working on right now. Branches follow a small set of prefixes - `feat/`, `fix/`, `chore/`, `doc/`, `tests/`, `release/`, and `automation/` for the bots - and each worktree directory is a flat kebab-case version of its branch name.

There's a single #link("https://github.com/casey/just")[`justfile`] at the top of the tree. Since `just` walks up the directory tree looking for one, every recipe works from inside any worktree of any repo. Most of the recipes are thin wrappers around `nanvix-scripts`, a small Python CLI that lives in `.config/scripts`.

The machine underneath is a Windows host with all development done inside WSL, because every one of these projects would rather be on something Unix-like. When I need the Windows side, I reach it from WSL through the `winhome` mount. That becomes important in #link(<making-local-match-ci>)[a minute].

Looking ahead: git submodules might be a cleaner way to express this layout. A superproject would give the "org as a monorepo" idea an actual commit history instead of a sync script. I haven't tried it yet.

== a day in the life
<a-day-in-the-life>
The loop looks like this:

+ *`just standup`* pulls yesterday's commits and my assigned GitHub issues, and has `pi` narrate them into a summary.
+ Pick an issue and make a worktree for it.
+ Make the change.
+ *`just lc`* runs the `./z` lifecycle locally.
+ Push. The pre-push hook on downstreams is two gates: a diff-size check (250 changed lines by default) and then `just lc --platform all`.
+ Review, then open a draft PR.
+ *`just prune`* sorts my branches into open PR, merged, closed, stale, and active, so I can clean up what's done.

The diff-size gate is the most opinionated thing in the whole setup, and the one I'd defend the hardest. You can override it with `--no-verify`, but having to type that is usually the nudge to split the PR.

When the change is in `zutils` or `workflows`, the loop gets a fleet-level step. *`just test-downstream`* takes a local zutils worktree (`worktrees/active` by default) and runs its lifecycle across every downstream, optionally with `--with-windows` and `--with-nanvix`. This is the crater run: see what breaks _before_ it ships. After merging, *`just ci-status`* shows the latest CI result on each downstream's default branch, and *`just auto-status`* shows where each open `automation/` PR stands. There are also some `stack-*` helpers for rebasing and pushing stacked branches, which I lean on whenever one fix turns into three PRs.

An honest note on worktrees. They made parallel work easy on the interpreted-language repos, where a worktree is basically free. On `nanvix/nanvix` they were less fun: every worktree grows its own compilation targets, and those ate disk space fast. My personal projects have since gone back to a single workspace per repo. This setup hasn't switched yet.

== making local match CI
<making-local-match-ci>
A local check you don't trust is worse than no local check at all. It costs time and still sends you to CI to find out. So a lot of effort went into making "passes on my machine" mean "passes on CI".

*`just lc`* is the entry point. It runs the lifecycle with `--platform linux`, `windows`, `windows-ci`, or `all`, and can swap in local versions of the pieces upstream of the repo: `--with-zutils`, `--with-nanvix`, and `--with-local-workflows`. On a downstream, `all` means linux, then windows-ci, then windows. It's one command, and it tests both hosts from the same terminal.

The `windows` leg mirrors the working tree out of WSL to `~/winhome/tmp/<repo>/<branch>`, runs `pwsh.exe .\z.ps1` against that copy, and checks that `.nanvix/out/dist` came out the other end.

The `windows-ci` leg goes a step further. Rather than keeping a local imitation of CI (which drifts, always), it hands the _real_ `nanvix-ci.yml` to `wfrun`, a small interpreter in `nanvix-scripts`. `wfrun` is a Python orchestrator with a Node sidecar that wraps GitHub's own `@actions/workflow-parser` and `@actions/expressions` packages, so the matrix and expressions are evaluated the same way Actions evaluates them. It reproduces CI's Windows jobs, with `gh` and `pip` stubbed out so a local run can't touch anything real on GitHub. The point is that the workflow file stays the single source of truth. If CI changes, the local run changes with it.

== working with agents
<working-with-agents>
The agents aren't an add-on here. I use #link("https://github.com/badlogic/pi-mono")[Pi] as my agent harness, and a lot of this setup is shaped around the fact that an agent is also a user of it.

That's the other half of why the uniform interface matters. An agent doesn't need to know how libxslt builds; it needs to know `./z build` and `just lc`, which are the same everywhere. The shared `AGENTS.md` (symlinked into every repo by `just sync`) tells it who's who, which repos exist, and where the rules live. Machine-specific notes go in `AGENTS.local.md`.

On top of that:

- *Subagents with narrow roles:* an implementor, a reviewer, an auditor, and a researcher. Each one gets the context its job needs and not much else.
- *Skills for recurring workflows.* `nanvix-fix` walks a kernel bug from issue to C repro test to fix to draft PR. `nskip-fix` re-enables skipped CPython tests once the kernel fix they were waiting on has landed. `crit` and `difit-review` put a diff or a plan in front of me for inline review.

A human stays in the loop for every commit and every GitHub operation. The agents can research, implement, and run the lifecycle as much as they like, but nothing gets committed, pushed, or posted without me approving it. The pre-push gates apply to them too, and that's by design.

== principles and lessons
<principles-and-lessons>
Stated plainly, since I only figured most of these out in hindsight:

- *One source of truth.* The registry says what the fleet is, and the CI YAML says what CI does. Everything else reads from them.
- *Uniform interfaces.* The same verbs in every repo, for every client: human, CI, or agent.
- *Small, reviewable PRs.* Enforced by a hook, because good intentions don't survive a Friday.
- *Local should equal CI.* If the two disagree, the local check is the bug.
- *Automate the fleet, not the repo.* Anything I'd do to one downstream, I'll eventually need to do to all of them.

The meta-lesson is that *structure should follow need.* Tiers only arrived once the dependency chains were deep enough to pay for them. Worktrees stayed only where they paid for themselves, and I'd drop them from `nanvix/nanvix` tomorrow. Every piece of this setup started as a workaround for something that hurt. The ones that stuck are the ones that kept paying.

== appendix
<appendix>
=== glossary
<glossary>
/ downstream: A library ported to Nanvix that builds with `zutils` and is listed in `consumer-registry.json`. `nanvix` itself is not a downstream.
/ tier: A downstream's position in the dependency chain. Each tier builds nightly, an hour after the tier above it.
/ lifecycle: The `./z` verbs every downstream implements: setup, build, test, release, benchmark, and clean.
/ worktree: A git working tree attached to a repo's bare clone. Here, one per branch under `<repo>/worktrees/`.

=== cheat sheet
<cheat-sheet>
```sh
just sync                      # clone, link config, install hooks
just standup                   # yesterday's commits + my issues
just lc --platform all         # lifecycle on linux and windows
just lc --platform windows-ci  # CI's windows jobs, via wfrun
just lc --with-zutils <path>   # ...against a local zutils
just test-downstream           # local zutils across the fleet
just ci-status                 # latest CI per downstream
just auto-status               # open automation/ PRs
just prune                     # sort and clean up branches
```

#metadata(none) <crater-for-a-kernel-end>
