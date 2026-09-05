// Bundle definition. Include your files here.
// Blog posts are compiled separately!

#document(
  "index.html",
  title: [Home],
)[
  #include "./index.typ"
]

#document(
  "now.html",
  title: [Now],
  description: "What I'm up to.",
)[
  #include "./now.typ"
]

#let blog-description = "An index of blog posts."

#document(
  "blog.html",
  title: [Blog],
  description: blog-description,
)[
  #include "./blog/index.typ"
]

#document(
  "blog/index.html",
  title: [Blog],
  description: blog-description,
)[
  #include "./blog/index.typ"
]
