// #import "@local/prefs:0.1.0": *; #show: prefs

#import "@preview/touying:0.7.4": *
#import themes.simple: *

#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/cetz:0.3.4": draw as cetz-draw
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *
#import "@preview/zebra:0.1.0": qrcode

#show: codly-init.with()
#codly(languages: codly-languages, zebra-fill: none, stroke: none)

#show: simple-theme.with(
  aspect-ratio: "16-9",
  header: none,
  footer-right: context {
    // hide the slide number on pages marked with `hide-slide-number()`
    // (every corner-acronym page, plus any page that needs the room)
    let pg = here().page()
    let hidden = query(<hide-slide-number>).any(m => m.location().page() == pg)
    if not hidden {
      utils.slide-counter.display() + " / " + utils.last-slide-number
    }
  },
  subslide-preamble: block(
    width: 100%,
    below: 0.6em,
    align(center)[#text(1em, weight: "bold")[#underline(utils.display-current-heading(level: 2))]],
  ),
  config-page(margin: (top: 1em, rest: 2em)),
)

// ---------- global sizing (matches the original slides' larger, readable type) ----------
#set text(font: "Arial")
#show raw: set text(size: 0.8em)
#show link: it => underline(text(fill: rgb("#3d6b78"))[#it])

// Per-slide text scale. Wrap a slide's body in this rather than using a bare
// top-level `#set text(size: ...)`, which would leak into every later slide
// (and `em` sizes would compound).
#let slide-text(size, body) = {
  set text(size: size)
  set par(spacing: 0.3em)
  body
}

// VBA styling, applied to every ```vb block in the deck: real VBA editors
// (and the original slides) show comments in green and keywords in navy,
// set in Courier New. Typst has no built-in VBA/Basic grammar to
// syntax-highlight against, so this hand-tokenizes each line instead: find
// the comment-start apostrophe (skipping ones inside "double-quoted"
// strings), color everything after it green, and color any bare keyword
// tokens before it navy.
#let vba-kw-color = rgb("#000080")
#let vba-cm-color = rgb("#008000")
#let vba-keywords = ("Option", "Explicit", "Sub", "End", "Dim", "As", "Set",
  "True", "False", "If", "Then", "ElseIf", "Else", "Select", "Case", "Is",
  "To", "For", "Each", "In", "Next", "Do", "While", "Until", "Loop", "Function")

#let vba-join(arr) = if arr.len() == 0 { "" } else { arr.join() }

#let vba-tokenize-code(s) = {
  let toks = s.matches(regex("[A-Za-z0-9_]+|[^A-Za-z0-9_]+"))
  if toks.len() == 0 { none } else {
    toks.map(m => {
      let t = m.text
      if t in vba-keywords { text(fill: vba-kw-color)[#t] } else { t }
    }).join()
  }
}

#let vba-line(line) = {
  let chars = line.clusters()
  let in-str = false
  let idx = none
  for i in range(chars.len()) {
    let c = chars.at(i)
    if c == "\"" { in-str = not in-str }
    else if c == "'" and not in-str { idx = i; break }
  }
  if idx == none {
    vba-tokenize-code(line)
  } else {
    let code-part = vba-join(chars.slice(0, idx))
    let comment-part = vba-join(chars.slice(idx))
    [#vba-tokenize-code(code-part)#text(fill: vba-cm-color)[#comment-part]]
  }
}

#show raw.where(lang: "vb"): it => {
  set text(font: "Courier New")
  // tighter than the default 0.65em, matching the original's line spacing
  set par(leading: 0.5em)
  let lines = it.text.split("\n")
  for (i, line) in lines.enumerate() {
    vba-line(line)
    if i < lines.len() - 1 { linebreak() }
  }
}
// Lets a VBA slide's code run into the page's side/bottom margins (and, with
// a negative `top`, up beside the slide title) so it can fill the slide the
// way the original's code does.
#let vba-fill(top: 0pt, body) = pad(top: top, bottom: -36pt, x: -30pt, body)

// ---------- helpers ----------

// small entity-relationship table, e.g.
// #entity("company", (("PK", [company_id]), ("", [company_name]), ...))
// Only shows lines under the header and under the PK row (plus the outer
// border and a divider between the PK/FK column and the field names) — no
// lines between every attribute.
#let entity(title, rows) = table(
  columns: (auto, 1fr),
  stroke: none,
  inset: 4pt,
  table.hline(y: 0, stroke: 0.5pt + gray),
  table.vline(x: 0, stroke: 0.5pt + gray),
  table.vline(x: 2, stroke: 0.5pt + gray),
  table.vline(x: 1, start: 1, stroke: 0.5pt + gray),
  table.header(
    table.cell(colspan: 2, fill: luma(230))[*#title*],
  ),
  table.hline(y: 1, stroke: 0.5pt + gray),
  ..rows.map(r => (
    text(weight: "bold")[#r.at(0)],
    text[#r.at(1)],
  )).flatten(),
  table.hline(y: 2, stroke: 0.5pt + gray),
  table.hline(y: rows.len() + 1, stroke: 0.5pt + gray),
)

#let hl(body, color: yellow) = box(fill: color.lighten(40%), inset: 2pt, outset: 2pt, radius: 2pt)[#body]

// shows only the (x, y, w, h) pixel region of an image that is `size` =
// (width, height) pixels, scaled so that region comes out `width` wide —
// crops without touching the source file, e.g.
// #crop-img("assets/img/shot.png", (642, 256), 52, 38, 534, 173, width: 10cm)
#let crop-img(src, size, x, y, w, h, width: 10cm, radius: 0pt) = {
  let (iw, ih) = size
  let s = width / w
  // negative padding on all four sides trims the image's frame to exactly
  // the crop region. (Offsetting with place/move/a one-sided pad leaves an
  // oversized frame, which an inherited `horizon` alignment — e.g. from a
  // grid — vertically re-centers, shifting the crop.)
  box(clip: true, radius: radius,
    pad(
      top: -y * s, left: -x * s,
      bottom: -(ih - y - h) * s, right: -(iw - x - w) * s,
      image(src, width: iw * s),
    ))
}

// the acronym stacked in a slide's bottom-right corner, e.g.
// #corner-acronym("Entity", "Relationship", "Diagram")
// A line can also be an array of parts glued together with no space,
// each contributing its own bolded letter, e.g. #corner-acronym(("Hyper", "Text"), "Markup", "Language")
// for HTML, where "HyperText" is one word but contributes two acronym letters.
// Uses an absolute size (not em) so it stays visually consistent regardless
// of what ambient text size a slide's content happens to leave behind.
// marks the current page so the footer leaves off its slide number
#let hide-slide-number() = [#metadata(none) <hide-slide-number>]

// (hides the page's slide number so the acronym can sit in the true corner,
// matching the original slides, which don't number those pages either)
#let corner-acronym(..words) = hide-slide-number() + place(bottom + right)[
  #text(size: 27pt)[
    #words.pos().map(w => {
      let parts = if type(w) == array { w } else { (w,) }
      parts.map(p => [#strong[#p.first()]#p.slice(1)]).join()
    }).join([ \ ])
  ]
]

// ---------- ERD building blocks (real entity boxes + crow's-foot connectors) ----------
#let erd-pk-fill = rgb("#f7d6da")
#let erd-fk-fill = rgb("#cfe0f5")
#let erd-highlight-fill = rgb("#fff5b3")
#let erd-header-h = 0.85cm
#let erd-row-h = 0.72cm
#let erd-key-col-w = 1.75cm

