# Tutorial Day 2 — Lists, Pattern Matching, and Recursion

Day 1 covered values, bindings, and functions. Today adds the three constructs that appear in essentially every AoC solution written in OCaml: the **list**, the **`match` expression**, and **recursion over a list's shape**. They are really one idea — a list is defined by two shapes, `match` takes those shapes apart, and recursion applies the same treatment to what's left.

---

## Part 1 — Lists

### List literals

Elements are separated by semicolons, not commas:

```ocaml
let primes = [2; 3; 5; 7; 11]
```

This is the same separator role Day 1 described: `;` sits *between* elements, and a trailing one (`[1; 2; 3;]`) is legal but ocamlformat will remove it.

Lists are **homogeneous** — every element must have the same type. `[1; "two"]` is a type error.

### The comma trap

`[1, 2, 3]` is not an error, and that is exactly what makes it dangerous:

```ocaml
let l = [1, 2, 3]
List.length l   (* = 1, not 3 *)
```

It is a **one-element list containing the tuple `(1, 2, 3)`**, type `(int * int * int) list`. It compiles silently and fails later somewhere confusing. If a list is mysteriously length 1, check your separators.

### Cons and the empty list

Every list is built from exactly two constructors:

| Constructor | Meaning |
|---|---|
| `[]` | the empty list |
| `hd :: tl` | element `hd` in front of list `tl` ("cons") |

So the literal is just sugar — `[1; 2; 3]` *is* `1 :: (2 :: (3 :: []))`. This matters because it tells you what shapes you have to match on: there are only ever two.

### Sharing and immutability

Cons is O(1) and **shares** the tail rather than copying it:

```ocaml
let small  = [1; 2; 3]
let bigger = 0 :: small    (* does not copy `small` *)
```

Both stay valid, because lists are immutable — nothing can later modify `small` out from under `bigger`. This is why OCaml can share structure freely where Rust would need `Rc` or a clone.

### Append is not cons

```ocaml
[1; 2] @ [3; 4]     (* = [1; 2; 3; 4] *)
```

`@` must copy its entire left argument, so it is O(n). Building a list by repeatedly appending one element is an accidental O(n²) — a common source of slow AoC solutions. Build with `::` and `List.rev` at the end instead.

Similarly, `List.nth lst 5` is O(n), not O(1). A list is a linked list, not an array. If you need indexing, you want an array (Day 6).

### Useful functions

| Function | Purpose |
|---|---|
| `List.length` | element count (O(n)) |
| `List.rev` | reverse |
| `List.map` | transform every element |
| `List.filter` | keep elements matching a predicate |
| `List.fold_left` | reduce to a single value (Day 8) |
| `List.iter` | run a side effect per element, returns `unit` |
| `List.mem` | membership test |

---

## Part 2 — Pattern Matching

### The match expression

```ocaml
match value with
| pattern1 -> result1
| pattern2 -> result2
```

`match` is an **expression** — it evaluates to a value, like `if`. Every branch must return the same type. Branches are tried top to bottom, so more specific patterns go first.

A pattern describes a *shape*, and matching **binds names** as a side effect of that shape fitting. There are no accessor functions:

```ocaml
let head_or_zero lst =
  match lst with
  | [] -> 0
  | hd :: _ -> hd      (* `hd` is bound by the pattern itself *)
```

### Matching list shapes

```ocaml
let describe lst =
  match lst with
  | []       -> "empty"
  | [ _ ]    -> "exactly one element"
  | [ _; _ ] -> "exactly two elements"
  | _ :: _   -> "three or more"
```

Note that `[ _ ]` (a one-element list) and `_ :: _` (any non-empty list) are different patterns. `[ _ ]` is sugar for `_ :: []`.

### Exhaustiveness is checked — and enforced

This is one of OCaml's best features. Leave out a case and the compiler tells you precisely which one:

```
Warning 8 [partial-match]: this pattern-matching is not exhaustive.
Here is an example of a case that is not matched:
_::_
```

**Important for this repo:** that is a *warning* when you run `ocaml file.ml`, but dune's dev profile promotes it to a hard **error**, so `dune build` will refuse to compile a non-exhaustive match. This is deliberate and worth keeping. You will also get `Warning 11 [redundant-case]` if a branch can never be reached because an earlier one already covers it.

Resist the urge to silence warning 8 with a lazy `| _ -> ...` catch-all. The exhaustiveness check is what makes it safe to add a case to a type later — the compiler then walks you to every place that needs updating.

### Guards

A `when` guard adds a boolean test to a pattern:

```ocaml
let classify n =
  match n with
  | 0 -> "zero"
  | n when n < 0 -> "negative"
  | n when n mod 2 = 0 -> "positive even"
  | _ -> "positive odd"
```

The compiler **cannot see through a guard** when checking exhaustiveness — it must assume any guard might be false — so a guarded match always needs a catch-all.

### Or-patterns

One branch, several shapes:

```ocaml
let is_vowel c =
  match c with
  | 'a' | 'e' | 'i' | 'o' | 'u' -> true
  | _ -> false
```

Alternatives must bind exactly the same names (most often, none at all).

### `as` patterns

`as` names a value while still matching *inside* it — the key to sliding windows:

```ocaml
| a :: (b :: _ as rest) -> ...
```

This binds `a` to the first element, `b` to the second, and `rest` to the list starting at `b`. You get the pieces and the whole sub-list from one pattern.

### The `function` shorthand

`function` is shorthand for `fun x -> match x with`, idiomatic when a function does nothing but match its last argument:

```ocaml
let rec length = function
  | [] -> 0
  | _ :: tl -> 1 + length tl
```

---

## Part 3 — Recursion Over Lists

Because a list has exactly two shapes, a recursive list function has exactly two branches. The shape of the data dictates the shape of the code:

