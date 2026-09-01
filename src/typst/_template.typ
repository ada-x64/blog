/// The main website template.
#let conf(content, header: "Header", footer: "Footer") = {
  html.elem("head")[
    #html.elem("link", attrs: (rel: "stylesheet", href: "/static/styles/main.css"))
  ]
  html.elem("header", attrs: (id: "header"))[#header]
  html.elem("main", attrs: (id: "main"))[#content]
  html.elem("footer", attrs: (id:"footer"))[#footer]
}