// header row of an ERD entity box (with a small "collapse" icon, like
// dbdiagram.io). The border is drawn as part of THIS row's own box (top,
// left, right always; bottom too, since the header is always followed by a
// divider) — never as a separately-computed overlay — so it is always
// exactly where this row actually is, no matter the scale or table size.
#let erow-header(coord, title, width: 6cm, fill: luma(230), scale: 1.0, stroke: 0.5pt + gray) = node(
  coord,
  box(width: width, height: erd-header-h * scale, fill: fill, stroke: (top: stroke, bottom: stroke, left: stroke, right: stroke))[
    #align(left + horizon)[
      #pad(left: 4pt * scale)[
        #box(width: 7pt * scale, height: 7pt * scale, stroke: 0.5pt + gray)[#align(center + horizon)[#text(size: 6pt * scale)[#sym.minus]]]
        #h(4pt * scale) #text(weight: "bold", size: 11pt * scale)[#title]
      ]
    ]
  ],
  shape: rect, stroke: none, fill: none, inset: 0pt,
  width: width, height: erd-header-h * scale, outset: 0pt,
)

// one attribute row of an ERD entity box. Left/right borders are always
// drawn (so consecutive rows form one continuous outer side); `bottom: true`
// adds the divider under the PK row or the outer border under the last row.
// The PK/FK-column divider is a `place()`d line spanning the row's FULL
// height (not a `grid.vline`, which only spans the height of the text next
// to it, leaving a short dash with gaps between rows) — so it reads as one
// continuous line down the table, at exactly the same x as the text's
// column boundary since it uses the same `erd-key-col-w`.
#let erow(coord, key, label, width: 6cm, fill: white, name: none, scale: 1.0, key-divider: false, bottom: false, stroke: 0.5pt + gray, divider-stroke: 0.6pt + luma(120)) = node(
  coord,
  box(width: width, height: erd-row-h * scale, fill: fill, stroke: (left: stroke, right: stroke, bottom: if bottom { stroke } else { none }))[
    #if key-divider [
      #place(top + left, dx: erd-key-col-w * scale, dy: 0pt)[#line(angle: 90deg, length: erd-row-h * scale, stroke: divider-stroke)]
    ]
    #align(left + horizon)[
      #grid(columns: (erd-key-col-w * scale, 1fr), align: left + horizon,
        pad(left: 4pt * scale)[#text(weight: "bold", size: 11pt * scale)[#key]],
        pad(left: 4pt * scale)[#text(size: 11pt * scale)[#label]],
      )
    ]
  ],
  shape: rect, stroke: none, fill: none, inset: 0pt,
  width: width, height: erd-row-h * scale, outset: 0pt, name: name,
)

// a full small entity box: header + PK row + attribute rows, e.g.
// #erd-box(0, 0, "Store", "StoreID", ("StoreLocation", "SquareFootage"))
#let erd-box(col, row, title, pk, attrs, width: 3.6cm, header-fill: luma(230), pk-fill: erd-pk-fill, scale: 1.0) = (
  erow-header((col, row), title, width: width, fill: header-fill, scale: scale),
  erow((col, row + 1), "PK", underline[#pk], width: width, fill: pk-fill, scale: scale, key-divider: true, bottom: true),
  ..attrs.enumerate().map(((i, a)) => erow(
    (col, row + 2 + i), "", a, width: width, scale: scale, key-divider: true, bottom: i == attrs.len() - 1,
  ))
)

// a pair of small entity boxes connected by a crow's-foot relationship. A
// highlighter-style patch (like #hl) sits behind the mark nearest the LEFT
// entity — matching the "reading right-to-left" (orange) sentence — and
// behind the mark nearest the RIGHT entity — matching the "reading
// left-to-right" (blue) sentence — so students can see which mark answers
// which sentence, without changing the line/mark's own color. e.g.
// #erd-pair("Store", "StoreID", ("StoreLocation",), "Manager", "ManagerID", ("FirstName",), left-mark: "1", right-mark: "1")
#let erd-pair(left-name, left-pk, left-attrs, right-name, right-pk, right-attrs, left-mark: "1", right-mark: "1", width: 4.4cm) = {
  let gap = 1.6cm
  let mark-cy = erd-header-h + erd-row-h / 2
  box[
    #place(top + left, dx: width - 0.35cm, dy: mark-cy - 0.2cm)[
      #box(fill: rgb("#f4d9a0").lighten(35%), width: 0.7cm, height: 0.4cm)
    ]
    #place(top + left, dx: width + gap - 0.35cm, dy: mark-cy - 0.2cm)[
      #box(fill: rgb("#c2d6f4").lighten(35%), width: 0.7cm, height: 0.4cm)
    ]
    #diagram(
      node-stroke: none,
      spacing: (gap, 0pt),
      ..erd-box(0, 0, left-name, left-pk, left-attrs, width: width, header-fill: rgb("#c2d6f4"), pk-fill: white),
      ..erd-box(1, 0, right-name, right-pk, right-attrs, width: width, header-fill: rgb("#f4d9a0"), pk-fill: white),
      edge((0, 1), (1, 1), left-mark + "-" + right-mark, stroke: 0.6pt + black),
    )
  ]
}

// a min/max cardinality connector: a plain line between two tables, with
// combined min+max crow's-foot marks at each end (e.g. "1?" = zero-or-one,
// "n!" = one-or-many). The pink band highlights the two INNER (minimum)
// symbols and the green band highlights the two OUTER (maximum) symbols,
// matching the "inner = minimum, outer = maximum" callout above. The zero
// (circle) symbol is filled with the same "inner" pink.
//
// The marks themselves are hand-drawn (not fletcher's `marks:`/built-in
// crow's-foot system) at explicit offsets from the pink/green boundary,
// tuned by pixel-measuring the original slide. fletcher's own mark
// placement turned out to have an internal, `mark-scale`-independent gap
// between an edge's node coordinate and where the mark's ink actually
// starts, which made it unreliable to line up with the bands — drawing the
// ticks/circle/crow's-foot directly gives exact, predictable control.
//
// The pink/green bands and the TABLE A / TABLE B labels are drawn ONCE as
// full-height blocks (not per-row), so they read as one continuous strip
// down the whole diagram instead of four separately-broken rectangles.
#let erd-minmax-outer-w = 1.1cm
#let erd-minmax-inner-w = 1.1cm
#let erd-minmax-edge-w = 5.3cm
#let erd-minmax-line-w = erd-minmax-outer-w * 2 + erd-minmax-inner-w * 2 + erd-minmax-edge-w
#let erd-minmax-row-h = 2.3cm
#let erd-minmax-table-w = 0.9cm
#let erd-minmax-pink = rgb("#f4c2c2")
#let erd-minmax-green = rgb("#b7e4b7")

// mark geometry, tuned against the original slide's proportions
#let erd-minmax-tick-h = 0.6cm
#let erd-minmax-circle-r = 0.4cm
#let erd-minmax-splay = 0.5cm

// a single vertical tick, centered at local (x, 0)
#let erd-minmax-tick(x) = place(top + left, dx: x, dy: -erd-minmax-tick-h / 2)[
  #line(length: erd-minmax-tick-h, angle: 90deg, stroke: 1.2pt + black)
]

