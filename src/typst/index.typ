#import "_template.typ": conf
#import "blog/_template.typ": published_posts, timestamp

#show: conf
= /home
== hi, i'm ada

_software developer, parent, philosopher, artist._

After earning a bachelor’s with honors in philosophy and mathematics, I decided
to pursue software development as a career. I've been creating web and desktop
applications since 2016 and doing philosophy on the side.

Professional accomplishments include development on an
#link("https://github.com/nanvix/nanvix")[experimental operating system at
Microsoft,] (#link("https://github.com/microsoft/mxc")[2]) a
#link("https://github.com/perspective-dev/perspective")[real-time, browser-based
database], the development of ESPN+ on the PS5, and the creation of front-ends
for #link("https://burnbryte.com")[an original tabletop roleplaying game.]

For fun I like to build and contribute to #link("https://github.com/ada-x64/sundile_rs")[game engines] (#link("https://github.com/bevyengine/bevy")[2]). Currently I'm working on a #link("https://github.com/cubething-qproj")[Bevy-based game framework.] I blog about it regularly.

I also like to read and write. I am ecclesiastically compelled to call this the
"real work." My philosophical interests include Buddhist conceptions of mind,
aesthetics, phenomenology, media theory, critical theory, logic, semantics, and
semiotics.

#link("https://github.com/ada-x64/blog")[This website is OSS.]

#let recent_posts() = {
  [== Recent posts]
  html.elem("nav", attrs: (id: "recent-posts"))[
    #for post in published_posts().slice(0, 3) {
      // path: "./ai-identity-crises.html",
      // title: "AI Identity Crises",
      // description: "On the death of the Californian Ideology",
      // date: datetime(year: 2026, month: 2, day: 14),
      // draft: false
      [
        #html.elem("section")[
          #heading(depth:3)[
            #link("/blog/" + post.path)[#post.title]
          ]
          #timestamp(post.date) #post.description
        ]
      ]
    }
  ]
}

#divider()
#recent_posts()
