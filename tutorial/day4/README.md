# Tutorial Day 4 — String Parsing and Lightweight I/O Helpers

Day 3 ended on the idea that **parsing narrows an untrusted string into a value that cannot be wrong**. Today is the other half of that sentence: the actual mechanics of getting from a file of text to those types. This is the least glamorous part of AoC and the part you will write twenty-five times, so it's worth having the tools at hand.

---

## Part 1 — Strings

An OCaml `string` is an **immutable, GC-managed sequence of bytes**. Coming from Rust, note what is *absent*: there is no `String`/`&str` split, no ownership, no lifetimes, no `.clone()`, no `.to_string()` ceremony. There is one type, you pass it around freely, and you cannot modify it.

```ocaml
let s = "forward 5"

String.length s          (* 9 *)
s.[0]                    (* 'f' — indexing is a dot-bracket *)
String.sub s 0 7         (* "forward" — (start, length), not a range *)
"a" ^ "-" ^ "b"          (* concatenation *)
String.concat ", " lst   (* join a string list *)
"abc" = "abc"            (* true — structural equality, no strcmp/.equals *)
```

`String.sub` takes a **start and a length**, not a start and an end. Getting this wrong is a runtime `Invalid_argument`, not a compile error.

If you genuinely need to mutate, that's the separate `Bytes` type. You will almost certainly not need it for AoC.

### Bytes, not characters

Indexing is by **byte**. For AoC input — ASCII grids and digits — that is exactly what you want and it's fast. It would be wrong for UTF-8 text, which OCaml's stdlib does not handle for you.

Handy predicates (all present in 4.14):

```ocaml
String.starts_with ~prefix:"for" s
String.ends_with ~suffix:"rd" s
String.for_all (fun c -> c = '0' || c = '1') "10110"
String.index_opt s ','
```

---

## Part 2 — Splitting and Trimming

### `String.split_on_char` is the workhorse

```ocaml
String.split_on_char ',' "7,4,9"     (* ["7"; "4"; "9"] *)
```

**Note the name: it splits on a `char`.** OCaml's stdlib has *no* split-on-substring function. If you need to split on `" -> "`, either use `Scanf` (Part 4), hand-roll it with `String.index_opt` + `String.sub`, or pull in the `Str` / `re` library. This surprises most people once.

### The repeated-separator gotcha

Splitting on `' '` yields an **empty string wherever separators repeat**. AoC grids are column-aligned with double spaces, so this bites immediately:

```ocaml
String.split_on_char ' ' "22 13  17   11"
(* ["22"; "13"; ""; "17"; ""; ""; "11"]  — 7 pieces, not 4 *)
```

The fix is a filter, and it belongs in every whitespace parser you write:

```ocaml
let ws_ints line =
  line |> String.trim |> String.split_on_char ' '
  |> List.filter (fun piece -> piece <> "")
  |> List.map int_of_string
```

### `String.trim` and the CRLF problem

`String.trim` strips leading and trailing whitespace **including `\r`**. This is not a cosmetic detail — it is what makes parsing survive a Windows-line-ending input file. Without it, every line ends in an invisible carriage return and `int_of_string` fails on all of them.

This is why [`src/day00.ml`](../../src/day00.ml) trims before converting, and why you should assume every line needs it.

---

## Part 3 — Converting Text to Values

### `int_of_string` does not trim

Worth stating on its own line, because it's the single most common parsing surprise:

```ocaml
int_of_string_opt "  17  "                 (* None  *)
int_of_string_opt (String.trim "  17  ")   (* Some 17 *)
```

Whitespace is a parse *failure*, not something silently skipped. Trim first, always.

### Which variant to use

Day 3's `_opt` convention applies directly. Use `int_of_string_opt` when input might legitimately be malformed and you want to report it; use plain `int_of_string` when a bad line means *your* code has a bug and a crash is a perfectly good report. For your own puzzle input, the raising version is usually the right call.

### Characters and digits

Chars are bytes, so digit conversion is arithmetic:

```ocaml
let digit_of_char c = Char.code c - Char.code '0'
```

### Binary, octal, hex for free

`int_of_string` understands `0b` / `0o` / `0x` prefixes, which is a genuine shortcut for AoC 2021's binary-diagnostic day:

```ocaml
int_of_string ("0b" ^ "10110")    (* 22 *)
```

No bit-shifting loop required.

### Walking a string

```ocaml
String.to_seq "3141" |> Seq.map digit_of_char |> List.of_seq
String.fold_left (fun acc c -> if c = '1' then acc + 1 else acc) 0 "10110"
```

---

## Part 4 — `Scanf`: Format Strings That Parse

