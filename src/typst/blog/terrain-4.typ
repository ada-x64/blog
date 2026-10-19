#import "_template.typ": *
#show: post.with(
  title: "getting all hexed up",
  description: "notes on hex based terrain + in praise of llms",
  date: datetime(year: 2026, month: 10, day: 16),
  tags: ("devlog", "qproj", "ai"),
  aliases: none,
  draft: true,
  cover: "TODO", // should be one of the hex grid outputs
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

#media(
  "/media/terrain-4/physical.jpg",
  linked: true,
  caption: "The physical prototype",
)

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

#carousel(
  caption: "Design documents carousel. Click to view.",
  media("/media/terrain-4/27-sept-26c.jpg", linked: true),
  media("/media/terrain-4/7-oct-26a.jpg", linked: true),
  media("/media/terrain-4/7-oct-26b.jpg", linked: true),
)

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

#figure(caption: "A snippet from " + `qproj/AGENTS.md`)[
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

I started off just replicating the 2d board. It was a flat, gizmo-based hex grid
with nodes, paths on the edges. From there we started experimenting with rules
for node placements and path constraints. Originally, we were just playing
around with pathfinding algorithms. Then I realized that we were going about it
backwards -- instead of building the terrain around the paths, we need to build
the paths around the terrain. This is obvious in hindset, but moving from 2d to
3d it wasn't immediate :)

I had the bots whip up a python laboratory to do some quick experiments over
large sample sizes for the different path algorithms. We were trying to restrict
the number of path tiles, loops, and other such path properties directly as a
factor of the algorithm. Here are some of the visuals we got out of it.

#carousel(
  caption: "Initial 2d experiment results. 'Current' means A* + noise.",
  media("/media/terrain-4/2d/gallery.png", linked: true),
  media("/media/terrain-4/2d/distributions.png", linked: true),
  media("/media/terrain-4/2d/character.png", linked: true),
)

We didn't begin moving back to rust for a bit, the python code was faster to
iterate with, and we can still visualize everything in 2d using SVG-based
visualizations for a heightmap, color-coded for height like a typical
geographical survey. We began with a typical perlin noise based terrain
algorithm. From there we add tweaks. I'm basing this game off of hikes I've been
on, in the glacial hills of northeast Kansas. So we landed on rolling hills and
creeks cutting into the loam, oak and hickory dense around the water.

In order to make a path, we need to rank how easy it is to hike around. So we used a symmetric approximation of the #link("https://en.wikipedia.org/wiki/Tobler's_hiking_function")[Tobler hiking function] to rank edges. From there, we place the nodes according to suitability (terrain flatness \* pull toward water, discussed in detail below), and link between them using a slightly noisy A\* algorithm.

#carousel(
  media("/media/terrain-4/2d/01-heightmap.png", caption: "Terrain"),
  media("/media/terrain-4/2d/02-cost.png", caption: "Path cost"),
  media("/media/terrain-4/2d/03-node-sites.png", caption: "Node placement"),
  media(
    "/media/terrain-4/2d/05-graph.png",
    caption: "Connected node network, ranked by cost",
  ),
  media("/media/terrain-4/2d/06-trails.png", caption: "Node placement"),
)

Paths are limited by a maximum budget. In the figure above on the connected node network, note that nodes 0 and 2 do not even have a candidate connection as the cost between them would be too high. The 10 cheapest paths are chosen. Extra pathing

I came up with the idea for a "tease" constraint, where two
nodes would be placed within eyesight but disconnected. And we came up with rest
spots, benches, which are placed at either scenic vistas or cozy nooks. I did
not come up with the algorithms for this myself, but the idea is that we take a
differential over the terrain to calculate how flat or bumpy it is. This value
is normalized across the board and can be tweaked with a 'spread' variable.


== Nodes

=== Points of Interest

Let $h(v)$ denote the height of a vertex $v$, and let $V(T)$ be the set of six
corner vertices of a hex tile $T$. Let $N(T)$ be the neighborhood of $T$. Our
board is a window over a larger hex grid, so all tiles are interior. Note that
$V(T) subset.eq V(N(T))$. The height range over that neighbourhood is

