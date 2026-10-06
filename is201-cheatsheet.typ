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

// 16:10 rather than 16:9: the classroom projector cut off the right edge
// of 16:9 slides
#let base-h = 473.56pt
#let base-w = base-h * 16 / 10

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
  config-page(
    width: base-w, height: base-h,
    margin: (top: 25pt, bottom: 50pt, x: 32pt),
    // a small house in the top-right corner of every slide but the first,
    // linking back to the first slide
    foreground: context if here().page() > 1 {
      let c = rgb("#3d6b78")
      let house = box(width: 14pt, height: 13pt, {
        place(polygon(fill: c, (0pt, 6.5pt), (7pt, 0pt), (14pt, 6.5pt)))
        place(dx: 2.5pt, dy: 6pt, rect(width: 9pt, height: 7pt, fill: c))
        place(dx: 5.5pt, dy: 8.5pt, rect(width: 3pt, height: 4.5pt, fill: white))
      })
      place(top + right, dx: -32pt, dy: 8pt,
        link((page: 1, x: 0pt, y: 0pt), house))
    },
  ),
)

// ---------- global sizing (matches the original slides' larger, readable type) ----------
#set text(font: "Arial")
#show raw: set text(font: "Consolas", size: 0.8em)

// ---------- shared style tokens (keep the deck cohesive across sections) ----------
// light panel behind cards/callouts; each section picks its own accent color
#let card-fill = luma(247)
// warnings and "don't do this" notes, everywhere in the deck
#let warn(body) = text(fill: rgb("#c62828"), weight: "bold", body)
// one color per topic: used for the Index swatches, the corner acronyms'
// letters, and each section's existing accent rules/headings
#let topic = (
  erd: rgb("#5a4fcf"),      // indigo
  sql: rgb("#d10099"),      // magenta
  flow: rgb("#e8850c"),     // draw.io orange
  vba: rgb("#217346"),      // Excel green
  stats: rgb("#b8860b"),    // dark gold
  tableau: rgb("#1f77b4"),  // Tableau blue
  solver: rgb("#8d5524"),   // brown
  html: rgb("#e34f26"),     // HTML5 red-orange
  css: rgb("#663399"),      // rebeccapurple, the CSS color
)
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

// one vb line with some phrases given a soft background: `hls` is an array
// of (regex pattern, fill). Each piece keeps its normal code/comment coloring.
#let vba-line-hl(line, hls) = {
  let chars = line.clusters()
  // where the comment starts (same rule as vba-line)
  let in-str = false
  let cmt = chars.len()
  for i in range(chars.len()) {
    let c = chars.at(i)
    if c == "\"" { in-str = not in-str }
    else if c == "'" and not in-str { cmt = i; break }
  }
  // highlighted ranges, in order
  let ranges = ()
  for (pat, fill) in hls {
    for m in line.matches(regex(pat)) { ranges.push((m.start, m.end, fill)) }
  }
  ranges = ranges.sorted(key: r => r.at(0))
  let piece(a, b) = {
    // a stretch of the line, colored as code or comment
    if b <= a { return [] }
    if a >= cmt { text(fill: vba-cm-color, vba-join(chars.slice(a, b))) }
    else if b <= cmt { vba-tokenize-code(vba-join(chars.slice(a, b))) }
    else [#vba-tokenize-code(vba-join(chars.slice(a, cmt)))#text(fill: vba-cm-color, vba-join(chars.slice(cmt, b)))]
  }
  let pos = 0
  for (a, b, fill) in ranges {
    piece(pos, a)
    box(fill: fill, outset: (y: 0.15em), radius: 2pt, piece(a, b))
    pos = b
  }
  piece(pos, chars.len())
}

// renders a vb code block. `hl` optionally picks lines by their CONTENT (so
// it survives reordering): an array of (line regex, that line's highlights),
// e.g. (("^Function", (("knight As String", fill),)),). The first matching
// entry applies to a line.
#let vba-render(it, hl: ()) = {
  set text(font: "Courier New")
  // tighter than the default 0.65em, matching the original's line spacing
  set par(leading: 0.5em)
  let lines = it.text.split("\n")
  for (i, line) in lines.enumerate() {
    let h = none
    for (sel, hls) in hl {
      if line.match(regex(sel)) != none { h = hls; break }
    }
    if h != none { vba-line-hl(line, h) } else { vba-line(line) }
    if i < lines.len() - 1 { linebreak() }
  }
}
#show raw.where(lang: "vb"): it => vba-render(it)
// Lets a VBA slide's code run into the page's side/bottom margins (and, with
// a negative `top`, up beside the slide title) so it can fill the slide the
// way the original's code does.
#let vba-fill(top: 0pt, body) = pad(top: top, bottom: -36pt, x: -20pt, body)

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

// ---------- dark "VS Code" code blocks (HTML/CSS slides) ----------
// styled like the original slides' VS Code screenshots: near-black
// background, Consolas, colors from assets/vscode-dark.tmTheme, and no line
// numbers or language badge. Pass a fenced block, e.g.
// #dark-code(```html
// <p>hi</p>
// ```)
// Each source line is its own fixed-height row, so `notes` — a dictionary
// of (line number as a string, starting at "1") → content — can sit beside
// exact lines.
#let code-dark-bg = rgb("#1e1e1e")  // VS Code's default dark editor gray
#let code-note-red = rgb("#ff6e61")  // light enough to read on the dark blocks
#let dark-code(code, size: 0.7em, pitch: 1.3em, notes: (:), width: auto) = no-codly(block(
  fill: code-dark-bg, width: width, inset: (x: 0.9em, y: 0.8em), breakable: false, {
    set text(size: size, fill: rgb("#d4d4d4"))
    set raw(theme: "assets/vscode-dark.tmTheme")
    // 1.5625em = 1.25 × 1.25 cancels both the global `show raw` 0.8em and
    // Typst's built-in 0.8em for raw text (show-set sizes compound), so
    // `size` is the code's actual size
    show raw: set text(font: ("Consolas", "Courier New"), size: 1.5625em)
    set par(leading: 0pt)
    // SQL keywords in the deck's SQL pink (lightened to read on the dark
    // background); an explicit list, since the bundled SQL grammar labels
    // some keywords (AND, AS, HAVING, ON...) as operators
    show regex("\b(SELECT|FROM|JOIN|ON|WHERE|AND|OR|NOT|IS|NULL|IN|LIKE|BETWEEN|GROUP BY|HAVING|ORDER BY|ASC|DESC|LIMIT|AS|DISTINCT)\b"): it => if code.lang == "sql" { text(fill: rgb("#f06bc4"), it) } else { it }
    // the whole block is highlighted at once (keeping multi-line syntax
    // context, e.g. CSS properties inside braces), but every line gets the
    // same fixed-height row, and a note is placed just past its line's end
    show raw.line: it => box(height: pitch, align(horizon, {
      it.body
      let note = notes.at(str(it.number), default: none)
      if note != none {
        context place(horizon + left, dx: measure(it.body).width + 1.2em,
          block({ set par(leading: 0.35em); text(font: "Arial", size: 0.95em, fill: code-note-red, note) }))
      }
    }))
    raw(code.text, lang: code.lang, block: true)
  }))

// a red curved arrow for code-block notes: leaves its start heading right,
// swings out by `reach`, and comes back in to (dx, dy), pointing left
#let red-arrow(dx, dy, reach: 3cm) = {
  let s = 1.4pt + code-note-red
  let y0 = 0pt  // notes are centered on their row, so this starts mid-row
  place(top + left, curve(stroke: s,
    curve.move((0pt, y0)),
    curve.cubic((reach * 0.9, y0), (reach * 1.1, y0 + dy), (dx + 8pt, y0 + dy)),
  ))
  place(top + left, dx: dx, dy: y0 + dy, polygon(fill: code-note-red, stroke: none,
    (0pt, 0pt), (9pt, -4.5pt), (9pt, 4.5pt)))
}

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
#let corner-acronym(..words, color: rgb("#3d6b78")) = hide-slide-number() + place(bottom + right)[
  #text(size: 27pt)[
    #words.pos().map(w => {
      let parts = if type(w) == array { w } else { (w,) }
      parts.map(p => [#text(weight: "bold", fill: color, p.first())#p.slice(1)]).join()
    }).join([ \ ])
  ]
]