// a filled "zero" circle, centered at local (x, 0)
#let erd-minmax-circle(x) = place(top + left, dx: x - erd-minmax-circle-r, dy: -erd-minmax-circle-r)[
  #box(width: 2 * erd-minmax-circle-r, height: 2 * erd-minmax-circle-r, radius: erd-minmax-circle-r, fill: erd-minmax-pink, stroke: 1.2pt + black)
]

// a "many" crow's-foot with its point at local (x, 0), splaying toward `dir`
// (+1 = rightward, -1 = leftward) across the green band
// each segment is wrapped in its own `place()` so all three overlay at the
// same origin point — without that, Typst flows successive block elements
// one after another instead of stacking them, which drew the three
// "splayed" lines end-to-end into an X shape instead of a fan.
#let erd-minmax-crowfoot(x, dir) = place(top + left, dx: x, dy: 0pt)[
  #place(line(end: (dir * erd-minmax-outer-w * 0.9, 0pt), stroke: 1.2pt + black))
  #place(line(end: (dir * erd-minmax-outer-w * 0.9, erd-minmax-splay), stroke: 1.2pt + black))
  #place(line(end: (dir * erd-minmax-outer-w * 0.9, -erd-minmax-splay), stroke: 1.2pt + black))
]

// draws one end's combined min+max symbol. `anchor` is the plain line's end
// (the pink band's inner edge); `dir` is +1 for a right-hand end (bands
// extend further +x) or -1 for a left-hand end (bands extend further -x).
// Single marks (the tick or circle standing alone in one band) sit centered
// in that band; only the crow's-foot is left spanning from the boundary
// out toward the green band's outer edge.
#let erd-minmax-inner-mid = erd-minmax-inner-w * 0.5
#let erd-minmax-outer-mid = erd-minmax-inner-w + erd-minmax-outer-w * 0.5
#let erd-minmax-mark(kind, anchor, dir) = {
  if kind == "1?" {
    erd-minmax-tick(anchor + dir * erd-minmax-outer-mid)
    erd-minmax-circle(anchor + dir * erd-minmax-inner-mid)
  } else if kind == "11" {
    erd-minmax-tick(anchor + dir * erd-minmax-inner-mid)
    erd-minmax-tick(anchor + dir * erd-minmax-outer-mid)
  } else if kind == "n!" {
    erd-minmax-crowfoot(anchor + dir * erd-minmax-inner-w, dir)
    erd-minmax-tick(anchor + dir * erd-minmax-inner-mid)
  } else if kind == "n?" {
    erd-minmax-crowfoot(anchor + dir * erd-minmax-inner-w, dir)
    erd-minmax-circle(anchor + dir * erd-minmax-inner-mid)
  }
}

// rows: an array of (left-mark, right-mark) pairs, one per row.
#let erd-minmax-diagram(rows) = {
  let n = rows.len()
  let total-h = erd-minmax-row-h * n
  box(width: erd-minmax-table-w * 2 + erd-minmax-line-w, height: total-h)[
    #place(top + left, dx: 0pt, dy: 0pt)[
      #box(width: erd-minmax-table-w, height: total-h)[#align(center + horizon)[#rotate(-90deg, reflow: true)[#text(weight: "bold")[TABLE A]]]]
    ]
    #place(top + left, dx: erd-minmax-table-w, dy: 0pt)[#box(fill: erd-minmax-green.lighten(35%), width: erd-minmax-outer-w, height: total-h)]
    #place(top + left, dx: erd-minmax-table-w + erd-minmax-outer-w, dy: 0pt)[#box(fill: erd-minmax-pink.lighten(35%), width: erd-minmax-inner-w, height: total-h)]
    #place(top + left, dx: erd-minmax-table-w + erd-minmax-line-w - erd-minmax-inner-w - erd-minmax-outer-w, dy: 0pt)[#box(fill: erd-minmax-pink.lighten(35%), width: erd-minmax-inner-w, height: total-h)]
    #place(top + left, dx: erd-minmax-table-w + erd-minmax-line-w - erd-minmax-outer-w, dy: 0pt)[#box(fill: erd-minmax-green.lighten(35%), width: erd-minmax-outer-w, height: total-h)]
    #place(top + left, dx: erd-minmax-table-w + erd-minmax-line-w, dy: 0pt)[
      #box(width: erd-minmax-table-w, height: total-h)[#align(center + horizon)[#rotate(-90deg, reflow: true)[#text(weight: "bold")[TABLE B]]]]
    ]
    #for i in range(1, n) {
      place(top + left, dx: erd-minmax-table-w, dy: erd-minmax-row-h * i)[
        #line(length: erd-minmax-line-w, stroke: (paint: gray, thickness: 0.6pt, dash: "dotted"))
      ]
    }
    #for (i, pair) in rows.enumerate() {
      let (lm, rm) = pair
      let left-anchor = erd-minmax-table-w + erd-minmax-outer-w + erd-minmax-inner-w
      let right-anchor = erd-minmax-table-w + erd-minmax-line-w - erd-minmax-outer-w - erd-minmax-inner-w
      place(top + left, dx: 0pt, dy: erd-minmax-row-h * i + erd-minmax-row-h / 2 - 0.5pt)[
        #line(start: (erd-minmax-table-w, 0pt), end: (erd-minmax-table-w + erd-minmax-line-w, 0pt), stroke: 1.2pt + black)
        #erd-minmax-mark(lm, left-anchor, -1)
        #erd-minmax-mark(rm, right-anchor, 1)
      ]
    }
  ]
}

// content: an array of content blocks, one per row, each vertically
// centered within the same row-height slot the diagram uses, so they line
// up with the diagram's rows without needing a shared grid.
#let erd-minmax-descs(content) = stack(dir: ttb,
  ..content.map(c => box(height: erd-minmax-row-h)[#align(horizon)[#c]]))

// ---------- slides ----------

#title-slide[
  #box(width: 100%)[
    #image("assets/img/patsy-coconuts.jpg", width: 100%)
    #place(top + right, dx: -27%, dy: 36%)[
      #box(fill: white, inset: 3pt)[#text(size: 1.7em)[You]]
    ]
    #place(bottom + left, dx: 20pt, dy: -100pt)[
      #box(fill: white, inset: 3pt)[#text(size: 1.4em, weight: "bold")[James' Super Cool \ IS 201 Cheat Sheet]]
    ]

    #place(bottom + right, dx: 50pt, dy: 50pt)[#square(stroke:white, fill:white, width: 6cm)]


    #place(bottom + right, dx: 50pt, dy: 50pt)[
      #qrcode("https://jimna-h.github.io/james_super_cool_is_201_cheatsheet/is201-cheatsheet.pdf", width: 6cm, quiet-zone: true)
    ]
  ]
]

