#import "_template.typ": *
#show: post.with(
  title: "terrain 3 - chunks",
  date: datetime(year: 2025, month: 3, day: 11),
  tags: ("qproj", "devlog", "terrain"),
  aliases: none,
  draft: false,
  cover: none,
)

#link("https://bsky.app/profile/cubething.dev/post/3lk5e7uibh22k")[Bluesky]

#video("/static/media/Screen Recording 2025-03-11 194250.mp4") aw hell yeah next steps: center chunks around player entity and add LOD for distant chunks. then integrate noise\_gui into #link("https://bsky.app/hashtag/bevy")[\#bevy].

this is integrated as a crate feature btw, so for production build it's stripped from the binary. i plan on adding unity-style controls flycam controls (minus the gizmos since this is a pcg project) and the ability to "drop in" and explore the game as the player character.

the terrain is a simple heightmap mesh generator, so it's just 2d noise. i want to add cellular automata for features like foliage, water, landmarks, paths, loot drops, creature habitats, etc. it's key to have a good editor flow for this!