$ r(T) = max_(v in V(N(T))) h(v) - min_(v in V(N(T))) h(v) $

Let the board be the playable tiles,
$B = { T(x, y) : 0 <= x < "cols", 0 <= y < "rows" }$.

Let $m$ be the median range over the board,
$m = "median" { r(U) : U in B }$. Then we define the suitability score $s(T)$ as

$ s(T) = exp(- r(T) / m) $

Perfectly flat ground scores 1, and a tile exactly as bumpy as the median tile
scores $e^(-1) approx 0.37$. Because the range is divided by the median,
"flat" is relative to the board, so on bumpy boards the flattest available
ground still scores well.

Next, introduce $sigma$, our spread variable. Raising suitability to the power
$sigma$ sharpens it: the larger $sigma$ is, the more strongly POIs prefer the
flattest ground. At $sigma = 0$ flatness is ignored entirely. On bumpy terrain,
flat patches are scattered, so POIs end up scattered too; on a plateau, they
gather towards it.

People naturally build structures towards water, so let's define a constant
$beta$ to track this. The larger $beta$ is, the more POIs favor ground near
water. Let $C$ be the set of creek tiles, and let $d(T, C)$ be the distance from
$T$ to the nearest creek tile, measured in hexes. The water pull factor is

$ omega(T) = 1 + beta e^(-d(T, C) \/ 2) $

so a tile right beside a creek gets up to $1 + beta$ times the weight, fading
over a couple of hexes. Nothing but a crossing may sit on a creek, so the final
placement weight is

#definition(
  $
    w_p (T) = cases(
      omega(T) s(T)^sigma & T in.not C,
      0 & T in C,
    )
  $,
  caption: "POI weight",
)

Placement doesn't sample tiles in proportion to $w$. Instead, each POI goes on
the tile that best balances weight against distance from everything already
placed.

```rust
fn place_poi(board: &Board, placed: &[Tile], rng: &mut Rng) -> Tile {
    board.tiles()
        .filter(|t| !placed.contains(t))
        .max_by_key(|&t| {
            // Distance to the nearest placed node; the board's edge counts
            // too, but repels only half as strongly.
            let separation = placed.iter()
                .map(|&p| hex_distance(t, p))
                .fold(2.0 * edge_distance(t), f32::min);
            separation * w(t) * rng.jitter()
        })
}
```

#media(
  "/media/terrain-4/suitability3d.png",
  title: "Suitability on the 3D heightmap",
  caption: "Suitability on the 3D heightmap. More blue is more suitable.",
  linked: true,
)


== Benches

When you're on the trail, you need to take a break every now and again. Maybe
you need to reorganize your stuff or you just need a breather. Benches offer
that. I want to place them somewhere with a sense of beauty. There are two
really contemplative views, I think: those with a great view, like a
mountain-top, or those tucked away in a dense patch of green. Both are
questions about what you can see from a tile, so let's put a viewer on every
tile and look around.

Let $x(T)$ be the center of tile $T$, and let $h(p)$ be the ground height at
any point $p$ on the terrain. We'll write $h(T)$ for $h(x(T))$. Our viewer's
eye sits a height $g$ above the ground, and they look at every other tile
within a radius of $rho$ hexes:

$ R(T) = { U : U != T, ||x(U) - x(T)|| <= sqrt(3) rho } $

(The $sqrt(3)$ converts hexes to edge lengths, since neighboring tile centers
are $sqrt(3)$ edges apart.) Let $S(T) subset.eq R(T)$ be the tiles we can see:
those where a ray from the viewer's eye to the ground at $x(U)$ isn't blocked
by the terrain. We check this with a simple ray march, sampling $n = 16$
points along the way.

We can get two measures from this. The first is openness: the ratio of visible
tiles over the given radius.

$ "open"(T) = (|S(T)|)/(|R(T)|) $

