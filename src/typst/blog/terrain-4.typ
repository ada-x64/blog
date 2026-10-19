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

== The design

As always, the design developed as I went along. The initial idea was to create a simple path-based hiking simulation over a terrain. This evolved as

== Initial experiments

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

#callout()[
  #html.details[
    #html.summary[Workflows - Snippet from `AGENTS.md`]
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

I started off just replicating the 2d board. It was a flat, gizmo-based hex grid
with nodes, paths on the edges. From there we started experimenting with rules
for node placements and path constraints. Originally, we were just playing
around with pathfinding algorithms. Then I realized that we were going about it
backwards -- instead of building the terrain around the paths, we need to build
the paths around the terrain. This is obvious in hindsight, but moving from 2d to
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
algorithm. From there we added tweaks. I'm basing this game off of hikes I've
been on, in the glacial hills of northeast Kansas, so we landed on rolling hills
and creeks cutting into the loam, oak and hickory dense around the water.

In order to make a path, we need to rank how easy it is to hike around. So we
used a symmetric approximation of the
#link("https://en.wikipedia.org/wiki/Tobler's_hiking_function")[Tobler hiking
function] to rank edges. From there, we place the nodes according to suitability
and link between them using a slightly noisy A\* algorithm.

#carousel(
  media("/media/terrain-4/2d/01-heightmap.png", caption: "Terrain"),
  media("/media/terrain-4/2d/02-cost.png", caption: "Path cost"),
  media("/media/terrain-4/2d/03-node-sites.png", caption: "Node placement"),
  media(
    "/media/terrain-4/2d/05-graph.png",
    caption: "Connected node network, ranked by cost"),
  media("/media/terrain-4/2d/06-trails.png", caption: "Path placement"),
)

We limit paths by a budget over edge weights. In Figure 14 above, note that
nodes 0 and 2 do not even have a candidate connection as the cost between them
would be too high. Paths are chosen based on a greedy graph spanner, weighted by
various factors such as hiking cost, whether they make a loop between nodes, and
whether they create a 'tease' between two nodes. We'll discuss this more below.
Extra pathing is added after the initial greedy spanner as necessary to maximize
the constraint score.

== Formalizing the generation method

=== Points of Interest

Let $h(v)$ denote the height of a vertex $v$, and let $V(T)$ be the set of six
corner vertices of a hex tile $T$. Let $A(T)$ be the nodes adjacent to $T$. Our
board is a window over a larger hex grid, so all tiles are interior. Note that
$V(T) subset.eq V(A(T))$. The height range over that neighborhood is

$ hat(r)(T) = max_(v in V(A(T))) h(v) - min_(v in V(A(T))) h(v) $

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
water. Let $C$ be the set of creek tiles, and let $delta(T, C)$ be the distance from
$T$ to the nearest creek tile, measured in hexes. The water pull factor is

$ omega(T) = 1 + beta e^(-delta(T, C) \/ 2) $

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

Placement doesn't sample tiles in proportion to $w_p$. Instead, each POI goes on
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
            separation * w_p(t) * rng.jitter()
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

But for nooks, what we're looking for is the _opposite_ of openness. So let's
just take the complement:

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
score $f : B -> [0,1]$, let $"rank"(f) : (B -> [0,1]) -> (B -> [0, 1])$ be

$ "rank"(f)(T) = (|{ U in B : f(U) < f(T) }|) / (|B| - 1) $

so that $r_q : B -> RR = "rank"("quiet")$ and $r_r : B -> RR = "rank"("relief")$
are both functions from tiles to $[0, 1]$. Ranks only care about order, so a
board with a few dramatic cliffs and a board with gentle hills both get their
best spots ranked at the top.

Introduce $k gt.eq 1$, our sharpness parameter. Raising a rank to the power $k$
crushes everything except the very top, so only the most enclosed spots and the
best views score well. Ground that's middling at both doesn't win. Finally, $nu$
is our view preference, from 0 (quiet benches) to 1 (view benches):

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

Now that we've placed the nodes, we need to join them. Our terrain is a large
hexagonal lattice, which we'll represent as a graph $G = (V, E)$. The playable
board is a window over this larger terrain, so let's define that as $cal(B) subset
G$. Denote the edges of a graph $G$ as $E_G$, sim. for vertices. Now, let's call
$E_cal(C) subset E_cal(B)$ the set of edges which a creek crosses.

