// #import "@local/prefs:0.1.0": *; #show: prefs

#import "@preview/touying:0.7.4": *
#import themes.simple: *

#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *
#import "@preview/zebra:0.1.0": qrcode

#show: codly-init.with()
#codly(languages: codly-languages, zebra-fill: none, stroke: 0.5pt + gray)

#show: simple-theme.with(
  aspect-ratio: "16-9",
  header: none,
  footer-right: context {
    // hide the slide number on a topic's primary (title) page, so corner
    // content (like an acronym or note) can sit in the true corner —
    // matching the original slides, which don't number those pages either.
    let pg = here().page()
    let starts-here = query(heading).any(h => h.location().page() == pg)
    if not starts-here {
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

// ---------- helpers ----------

// small entity-relationship table, e.g.
// #entity("company", (("PK", [company_id]), ("", [company_name]), ...))
#let entity(title, rows) = table(
  columns: (auto, 1fr),
  stroke: 0.5pt + gray,
  inset: 4pt,
  table.header(
    table.cell(colspan: 2, fill: luma(230))[*#title*],
  ),
  ..rows.map(r => (
    text(weight: "bold")[#r.at(0)],
    text[#r.at(1)],
  )).flatten()
)

#let hl(body, color: yellow) = box(fill: color.lighten(40%), inset: 2pt, outset: 2pt, radius: 2pt)[#body]

// ---------- ERD building blocks (real entity boxes + crow's-foot connectors) ----------
#let erd-pk-fill = rgb("#f7d6da")
#let erd-fk-fill = rgb("#cfe0f5")

// header row of an ERD entity box (with a small "collapse" icon, like dbdiagram.io)
#let erow-header(coord, title, width: 6cm) = node(
  coord,
  align(left + horizon)[
    #box(width: 7pt, height: 7pt, stroke: 0.5pt + gray)[#align(center + horizon)[#text(size: 6pt)[#sym.minus]]]
    #h(4pt) #text(weight: "bold", size: 11pt)[#title]
  ],
  shape: rect, stroke: 0.5pt + gray, fill: luma(230),
  width: width, height: 0.85cm, outset: 0pt,
)

// one attribute row of an ERD entity box
#let erow(coord, key, label, width: 6cm, fill: white, name: none) = node(
  coord,
  align(left + horizon)[
    #grid(columns: (1.5cm, 1fr), align: left + horizon,
      text(weight: "bold", size: 11pt)[#key],
      text(size: 11pt)[#label],
    )
  ],
  shape: rect, stroke: 0.5pt + gray, fill: fill,
  width: width, height: 0.72cm, outset: 0pt, name: name,
)

// ---------- slides ----------

#focus-slide(background: black)[
  #text(size: 1.3em)[IS 201 TA Lab]
]

#title-slide[
  #box(width: 100%)[
    #image("Patsy-Coconuts.jpg", width: 100%)
    #place(top + right, dx: -27%, dy: 36%)[
      #box(fill: white, inset: 3pt)[#text(size: 1.7em)[You]]
    ]
    #place(bottom + left, dx: 20pt, dy: -100pt)[
      #box(fill: white, inset: 3pt)[#text(size: 1.4em, weight: "bold")[James' Super Cool \ IS 201 Cheat Sheet]]
    ]

    #place(bottom + right, dx: 50pt, dy: 50pt)[#square(stroke:white, fill:white, width: 6cm)]


    #place(bottom + right, dx: 50pt, dy: 50pt)[
      #qrcode("https://jimna-h.github.io/IS_201_CHEATSHEET/is201-cheatsheet.pdf", width: 6cm, quiet-zone: true)
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
    node-stroke: 0.5pt + gray,
    spacing: (1.6cm, 0pt),
    erow-header((0, 0), "company", width: 4.6cm),
    erow((0, 1), "PK", underline[company_id], width: 4.6cm, fill: erd-pk-fill, name: <company-pk>),
    erow((0, 2), "", "company_name", width: 4.6cm),
    erow((0, 3), "", "employees", width: 4.6cm),
    erow((0, 4), "", "followers", width: 4.6cm),
    erow((0, 5), "", "industry", width: 4.6cm),
    erow((0, 6), "", "state", width: 4.6cm),
    erow((0, 7), "", "country", width: 4.6cm),
    erow((0, 8), "", "city", width: 4.6cm),
    erow((0, 9), "", "zip", width: 4.6cm),

    erow-header((1, 0), "posting", width: 5.4cm),
    erow((1, 1), "PK", underline[job_id], width: 5.4cm, fill: erd-pk-fill),
    erow((1, 2), "", "title", width: 5.4cm),
    erow((1, 3), "", "description", width: 5.4cm),
    erow((1, 4), "", "pay_period", width: 5.4cm),
    erow((1, 5), "", "work_type", width: 5.4cm),
    erow((1, 6), "", "job_location", width: 5.4cm),
    erow((1, 7), "", "applies", width: 5.4cm),
    erow((1, 8), "", "remote", width: 5.4cm),
    erow((1, 9), "", "views", width: 5.4cm),
    erow((1, 10), "", "level", width: 5.4cm),
    erow((1, 11), "", "sponsored", width: 5.4cm),
    erow((1, 12), "", "compensation", width: 5.4cm),
    erow((1, 13), "", "job_domain", width: 5.4cm),
    erow((1, 14), "FK", "company_id", width: 5.4cm, fill: erd-fk-fill, name: <posting-fk>),
    erow((1, 15), "FK", "ben_pack_id", width: 5.4cm),

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

