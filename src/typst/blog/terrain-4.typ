#import "_template.typ": *
#show: post.with(
  title: "getting all hexed up",
  description: "notes on hex based terrain + in praise of llms",
  date: datetime(year: 2026, month: 10, day: 16),
  tags: ("devlog", "qproj", "ai"),
  aliases: none,
  draft: true,
  cover: "TODO" // should be one of the hex grid outputs
)

// PICTURE: finalized output

#link("/blog/general-introduction")[as you may know] i have been working on a
game (#link("https://github.com/cubething-qproj/quell")[github]). it's a
philosophically-inclined hiking simulator where you go around and read stuff and
talk to people and try to atone for something awful you did. i've been working
on it for like 7 years now. but here's something new: i've been using llms to
speed up the process and boy HOWDY is it working wonders for me. let's start by
talking about the meat of what we've made before i start talking about llms and
how i like to use them. if you're annoyed by that part then just read the first
half i don't care

== Map generation

I've written on terrain generation in the past (#link("/blog/terrain-1")[1],
#link("/blog/terrain-2")[2], #link("/blog/terrain-3")[3]). This isn't the
same algorithm but I'm glad I had those initial experiments, because it made
figuring out how to do this a lot easier.

// IMAGE: IRL board

I started with an IRL prototype. My focus was on path routing and an abstract
sense of exploration much more than terrain generation, so I used a simple hex
grid for this. In the IRL prototype I had paths per-hex, with 2 or 3 spokes
coming out the middle. Placing them in the middle instead of the edge is
equivalent, just on the dual of the hex grid instead. This was easy enough to
do. I had an agent print off some card stock with two copies of all of the
possible two-spoke patterns and one copy of the three-spoke patterns, plus a
small set of nodes with icons for points of interest. Then I added a standee for
the player. POIs were placed in one deck, nodes in another. The board was set up
with dice rolls on a hex grid; each node placement was determined by a dice roll
(mod board size - which I now realize was probably the reason my nodes kept
skewing to one side) for the x and y coordinates. The player would begin in the
center of the board (or wherever else I wanted the spawn tile to go), and
attempt to get to all the key points of interest. As the player proceed, they
would draw from the path deck and place down their tile, one at a time. This
simulated path visiblity, albeit somewhat crudely. While this wasn't really how
the end-result would be on the computer, it helped me think through the
constraints I wanted for the paths and the various gameplay mechanics
surrounding the nodes. Plus it was cool and fun to have physical artifacts.

// PICTURE: Design sketches

Next up was software. I scanned my sketches for the design and ensured the LLM
understood what I had shown it. Then we discussed and came up with a design
document, drafted to disk. Before hopping into implementation, we wrote out an
attack plan, commit-by-commit. Issues were drafted from the plan, and
implementation followed. I made sure we used existing libraries (like
#link("https://github.com/ManevilleF/hexx")[hexx] and my own
#link("https://github.com/cubething-qproj/q_screens")[q_screens]), with bevy_ui
\+ bsn as the front-end for code tweaking. Settings were initially stored as
resources, but I later converted these to assets to make tweaking easier. I used
#link("https://github.com/NiklasEi/bevy_asset_loader")[bevy_asset_loader] to
create asset collections and block on the load, and
#link("https://github.com/NiklasEi/bevy_common_assets")[bevy_common_assets] for
RON serialization.

#figure(caption: "Workflows")[
  #html.details[
    #html.summary[A snippet from `qproj/AGENTS.md`]
    ```md
    ## Workflows

    ### Design

    When I ask you for a _design,_ create a document in `.docs/`. I will review the
    document and provide you commentary. This is likely to have several rounds of
    discussion.

    ### Delegate

    Lay out a plan for implementation. Create a step-by-step implementation plan,
    where each step is a commit. For each, determine risk factors and likely outcomes.


    ### Develop

    Being building out a specified design, one step at a time. After the initial
    pass, stop for manual review. Summarize your work with a story, similar to crit
    story mode. (See the crit skill -- but do not open a crit server.) Once that is
    approved, stage your changes and proceed to an automated subagent review
    focusing on correctness and maintainability. (Your call on what exactly it
    focuses.) The subagent should leave comments in the modified, unstaged code.
    Once automated review changes are approved, then we commit and move on to the
    next step. After all steps are completed, we push a PR.

    A plan or a github issue is _not_ required for work to begin. I will give you
    ad-hoc instructions if necessary. That being said, always scan for existing
    issues and PRs when we're ready to push. It's important to keep all that clean.

    When building out a feature for a binary package, we are most likely going to
    need manual review and playtesting to ensure that the code is correct. I will
    mostly prompt you for architectural implementations and will tweak the code
    myself to suit the feel of the game. Do not modify existing constant values,
    those are essential to game feel.

    When writing tests, avoid tests which are fragile or redundant. Keep the testing
    surface minimal -- check for edge cases and correctness. Avoid change-detector
    tests, i.e., tests which rely on highly specific facets of the code, e.g.
    constant values, or things which _happen_ to be true, such as screen order. Avoid
    writing tests which would be better off as unit tests for an upstream crate. If
    you find such scenarios, report them and suggest writing an issue in the
    upstream crate's repo.

    ```
  ]
]

  - how it works: heightmap terrain generation on top of a hex-based grid
  - paths go on the hex grid, terrain is constrained to the vertices
  - nodes with points of interest exist scattered throughout the map, filling a tile
  - a large map is generated with creeks starting at high points and eroding the land
  - a window over the overall terrain is picked based on suitability factors: node placement suitability (flatness), nice view calcuation for rest spots (e.g. overhangs, nooks, near water), crossings for creeks placed at most twice, path constraints to reduce spurs and ensure loops, recalcuation of paths given node and path constraints for the surrealist 'getting lost' vibe
  - all of this is configurable and asset-based. what we've made is a tool for level generation.