For lines with a fixed shape, `Scanf.sscanf` reads the string against a format and hands the pieces to a function. Literal text in the format must match exactly:

```ocaml
Scanf.sscanf "0,9 -> 5,9" "%d,%d -> %d,%d" (fun x1 y1 x2 y2 -> { x1; y1; x2; y2 })
```

That one line replaces a split-on-`->`, two trims, two splits-on-`,` and four conversions. For AoC's rigidly formatted input it is often the shortest correct thing you can write.

Two cautions:

- **`%s` reads up to the next whitespace**, not to end of line. It is not "the rest of the string."
- **It raises on mismatch** — `Scanf.Scan_failure`, `Failure`, or `End_of_file`. Wrap it to get back to Day 3's `result`:

```ocaml
let parse_segment line =
  try Ok (Scanf.sscanf (String.trim line) "%d,%d -> %d,%d" (fun x1 y1 x2 y2 -> { x1; y1; x2; y2 }))
  with Scanf.Scan_failure msg -> Error msg
     | Failure msg -> Error msg
     | End_of_file -> Error "ran out"
```

---

## Part 5 — I/O Helpers

### What the repo already has

[`src/common/io.ml`](../../src/common/io.ml) currently provides two:

| Helper | Type | Purpose |
|---|---|---|
| `Io.read_file` | `string -> string` | whole file as one string |
| `Io.nonempty_lines` | `string -> string list` | split on `\n`, drop blank lines |

`read_file` opens in **binary** mode (`open_in_bin`) deliberately: it avoids platform newline translation, and `String.trim` cleans up the `\r` instead. It also uses `Fun.protect` so the channel closes even if reading raises — OCaml's equivalent of a `defer` or RAII guard.

Note that `Day_registry` fixes `parsed = string list` for every day, so `parse_input` hands you lines and each day does its own conversion from there.

### The helper that's missing

The one AoC needs constantly and `io.ml` does **not** have is *split into paragraphs on blank lines* — required by AoC 2021 day 4's bingo boards and several later days. [`example.ml`](./example.ml) implements it:

```ocaml
let chunks raw = ...   (* string -> string list list *)
```

This is a good candidate to promote into `src/common/io.ml` once you hit the first day that needs it — the tutorial README suggests exactly that workflow. I've left it in the tutorial for now rather than editing shared source you haven't needed yet.

### Quoted string literals

For embedding sample input verbatim, `{| ... |}` takes its contents **raw** — no backslash escapes, no doubled quotes:

```ocaml
let sample = {|
7,4,9,5,11

22 13 17 11  0
|}
```

Much better than a `\n`-riddled one-liner when you want a test fixture to look like the real file.

---

## Worked Example

Run it:

```bash
ocaml tutorial/day4/example.ml
```

```bash
dune exec tutorial/day4/example.exe
```

Part 5 of the example parses a bingo-style input end to end: `chunks` splits it into paragraphs, the first paragraph becomes comma-separated draws, and each remaining paragraph becomes a grid of whitespace-separated ints.

Deliberately, **nothing here solves a puzzle.** Today is only about getting from text to types — the algorithms stay yours.

---

## Key Takeaways for Day 4

| Task | OCaml | Notes / Rust analogy |
|---|---|---|
| String type | `string` | immutable bytes; no `&str`/`String` split |
| Length / index | `String.length s`, `s.[i]` | byte-indexed |
| Substring | `String.sub s start len` | **length**, not end index |
| Concatenate | `^`, `String.concat sep lst` | `format!` / `join` |
| Compare | `s = t` | structural; no `.equals` |
| Split | `String.split_on_char c s` | **char only** — no split-on-string |
| Repeated separators | filter `<> ""` | `split_whitespace()` does this for you |
| Trim | `String.trim` | also strips `\r` — essential for CRLF |
| To int | `int_of_string_opt` | **does not trim**; trim first |
| Binary literal | `int_of_string ("0b" ^ bits)` | `i64::from_str_radix(bits, 2)` |
| Digit value | `Char.code c - Char.code '0'` | `c.to_digit(10)` |
| Formatted parse | `Scanf.sscanf` | no direct equivalent; raises on mismatch |
| Raw literal | `{\| ... \|}` | `r"..."` |
| Read a file | `Io.read_file` | `fs::read_to_string` |
| Mutable string | `Bytes` | `String` / `Vec<u8>` |

The habit to build: **trim early, split defensively, convert with the `_opt` you actually want.** Most AoC parsing bugs are a stray `\r` or an empty string from a repeated separator.

---

## Day 5 Preview

Tomorrow: **tail recursion and accumulators** — why the inner-`go`-with-accumulator idiom from Day 2 matters once a list is long enough to blow the stack.
