#import "../_template.typ": conf

#let timestamp(date) = html.elem("time")[#date.display("[day] [month repr:short], [year]")]

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
  conf[
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
  posts = posts
    .filter(post => {
     if post.draft == true {
       return false
     }
     return true
    })
    .map(post => {
      if post.date == none {
        post.date = datetime.today()
      }
      return post
    })
    // cannot compare date and datetime,
    // so work around it
    .sorted(key: post => (
      post.date.year() * 10000
      + post.date.month() * 100
      + post.date.day()
    ))
    .rev()
    .map(post => {
      link("/blog/" + post.path)[
        #post.title
      ]
      [
        #timestamp(post.date)
        #post.description
      ]
    })
  list(..posts)
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