== Index

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + gray,
  inset: 8pt,
  [Slide], [Topic],
  [2], [#link(<erd-pfk>)[ERDs]],
  [6], [#link(<sql>)[SQL]],
  [8], [#link(<flowcharts>)[Flow Charts]],
  [9], [#link(<vba>)[VBA]],
  [15], [#link(<statistics>)[Statistics]],
  [16], [#link(<tableau>)[Tableau]],
  [17], [#link(<solver>)[Solver]],
  [18], [#link(<html>)[HTML]],
  [27], [#link(<css>)[CSS]],
)

== ERD: Primary / Foreign Keys <erd-pfk>

#grid(columns: (auto, 11.5cm), gutter: 1.2em,
[
  #diagram(
    node-stroke: none,
    spacing: (1.6cm, 0pt),
    erow-header((0, 0), "company", width: 4.6cm),
    erow((0, 1), "PK", underline[company_id], width: 4.6cm, fill: erd-pk-fill, name: <company-pk>, key-divider: true, bottom: true),
    erow((0, 2), "", "company_name", width: 4.6cm, key-divider: true),
    erow((0, 3), "", "employees", width: 4.6cm, key-divider: true),
    erow((0, 4), "", "followers", width: 4.6cm, key-divider: true),
    erow((0, 5), "", "industry", width: 4.6cm, key-divider: true),
    erow((0, 6), "", "state", width: 4.6cm, key-divider: true),
    erow((0, 7), "", "country", width: 4.6cm, key-divider: true),
    erow((0, 8), "", "city", width: 4.6cm, key-divider: true),
    erow((0, 9), "", "zip", width: 4.6cm, key-divider: true, bottom: true),

    erow-header((1, 0), "posting", width: 5.4cm),
    erow((1, 1), "PK", underline[job_id], width: 5.4cm, fill: erd-pk-fill, key-divider: true, bottom: true),
    erow((1, 2), "", "title", width: 5.4cm, key-divider: true),
    erow((1, 3), "", "description", width: 5.4cm, key-divider: true),
    erow((1, 4), "", "pay_period", width: 5.4cm, key-divider: true),
    erow((1, 5), "", "work_type", width: 5.4cm, key-divider: true),
    erow((1, 6), "", "job_location", width: 5.4cm, key-divider: true),
    erow((1, 7), "", "applies", width: 5.4cm, key-divider: true),
    erow((1, 8), "", "remote", width: 5.4cm, key-divider: true),
    erow((1, 9), "", "views", width: 5.4cm, key-divider: true),
    erow((1, 10), "", "level", width: 5.4cm, key-divider: true),
    erow((1, 11), "", "sponsored", width: 5.4cm, key-divider: true),
    erow((1, 12), "", "compensation", width: 5.4cm, key-divider: true),
    erow((1, 13), "", "job_domain", width: 5.4cm, key-divider: true),
    erow((1, 14), "FK", "company_id", width: 5.4cm, fill: erd-fk-fill, name: <posting-fk>, key-divider: true),
    erow((1, 15), "FK", "ben_pack_id", width: 5.4cm, key-divider: true, bottom: true),

    edge(<company-pk>, (0.5, 1), (0.5, 14), <posting-fk>, "1-n", stroke: 0.6pt + black, layer: 1),
  )
],
[
  #text(size: 1.1em)[
    A #box(fill: erd-pk-fill, inset: 2pt, outset: 2pt, radius: 2pt)[primary key] is a unique identifier (think social security number)

    #v(0.6em)
    A #box(fill: erd-fk-fill, inset: 2pt, outset: 2pt, radius: 2pt)[foreign key] is another table's primary key, used to link two tables together
  ]
]
)

#corner-acronym("Entity", "Relationship", "Diagram")

== ERD: Cardinality
#slide-text(0.78em)[

#grid(columns: (auto, 1fr), column-gutter: 1.2em, align: (left + top, left + top),
  [
    #erd-pair(
      "Store", "StoreID", ("StoreLocation", "SquareFootage", "YearBuilt"),
      "Manager", "ManagerID", ("FirstName", "LastName", "DateHired"),
      left-mark: "1", right-mark: "1",
    )
    #v(0.6em)
    #erd-pair(
      "Customer", "CustomerID", ("FirstName", "LastName", "MembershipLevel"),
      "Order", "OrderID", ("OrderDate", "TotalAmount", "CardNumber"),
      left-mark: "1", right-mark: "n",
    )
    #v(0.6em)
    #erd-pair(
      "Student", "StudentID", ("FirstName", "LastName", "DeclaredMajor"),
      "Course", "CourseID", ("CourseTitle", "Credits", "Location"),
      left-mark: "n", right-mark: "n",
    )
  ],
  [
    #underline[Read #hl(color: rgb("#c2d6f4"))[left-to-right] AND #hl(color: rgb("#f4d9a0"))[right-to-left]]

    #v(0.7em)
    *One to One (1:1)* \
    #pad(left: 1em)[
      #hl(color: rgb("#c2d6f4"))[A store has one manager] #sym.space
      #hl(color: rgb("#f4d9a0"))[A manager works at one store]
    ]

    #v(0.7em)
    *One to Many (1:N)* \
    #pad(left: 1em)[
      #hl(color: rgb("#c2d6f4"))[A customer can have multiple orders] #sym.space
      #hl(color: rgb("#f4d9a0"))[An order belongs to one customer]
    ]

    #v(0.7em)
    *Many to Many (M:N)* \
    #pad(left: 1em)[
      #hl(color: rgb("#c2d6f4"))[A student can enroll in many courses] #sym.space
      #hl(color: rgb("#f4d9a0"))[A course can have lots of students]
    ]

    #v(0.5em)
    #text(style: "italic", size: 0.7em)[Note! M:N cardinality requires a composite table (next slide)]
  ],
)
]

== ERD: Composite Table
#slide-text(0.78em)[

#let mw = 7.6cm
#let cw = 6.6cm
#let aw = 7.6cm
#let gap = 2.8cm
#let es = 1.22
#align(center)[#box[
  #diagram(
    node-stroke: none,
    spacing: (gap, 0pt),
    erow-header((0, 0), "movie", width: mw, scale: es),
    erow((0, 1), "PK", underline[movieid], width: mw, fill: erd-pk-fill, name: <movie-pk>, scale: es, key-divider: true, bottom: true),
    erow((0, 2), "", "title", width: mw, scale: es, key-divider: true),
    erow((0, 3), "", "mpaa_rating", width: mw, scale: es, key-divider: true),
    erow((0, 4), "", "budget", width: mw, scale: es, key-divider: true),
    erow((0, 5), "", "gross", width: mw, scale: es, key-divider: true),
    erow((0, 6), "", "release_date", width: mw, scale: es, key-divider: true),
    erow((0, 7), "", "genre", width: mw, scale: es, key-divider: true),
    erow((0, 8), "", "runtime", width: mw, scale: es, key-divider: true),
    erow((0, 9), "", "rating", width: mw, scale: es, key-divider: true),
    erow((0, 10), "", "rating_count", width: mw, scale: es, key-divider: true, bottom: true),

    erow-header((1, 0), "character", width: cw, scale: es),
    erow((1, 1), "PK/FK", underline[movieid], width: cw, fill: erd-fk-fill, name: <char-movieid>, scale: es, key-divider: true),
    erow((1, 2), "PK/FK", underline[actorid], width: cw, fill: erd-pk-fill, name: <char-actorid>, scale: es, key-divider: true, bottom: true),
    erow((1, 3), "", "character_name", width: cw, scale: es, key-divider: true),
    erow((1, 4), "", "credit_order", width: cw, scale: es, key-divider: true),
    erow((1, 5), "", "pay", width: cw, fill: erd-highlight-fill, scale: es, key-divider: true),
    erow((1, 6), "", "screentime", width: cw, scale: es, key-divider: true, bottom: true),

    erow-header((2, 0), "actor", width: aw, scale: es),
    erow((2, 1), "PK", underline[actorid], width: aw, fill: erd-pk-fill, name: <actor-pk>, scale: es, key-divider: true, bottom: true),
    erow((2, 2), "", "name", width: aw, scale: es, key-divider: true),
    erow((2, 3), "", "date_of_birth", width: aw, scale: es, key-divider: true),
    erow((2, 4), "", "birth_city", width: aw, scale: es, key-divider: true),
    erow((2, 5), "", "birth_country", width: aw, scale: es, key-divider: true),
    erow((2, 6), "", "height_inches", width: aw, scale: es, key-divider: true),
    erow((2, 7), "", "biography", width: aw, scale: es, key-divider: true),
    erow((2, 8), "", "gender", width: aw, scale: es, key-divider: true),
    erow((2, 9), "", "ethnicity", width: aw, scale: es, key-divider: true),
    erow((2, 10), "", "networth", width: aw, scale: es, key-divider: true, bottom: true),

    edge(<movie-pk>, <char-movieid>, "1-n", stroke: 0.6pt + black),
    edge(<char-actorid>, (1.5, 2), (1.5, 1), <actor-pk>, "n-1", stroke: 0.6pt + black, layer: 1),
  )
]]

