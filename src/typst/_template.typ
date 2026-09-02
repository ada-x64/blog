/// The main website template.
#let icon = image("assets/cube.gif", alt: "A rotating cube")

#let nav = block[
  #link("/")[home] |
  #link("/now")[now] |
  #link("/blog")[blog]
]

#let header = block[
  #title[#icon cubething]
  #nav
]

#let footer(footer_nav: none) = [
  #html.elem("center")[❦]

  #if footer_nav != none {
    footer_nav
  }

  _Looking for work. Email me at #link("mailto:scout@cubething.dev")[`scout@cubething.dev`]_
]

#let conf(content, header: header, footer: footer()) = {
  html.elem("head")[
    #html.elem("link", attrs: (rel: "stylesheet", href: "/static/styles/main.css"))
    #html.elem("link", attrs: (rel: "stylesheet", href: "/static/styles/fonts.css"))
    #html.elem("script", attrs: (src: "/static/scripts/main.js"))
  ]
  html.elem("header", attrs: (id: "header"))[#header]
  html.elem("main", attrs: (id: "main"))[#content]
  html.elem("footer", attrs: (id:"footer"))[#footer]

}
