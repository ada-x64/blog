/// The main website template.
#let icon = image("assets/cube.gif", alt: "A rotating cube", height: 1em, width: 1em)

#let nav = block[
  #link("/")[home] |
  #link("/now")[now] |
  #link("/blog")[blog]
]

#let header = block[
  #title[#icon cubething]
  #nav
]

#let footer = [
  #html.elem("center")[❦]

  _Looking for work. Email me at #link("mailto:scout@cubething.dev")[`scout@cubething.dev`]_
]

#let conf(content, header: header, footer: footer) = {
  html.elem("head")[
    #html.elem("link", attrs: (rel: "stylesheet", href: "/static/styles/main.css"))
    #html.elem("link", attrs: (rel: "stylesheet", href: "/static/styles/fonts.css"))
  ]
  html.elem("header", attrs: (id: "header"))[#header]
  html.elem("main", attrs: (id: "main"))[#content]
  html.elem("footer", attrs: (id:"footer"))[#footer]

}