#v(0.3em)
#align(center)[#box(width: 85%)[#text(size: 0.85em)[
To know how much money Tom Hanks got #box(fill: erd-highlight-fill, inset: 2pt, outset: 2pt, radius: 2pt)[paid] to play Woody in _Toy Story_,
you need to know both the #hl(color: rgb("#c2d6f4"))[movie] and the #hl(color: rgb("#f4c2c2"))[actor]. His pay is probably different than when he was Woody in
_Toy Story 2_, or when he was Forrest Gump in _Forrest Gump_
]]]
]

== ERD: Minimum / Maximum Cardinality
#slide-text(0.75em)[

#align(center)[#text(size: 1.05em)[
The #hl(color: rgb("#f4c2c2"))[inner marks are minimum] (0 or 1) \
and the #hl(color: rgb("#b7e4b7"))[outer marks are maximum] (1 or many)
]]

#v(0.8em)
#grid(
  columns: (auto, 1fr), column-gutter: 1.4em,
  align: (left + horizon, left + horizon),
  erd-minmax-diagram((("1?", "11"), ("n!", "n?"), ("n?", "1?"), ("11", "n!"))),
  erd-minmax-descs((
    [
      #text(size: 1.15em)[
        A could have #hl(color: rgb("#f4c2c2"))[1 B] or #hl(color: rgb("#b7e4b7"))[1 B] \
        B could have #hl(color: rgb("#f4c2c2"))[0 A] or #hl(color: rgb("#b7e4b7"))[1 A]
      ]
    ],
    [
      #text(size: 1.15em)[
        A could have #hl(color: rgb("#f4c2c2"))[0 B] or #hl(color: rgb("#b7e4b7"))[many B] \
        B could have #hl(color: rgb("#f4c2c2"))[1 A] or #hl(color: rgb("#b7e4b7"))[many A]
      ]
    ],
    [
      #text(size: 1.15em)[
        A could have #hl(color: rgb("#f4c2c2"))[0 B] or #hl(color: rgb("#b7e4b7"))[1 B] \
        B could have #hl(color: rgb("#f4c2c2"))[0 A] or #hl(color: rgb("#b7e4b7"))[many A]
      ]
    ],
    [
      #text(size: 1.15em)[
        A could have #hl(color: rgb("#f4c2c2"))[1 B] or #hl(color: rgb("#b7e4b7"))[many B] \
        B could have #hl(color: rgb("#f4c2c2"))[1 A] or #hl(color: rgb("#b7e4b7"))[1 A]
      ]
    ],
  )),
)

#v(0.5em)
#align(center)[#text(style: "italic", size: 1em)[
  Think: a student could have #hl(color: rgb("#f4c2c2"))[0 cars], but they could also have #hl(color: rgb("#b7e4b7"))[multiple].
]]
]

== SQL <sql>
#slide-text(0.75em)[

// styling matches the original slide: pink clause keywords, purple aggregate
// functions, gray comments — here aligned into a straight column (rather
// than trailing right after each line's code) so the bigger comment text
// stays readable. Shifted left (negative pad) to make room for that.
#let sql-code-size = 1.35em
#let sql-comment-size = 1.05em
#let sql-num-size = 0.8em
#let sql-num-color = rgb("#8a939c")
#let sql-kw-color = rgb("#d10099")
#let sql-fn-color = rgb("#390087")
#let sql-kw(code, color: sql-kw-color) = text(size: sql-code-size, fill: color)[#raw(code)]
#let sql-cm(comment) = text(size: sql-comment-size, fill: gray)[#raw("-- " + comment)]
#let sql-n(n) = text(size: sql-num-size, fill: sql-num-color)[#n]

#pad(left: -1.4em)[
#no-codly(grid(
  columns: (1.3em, auto, 1fr),
  column-gutter: (0.45em, 0.8em),
  row-gutter: 0.6em,
  align: (right + horizon, left + horizon, left + horizon),
  sql-n[1], sql-kw("SELECT"), sql-cm("attributes -- do SELECT DISTINCT to only show unique results"),
  sql-n[2], sql-kw("FROM"), sql-cm("tableA"),
  sql-n[3], sql-kw("JOIN"), sql-cm("tableB ON tableA.attribute = tableB.attribute (order doesn't matter)"),
  sql-n[4], sql-kw("WHERE"), sql-cm("attribute filters [=, !=, <>, IS, LIKE '%___%', IN (\"__\",\"__\",\"__\")]"),
  sql-n[5], sql-kw("    AND/OR"), sql-cm("you only say WHERE once, but can have many filters"),
  sql-n[6], sql-kw("GROUP BY"), sql-cm("all non-aggregated attributes when aggregating"),
  sql-n[7], sql-kw("HAVING"), sql-cm("group-based filters (not used in the SQL project)"),
  sql-n[8], sql-kw("ORDER BY"), sql-cm("attributes in ASC (default) / DESC order"),
  sql-n[9], sql-kw("LIMIT"), sql-cm("to xx top results"),
  sql-n[10], [], [],
  sql-n[11], grid.cell(colspan: 2)[#sql-cm("aggregate(attribute) AS newName")],
  sql-n[12], sql-kw("count()", color: sql-fn-color), [],
  sql-n[13], sql-kw("avg()", color: sql-fn-color), [],
  sql-n[14], sql-kw("min()", color: sql-fn-color), [],
  sql-n[15], sql-kw("max()", color: sql-fn-color), [],
  sql-n[16], grid.cell(colspan: 2)[#sql-cm("etc.")],
))
]

#corner-acronym("Structured", "Query", "Language")
]

== SQL: Where Use Cases
#slide-text(0.858em)[

// filter terms (=, !=, IS, LIKE, IN, ...) rendered noticeably bigger than
// the surrounding text, like the original. The left/right columns are a
// single grid so every note lines up in a straight column — except the
// != / <> pair (and the wildcard/IN follow-up notes), which use a small
// row-gutter to stay visually grouped, matching the original.
#let wc-term(body) = text(size: 1.2em, weight: "bold")[#body]
#let wc-big-gap = 2.1em
#let wc-small-gap = 0.2em

