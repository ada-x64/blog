#import "_template.typ": *
#show: post.with(
  title: " terrain 1 - beginnings",
  description: "",
  date: datetime(year: 2025, month: 2, day: 4),
  tags: ("devlog", "qproj", "terrain"),
  aliases: none,
  draft: false,
  cover: none,
)

#link("https://bsky.app/profile/cubething.dev/post/3lhfus56uvk2k")[Bluesky] #video("/media/Screen Recording 2025-02-04 234658.mp4") getting somewhere. terrain generation with #link("https://bsky.app/profile/did:plc:rurf32i2ytudjhvyytliz7ct")[\@bevyengine.org]. not sure what's up with the black blobs, probably something with the normals. each chunk here is 256x256 vertices. been trying to test that there are no overlaps or gaps in the terrain, which has proven to be difficult
