#import "_template.typ": *
#show: post.with(
  title: "terrain 2 - noise_rs",
  date: datetime(year: 2025, month: 3, day: 6),
  tags: ("qproj", "devlog", "terrain"),
  aliases: none,
  draft: false,
  cover: none,
)

#link("https://bsky.app/profile/cubething.dev/post/3ljot6wq4u22n")[Bluesky] #video("/media/Screen Recording 2025-03-05 235548.mp4") getting somewhere. Deserializing terrain generation asset files and using them to create chunked heightmap meshes with \#bevy. This is the "complex planet" example from noise\_rs running on my laptop.

Indebted to the noise\_gui project for making this possible. -\> #link("https://github.com/attackgoat/noise_gui")[github.com/attackgoat/n…]