#pad(left: -1em)[
#grid(
  columns: (auto, 1fr),
  column-gutter: 0.9em,
  row-gutter: (wc-big-gap, wc-small-gap, wc-big-gap, wc-big-gap, wc-small-gap, wc-big-gap, wc-small-gap),
  align: (left + horizon, left + horizon),
  [ta_name #wc-term[=] "James"], [→ Exact match],
  [ta_name #wc-term[!=] "James"], [→ Not exact match],
  [ta_name #wc-term[<>] "James"], [#text(style: "italic")[(these are equivalent)]],
  [ta_name #wc-term[IS] NULL], [→ NULL means blank data \ (can also do #text(fill: black, weight: "bold")[IS NOT] NULL)],
  [ta_name #wc-term[LIKE] '%ame%'], [→ The text #text(style: "italic")[("ame")] is contained within the attribute],
  [], [#text(style: "italic")[(% = wildcard)]],
  grid.cell(colspan: 2)[ta_name #wc-term[IN] ("James", "Robert", "Frankie")],
  [], [→ Exact match for #underline[any] of these],
)
]
]

== Flow Charts <flowcharts>
#slide-text(0.4em)[

#place(top + left, text(size: 0.85em)[go to \ #link("https://draw.io")[draw.io]])
#place(bottom + left, text(size: 0.85em)[file \> export as \> pdf])
#grid(columns: (1fr, 1fr), column-gutter: 1.2em, inset: (left: 0.7em, right: 0.7em),
  align: (center, center),
  stroke: (x, y) => if x == 1 { (left: 0.7pt + black) } else { none },
[
  #scale(x: 82%, y: 82%, reflow: true)[
    #diagram(
      node-stroke: 0.7pt,
      spacing: (0.7cm, 1.3cm),
      node((0,0), [start/end], shape: fletcher.shapes.ellipse, width: 2.8cm, height: 1.9cm),
      node((1,0), align(left)[you can only have ONE start \ #v(0.3em) but you CAN have multiple ends], shape: rect, stroke: none, width: 5.2cm),
      node((0,1), [process \ (something happens)], shape: rect, width: 3.4cm, height: 1.9cm),
      node((0,2), [decision \ (T/F or Y/N)], shape: fletcher.shapes.diamond, width: 2.9cm, height: 2.8cm),
      node((1,2), align(left)[decisions are the ONLY thing that can have more than one arrow pointing OUT of them], shape: rect, stroke: none, width: 5.2cm),
      node((0,3), [input/output \ (info entered or displayed)], shape: fletcher.shapes.parallelogram, width: 4.2cm, height: 1.8cm),
      node((0,4), [connector], shape: fletcher.shapes.circle, width: 2cm),
      node((1,4), align(left)[connectors are the ONLY thing that can have more than one arrow pointing INTO them], shape: rect, stroke: none, width: 5.2cm),
    )
  ]
],
[
  #text(size: 1.05em, weight: "bold")[EXAMPLE: How to solve 1+1]
  #v(1.4em)
  #scale(x: 65%, y: 65%, reflow: true)[
    #diagram(
      node-stroke: 0.7pt,
      edge-stroke: 0.7pt,
      spacing: (2.7cm, 1.6cm),
      node((1,0), [start], shape: fletcher.shapes.ellipse, width: 2.1cm, height: 1.4cm),
      edge((1,0), (1,1), "-|>"),
      node((1,1), [do you have a \ calculator?], shape: fletcher.shapes.diamond, width: 3.5cm, height: 2.8cm),
      edge((1,1), (0,1), "-|>", [no], label-side: center),
      node((0,1), [do 1+1 in \ your head], shape: rect, width: 2.6cm, height: 1.5cm),
      edge((1,1), (2,1), "-|>", [yes], label-side: center),
      node((2,1), [enter "1+1=" \ into calculator], shape: fletcher.shapes.parallelogram, width: 3.9cm, height: 1.6cm),
      edge((2,1), (2,2), "-|>"),
      node((2,2), [calculator processes \ the math], shape: rect, width: 3.4cm, height: 1.6cm),
      edge((2,2), (2,3), "-|>"),
      node((2,3), [calculator displays \ the result], shape: fletcher.shapes.parallelogram, width: 3.9cm, height: 1.6cm),
      edge((0,1), (0,4), "-"),
      edge((0,4), (1,4), "-|>"),
      edge((2,3), (2,4), "-"),
      edge((2,4), (1,4), "-|>"),
      node((1,4), [], shape: fletcher.shapes.circle, width: 0.7cm),
      edge((1,4), (1,5), "-|>"),
      node((1,5), [end], shape: fletcher.shapes.ellipse, width: 2.1cm, height: 1.4cm),
    )
  ]
]
)
]

== VBA: Basics <vba>
#slide-text(0.83em)[

#corner-acronym("Visual", "Basic for", "Applications")

#vba-fill()[
```vb
Option Explicit 'This makes it so that you can only use variables you've declared (VERY RECOMMENDED)

Sub thisIsMySubName()

    'BASICS!

        'Generally you will first refer to an object type (like a Sheet)
        'and then tell it what you want to do (like delete or add or copy, etc):

            ' Sheets and Worksheets are the same thing
            Sheets("MySheet").Delete
            Sheets.Add.name = "MySheet"
            Worksheets("MySheet").Activate

            ' Range and Cells are SIMILAR but different: Range("E7") = Cells(7, 5)
            Range("A1").Activate
            ActiveCell.Value = "Hello"

            Range("A1:D3").Copy
            Range("E5").PasteSpecial

            ' Columns and Rows are what they sound like
            Columns("B:D").Delete
```
]
]

== VBA: Navigation and Misc.
#slide-text(0.84em)[

#vba-fill()[
```vb
'NAVIGATION!

    '
    ActiveCell.End (xlDown)
    ActiveCell.End (xlToLeft)

    ' Move (rows, columns) based on a cell or range
    ActiveCell.Offset(1, 2).Value = "NewSpot"
        Range("A1").Offset(3, 4).Value = "NewSpot" 'The cell that now says "NewSpot" is E4

' MISCELLANEOUS!

    ' Bolding
    Range("A1").Font.Bold = True

    ' Autofitting columns
    Columns.AutoFit 'all columns
    Columns("A:C").AutoFit 'specific columns

    ' Currency format
    Range("A1").Style = "Currency"

    ' Bottom border
    Range("A1").Borders(xlEdgeBottom).LineStyle = xlContinuous

    ' Text splicing
    name = "James"
    first_initial = Left(name, 1)
```
]
]

== VBA: Variables
#slide-text(0.79em)[

#vba-fill()[
```vb
'DECLARE VARIABLES!
    Dim i As Integer   'a whole number
    Dim j As Double     'a number with a decimal
    Dim k As String     'a line of text
    Dim l As Boolean    'true or false
    Dim m As Worksheet

    i = 5
    j = 1.2345
    k = "Hello there! General Kenobi!"
    l = True
    Set m = Sheets("Sheet1") 'objects (sheets, books, ranges) use Set instead of =

'USER INTERFACE!

    'Tell the user something
    MsgBox "Oh hello there user, welcome to my spreadsheet"

    'Ask for an input
    Dim username As String
    username = InputBox("What's your name?")

' COMBINGING STRINGS

    Dim myOutput As String
    Dim name As String
    name = "James"

    ' COmbine strings with ampersands (&)-- don't forget spaces
    myOutput = "Hello. My name is " & name & " and this is Disney Channel!"
```
]
]