// ---------- ERD building blocks (real entity boxes + crow's-foot connectors) ----------
// ERD highlights use just two colors: purple (the ERD topic color) for the
// main idea on each slide, yellow as the one secondary
#let erd-purple = topic.erd.lighten(75%)
#let erd-yellow = rgb("#fff5b3")
// the same two for `hl(...)`, which lightens its color by 40%
#let erd-purple-hl = topic.erd.lighten(58%)
#let erd-yellow-hl = rgb("#ffee80")
// (the Composite Table slide also uses a green, for its one example field)
#let erd-green = rgb("#d4efcf")
#let erd-pk-fill = erd-purple
#let erd-fk-fill = erd-yellow
#let erd-highlight-fill = erd-yellow
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
      #box(fill: erd-yellow, width: 0.7cm, height: 0.4cm)
    ]
    #place(top + left, dx: width + gap - 0.35cm, dy: mark-cy - 0.2cm)[
      #box(fill: erd-purple, width: 0.7cm, height: 0.4cm)
    ]
    #diagram(
      node-stroke: none,
      spacing: (gap, 0pt),
      ..erd-box(0, 0, left-name, left-pk, left-attrs, width: width, header-fill: erd-purple, pk-fill: white),
      ..erd-box(1, 0, right-name, right-pk, right-attrs, width: width, header-fill: erd-yellow, pk-fill: white),
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
#let erd-minmax-pink = erd-purple-hl  // (name kept) minimum: purple
#let erd-minmax-green = erd-yellow-hl  // (name kept) maximum: yellow

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

    #place(bottom + right, dx: 32pt, dy: 50pt)[#square(stroke:white, fill:white, width: 6cm)]


    #place(bottom + right, dx: 32pt, dy: 50pt)[
      #qrcode("https://jimna-h.github.io/james_super_cool_is_201_cheatsheet/is201-cheatsheet.pdf", width: 6cm, quiet-zone: true)
    ]
  ]
]

== Index

// slide numbers are looked up from each section's label, so they stay
// right when slides are added or reordered
#let slide-no(lbl) = context utils.slide-counter.at(lbl).first()
#let sw(c) = box(width: 0.55em, height: 0.55em, radius: 2pt, fill: c, baseline: -0.05em)
#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + gray,
  inset: 8pt,
  [Slide], [Topic],
  slide-no(<erd-pfk>), [#sw(topic.erd) #h(0.3em) #link(<erd-pfk>)[ERDs]],
  slide-no(<sql>), [#sw(topic.sql) #h(0.3em) #link(<sql>)[SQL]],
  slide-no(<flowcharts>), [#sw(topic.flow) #h(0.3em) #link(<flowcharts>)[Flow Charts]],
  slide-no(<vba>), [#sw(topic.vba) #h(0.3em) #link(<vba>)[VBA]],
  slide-no(<statistics>), [#sw(topic.stats) #h(0.3em) #link(<statistics>)[Statistics]],
  slide-no(<tableau>), [#sw(topic.tableau) #h(0.3em) #link(<tableau>)[Tableau]],
  slide-no(<solver>), [#sw(topic.solver) #h(0.3em) #link(<solver>)[Solver]],
  slide-no(<html>), [#sw(topic.html) #h(0.3em) #link(<html>)[HTML]],
  slide-no(<css>), [#sw(topic.css) #h(0.3em) #link(<css>)[CSS]],
)

== ERD: Primary / Foreign Keys <erd-pfk>

// a few rows of real data, so students see the FK values pointing at PKs
#let pf-cell(body, fill: none) = table.cell(fill: fill, box(text(font: "Consolas", size: 0.42em, body)))
#let pf-head(body) = table.cell(fill: luma(230), box(text(font: "Consolas", size: 0.42em, weight: "bold", body)))
// each example table sits right under its ERD box, with an arrow down from it
#let pf-table(title, cols, ..cells) = box(stack(dir: ttb, spacing: 0.6em,
  align(center, text(size: 0.8em, fill: luma(120))[↓]),
  table(columns: cols, inset: (x: 0.4em, y: 0.25em), stroke: 0.5pt + luma(190), align: left, ..cells),
))

// (no slide number on acronym pages, so this can use the bottom margin)
#pad(bottom: -36pt)[
#grid(columns: (auto, 1fr), column-gutter: 1.2em,
[
  #scale(110%, reflow: true, origin: top + left)[#diagram(
    node-stroke: none,
    spacing: (1.6cm, 0pt),
    erow-header((0, 0), "movie_info", width: 4.6cm),
    erow((0, 1), "PK", underline[movie_id], width: 4.6cm, fill: erd-pk-fill, name: <company-pk>, key-divider: true, bottom: true),
    erow((0, 2), "", "title", width: 4.6cm, key-divider: true),
    erow((0, 3), "", "release_date", width: 4.6cm, key-divider: true),
    erow((0, 4), "", "imdb_score", width: 4.6cm, key-divider: true),
    erow((0, 5), "", "duration", width: 4.6cm, key-divider: true),
    erow((0, 6), "", "genre", width: 4.6cm, key-divider: true),
    erow((0, 7), "", "director", width: 4.6cm, key-divider: true, bottom: true),

    erow-header((1, 0), "survey_responders", width: 5.4cm),
    erow((1, 1), "PK", underline[responder_id], width: 5.4cm, fill: erd-pk-fill, key-divider: true, bottom: true),
    erow((1, 2), "", "name", width: 5.4cm, key-divider: true),
    erow((1, 3), "", "birth_date", width: 5.4cm, key-divider: true),
    erow((1, 4), "", "email", width: 5.4cm, key-divider: true),
    erow((1, 5), "", "owns_copy", width: 5.4cm, key-divider: true),
    erow((1, 6), "", "times_watched", width: 5.4cm, key-divider: true),
    erow((1, 7), "FK", "movie_id", width: 5.4cm, fill: erd-fk-fill, name: <posting-fk>, key-divider: true, bottom: true),

    edge(<company-pk>, (0.5, 1), (0.5, 7), <posting-fk>, "1-n", stroke: 0.6pt + black, layer: 1),
  )]
  #v(-0.75em)
  // the 2nd table starts where the 2nd ERD box does (box + gap, at 110%)
  #grid(columns: ((4.6cm + 1.6cm) * 1.1, auto), align: left + top,
    pf-table("movie_info", 2,
      pf-head[movie_id], pf-head[title],
      pf-cell(fill: erd-pk-fill)[1], pf-cell[Monty Python…],
      pf-cell(fill: erd-pk-fill)[2], pf-cell[Princess Bride],
      pf-cell(fill: erd-pk-fill)[3], pf-cell[Shrek]),
    pf-table("survey_responders", 3,
      pf-head[responder_id], pf-head[name], pf-head[movie_id],
      pf-cell(fill: erd-pk-fill)[1], pf-cell[James], pf-cell(fill: erd-fk-fill)[1],
      pf-cell(fill: erd-pk-fill)[2], pf-cell[Ava], pf-cell(fill: erd-fk-fill)[2],
      pf-cell(fill: erd-pk-fill)[3], pf-cell[Lee], pf-cell(fill: erd-fk-fill)[1]),
  )
  #v(-0.2em)
  #block(width: 15cm, text(size: 0.5em, fill: luma(80))[Want the duration of James's favorite movie? Look up his #text(font: "Consolas")[movie_id] (1) in #text(font: "Consolas")[movie_info]. The movie's info is stored once there, not copied onto James's and Lee's rows. Avoiding that repetition is the power of foreign keys!])
],
[
  #text(size: 0.85em)[
    A #box(fill: erd-pk-fill, inset: 2pt, outset: 2pt, radius: 2pt)[primary key] is a unique identifier (think social security number)

    #v(0.6em)
    A #box(fill: erd-fk-fill, inset: 2pt, outset: 2pt, radius: 2pt)[foreign key] is another table's primary key, used to link two tables together
  ]
]
)

]
#corner-acronym("Entity", "Relationship", "Diagram", color: topic.erd)

== ERD: Cardinality
#slide-text(0.78em)[
// runs into the bottom margin; the slide number (bottom right) stays clear of it
#pad(bottom: -36pt)[

// one card per relationship: its diagram, with its two readings beside it
#let card-row(diagram, title, fwd, back, note: none) = block(width: 100%,
  grid(columns: (auto, 1fr), column-gutter: 1.6em, align: (left + horizon, left + horizon),
    diagram,
    stack(dir: ttb, spacing: 0.55em,
      text(weight: "bold", fill: rgb("#3d6b78"), title),
      hl(color: erd-purple-hl, fwd),
      hl(color: erd-yellow-hl, back),
      ..if note != none { (text(style: "italic", size: 0.75em, note),) },
    ),
  ))

#align(center, underline[Read #hl(color: erd-purple-hl)[left-to-right] AND #hl(color: erd-yellow-hl)[right-to-left]])
#v(0.1em)
#card-row(erd-pair(
    "Knight", "KnightID", ("Name", "Title", "Motto"),
    "Quest", "QuestID", ("Goal", "StartDate", "Status"),
    left-mark: "1", right-mark: "1",
  ), [One to One (1:1)], [A knight has one quest], [A quest belongs to one knight])
#v(0.55em)
#card-row(erd-pair(
    "Movie", "MovieID", ("Title", "ReleaseDate", "Duration"),
    "Scene", "SceneID", ("Location", "Runtime", "SceneOrder"),
    left-mark: "1", right-mark: "n",
  ), [One to Many (1:N)], [A movie has multiple scenes], [A scene belongs to one movie])
