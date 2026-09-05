/// The main website template.
#let icon = image("assets/cube.gif", alt: "A rotating cube")

#let nav = block[
  #link("/")[home] |
  #link("/now")[now] |
  #link("/blog")[blog] |
  #html.elem("a", attrs: (rel: "noopener noreferrer", target: "_blank", href: "https://github.com/ada-x64/blog"))[source] |
  #link("/resume.pdf")[résumé] |
  #link("#")[#html.elem("span", attrs: (class: "toggle-lights"))[toggle theme]]
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
  html.elem("header")[#header]
  html.elem("main")[#content]
  html.elem("footer")[#footer]
}
