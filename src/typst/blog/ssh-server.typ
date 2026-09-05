#import "_template.typ": *
#show: post.with(
  title: "basic ssh server (wsl)",
  date: datetime(year: 2025, month: 4, day: 17),
  tags: ("qproj", "devlog"),
  aliases: none,
  draft: false,
  cover: none,
)

#link("https://bsky.app/profile/cubething.dev/post/3lmxit4rnys2k")[Bluesky] #link("https://github.com/ada-x64/qproj/pull/4")[Github PR]

Spent the last two days setting up SSH support for my \#bevy build system. Now I can build with my Ryzen 9 PC anywhere over a WAN. This was quite a challenge and I learned a lot along the way!

#media("/media/ssh-server-excalidraw.png", caption: [Excalidraw image detailing the SSH server I built. See the PR linked above for more details.], linked: true)

This PR doesn't explain all the stuff I had to learn about systemd, WSL2 networking, wake-on-LAN, and SSH/D configuration in order to make this work. Although I spent the last two days making this, it was the culmination of a lot of time spent messing around, including a Minecraft server at one point.
