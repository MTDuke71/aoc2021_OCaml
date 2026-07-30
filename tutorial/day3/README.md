# Tutorial Day 3 — Records, Variants, and Result Types

Day 2 gave you `match` and recursion, but only over shapes the standard library already defined. Today you define your own. There are exactly two ways to build a type in OCaml, and everything else is a combination of them:

| | Meaning | Called | Rust |
|---|---|---|---|
| **Record** | this field **and** that field | product type | `struct` |
| **Variant** | this case **or** that case | sum type | `enum` |

Nesting one inside the other gives you *algebraic data types* — "sums of products" — which is the whole vocabulary. `option` and `result`, which look like language features, turn out to be ordinary variants someone already wrote for you.

---

## Part 1 — Records

### Declaring and constructing

```ocaml
type point = { x : int; y : int }

let origin = { x = 0; y = 0 }
```

Fields are separated by `;`, same as lists. Construction must name **every** field — leaving one out is a hard error, not a silently-zeroed value:

```
Error: Some record fields are undefined: y
```

Misspelling a field is `Error: Unbound record field z`. There is no way to end up with a partially built record.

### Field access and functional update

Access is a dot, as you would expect. Updating is the interesting part:

```ocaml
let shifted = { origin with x = 3 }
```

`{ r with ... }` builds a **new** record, copying every field you didn't mention. It does not mutate `r` — records are immutable by default, so `origin` is still `{ x = 0; y = 0 }` afterwards. Rust spells this `P { x: 3, ..origin }`.

### Punning

When a variable already has the field's name, you can drop the `= x`:

```ocaml
let make_point x y = { x; y }     (* same as { x = x; y = y } *)
```

### Records in patterns

Records destructure by field name:

```ocaml
let describe_point { x; y } = ...
```

**This repo will make you be explicit.** A pattern that names only some fields triggers `Warning 9 [missing-record-field-pattern]`, which dune's dev profile promotes to an error:

```
Error (warning 9): the following labels are not bound in this record pattern: y
Either bind these labels explicitly or add '; _' to the pattern.
```

So write `{ x; _ }` when you genuinely only want one field. This is a good default: when you later add a field to a record, the compiler shows you every pattern that might need to account for it.

### Records are nominal

A record type is not a structural bag of fields — field names belong to the type that declared them. If two record types declare the same field name, the **most recently declared** one wins for a bare `{ v = 1 }`, and you disambiguate with an annotation:

```ocaml
let f (r : a) = r.v
```

In practice, give distinct types distinct field names and this never comes up.

### Mutable fields

Individual fields can opt into mutability:

```ocaml
type counter = { mutable count : int }

let c = { count = 0 }
let () = c.count <- c.count + 1     (* <- assigns, = compares *)
```

Note `<-` for assignment. This is the exception, not the rule — reach for it when a simulation genuinely needs in-place update, not by habit.

---

## Part 2 — Variants

### Alternatives

```ocaml
type direction = North | South | East | West
```

A value is exactly one case. Constructors must be **Capitalized**. This is Rust's `enum`, and it is what makes Day 2's exhaustiveness checking valuable — the compiler knows the complete list of cases, so leaving one out of a `match` is `Warning 8 [partial-match]`, an error under dune.

### Payloads

Each case may carry data, and the shape may differ per case — the thing a record cannot do:

```ocaml
type shape =
  | Circle of float           (* radius *)
  | Rect of float * float     (* width, height *)
  | Square of float

let area = function
  | Circle r -> Float.pi *. r *. r
  | Rect (w, h) -> w *. h
  | Square s -> s *. s
```

Matching binds the payload in the same step that selects the case.

For more than two or three payload fields, use an **inline record** so the fields have names:

```ocaml
type entry =
  | Empty
  | Filled of { name : string; score : int }
```

### Recursive variants

A case may refer to the type being defined, which is how you build trees:

```ocaml
type tree = Leaf | Node of tree * int * tree
```

Worth pausing on if you're coming from Rust: this needs **no `Box`**. Rust requires indirection because it must compute a fixed size for the enum; OCaml values of variant type are already boxed pointers, so recursion costs you no extra syntax.

### One gotcha you will hit

Declare a constructor and never *build* a value with it — only match on it — and dune fails the build:

```
Error (warning 37 [unused-constructor]): constructor South is never used to build values.
(However, this constructor appears in patterns.)
```

I hit this writing today's example. It's usually a real signal (a case you meant to produce and forgot), but it does mean a variant enumerated "for completeness" needs at least one construction site.

---

## Part 3 — `option`

`option` is **not special syntax**. It is an ordinary variant, defined in the standard library as:

```ocaml
type 'a option = None | Some of 'a
```

That's it — one variant with two cases, using Day 2's `'a` so it works for any payload type. OCaml has no null, so this is how "might be absent" is expressed, and because it's a real type the compiler will not let you forget the empty case.