#place(bottom + right, dx: 0em, dy: 0em)[
  #text(size: 1.1em)[#strong[E]ntity \ #strong[R]elationship \ #strong[D]iagram]
]

== ERD: Cardinality

#set text(size: 0.92em)
#set par(spacing: 0.55em)
Read #underline[left-to-right] AND #underline[right-to-left]

#v(0.2em)
*One to One (1:1)* \
#hl(color: rgb("#c2d6f4"))[A store has one manager] #sym.space
#hl(color: rgb("#f4d9a0"))[A manager works at one store]

*One to Many (1:N)* \
#hl(color: rgb("#c2d6f4"))[A customer can have multiple orders] #sym.space
#hl(color: rgb("#f4d9a0"))[An order belongs to one customer]

*Many to Many (M:N)* \
#hl(color: rgb("#c2d6f4"))[A student can enroll in many courses] #sym.space
#hl(color: rgb("#f4d9a0"))[A course can have lots of students]

#v(0.2em)
#text(style: "italic", size: 0.85em)[Note! M:N cardinality requires a composite table (next slide)]

== ERD: Composite Table

#set text(size: 0.75em)
#grid(columns: (1fr, 1fr, 1fr), gutter: 0.8em,
entity("movie", (
  ("PK", underline[movieid]), ("", [title]), ("", [mpaa_rating]),
  ("", [budget]), ("", [gross]), ("", [release_date]),
  ("", [genre]), ("", [runtime]), ("", [rating]),
  ("", [rating_count]),
)),
entity("character", (
  ("PK/FK", underline(hl(color: rgb("#c2d6f4"))[movieid])),
  ("PK/FK", underline(hl(color: rgb("#f4c2c2"))[actorid])),
  ("", [character_name]), ("", [credit_order]),
  ("", hl[pay]), ("", [screentime]),
)),
entity("actor", (
  ("PK", underline[actorid]), ("", [name]), ("", [date_of_birth]),
  ("", [birth_city]), ("", [birth_country]), ("", [height_inches]),
  ("", [biography]), ("", [gender]), ("", [ethnicity]), ("", [networth]),
))
)

#v(0.3em)
#align(center)[#text(size: 0.85em)[
To know how much money Tom Hanks got #hl[paid] to play Woody in _Toy Story_,
you need to know both the #hl(color: rgb("#c2d6f4"))[movie] and the #hl(color: rgb("#f4c2c2"))[actor]. His pay is probably different than when he was Woody in
_Toy Story 2_, or when he was Forrest Gump in _Forrest Gump_
]]

== ERD: Minimum / Maximum Cardinality

