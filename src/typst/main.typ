// Bundle definition. Include your files here.
// Blog posts are compiled separately!

#document(
  "index.html",
  title: [Home],
)[
  #include("./index.typ")
]

#document(
  "now.html",
  title: [Now],
  description: "What I'm up to."
)[
  #include("./now.typ")
]

#document(
  "blog.html",
  title: [Blog],
  description: "An index of blog posts."
)[
  #include("./blog/index.typ")
]
