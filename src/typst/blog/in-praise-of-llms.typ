#import "_template.typ": *
#show: post.with(
  title: "hex based terrain and pathing - in praise of llms",
  date: datetime(year: 2026, month: 10, day: 16),
  tags: ("devlog", "qproj", "ai"),
  aliases: none,
  draft: true,
  cover: "TODO" // should be one of the hex grid outputs
)

- on the hex terrain -- an overview of how it works and why i want it
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

  so in summary: we made a sick little terrain generation thingy, and it happened very quickly and with very good results. this was the outcome of \$20/month of tokens over the course of about two weeks. This would have taken far more than double the time doing it by hand. In terms of pure efficacy there is no question that this is the way I have to work if I want to achieve my ambitions. Whether it is ethical to do is another question, one I've explored elsewhere. But for now, because I need a job and I will probably kill myself if I don't make this game _soon,_ I am going to be using these machines. I would prefer to be doing it locally. Let's hope I get a job soon so I can get a GPU and stop relying on massive amounts of cloud compute.