#text(size: 0.9em)[
The #hl(color: rgb("#f4c2c2"))[inner] ones are *minimum* (0 or 1) \
and the #hl(color: rgb("#b7e4b7"))[outer] ones are *maximum* (1 or many)
]

#v(0.4em)
#table(
  columns: (1fr, 1fr),
  stroke: 0.5pt + gray,
  inset: 6pt,
  table.header([*Table A*], [*Table B*]),
  [1 B or many B], [1 A or 1 A],
  [0 B or many B], [1 A or many A],
  [1 B or 1 B], [0 A or 1 A],
  [0 B or 1 B], [0 A or many A],
)

#v(0.4em)
#text(style: "italic", size: 0.85em)[
  Think: a student could have 0 cars, but they could also have multiple.
]

== SQL <sql>

#align(right)[#text(size: 0.85em)[#strong[S]tructured #strong[Q]uery #strong[L]anguage]]

```sql
SELECT (DISTINCT)  -- attributes
FROM                -- tableA
JOIN                -- tableB ON tableA.attribute = tableB.attribute (order doesn't matter)
WHERE               -- attribute filters [=, !=, <>, IS, LIKE '%___%', IN ("__","__","__")]
    AND/OR          -- you only say WHERE once, but can have many filters
GROUP BY            -- all non-aggregated attributes when aggregating
HAVING              -- group-based filters (not used in the SQL project)
ORDER BY            -- attributes in ASC (default) / DESC order
LIMIT               -- to xx top results

-- aggregate(attribute) AS newName
count()
avg()
min()
max()
etc.
```

== SQL: Where Use Cases

#set text(size: 1.1em)
#set par(leading: 1.2em)
ta_name *=* "James" #h(1fr) → Exact match

#v(1em)
ta_name *!=* "James" #h(1fr) → Not exact match \
ta_name *\<\>* "James" #h(1fr) #text(style: "italic")[(these are equivalent)]

#v(1em)
ta_name *IS* NULL #h(1fr) → NULL means blank data (can also do *IS NOT* NULL)

#v(1em)
ta_name *LIKE* '%ame%' #h(1fr) → The text ("ame") is contained within the attribute \
#h(1fr) #text(style: "italic")[(% = wildcard)]

#v(1em)
ta_name *IN* ("James", "Robert", "Frankie") \
#h(1fr) → Exact match for #underline[any] of these

== Flow Charts <flowcharts>

#set text(size: 0.58em)
#grid(columns: (1fr, 1.5fr), gutter: 1.2em,
[
  #text(size: 0.9em)[go to \ draw.io]
  #scale(x: 68%, y: 68%, reflow: true)[
    #diagram(
      node-stroke: 0.7pt,
      spacing: (0.8cm, 0.9cm),
      node((0,0), [start/end], shape: fletcher.shapes.circle, width: 2.4cm),
      node((0,1), [process \ (something happens)], shape: rect, width: 2.4cm),
      node((0,2), [decision \ (T/F or Y/N)], shape: fletcher.shapes.diamond, width: 2.6cm, height: 1.7cm),
      node((0,3), [input/output \ (info entered or displayed)], shape: fletcher.shapes.parallelogram, width: 2.6cm),
      node((0,4), [connector], shape: fletcher.shapes.circle, width: 1.2cm),
    )
  ]
  #text(size: 0.9em)[you can only have ONE start, but you CAN have multiple ends. \
  decisions are the ONLY shape with >1 arrow OUT. \
  connectors are the ONLY shape with >1 arrow IN.]

  #v(0.4em)
  #text(size: 0.9em)[file \> export as \> pdf]
],
[
  #text(size: 1.05em, weight: "bold")[EXAMPLE: How to solve 1+1]
  #v(0.15em)
  #scale(x: 68%, y: 68%, reflow: true)[
    #diagram(
      node-stroke: 0.7pt,
      edge-stroke: 0.7pt,
      spacing: (1.3cm, 1cm),
      node((1,0), [start], shape: fletcher.shapes.circle, width: 1.6cm),
      edge((1,0), (1,1), "-|>"),
      node((1,1), [do you have a \ calculator?], shape: fletcher.shapes.diamond, width: 3.1cm, height: 1.9cm),
      edge((1,1), (0,1), "-|>", [no], label-side: center),
      node((0,1), [do 1+1 in \ your head], shape: rect, width: 2.2cm),
      edge((1,1), (2,1), "-|>", [yes], label-side: center),
      node((2,1), [enter "1+1=" \ into calculator], shape: fletcher.shapes.parallelogram, width: 2.9cm),
      edge((2,1), (2,2), "-|>"),
      node((2,2), [calculator processes \ the math], shape: rect, width: 2.9cm),
      edge((2,2), (2,3), "-|>"),
      node((2,3), [calculator displays \ the result], shape: rect, width: 2.9cm),
      edge((0,1), (1,4), "-|>"),
      edge((2,3), (1,4), "-|>"),
      node((1,4), [], shape: fletcher.shapes.circle, width: 0.6cm),
      edge((1,4), (1,5), "-|>"),
      node((1,5), [end], shape: fletcher.shapes.circle, width: 1.6cm),
    )
  ]
]
)