- ai has made me orders of magnitude more productive
- i can focus more on design in all aspects
  - instead of spending a month struggling to find resources on game development e.g. how rasterization over a terrain mesh works, or how path finding algos work and how to tweak them, i can prompt to ask and it teaches me at a high level, then implements it. i may not have the hard-earned experience of crunching the numbers myself, but for game design that was never the point.
- i don't have to re-do solved problems
  - the knowledge i need isn't expert-level and in depth -- i need know _how_ not know _that_ -- these algorithms are tools, not the object of my art
  - an algorithm is like a ball bearing. it can be a beautiful thing! but most of the time you don't care about how it works, just _that_ it works, and in what situations it is useful
- spiking is incredibly easy
  - the hex terrain was initially tested in a python lab for quick compilation and turnaround. we did statistical analysis over 1000 seeds per run, generated SVG-based visualzations for the terrain, and several graphs tracking things like path loop count, bench locations, creek depth, and time to cross all paths based on the tobler hiking algorithm
  - it would have taken me a month or longer of full time work to do this. i spent 3 days on it.
- code review is not that hard
  - having somewhat messy code for the sake of moving on is super common especially in long-term projects, it can always be cleaned up later if needed
  - that is the same attitude i have always had -- why stop now?
    - on the argument that it's all slop: not if you review, not if you have proper ownership and safeguards. ai can be coaxed into producing really good output very quickly, but you have to know how to tune it to your specifications
    - it may not be organized exactly how you like it (but you can work around it -- i have file organization in my AGENTS.md and reinforce it at review time)
    - automated review with a subagent is extremely important for catching subtle bugs -- but it's also important to know what's worth doing now and what's a red herring. these machines are meant to provide you the highest quality code, but are trained on a huge corpus of code -- that means they'll often write middling code and point out nits that don't matter. sometimes that means going against _your_ instincts. it takes discipline and skill to know what's worth doing. in the end, _you_ are still the operator and _you_ still own the output. act like it!

so in summary: we made a sick little terrain generation thingy, and it happened
very quickly and with very good results. this was the outcome of \$20/month of
tokens over the course of about two weeks. This would have taken far more than
double the time doing it by hand. In terms of pure efficacy there is no question
that this is the way I have to work if I want to achieve my ambitions. Whether
it is ethical to do is another question, one I've explored
#link("/blog/notes-on-vibe-coding")[elsewhere.] But for now, because I need a
job and I will probably kill myself if I don't make this game _soon,_ I am going
to be using the bots. I would prefer to be doing it locally. Let's hope I get a
job soon so I can get a GPU and stop relying on massive amounts of cloud
compute.