But what we're looking for is the _opposite_ of openness. We want benches in
quiet nooks. So let's just take the complement:

$ "quiet"(T) = 1 - "open"(T) $

Our second score is for dramatic views. Let $D$ be the height difference at
which a view counts in full; anything bigger is capped. With a small $D$,
almost any visible height difference counts fully, so we're mostly counting
_how many_ tiles differ from us. With a large $D$, few differences reach the
cap, so dramatic cliffs and deep gullies win.

Let $Delta(T, U) = h(T) - h(U)$, positive when $U$ is below us. With
$theta in [0, 1]$ weighting upward views against downward ones,

$
  "relief"(T) = 1 / (|R(T)|) sum_(U in S(T))
  min(1, ((1 - theta) max(Delta, 0) + theta max(-Delta, 0)) / D)
$

The $min$ caps each tile's contribution at 1, so relief stays in $[0, 1]$.
Note that we divide by $|R(T)|$, not $|S(T)|$: hidden tiles count as zero, so
a spot that sees only a sliver of a big drop scores less than one that sees
the whole valley.

So we have our two scores, but they live on different scales, and blending
them directly would let whichever varies more dominate. So we rank them. For a
score $f : B -> RR$, let $"rank"(f) : B -> [0, 1]$ be

$ "rank"(f)(T) = (|{ U in B : f(U) < f(T) }|) / (|B| - 1) $

so that $r_q : B -> RR = "rank"("quiet")$ and $r_r : B -> RR = "rank"("relief")$ are both
functions from tiles to $[0, 1]$. Ranks only care about order, so a board with
a few dramatic cliffs and a board with gentle hills both get their best spots
ranked at the top.

Introduce $k$, our sharpness parameter. Raising a rank to the power $k$ crushes
everything except the very top, so only the most enclosed spots and the best
views score well. Ground that's middling at both doesn't win. Finally,
$nu$ is our view preference, from 0 (quiet benches) to 1 (view benches):

#definition(
  $ w_b (T) = (1 - nu) r_q (T)^k + nu r_r (T)^k $,
  caption: "Bench weight",
)

Benches are placed the same way as POIs, using $b$ instead of $w$. Like POIs,
they stay off creeks, and they try to keep a minimum distance from one another.

#carousel(
  media(
    "/media/terrain-4/dramatic-bench.png",
    caption: "A dramatic bench",
    linked: true,
  ),
  media(
    "/media/terrain-4/quiet-bench.png",
    caption: "A (relatively) quiet bench",
    linked: true,
  ),
)

The quiet benches don't look so quiet here, but you have to imagine them
surrounded by forestry. We're early in development, so a little imagination
goes a long way :)

== Trails

=== Cost

Now that we've placed the nodes, we need to join them. Trails run along the edges of
the honeycomb, so our graph $G = (V, E)$ has every hex corner as a vertex and
every hex edge as an edge. Each node $N$ sits on a pad: its tile is levelled,
and the ground around it graded to match, so we can easily fit pre-authored
scenes onto it. Let $h'(v)$ be the height of vertex $v$ after levelling.

Walking uphill or downhill is harder than walking on the flat, so the cost of
an edge $epsilon = {u, v}$ grows exponentially with how much it climbs. Let
$alpha$ be our aversion to slopes:

#definition(
  $
    c(epsilon) = cases(
      exp(alpha |h'(u) - h'(v)|) & epsilon "is on the board and doesn't cross a creek",
      infinity & "otherwise",
    )
  $,
  caption: "Path traversal cost",
)

For two nodes $N$ and $M$, let $Pi(N, M)$ be the set of paths that start at
a corner of $N$'s tile and end at a corner of $M$'s. A path $pi in Pi$ is just a collection of edges; $pi = { epsilon_1, ..., epsilon_n : epsilon in E}$. Given a price for each
edge, $w : E -> RR$, the distance between them is the cheapest such path:

$ d(w, N,M ) = min_(pi in Pi(N, M)) sum_(epsilon in pi) w(epsilon) $