== VBA: Basics <vba>

#align(right)[#text(size: 0.85em)[#strong[V]isual #strong[B]asic for #strong[A]pplications]]

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

== VBA: Navigation and Misc.

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

== VBA: Variables

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

== VBA: Conditionals

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

== VBA: Loops

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

== VBA: Functions

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

== Statistics <statistics>

#grid(columns: (1fr, 1fr), gutter: 1.5em,
[
  *Null Hypothesis* \
  H#sub[0]: No x's are significant

  *Alt Hypothesis* \
  H#sub[A]: At least one x is significant

  #v(0.4em)
  *Scientific Notation:* \
  $a E b = a times 10^b$ \
  $a E 3 = a times 1000$ (big) \
  $a E (-3) = a times 0.001$ (small)
],
[
  #table(
    columns: (auto, 1fr, auto),
    stroke: 0.5pt + gray,
    inset: 5pt,
    [*Test*], [*Variables*], [*Stat*],
    [Correlation], [numeric – numeric], [$r$],
    [Regression], [numeric – multi. numeric], [$R^2$],
    [ANOVA], [numeric – mult. categorical], [$p$],
    [T-test], [numeric – 2 pair categorical], [$p$],
  )

  #v(0.3em)
  #text(size: 0.85em)[
    $r$: −1 to 1 (as x↑, y↓ / y↑) \
    $R^2$: 0 to 1 (share of variance in y explained by x) \
    $p$: 0 to α (usually 0.05) → reject the null if $p < alpha$
  ]
]
)

== Tableau <tableau>

- "Default" settings are usually a good starting point — check them first
- Switching the x- and y-axis can reveal a clearer story
- Watch your sort/ordering — Tableau doesn't always order the way you expect

== Solver <solver>

*Two important Excel formulas:*

```
=SUM(A1:A5)                  → A1 + A2 + A3 + A4 + A5
=SUMPRODUCT(A1:A5, B11:B15)  → A1*B11 + A2*B12 + ... + A5*B15
                                (the two ranges should be the same size and shape)
```

- *Constraints:* set a changing-cell reference, an operator (`<=`, `=`, `>=`), and the constraint value
- *If integer constraints aren't working:* Solver → Options → uncheck "Ignore Integer Constraints" and set Integer Optimality to 1%

== HTML: Setup <html>

#align(right)[#text(size: 0.85em)[#strong[H]yper#strong[T]ext #strong[M]arkup #strong[L]anguage]]

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

== HTML: Tags

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

#align(right)[#text(size: 0.85em)[#strong[C]ascading #strong[S]tyle #strong[S]heets]]

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

#focus-slide(background: black)[
  #text(size: 0.55em)[jimna-h.github.io/IS_201_CHEATSHEET]
  #v(0.5em)
  #box(fill: white, inset: 8pt)[#qrcode("https://jimna-h.github.io/IS_201_CHEATSHEET/is201-cheatsheet.pdf", width: 6cm, quiet-zone: true)]
]