== VBA: Conditionals
#slide-text(0.84em)[

#vba-fill(top: -40pt)[
```vb
'CONDITIONALS!
    ' If Statements
    If i < 0 Then
        ' your code here
    ElseIf i < 5 Then
        ' your code here
    ElseIf i < 10 Then
        ' your code here
    Else
        ' your code here
    End If

    'Case Statements
    Select Case fruit
        Case "apple", "strawberry"
            Color = "red"
        Case "grape"
            Color = "purple"
        Case Else
            Color = "unknown"
    End Select

    'Another Case Statement
    Select Case temperature
        Case Is >= 100
            feel = "too hot"
        Case 80 To 100
            feel = "pretty warm"
        Case Is < 80
            feel = "I'm probably staying out of the pool"
    End Select
```
]
]

== VBA: Loops
#slide-text(0.76em)[

#vba-fill(top: -40pt)[
```vb
'LOOPS!

    'For Loop
    For i = 0 To 5
        ' your code here
    Next i

    'For Each Loop
    Dim x As Range
    For Each x In Range("A2", Cells(lastrow, "A"))
        ' your code here
    Next

    'For Each Loop 2
    Dim x As Range
    Dim mtRange As Range
    Set myRange = Range("A1:E5")
    For Each x In myRange
        ' your code here
    Next

    'Do While Loop
    Do While i = 5 'condition does NOT have to be numbers
        ' your code here
    Loop

    ' Do Until Loop
    Do Until i = 10 'condition does NOT have to be numbers
        'your code here
    Loop



End Sub
```
]
]

== VBA: Functions
#slide-text(0.97em)[

#vba-fill()[
```vb
Function thisIsMyFunctionName(num As Integer, tf As Boolean) As String

    ' a function declaration is just like a set of dims
    ' the INPUT is in the parentheses ()
    ' the OUTPUT is outside of it
    ' so this function KIND OF has this baked into it:

    Dim num As Integer
    Dim tf As Boolean
    Dim thisIsMyFunctionName As String

    ' the INPUT then comes from your excel sheet
    ' for example, in your sheet you cell might say:
    ' =thisIsMyFunctionName(15, True)

    ' the OUTPUT comes from your function
    ' set the function's name equal to something
    ' in this case, our outpus has ot be a string:

    thisIsMyFuncitonName = "That's a very nice hat you have there, partner!"

    ' generally your inputs will be used to calculate/decide your output

End Function
```
]
]

== Statistics <statistics>
#slide-text(0.7em)[

#let stat-line = 1pt + luma(90)
#let stat-green = rgb("#b7e4b7")
// correlation strength: same green on both sides, fullest at ±1, white at 0
#let stat-strength = gradient.linear(stat-green, white, stat-green)
#let stat-gray = luma(110)

