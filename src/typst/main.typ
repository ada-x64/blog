#import "_template.typ": conf


#document(
  "index.html",
  title: [Home],
)[
  #include("./index.typ")
]

#document(
  "now.html",
  title: [Now],
)[
  #include("./now.typ")
]

#document(
  "/posts/post1.html",
  title: [Post 1]
)[
  #include("./posts/post1.typ")
]