So $d(c, K, K')$ is the cost of walking cross-country, ignoring trails.
Let $Pi$ denote the set of all paths. For any edge weighting $w$, let $d(w, (N,
    M)): (RR, Pi^2) -> RR$ be the cheapest way between two nodes: the minimum over
paths $Pi$ from any vertex of $v in V(N)$ to any vertex $u in V(M)$ of $sum_(v in
Pi) w(v)$. So $d(c, (N,M))$ is the cost of walking cross-country, ignoring
trails.

As we lay trails, let $L subset.eq E$ be the set of laid edges. Walking the
network means staying on $L$, but crossing a node is free:

$
  n(epsilon) = cases(
    0 & epsilon "is on a node's perimeter",
    c(epsilon) & epsilon in L,
    infinity & "otherwise",
  )
$

=== The spanner

Start with the cheapest pairs of nodes, ordered by $d(c, K, K')$. For each
pair, check whether the network already gives a reasonable walk. If it's more
than $s$ times the cross-country cost, it doesn't, and we lay a new trail:

$ d(n, K, K') > s d(c, K, K') $

New trails should merge into old ones rather than run beside them, so routes
are planned with two adjustments to the cost: a discount $mu < 1$ for reusing
trail, and a penalty $gamma > 1$ for walking alongside a trail without joining
it. "Alongside" means a band of edges just off the trail:

```rust
/// Penalise edges that run beside a trail without joining it.
fn alongside(trail: &Trail, radius: u32) -> impl Fn(Edge) -> f32 {
    // How many hops each corner is from the trail, out to `radius`.
    let hops = breadth_first(trail.corners(), radius);
    move |(u, v)| {
        let on = |c| trail.touches(c);
        let near = |c| hops.contains(c) && !on(c);
        // Stepping onto the trail is never penalised.
        if !on(u) && !on(v) && (near(u) || near(v)) { GAMMA } else { 1.0 }
    }
}
```

The spanner itself:

```rust
fn span(nodes: &[Node], trail: &mut Trail) {
    let mut pairs: Vec<_> = node_pairs(nodes)
        .filter(|&(a, b)| !trail.is_tease(a, b))
        .collect();
    pairs.sort_by_key(|&(a, b)| d(cost, a, b));
    // Twice: a pair the tease guard rejects early may pass later.
    for &(a, b) in pairs.iter().chain(&pairs) {
        if d(trail.network(), a, b) <= S * d(cost, a, b) {
            continue; // already a reasonable walk
        }
        let beside = alongside(trail, 1);
        let reuse = |e| if trail.contains(e) { MU } else { 1.0 };
        let weight = |e| cost(e) * reuse(e) * beside(e);
        trail.lay_guarded(&[cheapest_route(weight, a, b)]);
    }
    // Anything still cut off joins the nearest node we can reach.
    while let Some(a) = trail.nearest_cut_off(nodes) {
        let routes = cheapest_routes(cost, a, trail.reached()).take(40);
        if !trail.lay_guarded(&routes) {
            trail.lay_unguarded(&routes[0]); // may break a tease
        }
    }
}
```

This is a greedy spanner: it adds just enough trail that no node is more than
$s$ times worse off than walking straight there, and the final pass makes sure
every node can be reached from spawn.

=== Loops

A spanner is a tree-like thing, full of dead ends, and dead ends make for
frustrating hikes. So every node that isn't already on a loop gets a second way
out. A node is on a loop when there are two paths from its pad to another pad
that share no vertices along the way.

Each new loop must be cheap compared with the node's existing link (by a
factor $kappa$), at most $M$ edges long, and make a round trip of at least
$lambda$ edges, so it doesn't just circle the pad:

```rust
fn close_loops(nodes: &[Node], trail: &mut Trail, limits: Option<Limits>) {
    for k in nodes {
        if trail.on_loop(k) {
            continue;
        }
        // No reusing trail, and keep clear of the branch k hangs from,
        // so the loop isn't a thin finger running alongside it.
        let beside = alongside(trail, 2);
        let weight = |e| {
            if trail.contains(e) || near_own_branch(trail, k, e) {
                f32::INFINITY
            } else {
                cost(e) * beside(e)
            }
        };
        let budget = KAPPA * trail.nearest_link(k);
        let routes = cheapest_routes(weight, k, trail.other_trails_and_pads(k))
            .filter(|pi| pi.len() + trail.back(k, pi) >= LAMBDA)
            .filter(|pi| limits.is_none_or(|_| pi.cost(weight) <= budget && pi.len() <= M))
            .take(40);
        trail.lay_guarded(&routes);
    }
}

close_loops(&nodes, &mut trail, Some(limits)); // cheap loops
close_loops(&nodes, &mut trail, None);         // second chance, no limits
```

Here `back(k, pi)` is how many edges it takes to walk from where $pi$ joins
the network back to $k$.

=== Teases

A tease is a view of something you can't easily reach: you see a point of
interest from a viewpoint, but the trail makes you take the long way round.

Let $eta(K, K')$ be the number of trail edges between two nodes (with pads
free to cross), and $"walked"(K) = eta(K_0, K)$ how far a node is from spawn.
A pair $(K_v, K_t)$ can be a tease if $K_t$ is a POI, it's within sight
distance of $K_v$, and the player meets the viewer first:

```rust
fn choose_teases(nodes: &[Node], walked: &Walked, count: usize) -> Vec<(Node, Node)> {
    let mut candidates: Vec<_> = node_pairs(nodes)
        .filter(|&(v, t)| t.is_poi() && crow(v, t) <= SIGHT && walked[v] < walked[t])
        .collect();
    // Visible pairs first, then the biggest drops, then the closest.
    candidates.sort_by_key(|&(v, t)| (!visible(v, t), -drop(v, t).min(TOP), crow(v, t)));
    let mut used = Set::new();
    let mut teases = vec![];
    for (v, t) in candidates {
        if teases.len() == count {
            break;
        }
        if !used.contains(v) && !used.contains(t) {
            teases.push((v, t));
            used.extend([v, t]);
        }
    }
    teases
}
```

A tease only works if the walk really is long. Let $tau$ be the minimum
detour. We compare the walk with the open ground between the two pads, which
is the centre-to-centre distance minus a pad radius at each end:

$ "detour"(K_v, K_t) = eta(K_v, K_t) / (max(||x(K_v) - x(K_t)|| - 2, 1)) $

A tease is broken if the detour is too short, or if the player could reach
the target before the viewpoint:

$
  "broken"(K_v, K_t) <==> "detour"(K_v, K_t) < tau
  or "walked"(K_t) <= "walked"(K_v)
$

Let $X(L)$ be the set of broken teases for trail network $L$. Every trail we
lay, from the spanner onwards, goes through a guard. A new route $pi$ is only
accepted if it doesn't break anything that wasn't already broken:

$ |X(L union pi)| <= |X(L)| $

Sometimes a node can only be connected by breaking a tease. When that happens,
we lay the trail anyway (it shows in magenta), give up on that tease, and
rebuild the whole layout so another pair can take its place. Putting it all
together:

```rust
fn generate(seed: u64) -> Layout {
    // A first build without teases tells us the order the player meets nodes.
    let walked = build(seed, &[]).walked_from_spawn();
    let mut disqualified = Set::new();
    let mut layout = None;
    for _ in 0..RETRIES {
        let teases = choose_teases_except(&walked, &disqualified);
        let attempt = build(seed, &teases);
        if attempt.broken().is_empty() {
            return attempt;
        }
        disqualified.extend(attempt.broken());
        layout = Some(attempt);
    }
    layout.unwrap().without_broken_teases()
}

fn build(seed: u64, teases: &[(Node, Node)]) -> Layout {
    let nodes = place_nodes(seed);
    let mut trail = Trail::guarding(teases);
    span(&nodes, &mut trail);
    close_loops(&nodes, &mut trail, Some(limits));
    close_loops(&nodes, &mut trail, None);
    join_creek_banks(&nodes, &mut trail);
    Layout::new(nodes, trail)
}
```

// #media("/media/terrain-4/trails3d.png", title: "Trails by pass", caption: "Spanner in brown, loops in blue, second-chance loops in purple, forced connections in red, broken teases in magenta.", linked: true)

---

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
  - another way to put this: i used to write code like an achievement player, going for a _win,_ for the maximally clean and well-written code. what i cared about was what other people thought, and how the value i got from coding transferred outside the session. now i don't care too much about that -- ai has forced me to switch from being an achievement coder to being a striving coder. now instead of making the _perfect_ algorithm, i am focused on making an _interesting_ algorithm; my focus has gone from attempting to match the standard to using the standard as a tool to achieve my own local vision.
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

= Appendix - Function types and Notation

== Notation

- $H$ is the set of all hex tiles in the grid. $B subset.eq H$ the
  playable board. $C subset.eq H$ is the set of creek tiles.
- Each tile $T$ has a centre $x(T) in RR^2$ and six corners. For a set of
  tiles $A subset.eq H$, $V(A) subset RR^2$ is the set of all their corners,
  and $V(T)$ is short for $V({T})$.
- The honeycomb graph is $G = (V(H), E)$: corners joined by hex edges.
- $cal(N) subset.eq B$ is the set of nodes, written $N$, with spawn $N_0$.
- $cal(P)(X)$ is the power set of $X$, and $hat(RR) = RR union {infinity}$.

== Terrain
// this works because text and math are different elements.
// not a stable feature, keep an eye on this
#html.div(class: "columns")[
  Ground height at a point $p$
  $ h(p) : RR^2 -> RR $

  Tile center
  $ x(T) : H -> RR^2 $

  Corners of a set of tiles
  $ V(T): cal(P)(H) -> cal(P)(RR^2) $

  Adjacent tiles
  $ N(T) : H -> cal(P)(H) $
]
== Points of interest
#html.div(class: "columns")[
  Height range around a tile
  $ r(T) : H -> RR_(>= 0) $

  Suitability for node placement of a tile $T in H$
  $ s(T) : H -> (0, 1] $

  Distance to the nearest tile in a set, in hexes
  $ d() : H times cal(P)(H) -> [0, infinity) $

  Water pull  $ omega : H -> [1, 1 + beta] $           // water pull
  POI placement weight  $ w : H -> [0, infinity) $                   // POI placement weight
]