```ocaml
let rec sum lst =
  match lst with
  | [] -> 0                      (* base case: answer for the empty list *)
  | hd :: tl -> hd + sum tl      (* use the head, recurse on the tail *)
```

Remember `rec` from Day 1 — without it the name isn't in scope inside its own body.

Building a list instead of a number is the same shape:

```ocaml
let rec map_double = function
  | [] -> []
  | hd :: tl -> (hd * 2) :: map_double tl
```

### Accumulators

`sum` above builds its answer *on the way back out* of the recursion, so it holds one stack frame per element. An **accumulator** carries the running answer *down* instead:

```ocaml
let sum_tail lst =
  let rec go acc lst =
    match lst with
    | [] -> acc
    | hd :: tl -> go (acc + hd) tl
  in
  go 0 lst
```

Here the recursive call is the *last* thing that happens, so OCaml reuses the stack frame — this runs in constant stack space and won't overflow on a long list. Day 5 covers tail recursion properly; for now just note the inner-`go`-with-accumulator idiom, because you will write it constantly.

---

## Part 4 — Patterns Nest

Patterns compose, and they work on tuples too. Matching two lists at once:

```ocaml
let rec zip a b =
  match (a, b) with
  | [], _ | _, [] -> []                      (* either ran out: stop *)
  | x :: xs, y :: ys -> (x, y) :: zip xs ys
```

The or-pattern works here precisely because neither alternative binds a name.

### `'a` and `'b` are type variables, not lifetimes

Your editor will show an inferred type above `zip`:

```ocaml
val zip : 'a list -> 'b list -> ('a * 'b) list
```

If you are coming from Rust, `'a` looks alarmingly like a lifetime. It is not. **OCaml has no lifetimes at all** — it is garbage-collected, with no ownership and no borrow checker. The two languages just happen to spell different things with the same apostrophe:

| Concept | Rust | OCaml |
|---|---|---|
| Generic type parameter | `<T>`, `<A, B>` | `'a`, `'b` |
| Lifetime | `'a` | does not exist |

So `'a` (say "tick a") is what Rust writes as `<T>`. The signature above is Rust's:

```rust
fn zip<A, B>(a: Vec<A>, b: Vec<B>) -> Vec<(A, B)>
```

This is also why `let bigger = 0 :: small` back in Part 1 shares memory with no annotation anywhere — there is nothing to annotate.

Note that you never wrote `<A, B>`. Inference derived it, and derived the *most general* type your code allows. The contrast across this day's functions shows exactly how that works:

| Inferred signature | Generic? | Why |
|---|---|---|
| `length : 'a list -> int` | yes | never looks at an element, only counts |
| `describe : 'a list -> string` | yes | only inspects the list's shape |
| `sum : int list -> int` | no | `hd + sum tl` uses `+`, which forces `int` |

`length` and `sum` are nearly identical code, yet one is generic and one is not. OCaml hands you genericity everywhere your code doesn't rule it out — you opt out by accident, not in by effort.

There is a real payoff hiding in a generic signature. Because `zip` is fully generic in its elements, it is *incapable* of inspecting them — it cannot know what they are, so it can only move them around. Reading `'a list -> 'b list -> ('a * 'b) list`, you know before reading the body that it cannot compare, sum, or filter by element value. This property is called **parametricity**, and it makes generic signatures unusually informative about behavior.

(If you later see `'_weak1`, with an underscore, that is *not* an ordinary type variable — it is a type OCaml has not pinned down yet and will not generalize. A different topic for another day.)

---

## Part 5 — Worked Example

See [`example.ml`](./example.ml) for a complete program covering all of the above. It ends with the actual shape of **AoC 2021 Day 1**: counting how many depth readings exceed the previous one, then doing the same over three-measurement sliding windows.

```ocaml
let rec count_increases = function
  | a :: (b :: _ as rest) -> (if b > a then 1 else 0) + count_increases rest
  | _ -> 0
```

Recursing on `rest` rather than the tail is what steps the window forward by exactly one. The final `| _ -> 0` covers both `[]` and the one-element list, which is what makes the match exhaustive.

Run it with the interpreter:

```bash
ocaml tutorial/day2/example.ml
```

Or with dune from the repo root:

```bash
dune exec tutorial/day2/example.exe
```

It prints the puzzle's own sample answers, `7` and `5`, so you can confirm the logic is right before pointing it at real input.

---

## Key Takeaways for Day 2

| Concept | OCaml syntax | Rust analogy |
|---|---|---|
| List literal | `[1; 2; 3]` | `vec![1, 2, 3]` |
| Empty list | `[]` | `vec![]` |
| Prepend | `x :: xs` (O(1), shares) | no cheap `Vec` equivalent |
| Append | `xs @ ys` (O(n)) | `xs.extend(ys)` |
| Match | `match x with \| p -> e` | `match x { p => e }` |
| Wildcard | `_` | `_` |
| Guard | `\| p when cond -> e` | `p if cond => e` |
| Or-pattern | `'a' \| 'e' -> ...` | `'a' \| 'e' => ...` |
| Bind whole and parts | `b :: _ as rest` | `rest @ [b, ..]` |
| Match shorthand | `function \| ...` | closure + `match` |
| Missing case | warning 8, error under dune | compile error |
| Unreachable case | warning 11 | unreachable-pattern lint |
| Generic type param | `'a`, `'b` | `<T>`, `<A, B>` |
| Lifetime | does not exist (GC) | `'a` |

The habit to build: **let the shape of the data drive the shape of the code.** Two constructors means two branches, and the compiler will tell you when you've missed one.

---

## Day 3 Preview

Tomorrow: **records, variants, and result types** — defining your own shapes to match on, instead of only the ones the standard library gives you.
