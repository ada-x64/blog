#import "../_template.typ": conf

#let post(title: "", date: none, description: "", keywords: (), content) = {
  set document(
    title: title,
    author: "Phoenix Ada Rose Mandala",
    date: date,
    description: description,
    keywords: keywords
  )
  metadata(
    ( title: title,
    author: "Phoenix Ada Rose Mandala",
    date: date,
    description: description,
    keywords: keywords )
  )
  conf[
    #html.elem("article")[#content]
  ]
}

#let index_list(posts) = {
  posts = posts.map(post => {
    if post.date == none {
      post.date = datetime.today()
    }
    return post
  }).sorted(key: post => post.date).rev().map(post => {
    link("/blog/" + post.path)[
      #post.title
    ]
    [
      #html.elem("time")[#emph[#post.date.display("[day] [month repr:short], [year]")]]\
      #post.description
    ]
  })
  list(..posts)
}