#v(0.55em)
#card-row(erd-pair(
    "Actor", "ActorID", ("Name", "BirthDate", "Nationality"),
    "Movie", "MovieID", ("Title", "ReleaseDate", "Duration"),
    left-mark: "n", right-mark: "n",
  ), [Many to Many (M:N)], [An actor can be in many movies], [A movie can have lots of actors],
  note: [Note! M:N needs a composite table (next slide)])
]
]

== ERD: Associative Table
#slide-text(0.78em)[

#let mw = 6.4cm
#let cw = 5.6cm
#let aw = 6.4cm
#let gap = 2.2cm
#let es = 1.08
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
    erow((1, 1), "PK/FK", underline[movieid], width: cw, fill: erd-pk-fill, name: <char-movieid>, scale: es, key-divider: true),
    erow((1, 2), "PK/FK", underline[actorid], width: cw, fill: erd-yellow, name: <char-actorid>, scale: es, key-divider: true, bottom: true),
    erow((1, 3), "", "character_name", width: cw, scale: es, key-divider: true),
    erow((1, 4), "", "credit_order", width: cw, scale: es, key-divider: true),
    erow((1, 5), "", "pay", width: cw, fill: erd-green, scale: es, key-divider: true),
    erow((1, 6), "", "screentime", width: cw, scale: es, key-divider: true, bottom: true),

    erow-header((2, 0), "actor", width: aw, scale: es),
    erow((2, 1), "PK", underline[actorid], width: aw, fill: erd-yellow, name: <actor-pk>, scale: es, key-divider: true, bottom: true),
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
#align(center)[#box(width: 95%)[#text(size: 0.85em)[
To know how much Graham Chapman got #box(fill: erd-green, inset: 2pt, outset: 2pt, radius: 2pt)[paid] to play King Arthur in _Monty Python and the Holy Grail_,
you need both the #box(fill: erd-purple, inset: 2pt, outset: 2pt, radius: 2pt)[movie] and the #box(fill: erd-yellow, inset: 2pt, outset: 2pt, radius: 2pt)[actor].
Neither alone is enough: King Arthur has also been played by Sean Connery (_First Knight_) and Clive Owen (_King Arthur_),
and Chapman's pay was probably different when he played Brian in _Life of Brian_.
]]]
]

== ERD: Minimum / Maximum Cardinality
#slide-text(0.75em)[

#align(center)[#text(size: 1.05em)[
The #hl(color: erd-purple-hl)[inner marks are minimum] (0 or 1) \
and the #hl(color: erd-yellow-hl)[outer marks are maximum] (1 or many)
]]

#v(0.8em)
#grid(
  columns: (auto, 1fr), column-gutter: 1.4em,
  align: (left + horizon, left + horizon),
  erd-minmax-diagram((("1?", "11"), ("n!", "n?"), ("n?", "1?"), ("11", "n!"))),
  erd-minmax-descs((
    [
      #text(size: 1.15em)[
        A could have #hl(color: erd-purple-hl)[1 B] or #hl(color: erd-yellow-hl)[1 B] \
        B could have #hl(color: erd-purple-hl)[0 A] or #hl(color: erd-yellow-hl)[1 A]
      ]
    ],
    [
      #text(size: 1.15em)[
        A could have #hl(color: erd-purple-hl)[0 B] or #hl(color: erd-yellow-hl)[many B] \
        B could have #hl(color: erd-purple-hl)[1 A] or #hl(color: erd-yellow-hl)[many A]
      ]
    ],
    [
      #text(size: 1.15em)[
        A could have #hl(color: erd-purple-hl)[0 B] or #hl(color: erd-yellow-hl)[1 B] \
        B could have #hl(color: erd-purple-hl)[0 A] or #hl(color: erd-yellow-hl)[many A]
      ]
    ],
    [
      #text(size: 1.15em)[
        A could have #hl(color: erd-purple-hl)[1 B] or #hl(color: erd-yellow-hl)[many B] \
        B could have #hl(color: erd-purple-hl)[1 A] or #hl(color: erd-yellow-hl)[1 A]
      ]
    ],
  )),
)

#v(0.5em)
#align(center)[#text(style: "italic", size: 1em)[
  Think: a knight could have #hl(color: erd-purple-hl)[0 horses] (coconuts!) or #hl(color: erd-yellow-hl)[multiple].
]]
]

== SQL: Clauses <sql>
#slide-text(0.75em)[

// corner note, same size/spot as Flow Charts' "go to draw.io" (one line so
// it stays clear of the code below)
#place(top + left, text(size: 0.69em)[go to #link("https://gaskination.com/sql/")[gaskination.com/sql]])

// (no slide number on acronym pages, so this can use the bottom margin)
#pad(bottom: -36pt)[

// styling matches the original slide: pink clause keywords, purple aggregate
// functions, gray comments — here aligned into a straight column (rather
// than trailing right after each line's code) so the bigger comment text
// stays readable. Shifted left (negative pad) to make room for that.
#let sql-code-size = 1.35em
#let sql-comment-size = 1.05em
#let sql-num-size = 0.8em
#let sql-num-color = rgb("#8a939c")
#let sql-kw-color = topic.sql
#let sql-fn-color = rgb("#390087")
#let sql-kw(code, color: sql-kw-color) = text(size: sql-code-size, fill: color)[#raw(code)]
#let sql-cm(comment) = text(size: sql-comment-size, fill: gray)[#raw("-- " + comment)]
#let sql-n(n) = text(size: sql-num-size, fill: sql-num-color)[#n]

#let sql-see(lbl, name) = text(size: sql-comment-size)[#link(lbl)[#raw("see " + name)]]
#let sql-card(body) = block(width: 100%, fill: card-fill, stroke: (left: 3pt + sql-kw-color),
  inset: (x: 0.9em, y: 0.7em), body)

#sql-card[
  #text(size: 0.85em, style: "italic", fill: luma(90))[Always written in this order. Only #text(font: "Consolas", style: "normal")[SELECT] and #text(font: "Consolas", style: "normal")[FROM] are required.]
  #v(0.2em)
  #no-codly(grid(
    columns: (1.3em, auto, 1fr),
    column-gutter: (0.45em, 0.8em),
    row-gutter: 0.6em,
    align: (right + horizon, left + horizon, left + horizon),
    sql-n[1], sql-kw("SELECT"), sql-cm("which attributes to show (* = all, DISTINCT = no duplicate rows)"),
    sql-n[2], sql-kw("FROM"), sql-cm("the table to pull from (tableA)"),
    sql-n[3], sql-kw("JOIN"), [#sql-cm("tableB ON tableA.key = tableB.key") #h(0.6em) #sql-see(<sql-join>, "Join slides")],
    sql-n[4], sql-kw("WHERE"), [#sql-cm("keep only rows that pass a filter") #h(0.6em) #sql-see(<sql-where>, "Where slides")],
    sql-n[5], sql-kw("    AND/OR"), sql-cm("add more filters (only write WHERE once)"),
    sql-n[6], sql-kw("GROUP BY"), sql-cm("with aggregates: list every SELECT attribute that isn't aggregated"),
    sql-n[7], sql-kw("HAVING"), sql-cm("like WHERE, but filters groups"),
    sql-n[8], sql-kw("ORDER BY"), sql-cm("sort by an attribute: ASC (default, low to high) or DESC"),
    sql-n[9], sql-kw("LIMIT"), sql-cm("only show the first N rows (e.g. LIMIT 10)"),
  ))
]
#v(0.8em)
#block(width: 74%, sql-card[
  // aggregates: what they are, the pattern, an example, then the other functions
  #sql-cm("aggregates turn many rows into one value") \
  #sql-cm("function(attribute) AS new_name") \
  #text(font: "Consolas", size: sql-code-size * 0.64)[#text(fill: sql-kw-color)[SELECT] #text(fill: sql-fn-color)[avg]\(imdb_score) #text(fill: sql-kw-color)[AS] avg_score]
  #v(0.1em)
  #sql-cm("examples: count(), sum(), avg(), min(), max()")
  #v(0.6em)
  // plain math (not an aggregate): calculated for each row
  #sql-cm("you can also do math with attributes (+ - * /)") \
  #text(font: "Consolas", size: sql-code-size * 0.64)[#text(fill: sql-kw-color)[SELECT] imdb_score / duration #text(fill: sql-kw-color)[AS] score_per_min]
])

#corner-acronym("Structured", "Query", "Language", color: topic.sql)
]
]

// shared by both WHERE slides: one row per kind of filter, with a pink
// left rule. Operators are pink + bold (not bigger), so no keyword dominates.
#let sql-pink = topic.sql
#let op(body) = text(weight: "bold", fill: sql-pink, body)
#let ex(code, note) = [#text(font: "Consolas", size: 0.85em, code) \ #text(size: 0.8em, fill: luma(90))[→ #note]]
#let type-row(title, rule, cols, gap: 0.8em, pad-y: 0.7em, ..items) = block(width: 100%, fill: card-fill,
  stroke: (left: 3pt + sql-pink), inset: (x: 0.9em, y: pad-y),
  grid(columns: (6.2em, 1fr), column-gutter: 1em, align: (left + horizon, left + top),
    [#text(size: 1.2em, weight: "bold", fill: sql-pink, title) \ #text(size: 0.8em, style: "italic", fill: luma(90), rule)],
    grid(columns: cols, column-gutter: 1.5em, row-gutter: gap, ..items.pos()),
  ))

