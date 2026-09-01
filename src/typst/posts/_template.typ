#import "../_template.typ": conf

#let post(content) = {
  conf[
    #html.elem("article")[#content]
  ]
}