```ocaml
let safe_div a b = if b = 0 then None else Some (a / b)
```

Consuming one means matching it, and exhaustiveness means you cannot skip `None`.

### The `_opt` convention

Standard-library functions that could fail come in two flavors: one that raises, and one suffixed `_opt` that returns an option. Prefer the `_opt` version.

| Raises | Returns an option |
|---|---|
| `int_of_string` | `int_of_string_opt` |
| `List.find` | `List.find_opt` |
| `List.assoc` | `List.assoc_opt` |
| `List.hd` | (none — match instead) |

### The `Option` module

For routine shapes, skip the `match`:

```ocaml
Option.value opt ~default:0     (* unwrap with a fallback *)
Option.map (( * ) 2) opt        (* transform the payload if present *)
Option.is_none opt
```

---

## Part 4 — `result`

Also an ordinary variant, with **two** type parameters:

```ocaml
type ('a, 'b) result = Ok of 'a | Error of 'b
```

```ocaml
let parse_int text =
  match int_of_string_opt (String.trim text) with
  | Some n -> Ok n
  | None -> Error (Printf.sprintf "not a number: %S" text)
```

Note the spelling: OCaml's failure case is **`Error`**, where Rust's is `Err`. The success case is `Ok` in both.

### Choosing between them

| Situation | Use |
|---|---|
| Absence is the whole story ("not found") | `option` |
| The failure needs to explain itself | `result` |
| Truly exceptional, or a bug | raise an exception |

For AoC specifically: parsing your own puzzle input is a case where a raising `int_of_string` is often fine, because malformed input means *you* have a bug and a crash with a stack trace is a perfectly good report. Use `result` when you want the error to carry which line failed and why.

### There is no `?` operator

Rust's `?` has no OCaml equivalent at this stage. You match explicitly, which is why `sequence` in today's example is as verbose as it is. OCaml does have binding operators (`let*`) that collapse this pattern considerably — a later topic, once the explicit version is second nature.

---

## Part 5 — Worked Example

See [`example.ml`](./example.ml). Parts 1-4 each demonstrate one construct; Part 5 combines all three into the shape of **AoC 2021 day 2, part one**, whose input is lines like `forward 5` / `down 5` / `up 3`:

```ocaml
type command = Forward of int | Down of int | Up of int   (* a line is one of three things *)
type position = { horizontal : int; depth : int }         (* state is several things at once *)

let apply pos = function
  | Forward n -> { pos with horizontal = pos.horizontal + n }
  | Down n -> { pos with depth = pos.depth + n }
  | Up n -> { pos with depth = pos.depth - n }
```

This is the combination you will reach for on most AoC days: a **variant** for the input alternatives, a **record** for accumulated state, a **result** for parse failures, and `List.fold_left` to run the state forward.

The real idea is that **parsing narrows an untrusted string into a value that cannot be wrong.** Once a line has become a `command`, nothing downstream re-validates it — `apply` has no error case, because by then there is no error to have. Pushing validation to the boundary is most of what defining types buys you.

Run it:

```bash
ocaml tutorial/day3/example.ml
```

```bash
dune exec tutorial/day3/example.exe
```

It prints the puzzle's documented sample answer, `150`, and then shows a bad line being rejected with a reason. Part two of that puzzle is deliberately left alone — that one is yours to solve.

---

## Key Takeaways for Day 3

| Concept | OCaml | Rust analogy |
|---|---|---|
| Product type | `type p = { x : int; y : int }` | `struct P { x: i32, y: i32 }` |
| Field access | `p.x` | `p.x` |
| Functional update | `{ p with x = 3 }` | `P { x: 3, ..p }` |
| Field punning | `{ x; y }` | `P { x, y }` |
| Mutable field | `mutable x : int`, assign with `<-` | `mut` / interior mutability |
| Sum type | `type d = A \| B of int` | `enum D { A, B(i32) }` |
| Recursive sum type | `Node of tree * int * tree` | needs `Box<Tree>` |
| Named payload | `Filled of { name : string }` | `Filled { name: String }` |
| Maybe-absent | `'a option`, `Some` / `None` | `Option<T>`, `Some` / `None` |
| Fallible | `('a, 'b) result`, `Ok` / **`Error`** | `Result<T, E>`, `Ok` / `Err` |
| Error propagation | explicit `match` (or `let*` later) | `?` |
| Partial record pattern | error under dune; add `; _` | `..` |
| Unbuilt constructor | error under dune (warning 37) | `dead_code` lint |

The habit to build: **make the type describe exactly the values that are legal**, then let the compiler enforce it. A `command` cannot hold a typo, so no downstream code has to check for one.

---

## Day 4 Preview

Tomorrow: **string parsing and lightweight I/O helpers** — turning real puzzle input into the types you just learned to define, and growing `src/common/io.ml` as you go.
