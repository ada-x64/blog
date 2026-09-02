#import "../_template.typ": conf, footer
#import "_posts.typ": posts

#let timestamp(date) = html.elem("time")[#date.display("/[day] [month repr:short], [year]/")]

#let published_posts(posts: posts) = (
  posts.filter(post => post.draft != true)
  .map(post => {
    if post.date == none {
      post.date = datetime.today()
    }
    post
  })
  // Date-only and full datetime values cannot be compared directly.
  .sorted(key: post => (
    post.date.year() * 10000
    + post.date.month() * 100
    + post.date.day()
  ))
  .rev()
)

#let post_navigation(title) = {
  let ordered = published_posts()
  let current = ordered.position(post => post.title == title)

  if current != none {
    let previous = if current + 1 < ordered.len() {
      ordered.at(current + 1)
    }
    let next = if current > 0 {
      ordered.at(current - 1)
    }

    if previous != none or next != none {
      html.elem("nav", attrs: (class: "post-navigation"))[
        #html.elem("div", attrs: (class: "previous"))[
          #if previous != none {
            link(previous.path)[← Previous: #previous.title]
          }
        ]
        #html.elem("div")[#link("/blog")[≡ Index]]
        #html.elem("div", attrs: (class: "next"))[
          #if next != none {
            link(next.path)[Next: #next.title →]
          }
        ]
      ]
    }
  }
}

#let post(
  title: none,
  description: none,
  date: none,
  tags: (),
  aliases: none,
  draft: false,
  cover: none,
  content,
) = {
  set document(
    title: title,
    author: "Phoenix Ada Rose Mandala",
    date: date,
    description: description,
    keywords: tags,
  )
  metadata((
    title: title,
    author: "Phoenix Ada Rose Mandala",
    description: description,
    date: date,
    tags: tags,
    aliases: aliases,
    draft: draft,
    cover: cover,
  ))
  conf(footer: footer(footer_nav: post_navigation(title)))[
    #html.elem("article")[
      = #title
      #if date != none {
        timestamp(date)
      }
      #counter(figure.where(kind: table)).update(0)
      #counter(figure.where(kind: image)).update(0)
      #counter(figure.where(kind: "video")).update(0)
      #counter(footnote).update(0)
      #counter(math.equation).update(0)
      #counter(heading).update(0)

      #content
    ]
  ]
}

#let index_list(posts) = {
  let entries = published_posts().map(post => {
    link("/blog/" + post.path)[
      #post.title
    ]
    [
      #timestamp(post.date)
      #post.description
    ]
  })
  list(..entries)
}

#let media(url, caption: none, linked: false, alt: "", title: "") = {
  let img = html.elem("img", attrs: (src:url, alt: alt, title: title))
  if linked {
    img = link(url)[#img]
  }
  figure(img, caption: caption)
}

#let video(url, caption: none) = {
  figure(kind: "video", supplement: "Video", html.elem("video", attrs: (controls: "true"))[
    #html.elem("source", attrs: (src: url))
  ], caption:caption)
}

#let youtube(url, title: "YouTube video player") = {
  html.elem("iframe", attrs:(
    class: "youtube",
    src: url,
    title: title,
    frameborder: "0",
    allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
    referrerpolicy: "strict-origin-when-cross-origin",
    allowfullscreen: "true"
  ))
}

#let callout(kind: "note", title: none, content) = {
  html.elem("aside", attrs:(class: "callout " + kind))[
    #if title != none {
      html.elem("summary")[#title]
    }
    #content
  ]
}

#import "@preview/merman:0.3.0": mermaid