Let $cal(N)$ denote all nodes. The subset $cal(P) subset cal(N)$ contains all
POIs. Each node $N in cal(N)$ sits on flattened out ground. Its tile is leveled
and the ground around it graded to match, so we can easily fit pre-authored
scenes onto it. Let $h'(v)$ be the height of vertex $v$ after leveling.

Walking uphill or downhill is harder than walking on the flat, so the cost of an
edge $epsilon = {u, v}$ grows exponentially with how much it climbs. Let $alpha$
be our aversion to slopes, and let $Pi$ denote the set of all paths over
$cal(B)$. Then we can define $c_pi$ as the weight for an edge $epsilon in pi in
Pi$.

#definition(
  $
    c_pi (epsilon) = cases(
      exp(alpha |h'(u) - h'(v)|) & epsilon in E_cal(B) and epsilon in.not E_cal(C),
      infinity & "otherwise",
    )
  $,
  caption: "Path traversal cost",
)

We obviously don't want paths to lead straight into a creek or off the board, so
we denote this by setting the cost to infinity.

$e^(alpha |h'(u) - h'(v)|)$ is our symmetric Tobler approximation; the original is $e^(-3.5|"slope" + 0.05|)$.

Let's denote the paths from nodes $N$ to $M$ as $Pi_( N,M )$.
For any edge weighting $w$ and nodes $N, M in cal(N)$, let's write $d_(N,M)$ to denote the least expensive path from $N$ to $M$ given some weighting $w$.
$
  d_( N,M ) (w) = min_(pi in Pi_(N,M)) sum_( epsilon in pi ) w(epsilon)
$

So, $d_(N,M) (c_pi)$
is the least expensive path weighed by the cost of walking cross-country. The same formula can be used for other
The most efficient method of selecting a trail path would be to select the least
expensive route. But efficiency isn't fun, so that's not what we do. We'll
define exactly how we differ from the optimum below.

As we lay trails, let $L subset.eq E$ be the set of laid edges. We want to know
how far the walk is if we stick to the trails. The cost $n$ of walking across an
edge $epsilon in L$ is defined below. Note that we let paths cross nodes for free.

$
  c_L(epsilon) = cases(
    0 & epsilon in E_N "for some" N in cal(N),
    c(epsilon) & epsilon in L,
    infinity & "otherwise",
  )
$

We can use this to measure how far off the ideal geometric path we are. Because
the cost is always nonzero, we almost never take the ideal path. We can use the
ratio $d(c_L) \/ d(c_P)$ to measure how far off the preferred path we are.

=== The spanner

We don't want trails to be too long. Getting lost is a big part of the game, so
we need lots of branching paths and opportunities for decision making. We can
accomplish this by using a
#link("https://en.wikipedia.org/wiki/Geometric_spanner")[ graph spanner. ] In
particular, we use a
#link("https://en.wikipedia.org/wiki/Greedy_geometric_spanner")[greedy spanner.]

Start by calculating $d(c)$ over $cal(N) times cal(N)$. Then sort by value,
starting with the lowest cost. For each pair, check whether the network already
gives a reasonable walk. Define a parameter $t$ for the spanner's stretch; if
the walk is more than $t$ times the cross-country cost we lay a new trail. This
way we add just enough trail that no node is more than $t$ times worse off than
walking straight there. We additionally use a final pass to ensure that every
node can be reached from spawn.

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