== Benches

#html.div(class: "columns")[

  Tiles in range, tiles visible $ R, S : B -> cal(P)(H) $                // tiles in range, tiles visible
  Visibility scores $ "open", "quiet" : B -> [0, 1] $
  Height difference $ Delta : H times H -> RR $              // height difference
  Relief $ "relief" : B -> [0, 1] $
  Rank $ "rank" : (B -> RR) -> (B -> [0, 1]) $
  Applied ranks $ r_q, r_r, b : B -> [0, 1] $
]

== Trails
Leveled height $ h' : V(H) -> RR $                      // levelled height
Step cost $ c : E -> hat(RR)_(> 0) $          // step cost
Paths between nodes $ Pi : cal(K) times cal(K) -> cal(P)(E^*) $  // paths between two pads
$ d : (E -> hat(RR)_(>= 0)) times cal(K) times cal(K) -> hat(RR)_(>= 0) $
$ c_L : E -> hat(RR)_(>= 0) $       // cost on trails L (your n)
$ eta : cal(K) times cal(K) -> NN union {infinity} $  // trail hops
$ "walked" : cal(K) -> NN union {infinity} $
$ "detour" : cal(K) times cal(K) -> RR_(>= 0) $
$ "broken" : cal(K) times cal(K) -> {"true", "false"} $
$ X : cal(P)(E) -> cal(P)(cal(K) times cal(K)) $   // broken teases, given trails
