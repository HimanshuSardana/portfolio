// Open graph card for himanshu.co posts.
// Rendered by `kite build` into output/<slug>/og.png.
// Post data arrives as `--input` values, readable via sys.inputs.

#set page(fill: black, height: 630pt, width: 1200pt)

#let title = sys.inputs.at("title", default: "")
#let author = sys.inputs.at("author", default: "")

#text(fill: white.darken(30%), size: 80pt, font: "Iosevka NF")[#title]

#place(bottom + left)[#text(font: "Iosevka NF", fill: white.darken(50%), size: 40pt)[*#author*]]