== SQL: Where (1/2) <sql-where>
#slide-text(0.8em)[

#set smartquote(enabled: false)  // straight quotes, like real SQL

#type-row("Text", [in quotes], (1fr, 1fr), gap: 1.5em, pad-y: 1.1em,
  ex([name #op[=] "James"], [exactly "James"]),
  ex([name #op[!=] "James" \ name #op[<>] "James"], [anything but "James"]),
  ex([title #op[LIKE] "%Grail%"], [contains "Grail"]),
  text(size: 0.8em, fill: luma(90))[#text(font: "Consolas", size: 1.06em)[%] = any number of characters \ #text(font: "Consolas", size: 1.06em)[\_] = exactly one character],
  grid.cell(colspan: 2, ex([name #op[IN] ("James", "Ava", "Sam")], [exact match for #underline[any] of these])),
)
#v(1.2em)
#type-row("Blank", [any data type], (1fr, 1fr), pad-y: 1.1em,
  ex([movie_id #op[IS] NULL], [blank / missing]),
  ex([movie_id #op[IS NOT] NULL], [has data]),
)
]

== SQL: Where (2/2)
#slide-text(0.74em)[

#set smartquote(enabled: false)  // straight quotes, like real SQL

#type-row("Numbers", [no quotes], (1fr, 1fr),
  ex([imdb_score #op[>] 8 \ imdb_score #op[<] 8], [greater than / less than]),
  ex([imdb_score #op[>=] 8 \ imdb_score #op[<=] 8], [... or equal to]),
  grid.cell(colspan: 2, ex([duration #op[BETWEEN] 90 #op[AND] 120], [90 to 120 minutes (includes both)])),
)
#v(0.5em)
#type-row("Booleans", [no quotes], (1fr, 1fr),
  ex([owns_copy #op[=] TRUE], [people who own the movie]),
  ex([owns_copy #op[=] FALSE], [everyone else]),
)
#v(0.5em)
#type-row("Dates", [in quotes: "YYYY-MM-DD"], (1fr, 1fr),
  ex([release_date #op[>] "1980-01-01"], [released after 1980]),
  ex([birth_date #op[<] "2000-01-01"], [born before 2000]),
  grid.cell(colspan: 2, ex([release_date #op[BETWEEN] "1970-01-01" #op[AND] "1979-12-31"], [released in the 1970s])),
)
]

// shared by both JOIN slides
#let match-fill = sql-pink.lighten(80%)
#let miss(body) = text(fill: luma(150), body)
#let null-cell = text(fill: sql-pink, style: "italic")[NULL]
// a tiny example table: bold header row, light borders
#let mini-table(title, ..cells, size: 0.62em) = [
  #if title != "" [#text(size: 0.7em, weight: "bold", font: "Consolas", title) #v(-0.1em)]
  #table(columns: 2, inset: (x: 0.45em, y: 0.25em), stroke: 0.5pt + luma(190),
    fill: (_, y) => if y == 0 { luma(230) },
    ..cells.pos().map(c => if c.func() == table.cell { c } else { box(text(size: size, font: "Consolas", c)) }))
]
#let hit(body, size: 0.62em) = table.cell(fill: match-fill, box(text(size: size, font: "Consolas", body)))
// Venn diagram for one join type: A on the left, B on the right, with the
// rows that join keeps shaded
#let venn(keep-a, keep-b, d: 1.5cm) = {
  let off = d * 0.57
  let f = sql-pink.lighten(55%)
  let s = 0.8pt + luma(80)
  box(width: d + off, height: d, {
    if keep-a { place(circle(radius: d / 2, fill: f, stroke: none)) }
    if keep-b { place(dx: off, circle(radius: d / 2, fill: f, stroke: none)) }
    // the overlap is always kept
    place(box(width: d, height: d, radius: d / 2, clip: true,
      place(dx: off, circle(radius: d / 2, fill: f, stroke: none))))
    place(circle(radius: d / 2, stroke: s))
    place(dx: off, circle(radius: d / 2, stroke: s))
    // labels centered in each circle's own (non-overlapping) part
    place(dx: off / 2 - 0.13cm, dy: d / 2 - 0.25cm, text(size: 0.8em, weight: "bold")[A])
    place(dx: d + off / 2 - 0.13cm, dy: d / 2 - 0.25cm, text(size: 0.8em, weight: "bold")[B])
  })
}

== SQL: Join (1/2) <sql-join>
#slide-text(0.8em)[

#set smartquote(enabled: false)  // straight quotes, like real SQL

#text(size: 1.2em, weight: "bold", fill: sql-pink)[JOIN] #h(0.5em)
#text(style: "italic", fill: luma(90))[combines two tables, keeping rows that match in #underline[both]]
#v(0.5em)
#grid(columns: (auto, 1fr), column-gutter: 1.2em, align: horizon,
  dark-code(size: 0.62em, ```sql
SELECT survey_responders.name, movie_info.title
FROM survey_responders
JOIN movie_info
  ON survey_responders.movie_id = movie_info.movie_id
```),
  text(size: 0.85em, fill: luma(90))[#text(font: "Consolas")[ON] says which columns have to match. Each #text(font: "Consolas")[survey_responders] row is paired with the #text(font: "Consolas")[movie_info] row that has the same #text(font: "Consolas")[movie_id].],
)
#v(1fr)
#align(center, grid(columns: 4, column-gutter: 1.2em, align: top + left,
  mini-table("survey_responders", [name], [movie_id],
    [James], hit(size: 0.75em)[1], [Ava], hit(size: 0.75em)[2], miss[Sam], miss[4], size: 0.75em),
  mini-table("movie_info", [movie_id], [title],
    hit(size: 0.75em)[1], [Monty Python…], hit(size: 0.75em)[2], [Princess Bride], miss[3], miss[Shrek], size: 0.75em),
  pad(top: 2em, text(size: 1.6em, fill: luma(120))[→]),
  mini-table("result", [name], [title],
    [James], [Monty Python…], [Ava], [Princess Bride], size: 0.75em),
))
#v(0.6em)
#align(center, text(size: 0.85em, fill: luma(90))[Sam's movie (4) isn't in movie_info, and no one picked Shrek (3), so both are left out.])
#v(1fr)
]

== SQL: Join (2/2)
#slide-text(0.8em)[

#set smartquote(enabled: false)
// one join type: its Venn diagram, name, meaning, and what it would return
// for the example on the last slide
#let join-card(name, a, b, note, ..rows) = block(width: 100%, height: 5.2cm, fill: card-fill,
  stroke: (left: 3pt + sql-pink), inset: (x: 0.8em, y: 0.5em), [
    #text(font: "Consolas", weight: "bold", fill: sql-pink, name) \
    #text(size: 0.8em, fill: luma(90), note)
    #v(-0.1em)
    #grid(columns: (auto, 1fr), column-gutter: 1.2em, align: horizon,
      venn(a, b, d: 1.2cm),
      mini-table("", [name], [title], ..rows, size: 0.52em),
    )
  ])

#text(size: 0.8em, style: "italic", fill: luma(90))[A = the #text(font: "Consolas")[FROM] table, B = the joined table; same example as the last slide.]
#v(0.2em)
#grid(columns: (1fr, 1fr), gutter: 0.6em,
  join-card("INNER JOIN", false, false, [only matches (same as just JOIN)],
    [James], [Monty Python…], [Ava], [Princess Bride]),
  join-card("LEFT JOIN", true, false, [all of A + matches from B],
    [James], [Monty Python…], [Ava], [Princess Bride], [Sam], null-cell),
  join-card("RIGHT JOIN", false, true, [all of B + matches from A],
    [James], [Monty Python…], [Ava], [Princess Bride], null-cell, [Shrek]),
  join-card("FULL OUTER JOIN", true, true, [everything from both],
    [James], [Monty Python…], [Ava], [Princess Bride], [Sam], null-cell, null-cell, [Shrek]),
)
#v(0.3em)
#align(center, text(size: 0.8em, fill: luma(90))[Missing matches show up as #null-cell (that's where #text(font: "Consolas")[IS NULL] comes in handy).])
]

== SQL: Example <sql-example>
#hide-slide-number()
#slide-text(0.8em)[
// no slide number here, so the content can run into the bottom margin
#pad(bottom: -36pt)[

#set smartquote(enabled: false)
#text(size: 1.2em, weight: "bold", fill: sql-pink)[Question:] #h(0.4em)
#text(style: "italic", fill: luma(90))[For well-rated (7+) movies with more than one fan: how many years after each movie came out were its fans born, on average?]
#v(0.4em)
#dark-code(width: 100%, size: 0.62em, pitch: 2em, ```sql
SELECT movie_info.title,
       count(*) AS fans,
       avg(survey_responders.birth_date - movie_info.release_date) AS avg_years_between
FROM survey_responders
JOIN movie_info ON survey_responders.movie_id = movie_info.movie_id
WHERE movie_info.imdb_score >= 7
  AND survey_responders.birth_date IS NOT NULL
GROUP BY movie_info.title
HAVING count(*) > 1
ORDER BY avg_years_between DESC
LIMIT 5
```)
]
]

== Flow Charts <flowcharts>
#hide-slide-number()
#slide-text(0.4em)[
// no slide number here, so the cards can run into the bottom margin
#pad(bottom: -36pt)[

// each shape type gets its own soft fill, used in both the legend and the
// example, so students can match every box in the example to its meaning
#let fc-orange = topic.flow
#let fc-term = rgb("#d5e8d4")     // start/end: green
#let fc-proc = rgb("#dae8fc")     // process: blue
#let fc-dec = rgb("#fff2cc")      // decision: yellow
#let fc-io = rgb("#e1d5e7")       // input/output: purple
#let fc-conn = rgb("#e6e6e6")     // connector: gray
#let rule(body) = text(fill: luma(60), body)
#let key(body) = text(weight: "bold", fill: fc-orange, body)
#let fc-card(title, body) = block(width: 100%, height: 13.2cm, fill: card-fill,
  stroke: (top: 3pt + fc-orange), inset: (x: 1em, y: 0.9em), [
    #text(size: 1.5em, weight: "bold", fill: fc-orange, title)
    #v(0.4em)
    #body
  ])

#grid(columns: (1fr, 1fr), column-gutter: 1.2em,
  fc-card[The shapes][
    #align(center, scale(x: 78%, y: 78%, reflow: true)[
      #set text(size: 1.45em)
      #diagram(
        node-stroke: 0.7pt,
        spacing: (0.7cm, 0.5cm),
        node((0,0), [start/end], shape: fletcher.shapes.ellipse, width: 3.4cm, height: 2cm, fill: fc-term),
        node((1,0), align(left, rule[you can only have #key[ONE] start \ #v(0.3em) but you #key[CAN] have multiple ends]), shape: rect, stroke: none, width: 7cm),
        node((0,1), [process \ (happens behind \ the scenes)], shape: rect, width: 5.6cm, height: 2.4cm, fill: fc-proc),
        node((0,2), [decision \ (T/F or Y/N)], shape: fletcher.shapes.diamond, width: 3.4cm, height: 2.4cm, fill: fc-dec),
        node((1,2), align(left, rule[decisions are the #key[ONLY] thing that can have more than one arrow pointing #key[OUT] of them]), shape: rect, stroke: none, width: 7cm),
        node((0,3), [input/output \ (what the user \ enters or sees)], shape: fletcher.shapes.parallelogram, width: 5.2cm, height: 2.3cm, fill: fc-io),
        node((0,4), [connector], shape: fletcher.shapes.circle, width: 2.7cm, fill: fc-conn),
        node((1,4), align(left, rule[connectors are the #key[ONLY] thing that can have more than one arrow pointing #key[INTO] them]), shape: rect, stroke: none, width: 7cm),
      )
    ])
  ],
  fc-card[Example: the Bridge of Death][
    #align(center, scale(x: 64%, y: 64%, reflow: true)[
      #set text(size: 1.5em)
      #diagram(
        node-stroke: 0.7pt,
        edge-stroke: 0.7pt,
        spacing: (1.4cm, 0.75cm),
        node((1,0), [start], shape: fletcher.shapes.ellipse, width: 2.6cm, height: 1.5cm, fill: fc-term),
        edge((1,0), (1,1), "-|>"),
        node((1,1), [Bridgekeeper asks: \ "What is your quest?"], shape: fletcher.shapes.parallelogram, width: 6.4cm, height: 1.7cm, fill: fc-io),
        edge((1,1), (1,2), "-|>"),
        node((1,2), [you answer], shape: fletcher.shapes.parallelogram, width: 4.4cm, height: 1.4cm, fill: fc-io),
        edge((1,2), (1,3), "-|>"),
        node((1,3), [Bridgekeeper checks \ your answer], shape: rect, width: 5.4cm, height: 1.7cm, fill: fc-proc),
        edge((1,3), (1,4), "-|>"),
        node((1,4), [correct?], shape: fletcher.shapes.diamond, width: 3.4cm, height: 2cm, fill: fc-dec),
        // both branches leave the diamond sideways, then turn down into
        // the top of their output
        edge((1,4), (0,4), (0,5), "-|>", [yes], label-pos: 0.3, label-side: center, label-fill: card-fill),
        edge((1,4), (2,4), (2,5), "-|>", [no], label-pos: 0.3, label-side: center, label-fill: card-fill),
        node((0,5), ["Off you go."], shape: fletcher.shapes.parallelogram, width: 4.4cm, height: 1.5cm, fill: fc-io),
        node((2,5), ["Into the Gorge of \ Eternal Peril!"], shape: fletcher.shapes.parallelogram, width: 5.2cm, height: 1.7cm, fill: fc-io),
        // both paths come back together at the connector
        edge((0,5), (0,6), (1,6), "-|>"),
        edge((2,5), (2,6), (1,6), "-|>"),
        node((1,6), [], shape: fletcher.shapes.circle, width: 0.7cm, fill: fc-conn),
        edge((1,6), (1,7), "-|>"),
        node((1,7), [end], shape: fletcher.shapes.ellipse, width: 2.6cm, height: 1.5cm, fill: fc-term),
      )
    ])
    #v(0.2em)
    #align(center, text(size: 1.1em, fill: luma(70))[You only see and hear the #box(fill: fc-io, inset: (x: 3pt), outset: (y: 2pt), radius: 2pt)[input/output] steps; \ the #box(fill: fc-proc, inset: (x: 3pt), outset: (y: 2pt), radius: 2pt)[process] happens in the Bridgekeeper's head.])
  ],
)
#v(0.5em)
#align(center, text(size: 1.3em)[
  Make yours at #link("https://draw.io")[draw.io] #h(0.4em) → #h(0.4em) when done: *File → Export as → PDF*
])
]
]

== VBA: Basics <vba>
#slide-text(0.76em)[

#corner-acronym("Visual", "Basic for", "Applications", color: topic.vba)

#vba-fill()[
```vb
Option Explicit 'This makes it so that you can only use variables you've declared (VERY RECOMMENDED)

Sub thisIsMySubName()

    'BASICS!

        'Generally you will first refer to an object type (like a Sheet)
        'and then tell it what you want to do (like delete or add or copy, etc):

            ' Sheets and Worksheets work the same for normal sheets
            Sheets("MySheet").Delete
            Sheets.Add.name = "MySheet"
            Worksheets("MySheet").Activate

            ' Range and Cells are SIMILAR but different: Range("E7") = Cells(7, 5)
            Range("A1").Activate
            ActiveCell.Value = "We want... a shrubbery!"

            Range("A1:D3").Copy
            Range("E5").PasteSpecial

            ' Columns and Rows are what they sound like
            Columns("B:D").Delete
```
]
]

== VBA: Navigation and Misc.
#slide-text(0.8em)[

#vba-fill()[
```vb
'NAVIGATION!

    ' Jump to the edge of the data (like Ctrl + arrow key)
    ActiveCell.End(xlDown).Select
    ActiveCell.End(xlToLeft).Select

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
    Dim knight As String, first_initial As String
    knight = "Robin"
    first_initial = Left(knight, 1) '"R" (the first 1 character)
```
]
]

== VBA: Variables
#slide-text(0.74em)[

#vba-fill()[
```vb
'DECLARE VARIABLES!
    Dim i As Integer    'a whole number
    Dim j As Double     'a number with a decimal
    Dim k As String     'a line of text
    Dim l As Boolean    'true or false
    Dim m As Worksheet

    i = 5
    j = 1.2345
    k = "Tis but a scratch!"
    l = True
    Set m = Sheets("Sheet1") 'objects (sheets, workbooks, ranges) use Set instead of =

'USER INTERFACE!

    'Tell the user something
    MsgBox "Halt! Who would cross the Bridge of Death?"

    'Ask for an input
    Dim username As String
    username = InputBox("What is your name?")

' COMBINING STRINGS

    Dim myOutput As String
    Dim myName As String
    myName = "James"

    ' Combine strings with ampersands (&) -- don't forget spaces
    myOutput = "My name is " & myName & " and I seek the Grail!"
```
]
]

== VBA: Conditionals
#slide-text(0.79em)[

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

    'Case Statements (assume fruit, color, imdb_score, verdict are declared)
    Select Case fruit
        Case "apple", "strawberry"
            Color = "red"
        Case "coconut"
            Color = "brown"
        Case Else
            Color = "unknown"
    End Select

    'Another Case Statement
    Select Case imdb_score
        Case Is >= 8
            verdict = "must watch (like Monty Python)"
        Case 6 To 8 'an 8 already matched above: first match wins
            verdict = "pretty good"
        Case Is < 6
            verdict = "I'm probably skipping this one"
    End Select
```
]
]

== VBA: Loops
#slide-text(0.72em)[

#vba-fill(top: -40pt)[
```vb
'LOOPS!

    'For Loop (6 times: 0 to 5)
    For i = 0 To 5
        ' your code here
    Next i

    'For Each Loop
    Dim x As Range, lastrow As Long
    lastrow = Cells(Rows.Count, "A").End(xlUp).Row 'last filled row in A
    For Each x In Range("A2", Cells(lastrow, "A"))
        ' your code here
    Next

    'For Each Loop 2
    Dim myRange As Range
    Set myRange = Range("A1:E5")
    For Each x In myRange
        ' your code here
    Next

    'Do While Loop
    Do While i < 5 'condition does NOT have to be numbers
        ' your code here
        i = i + 1 'change something, or it loops forever
    Loop

    ' Do Until Loop
    Do Until i = 10 'condition does NOT have to be numbers
        ' your code here
        i = i + 1
    Loop

End Sub
```
]
]

== VBA: Functions
#slide-text(0.93em)[
// tie each variable in the declaration line to its "free" Dim below,
// one soft color per variable
#let fn-c1 = rgb("#fff0a8").lighten(55%)  // knight
#let fn-c2 = rgb("#cfe6ff").lighten(55%)  // isBrave
#let fn-c3 = rgb("#ffd6e8").lighten(55%)  // knightTitle (the output)
// (lines are picked by content, so the Dims can go in any order)
#show raw.where(lang: "vb"): it => vba-render(it, hl: (
  ("^Function", (("name As String", fn-c1), ("isBrave As Boolean", fn-c2),
                 ("knightTitle", fn-c3), ("As String$", fn-c3))),
  ("Dim knightTitle As String", (("Dim knightTitle As String", fn-c3),)),
  ("Dim name As String", (("Dim name As String", fn-c1),)),
  ("Dim isBrave As Boolean", (("Dim isBrave As Boolean", fn-c2),)),
))

#vba-fill()[
```vb
Function knightTitle(name As String, isBrave As Boolean) As String

    ' a Function RETURNS a value you can use in a cell (a Sub just DOES things)
    ' the INPUTS go in the parentheses, each with a type
    ' the OUTPUT's type goes at the end (As String)
    ' so the function declaration works like Dims you get for free:
    '     Dim knightTitle As String
    '     Dim name As String
    '     Dim isBrave As Boolean

    ' use the inputs to decide the output...
    If isBrave Then
        knightTitle = "Sir " & name & " the Brave"
    Else
        knightTitle = "Sir " & name & " the Not-Quite-So-Brave"
    End If
    ' ...and return it by setting the FUNCTION'S NAME equal to it

End Function

' to use it in a cell:
' =knightTitle("Robin", FALSE)   gives   Sir Robin the Not-Quite-So-Brave
```
]
]

== Statistics <statistics>
#slide-text(0.7em)[

#let stat-line = 1pt + luma(90)
#let stat-green = topic.stats.lighten(65%)  // (name kept; now the Statistics gold)
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
#let stat-test(name, vars) = [#text(size: 1.1em)[#text(weight: "bold", fill: topic.stats)[#name]] \ #text(size: 0.9em, fill: luma(70))[#vars]]
// "→ r": what the test on the left gives you
#let stat-out(sym) = box[#text(size: 1.2em, fill: luma(150))[→] #h(0.25em) #text(size: 1.4em, style: "italic")[#sym]]
#let stat-head(body) = text(size: 0.65em, weight: "bold", fill: luma(140), tracking: 0.06em, upper(body))

#grid(columns: (1fr, auto), column-gutter: 1.4em,
  grid(
    columns: (auto, 3.4em, 1fr),
    column-gutter: 0.6em,
    row-gutter: 0.8em,
    align: (left + horizon, left + horizon, left + horizon),
    align(center, stat-head[test & use case]), align(center, stat-head[output]), align(center, stat-head[how to read it]),

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
        (0.5, [#text(size: 0.8em, fill: stat-gray)[usually 0.05] \ #text(size: 1.4em)[#text(weight: "bold", fill: topic.stats)[α]]]),
        (1, [1]),
      ),
      bands: ((0, 0.5, stat-green),),
      notes: (
        (0.25, [reject the null \ #text(weight: "bold", fill: topic.stats)[significant]]),
        (0.75, [fail to reject the null \ #text(weight: "bold", fill: topic.stats)[not significant]]),
      ),
      caption: [p works like a percentage:\ 0.05 = 5% to see this or more extreme],
      height: 6.4em,
    ),
  ),
  // side notes
  block(width: 10em, height: 20em, stroke: (left: 1pt + topic.stats), inset: (left: 1em, y: 0.3em), text(size: 0.85em)[
    #text(weight: "bold", fill: topic.stats)[Null Hypothesis] \
    H#sub[0]: No x's are significant
    #v(0.8em)
    #text(weight: "bold", fill: topic.stats)[Alt Hypothesis] \
    H#sub[A]: At least one x is significant
    #v(1fr)
    #text(weight: "bold", fill: topic.stats)[Scientific Notation] \
    aE#text(weight: "bold", fill: topic.stats)[b] = a × 10#super[#text(weight: "bold", fill: topic.stats)[b]] \
    #v(0.3em)
    aE#text(weight: "bold", fill: topic.stats)[3] = a × 1000 (big) \
    aE#text(weight: "bold", fill: topic.stats)[−3] = a × 0.001 (small)
  ]),
)
]

== Tableau <tableau>
#slide-text(0.8em)[

#let tab-blue = topic.tableau
#let tab-icon(x) = box(stroke: 0.5pt + luma(200), radius: 4pt, inset: 3pt,
  crop-img("assets/img/tableau-trick.png", (135, 52), x, 18, 23, 23, width: 1.1cm))
#let tab-card(title, body) = block(width: 100%, fill: card-fill, breakable: false,
  stroke: (top: 3pt + tab-blue), inset: (x: 1em, y: 0.8em),
  [#text(size: 1.1em, weight: "bold", fill: tab-blue, title) \ #body])

#tab-card[“Default” means leave it alone][
  If the assignment says “default,” you don't have to change anything. It's the setting Tableau starts with.
]

#v(0.6em)
#tab-card[Toolbar buttons worth knowing][
  #v(0.3em)
  #grid(columns: (auto, 1fr), column-gutter: 1em, row-gutter: 0.8em, align: horizon,
    tab-icon(17), [*Swap rows and columns:* flips the x- and y-axis. A sideways chart can tell a clearer story.],
    tab-icon(56), [*Sort ascending:* smallest to largest],
    tab-icon(95), [*Sort descending:* largest to smallest],
  )
]
]

== Solver <solver>
#hide-slide-number()
#slide-text(0.85em)[
// no slide number here, so the content can run into the bottom margin
#pad(bottom: -36pt)[

#text(weight: "bold", fill: topic.solver)[Two important Excel formulas:]
#v(0.4em)

#grid(
  columns: (auto, auto, auto),
  column-gutter: 0.8em,
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
  [#text(weight: "bold", fill: topic.solver)[Constraints:]],
  crop-img("assets/img/solver_add_constraint.png", (642, 256), 52, 38, 534, 173, width: 11cm, radius: 5pt),
)

#v(1fr)

#grid(
  columns: (auto, auto),
  column-gutter: 1.2em,
  align: left + horizon,
  [#text(weight: "bold", fill: topic.solver)[If integer isn't working:] \ Solver > Options > uncheck this box:],
  crop-img("assets/img/solver_fix_integers.png", (697, 130), 88, 4, 478, 125, width: 10.8cm),
)
]
]

== HTML: Setup <html>
#slide-text(0.9em)[

#corner-acronym(("Hyper", "Text"), "Markup", "Language", color: topic.html)

In an html file inside VS Code, \ type an exclamation point and enter to automatically generate:

#v(0.8em)
#dark-code(size: 0.56em, ```html
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
```)
#v(0.22em)
Go here for free bootstrap themes:\
#link("https://startbootstrap.com/themes/portfolio-resume")[startbootstrap.com/themes/portfolio-resume]
]

== HTML: Tags
#slide-text(0.9em)[

// two equal-width examples side by side across the top (together they
// line up with the pattern box's edges), then the general pattern below
#v(0.3em)
#grid(columns: (1fr, 1fr), column-gutter: 1.2em, align: top,
  dark-code(size: 0.64em, width: 100%, ```html
<!-- This is a comment -->
<h1>The Holy Grail</h1>
<h2>The Knights</h2>
<h3>Sir Robin</h3>

<p>Bravely ran away.</p>

<!-- Line Break -->
<br>
```),
  dark-code(size: 0.64em, width: 100%, ```html
<!-- Unordered List (Bullets) -->
<ul>
    <li>Sir Lancelot</li>
    <li>Sir Galahad</li>
    <li>Sir Robin</li>
</ul>

<!-- Change <ul> to <ol>
for an ordered list (Numbers) -->
```),
)

#v(1fr)

// the general pattern every tag above follows
#let tg(body) = text(font: "Consolas", fill: rgb("#2e7d45"), weight: "bold", body)
#let lbl(body) = text(size: 0.85em, fill: luma(100), body)
#block(width: 100%, fill: card-fill, stroke: (left: 2.5pt + topic.html), inset: (x: 1em, y: 0.8em), text(size: 0.85em)[
  #grid(columns: (auto, 1fr), column-gutter: 2.5em, align: horizon,
    [
      *Every tag follows this pattern:*
      #v(0.2em)
      #grid(columns: (auto, auto), column-gutter: 1.4em, row-gutter: 0.5em, align: left + horizon,
        tg[\<tag\>], lbl[← start tag],
        pad(left: 1.2em, text(font: "Consolas")[stuff]), lbl[← what the tag applies to],
        tg[\</tag\>], lbl[← end tag: same name, plus a /],
      )
    ],
    [
      _The start and end tags act like parentheses._
      #v(0.4em)
      #lbl[(a few, like #text(font: "Consolas")[\<br\>], have no end tag)]
    ],
  )
])

#v(1fr)
]

== HTML: Anchors
#slide-text(0.9em)[

#v(1fr)
#dark-code(width: 100%, size: 0.68em, pitch: 1.5em, notes: (
  "7": [← #text(font: "Consolas")[../] goes up one folder],
  "11": [← #text(font: "Consolas")[\#] + the id jumps to it on the same page],
), ```html
<!-- Hyperlinks -->
<a href="https://www.google.com">Visit Google</a>

<!-- Folder References -->
<a href="otherpage.html">Visit Other Page</a>
<a href="subfolder/page.html">Visit Subfolder Page</a>
<a href="../anotherpage.html">Visit Another Page</a>

<!-- On-page Anchors -->
<h1 id="top">This is the main heading</h1>
<a href="#top">Jump to the top</a>
```)
#v(1fr)
]

== HTML: Images
#slide-text(0.9em)[

#v(1fr)
#dark-code(width: 100%, size: 0.7em, ```html
<!-- Images -->
<img src="images/swallow.jpg" alt="An unladen swallow.">

<img src="https://example.com/swallow.jpg"
    alt="African or European?">
```)
#v(1em)
#align(center)[
  Notice: images do NOT have an end tag \</img\> \
  #text(size: 0.8em, style: "italic")[(neither do line breaks \</br\>)]
]
#v(2fr)
]

== HTML: Divisions
#slide-text(0.9em)[

*Divs* don't inherently do anything: they're invisible boxes you put content into so that you can isolate it for positioning and CSS styling using classes.

#v(0.2em)
HTML:
#dark-code(size: 0.62em, ```html
<div class="square-image">
    <img src="assets/coconuts.jpg" alt="Two coconut halves">
</div>
```)

#v(0.2em)
CSS:
#grid(columns: (auto, 1fr), column-gutter: 2em, align: bottom,
  dark-code(size: 0.62em, ```css
.square-image {
    width: 200px;
    height: 200px;
}
```),
  [For more, see: \ #link(<css-selectors>)[*CSS: Selectors/Properties/Values*]],
)
]

== HTML: Embedding
#slide-text(0.8em)[

#let yt-red = rgb("#cc1f1a")
#let tab-blue = topic.tableau
// one numbered step: a number badge, the instruction, and (optionally) a
// small screenshot of exactly what to click
#let embed-step(n, color, body, shot: none) = grid(
  columns: (1.5em, 1fr, auto), column-gutter: 0.7em, align: horizon,
  box(width: 1.4em, height: 1.4em, radius: 50%, fill: color,
    align(center + horizon, text(fill: white, weight: "bold", size: 0.8em)[#n])),
  body,
  if shot != none { box(stroke: 0.5pt + luma(190), radius: 3pt, clip: true, shot) },
)
// a site's card: colored title bar, then its steps
#let embed-card(title, color, ..steps) = block(width: 100%,
  fill: card-fill, stroke: (top: 3pt + topic.html), inset: (x: 1em, y: 0.9em), {
    text(size: 1.2em, weight: "bold", fill: color, title)
    v(0.3em)
    for s in steps.pos() { s; v(0.55em) }
  })

#align(center, text(size: 0.9em, warn[Embeds sometimes don't show up until your site is live]))
#v(0.3em)

#grid(columns: (1fr, 1fr), column-gutter: 1.2em,
  embed-card("YouTube", yt-red,
    embed-step(1, yt-red, shot: crop-img("assets/img/youtube-share.png",
      (532, 88), 212, 22, 136, 60, width: 2.6cm))[Under the video, click *Share*],
    embed-step(2, yt-red, shot: crop-img("assets/img/youtube-share-menu.png",
      (608, 618), 36, 250, 100, 125, width: 1.7cm))[Click *Embed*],
    embed-step(3, yt-red, shot: crop-img("assets/img/youtube-embed.png",
      (541, 612), 440, 540, 100, 66, width: 2cm))[Click *Copy*],
    embed-step(4, yt-red)[Paste it into your HTML],
  ),
  embed-card("Tableau", tab-blue,
    embed-step(1, tab-blue)[Go to #link("https://public.tableau.com/app/discover")[#box(text(size: 0.8em)[public.tableau.com/app/discover])]],
    embed-step(2, tab-blue)[Search for a relevant viz],
    embed-step(3, tab-blue, shot: crop-img("assets/img/tableau-share.png",
      (347, 66), 145, 12, 44, 40, width: 1.1cm))[Click the share icon],
    embed-step(4, tab-blue, shot: crop-img("assets/img/tableau-embed.png",
      (477, 277), 266, 95, 188, 36, width: 4cm))[Click *Copy Embed Code*],
    embed-step(5, tab-blue)[Paste it into your HTML],
  ),
)
]

== HTML: Best Practices
#slide-text(0.72em)[

#let mono(body) = text(font: "Consolas", body)
#let good = rgb("#2e7d45")
#let bad = rgb("#c62828")
// a titled section with a colored rule on its left
#let fs-section(title, body) = block(width: 100%, stroke: (left: 2.5pt + topic.html),
  inset: (left: 0.9em, y: 0.2em), [#text(size: 1.15em, weight: "bold", fill: topic.html, title) \ #body])

// the example project (VS Code explorer) on the left, the rules on the right
#grid(columns: (auto, 1fr), column-gutter: 2em, align: top,
  box(radius: 4pt, clip: true, image("assets/img/folder-expanded.png", width: 5.2cm)),
  [
    #fs-section[Use folders!][
      Give each type of file its own folder: #mono[css/], #mono[html/], #mono[js/], and
      #mono[assets/] (with #mono[img/], #mono[fonts/], #mono[icons/] inside).
      #v(0.3em)
      #mono[index.html] stays at the top level. It's your homepage, so it's the
      first page the site loads.
    ]
    #v(0.9em)
    #fs-section[Never use spaces in file or folder names][
      Use a dash or underscore instead:
      #v(0.1em)
      #grid(columns: (auto, auto), column-gutter: 1.5em, row-gutter: 0.4em,
        text(fill: good)[✓ #mono[about-me.html]], text(fill: bad)[✗ #mono[about me.html]],
        text(fill: good)[✓ #mono[example_project/]], text(fill: bad)[✗ #mono[example project/]],
      )
    ]
    #v(0.9em)
    #fs-section[Format your code][
      #grid(columns: (1fr, auto), column-gutter: 1em, align: horizon,
        [Fixes indentation and long lines. \
         Right click → *Format Document* \
         #text(fill: luma(100))[shortcut: #mono[Shift+Alt+F]]],
        crop-img("assets/img/format-doc.png", (612, 246), 112, 64, 386, 96, width: 6.4cm, radius: 4pt),
      )
    ]
  ],
)
]

== HTML: Uploading to GitHub
#hide-slide-number()
#slide-text(0.64em)[
// no slide number here, so the cards can run into the bottom margin
#pad(bottom: -30pt)[

#let gh-green = topic.html  // (name kept; HTML section color)
#let gh-form = "assets/img/repo-creation.png"
// one numbered step: badge + instruction, with an optional screenshot of
// exactly what to click, beside the instruction (small buttons) or
// underneath it (`below: true`, for wide screenshots)
#let gh-badge(n) = box(width: 1.4em, height: 1.4em, radius: 50%, fill: gh-green,
  align(center + horizon, text(fill: white, weight: "bold", size: 0.8em)[#n]))
#let gh-step(n, body, shot: none, below: false) = if below {
  grid(columns: (1.5em, 1fr), column-gutter: 0.6em, row-gutter: 0.35em, align: horizon,
    gh-badge(n), body, [], shot)
} else {
  grid(columns: (1.5em, 1fr, auto), column-gutter: 0.6em, align: horizon,
    gh-badge(n), body, if shot != none { shot })
}
// one phase of the process: a titled card of steps
#let gh-card(title, ..steps) = block(width: 100%, height: 100%, fill: card-fill,
  stroke: (top: 3pt + gh-green), inset: (x: 0.9em, y: 0.8em), {
    text(size: 1.2em, weight: "bold", fill: gh-green, title)
    v(0.2em)
    for s in steps.pos() { s; v(0.7em) }
  })

#grid(columns: (1fr, 1fr), column-gutter: 1em, rows: 1fr,
  gh-card("A. Create the repository",
    gh-step(1)[Go to #link("https://github.com")[github.com] and sign in \ #text(fill: luma(100))[(or make a free account)]],
    gh-step(2, shot: crop-img("assets/img/repo-new.png", (427, 132), 306, 28, 88, 42, width: 2.3cm, radius: 4pt))[
      Click *New*],
    gh-step(3, shot: crop-img(gh-form, (858, 833), 215, 50, 632, 90, width: 7.5cm, radius: 4pt), below: true)[
      Type a *Repository name* #text(fill: luma(100))[(no spaces!)]],
    gh-step(4, shot: crop-img(gh-form, (858, 833), 54, 536, 792, 74, width: 8.4cm, radius: 4pt), below: true)[
      Leave it *Public* \ and turn *Add README* on],
    gh-step(5, shot: crop-img(gh-form, (858, 833), 690, 784, 158, 42, width: 3.2cm, radius: 4pt))[
      Click *Create repository* at the bottom],
  ),
  gh-card("B. Upload your website",
    gh-step(6, shot: crop-img("assets/img/repo-upload.png", (335, 196), 60, 34, 222, 132, width: 3.6cm, radius: 4pt), below: true)[
      On your new repository's page, \ click *Add file → Upload files*],
    gh-step(7)[Open your project folder and drag everything #emph[inside] it
      (#text(font: "Consolas")[index.html], #text(font: "Consolas")[css/], ...) onto the page
      #v(0.3em)
      #warn[Upload the CONTENTS of your project, not the folder itself]],
    gh-step(8, shot: crop-img("assets/img/repo-commit.png", (437, 167), 66, 91, 168, 46, width: 3.4cm, radius: 4pt))[
      Click *Commit changes* \ #text(fill: luma(100))[("commit" = save)]],
    text(fill: luma(100), style: "italic")[Next: turn it into a live website → #link(<going-live>)[Going Live]],
  ),
)
]
]

== HTML: Going Live <going-live>
#slide-text(0.72em)[

#let gh-green = topic.html  // (name kept; HTML section color)
#let gh-badge(n) = box(width: 1.4em, height: 1.4em, radius: 50%, fill: gh-green,
  align(center + horizon, text(fill: white, weight: "bold", size: 0.8em)[#n]))
// one step as a card: badge + instruction on top, its screenshot below
#let live-step(n, shot, body) = block(width: 100%, height: 100%, fill: card-fill,
  stroke: (top: 3pt + gh-green), inset: (x: 0.8em, y: 0.7em),
  grid(columns: (1.5em, 1fr), column-gutter: 0.6em, row-gutter: 0.7em, align: horizon,
    gh-badge(n), body,
    grid.cell(colspan: 2, align(center, shot)),
  ))

#text(fill: luma(90))[On your repository's page (from the last slide):]
#v(0.2em)
#grid(columns: (1fr, 1fr, 1.25fr), column-gutter: 0.8em, rows: 5.6cm,
  live-step(1, crop-img("assets/img/pages-settings.png", (438, 165), 148, 34, 112, 46, width: 3.4cm, radius: 4pt))[Click the *Settings* tab at the top],
  live-step(2, crop-img("assets/img/pages-pages.png", (447, 332), 84, 118, 170, 76, width: 4.4cm, radius: 4pt))[In the left sidebar, click *Pages*],
  live-step(3, crop-img("assets/img/pages-branch.png", (453, 161), 38, 84, 350, 50, width: 6.8cm, radius: 4pt))[Under *Branch*, change #text(font: "Consolas")[None] to #text(font: "Consolas")[main], then click *Save*],
)
#v(0.8em)
#block(width: 100%, fill: card-fill, stroke: (top: 3pt + gh-green), inset: (x: 0.8em, y: 0.7em), [
  #grid(columns: (1.5em, 1fr), column-gutter: 0.6em, align: horizon,
    gh-badge(4),
    [Wait a couple of minutes, then *refresh* the page. Your website's link will appear at the top:],
  )
  #v(0.5em)
  #align(center, crop-img("assets/img/pages-live.png", (1082, 200), 26, 104, 1034, 82, width: 22.5cm, radius: 4pt))
])
]

== CSS: Basics <css>
#slide-text(0.8em)[

#corner-acronym("Cascading", "Style", "Sheets", color: topic.css)

#let css-blue = topic.css
#let mono(body) = text(font: "Consolas", body)
#let css-head(n, body) = text(size: 1.1em, weight: "bold", fill: css-blue)[#n. #body]

#grid(columns: (1fr, 1fr), column-gutter: 1.5em, row-gutter: 1.1em, align: top,
  // 1. connecting the stylesheet
  [
    #css-head(1)[Connect it to your HTML]
    #v(0.2em)
    #dark-code(size: 0.54em, width: 100%, ```html
<head>
    <link rel="stylesheet" href="css/style.css">
</head>
```)
    #v(0.1em)
    #text(size: 0.85em, fill: luma(90))[Goes inside the #mono[\<head\>] of every page. #mono[href] is the path to your #mono[.css] file.]
  ],
  // 2. the one pattern all of CSS follows
  [
    #css-head(2)[Every rule looks like this]
    #v(0.2em)
    #dark-code(size: 0.62em, width: 100%, ```css
selector {
    property: value;
    property2: value2;
}
```)
    #v(0.1em)
    #text(size: 0.8em, fill: luma(90))[*property* = what to change, *value* = what to change it to. That's all CSS is! (see next slide)]
  ],
  // 3. cascading, spanning under both
  grid.cell(colspan: 2)[
    #v(0.6em)
    #css-head(3)[It's cascading: the later rule wins]
    #v(0.2em)
    #grid(columns: (auto, 1fr), column-gutter: 2em, align: horizon,
      dark-code(size: 0.62em, ```css
p {
    color: blue;
}
p {
    color: red;
}
```),
      box(width: 65%, text(size: 0.9em)[If you paint a door blue and then re-paint it red, it will be red instead of blue. CSS works the same way, but with everything not just colors.]),
    )
  ],
)
]

== CSS: Selectors / Properties / Values <css-selectors>
#slide-text(0.8em)[

#let css-blue = topic.css
#let mono(body) = text(font: "Consolas", body)
#let sel-card(title, sub, body) = block(width: 100%, height: 9.8cm, fill: card-fill,
  stroke: (top: 3pt + css-blue), inset: (x: 0.9em, y: 0.8em), [
    #text(size: 1.15em, weight: "bold", fill: css-blue, title) \
    #text(size: 0.85em, fill: luma(90), sub)
    #v(0.2em)
    #body
  ])

#grid(columns: (1fr, 1fr), column-gutter: 1em, rows: auto,
  sel-card([Built-in selectors], [Use a tag name (#mono[body], #mono[h1], #mono[p], #mono[a], #mono[img], ...) to style every one of those tags.],
    dark-code(size: 0.6em, width: 100%, notes: ("1": [← every \<body\>]), ```css
body {
    background-color: #f0f0f0;
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
}
```)),
  sel-card([Class (custom) selectors], [Make your own: a *period* + any name. Styles only tags with that class.],
    [
      #dark-code(size: 0.6em, width: 100%, ```css
.highlight {
    background-color: yellow;
    font-weight: bold;
}
```)
      #v(0.1em)
      #text(size: 0.85em)[Apply it in your HTML (no period):]
      #dark-code(size: 0.6em, width: 100%, ```html
<p class="highlight">Ni!</p>
```)
    ]),
)

#v(1fr)
#align(center, block(fill: rgb("#fff5b3"), inset: (x: 1em, y: 0.6em), radius: 4pt,
  text(size: 0.95em)[There are A LOT of selectors and properties. Google and AI are your friend for finding exactly what you want!]))
#v(1fr)
]

#focus-slide(background: black)[
  #text(size: 0.55em)[jimna-h.github.io/james_super_cool_is_201_cheatsheet]
  #v(0.5em)
  #box(fill: white, inset: 8pt)[#qrcode("https://jimna-h.github.io/james_super_cool_is_201_cheatsheet/is201-cheatsheet.pdf", width: 6cm, quiet-zone: true)]
  #v(0.5em)
  #text(size: 0.5em, fill: luma(200))[Suggestions? Reach out to me at #link("mailto:jbruce1@byu.edu")[#text(fill: white)[jbruce1\@byu.edu]]]
]

#focus-slide(background: black)[
  #text(size: 49pt)[IS 201 TA Lab]
]