/// Greedy spanner over the graph
fn span(nodes: &[Node], trail: &mut Trail) {
    let mut pairs: Vec<_> = node_pairs(nodes)
        .filter(|&(a, b)| !trail.is_tease(a, b))
        .collect();
    pairs.sort_by_key(|&(a, b)| d(cost, a, b));
    // Twice: a pair the tease guard rejects early may pass later.
    for &(a, b) in pairs.iter().chain(&pairs) {
        if d(trail.network(), a, b) <= T * d(cost, a, b) {
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


=== Loops

A spanner is a tree-like thing, full of dead ends, and dead ends make for
frustrating hikes. So every node that isn't already on a loop gets a second way
out. A node is on a loop when there are two paths from it to another node that
share no vertices along the way.

Let's define a few new parameters. Each new loop should be comparatively cheap,
a factor $kappa$ cheaper than the node's existing link. The new edge should be
at most $xi$ edges long, and make a round trip of at least $lambda$ edges, so it
doesn't just circle the pad.

```rust
fn close_loops(nodes: &[Node], trail: &mut Trail, limits: Option<Limits>) {
    for n in nodes {
        if trail.on_loop(n) {
            continue;
        }
        // No reusing trail, and keep clear of the branch n hangs from,
        // so the loop isn't a thin finger running alongside it.
        let beside = alongside(trail, 2);
        let weight = |e| {
            if trail.contains(e) || near_own_branch(trail, n, e) {
                f32::INFINITY
            } else {
                cost(e) * beside(e)
            }
        };
        let budget = KAPPA * trail.nearest_link(n);
        let routes = cheapest_routes(weight, n, trail.other_trails_and_pads(n))
            .filter(|pi| pi.len() + trail.back(n, pi) >= LAMBDA)
            .filter(|pi| limits.is_none_or(|_| pi.cost(weight) <= budget && pi.len() <= XI))
            .take(40);
        trail.lay_guarded(&routes);
    }
}

close_loops(&nodes, &mut trail, Some(limits)); // cheap loops
close_loops(&nodes, &mut trail, None);         // second chance, no limits
```

Here `back(n, pi)` is how many edges it takes to walk from where $pi$ joins
the network back to $n$.

=== Teases

A tease is a view of something you can't easily reach: you see a point of
interest from a viewpoint, but the trail makes you take the long way round.

Let $eta(N,M)$ be the number of trail edges between two nodes, and $d_0(N) =
eta(N_0, N)$ how far a node is from spawn. Consider a viewpoint node $N_v$ and a
target node $N_t$. $(N_v, N_t)$ can be a tease if $N_t$ is a POI (not a bench),
it's within sight at $N_v$, and $d_0(N_v) < d_0(N_t)$. This way a tease always
targets a POI, ensures that POI is visible, and ensures that the tease is
earlier on the trail than the target.

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

A tease only works if the walk from $N_v$ to $N_t$ is a real detour. Let $tau$
be the minimum detour length in edges. We compare the walk with the open ground
between the two nodes, which we define as the center-to-center distance minus a
radius at each end:

$ "detour"(N_v, N_t) = eta(N_v, N_t) / (max(||x(N_v) - x(N_t)|| - 2, 1)) $

A tease is _broken_ iff the detour is too short, or if the player could reach
the target before the viewpoint. Namely, if $"detour"(N_v, N_t) < tau$ or $d_0(N_t) lt.eq d_0 (N_v)$.

Let $X(L)$ be the set of broken teases for trail network $L$. Once we lay the
spanner, we want to guard our teases. A new route $pi$ is only accepted if it
doesn't break anything that wasn't already broken, that is if the following invariant holds: $|X(L union pi)| <= |X(L)|$.

Sometimes a node can only be connected by breaking a tease. When that happens,
we give up on that tease and lay the trail anyway (it shows in magenta). We then
rebuild the whole layout so another tease can take its place.

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

== Reflections on Method

AI has made me orders of magnitude more productive.

I can focus more on design in all aspects. Instead of spending a month
struggling to find resources on game development e.g. how rasterization over a
terrain mesh works, or how path finding algos work and how to tweak them, i can
prompt to ask and it teaches me at a high level, then implements it. i may not
have the hard-earned experience of crunching the numbers myself, but for game
design that was never the point.

I don't have to re-do solved problems. The knowledge I need isn't expert-level
and in depth -- i need know _how_ not know _that_ -- these algorithms are tools,
not the object of my art. Obviously this isn't to say that an algorithm cannot
be its own aesthetic object, lest the lobsters have my head. But for me, as a
game developer, what I need is a repertoire of common algorithms and the ability
to use them in a practical manner. Reinventing the wheel will get me stuck at
the engine level -- which is a lovely place to be! But I'm ready to move on and
actually make something. My focus has gone from attempting to match the standard
to using the standard as a tool to achieve my own local vision.

An algorithm is like a ball bearing. It can be a beautiful thing! But most of
the time you don't care about how it works, just _that_ it works, and in what
situations it is useful.

Having these tools ready at my fingertips makes spiking is incredibly easy. The
hex terrain was initially tested in a python lab for quick compilation and
turnaround. we did statistical analysis over 1000 seeds per run, generated
SVG-based visualzations for the terrain, and several graphs tracking things like
path loop count, bench locations, creek depth, and time to cross all paths based
on the Tobler hiking algorithm. It would have taken me a month or longer of full
time work and research to do this on my own. I spent 3 days on it.

The primary lesson I want to put out here though is that one needs to be
responsible for the code that their agents are producing. They're automation
machines, which makes code review extremely important. And code review is not
that hard! It's a bit boring, yes, but it's worthwhile to understand what you're
producing. And yes this leads to fatigue, but so does coding. Having somewhat
messy code for the sake of moving on is super common, especially in long-term
projects. It can always be cleaned up later if needed. Spending all your time polishing a single algorithm is pointless if that algorithm is a part of something much larger.

The output of an agent doesn't have to be slop. It's not if you review, if you
have proper ownership and safeguards. Agents can be coaxed into producing really
good output very quickly, but you have to know how to tune it to your
specifications. It may not always be organized exactly how you like it, or produce exactly what _you_ would have, but you can work around that. I have file organization in my AGENTS.md and reinforce it at review time.

#callout()[
  #html.details[
    #html.summary[File Organization and Documentation - Snippet from AGENTS.md]
    ```md
    ### File organization and Documentation

    Please place type definitions and their implementations at the _top_ of the
    file, with free functions below them. Bootstrapping is good because it prevents
    bugs, but it's ugly and shouldn't be a preferred style choice. I want to
    understand what I'm reading from top to bottom. Ontology, then semantics.

    If you are going to include any of these things in a file, then do so in this order:

    # module doc comments
    # imports -- try to use crate::prelude::* to reduce line count here
    # prelude with pub exports
    # type definitions and associated functions sorted by order of appearance
      # consts
      # resources
        # resources with no impls
        # resources with impls
      # components
        # components with no impls
        # components with impls
      # raw types
        # types with no impls
        # types with impls
    # free functions
    # plugin definition
    # unit tests

    Ensure that every public-facing function is documented. Ideally, _every_
    function with a non-obvious implementation has a doc comment expressing the
    intent. Type-level doc comments should explain the typical context for their
    usage and link to other types when they are related. Module-level docs should
    provide a brief summary of data pipelines and type relationships. Doc comments
    are essentially a wiki. Use them as such.

    For Bevy crates (which this entire project is), separate components from systems.
    Follow this project structure. See /bin/quell/docs/architecture.md for more detail.

    |- src/
      |- plugin.rs        # include this if it's a library. lib.rs should _only_ be exports and docs.
      |- lib.rs           # if needed - public exports
      |- bin.rs           # if needed - app definition
      |- my_module/
        |- mod.rs         # exports
        |- plugin.rs      # the plugin definition - scheduling, type registrations, etc. go here
        |- data.rs        # type definitions - components live here
        |- systems.rs     # semantics - systems go here
        |- test.rs        # unit tests
      |- screen/          # screen definitions - see q_screen
        |- mod.rs         # plugin which exposes all screen submodules
        |- my_screen/
          |- mod.rs       # Prelude and minimal plugin
          |- screen.rs    # Define the screen here
          |- data.rs      # types, components
      |- service/         # a service is a plugin which exposes a bunch of systems.
        |- mod.rs         # exports and plugin
        |- my_service
          |- mod.rs
          |- ...          # somewhat freeform layout
      |- prog/            # cross-frame orchestration - see q_proc, q_script, q_query_lang
        |- mod.rs         # exports and plugin
        |- my_prog/
          |- mod.rs       # exports and plugin
          |- prog.rs      # program definition

    `data` may be split into a module. If so, use `plugin.rs` to define a plugin for all registration concerns for the module. Otherwise register all data in the parent's `mod.rs`

    |- data/
      |- mod.rs
      |- plugin.rs      # Register anything necessary here
      |- big_struct.rs  # Use individual modules for large structs and their impls
    ```
  ]
]


Speaking of review, automated review with a subagent is extremely important for
catching subtle bugs. But it's also important to know what's worth doing now
and what's a red herring. These machines are meant to provide you the highest
quality code, but are trained on a huge corpus of code -- that means they'll
often write middling code and point out nits that don't matter. It takes
discipline and skill to know what's worth doing. in the end, _you_ are still the
operator and _you_ still own the output. Act like it!

---

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