// a number line for reading a test's output. positions run 0..1 across it:
// `ticks` are (pos, label) marks with the label sitting on top of the tick,
// `bands` are (from, to, fill) shaded strips behind the line, `notes` are
// (pos, body) centered underneath, and `caption` is one centered line at
// the bottom.
#let stat-scale(ticks: (), bands: (), notes: (), caption: none, height: 5em) = block(width: 100%, height: height, {
  let y = 2em
  for (from, to, fill) in bands {
    place(top + left, dx: from * 100%, dy: y - 0.4em,
      rect(width: (to - from) * 100%, height: 0.8em, fill: fill, stroke: none))
  }
  place(top + left, dy: y, line(length: 100%, stroke: stat-line))
  for (pos, label) in ticks {
    place(top + left, dx: pos * 100%, dy: y - 0.4em, line(angle: 90deg, length: 0.8em, stroke: stat-line))
    place(bottom + center, dx: (pos - 0.5) * 100%, dy: -(height - y) - 0.5em,
      align(center, text(size: 0.8em)[#label]))
  }
  for (pos, body) in notes {
    place(top + center, dx: (pos - 0.5) * 100%, dy: y + 0.65em,
      align(center, text(size: 0.75em, hyphenate: false)[#body]))
  }
  if caption != none {
    // allowed to run a little past the line's ends rather than wrap
    place(bottom + center, box(width: 130%, align(center, text(size: 0.7em, style: "italic", fill: stat-gray)[#caption])))
  }
})

// test name + what it compares
#let stat-test(name, vars) = [#text(size: 1.1em)[*#name*] \ #text(size: 0.9em, fill: luma(70))[#vars]]
// "→ r": what the test on the left gives you
#let stat-out(sym) = box[#text(size: 1.2em, fill: luma(150))[→] #h(0.25em) #text(size: 1.4em, style: "italic")[#sym]]
#let stat-head(body) = text(size: 0.65em, weight: "bold", fill: luma(140), tracking: 0.06em, upper(body))

#grid(columns: (1fr, auto), column-gutter: 1.4em,
  grid(
    columns: (auto, 3.4em, 1fr),
    column-gutter: 0.6em,
    row-gutter: 0.8em,
    align: (left + horizon, left + horizon, left + horizon),
    stat-head[test & use case], stat-head[output], stat-head[how to read it],

    stat-test("Correlation", [numeric – numeric \ (Pearson _r_ coefficient)]),
    stat-out[r],
    stat-scale(
      ticks: ((0, [−1]), (0.5, [0]), (1, [1])),
      bands: ((0, 1, stat-strength),),
      notes: ((0.25, [as x ↑, y ↓]), (0.75, [as x ↑, y ↑])),
      caption: [strength = distance from 0; sign = direction],
    ),

    stat-test("Regression", [numeric – multi. numeric]),
    stat-out[R#super[2]],
    stat-scale(
      ticks: ((0, [0]), (0.7, [0.7]), (1, [1])),
      bands: ((0, 0.7, stat-green),),
      notes: ((0.7, [↑ \ 70% of the variance in y \ is explained by the x's]),),
      height: 5.6em,
    ),

    // ANOVA and T-test both give a p-value; the bracket groups them
    grid(columns: (auto, 0.5em), column-gutter: 0.6em,
      stroke: (x, y) => if x == 1 { (right: 1pt + luma(150), top: 1pt + luma(150), bottom: 1pt + luma(150)) },
      [
        #stat-test("ANOVA", [numeric – mult. categorical])
        #v(1em)
        #stat-test("T-test", [numeric – 2 pair categorical])
      ],
      [],
    ),
    stat-out[p],
    stat-scale(
      ticks: (
        (0, [0]),
        (0.5, [#text(size: 0.8em, fill: stat-gray)[usually 0.05] \ #text(size: 1.4em)[*α*]]),
        (1, [1]),
      ),
      bands: ((0, 0.5, stat-green),),
      notes: (
        (0.25, [reject the null \ *significant*]),
        (0.75, [fail to reject the null \ *not significant*]),
      ),
      caption: [p works like a percentage:\ 0.05 = 5% to see this or more extreme],
      height: 6.4em,
    ),
  ),
  // side notes
  block(width: 10em, height: 20em, stroke: (left: 0.5pt + luma(160)), inset: (left: 1em, y: 0.3em), text(size: 0.85em)[
    *Null Hypothesis* \
    H#sub[0]: No x's are significant
    #v(0.8em)
    *Alt Hypothesis* \
    H#sub[A]: At least one x is significant
    #v(1fr)
    *Scientific Notation* \
    aE#strong[b] = a × 10#super[#strong[b]] \
    #v(0.3em)
    aE#strong[3] = a × 1000 (big) \
    aE#strong[−3] = a × 0.001 (small)
  ]),
)
]

== Tableau <tableau>

- "Default" settings are usually a good starting point — check them first
- Switching the x- and y-axis can reveal a clearer story
- Watch your sort/ordering — Tableau doesn't always order the way you expect

== Solver <solver>
#hide-slide-number()
#slide-text(0.9em)[
// no slide number here, so the content can run into the bottom margin
#pad(bottom: -36pt)[

*Two important Excel formulas:*
#v(0.4em)

#grid(
  columns: (auto, auto, auto),
  column-gutter: 1.2em,
  row-gutter: 0.5em,
  align: left + horizon,
  [=sum(A1:A5)], [→], [A1 + A2 + A3 + A4 + A5],
  grid.cell(colspan: 3)[#v(0.6em)],
  [=sumproduct(A1:A5, B11:B15)], [→], [A1\*B11 + A2\*B12 + … + A5\*B15],
  grid.cell(colspan: 3, inset: (left: 1.5em))[#text(style: "italic", fill: luma(80))[the two ranges should be the same size and shape]],
)

#v(1fr)

// each screenshot sits right after its own label (not in a shared column),
// like the original
#grid(
  columns: (auto, auto),
  column-gutter: 1.2em,
  align: left + horizon,
  [*Constraints:*],
  crop-img("assets/img/solver_add_constraint.png", (642, 256), 52, 38, 534, 173, width: 11cm, radius: 5pt),
)

#v(1fr)

#grid(
  columns: (auto, auto),
  column-gutter: 1.2em,
  align: left + horizon,
  [*If integer isn't working:* \ Solver > Options > uncheck this box:],
  crop-img("assets/img/solver_fix_integers.png", (697, 130), 88, 4, 478, 125, width: 12.2cm),
)
]
]

== HTML: Setup <html>
#slide-text(1em)[

#corner-acronym(("Hyper", "Text"), "Markup", "Language")

In VS Code, inside a `.html` file, type `!` then Enter to generate:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
</body>
</html>
```

#text(size: 0.8em)[startbootstrap.com/themes/portfolio-resume]
]

== HTML: Tags
#slide-text(0.7em)[

```html
<!-- This is a comment -->
<h1>Main heading</h1>
<h2>Section heading</h2>
<h3>Subsection</h3>
<p>This is a paragraph.</p>
<!-- Line break -->
<br>
<!-- Unordered list (bullets) -->
<ul>
    <li>Item 1</li>
    <li>Item 2</li>
</ul>
<!-- Ordered list (numbers) -->
<ol>
    <li>Item 1</li>
    <li>Item 2</li>
</ol>
```

#text(style: "italic", size: 0.85em)[The start and end tags act like parentheses: `<tag> stuff </tag>`]
]

== HTML: Anchors

```html
<!-- Hyperlinks -->
<a href="https://www.google.com">Visit Google</a>
<!-- Folder references -->
<a href="otherpage.html">Visit Other Page</a>
<a href="subfolder/page.html">Visit Subfolder Page</a>
<a href="../yetanotherpage.html">Visit yet another page</a>
<!-- On-page anchors (any tag can have an id, not just <a>) -->
<a id="section1">Section 1</a>
<a href="#section1">Go to Section 1</a>
```

#text(style: "italic", size: 0.85em)[`../` means go to the parent folder (or _root directory_)]

== HTML: Images

```html
<!-- Images -->
<img src="images/bird.jpg" alt="A bird wearing a bagel.">
<img src="https://example.com/bird-online.jpg" alt="That same bird, but online.">
```

#text(style: "italic", size: 0.85em)[Notice: images do NOT have an end tag `</img>` (neither do line breaks `</br>`)]

== HTML: Divisions

#text(size: 0.95em)[Divs don't inherently do anything — they're invisible boxes you put content into so you can isolate it for positioning and CSS styling using classes.]

#v(0.3em)
#grid(columns: (1fr, 1fr), gutter: 1em,
[
  #text(size: 0.8em)[*HTML*]
  ```html
  <div class="square-image">
      <img src="assets/doctor-who-tardis.jpg" alt="TARDIS">
  </div>
  ```
],
[
  #text(size: 0.8em)[*CSS*]
  ```css
  .square-image {
      width: 200px;
      height: 200px;
  }
  ```
]
)

#v(0.2em)
#text(size: 0.85em)[For more, see: *CSS: Selectors/Properties/Values*]

== HTML: Embedding

#text(fill: red, style: "italic", size: 0.85em)[Sometimes doesn't work until you go live]

#grid(columns: (1fr, 1fr), gutter: 1.5em,
[
  *YouTube* \
  1. Click *Share* \
  2. Click *Embed* \
  3. Click *Copy* \
  4. Paste into your code
],
[
  *Tableau* \
  1. Click the share icon \
  2. Click *Copy Embed Code* \
  3. Paste into your code
]
)

== HTML: Folder Structure & Formatting

*Use folders!* Keep `css/`, `html/`, `images/`, and `js/` separate, with `index.html` at the project root.

#v(0.5em)
To quickly format everything correctly (tabs, long lines, etc.) in VS Code: \
#hl[Right click → Format Document]

== HTML: Uploading to GitHub

+ Click *New* to create a repository
+ Click *Create repository*
+ On the repo page: *Add file → Upload files*
+ Click *Commit changes*

#v(0.5em)
#text(fill: red, weight: "bold", size: 0.9em)[Upload the CONTENTS of your folder, not the folder itself]

== Going Live

+ Go to *Settings*
+ Click *Pages* in the sidebar
+ Under Branch, select `main` (instead of `None`) and *Save*

#v(0.5em)
#text(fill: red, size: 0.9em)[After a couple of minutes, refresh the page — there will be a link to your website at the top.]

== CSS: Basics <css>

#corner-acronym("Cascading", "Style", "Sheets")

```html
<!-- Connect CSS to HTML, in your <head> -->
<link rel="stylesheet" href="styles.css" />
```

```css
selector {
    property: value;
    property2: value2;
}
```

#text(size: 0.85em)[
CSS is *cascading* because more recent styling supersedes previous styling — if you set the font color to blue, then later set it to red, it will be red.
]

== CSS: Selectors / Properties / Values
#slide-text(0.75em)[

```css
/* Built-in selectors: the tags you use in your HTML (body, h1, p, a, img...) */
body {
    background-color: #f0f0f0;
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
}
/* Class (custom) selectors: create your own with a period + name */
.highlight {
    background-color: yellow;
    font-weight: bold;
}
```

```html
<p class="highlight">This text will be highlighted.</p>
```

#text(style: "italic", size: 0.85em)[There are A LOT of selectors and properties — Google and AI are your friend for finding exactly what you want!]
]

#focus-slide(background: black)[
  #text(size: 0.55em)[jimna-h.github.io/james_super_cool_is_201_cheatsheet]
  #v(0.5em)
  #box(fill: white, inset: 8pt)[#qrcode("https://jimna-h.github.io/james_super_cool_is_201_cheatsheet/is201-cheatsheet.pdf", width: 6cm, quiet-zone: true)]
]

#focus-slide(background: black)[
  #text(size: 49pt)[IS 201 TA Lab]
]
