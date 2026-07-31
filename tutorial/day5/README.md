# Tutorial Day 5 — Tail Recursion and Accumulators

Day 2 showed the inner-`go`-with-accumulator idiom and promised an explanation. This is it. The short version: **a recursive call that isn't the last thing your function does costs a stack frame per element, and stacks are finite.**

Every number in this file was measured on this machine (8 MB stack, OCaml 4.14.1), not recalled.

---

## Part 1 — The Problem

Day 2's `sum`:

```ocaml
let rec naive_sum = function
  | [] -> 0
  | hd :: tl -> hd + naive_sum tl
```

The recursive call is **not** the last thing that happens. `naive_sum tl` returns, and *then* `+` runs. So the frame has to stay alive, waiting. One frame per element, all the way down.

The accumulator version:

```ocaml
let sum_tail lst =
  let rec go acc = function
    | [] -> acc
    | hd :: tl -> go (acc + hd) tl
  in
  go 0 lst
```

Here `go` calls itself as its very last action with nothing left to do afterwards, so OCaml **reuses the frame** instead of pushing a new one. Constant stack, any length.

### Where it actually breaks

`naive_sum` survives 100,000 elements and dies somewhere around **270,000** on a default 8 MB stack. At one million:

```
naive_sum (frame per element)      STACK OVERFLOW
sum_tail  (accumulator)            ok (499999500000)
```

For context: AoC inputs are typically a couple thousand lines, so naive recursion is *fine* for parsing. This matters when a puzzle has you generating or simulating millions of items — and by then you don't want to be retrofitting.

---

## Part 2 — What Counts as Tail Position

A call is in **tail position** when its result *is* the enclosing function's result — nothing remains to be done with it.

**Tail positions:**
- the body of a `match` branch
- either branch of an `if`
- the body of a `let ... in`

**Not tail positions:**
- an operand of an operator — `hd + f tl`
- an argument to another call — `g (f tl)`
- **the body of a `try ... with`**

That last one catches people. The exception handler has to survive the call, so the frame can't be reused:

```ocaml
let rec count_down     n = if n = 0 then 0 else count_down (n - 1)
let rec count_down_try n = if n = 0 then 0 else (try count_down_try (n-1) with Not_found -> 0)
```

```
plain tail call                    ok (0)
identical call inside try/with     STACK OVERFLOW
```

Same call, same arithmetic, one wrapped in `try`. Worth knowing before you wrap a recursive loop in error handling and wonder why it started overflowing.

**OCaml guarantees tail-call elimination.** This is a language-level promise, not an optimization that might happen — unlike Python (no TCO at all) or the JVM (none for the general case). You can rely on it.

---

## Part 3 — The Transformation

Mechanical once you've seen it:

1. Add an `acc` parameter to an inner `go`
2. Base case returns `acc` instead of a neutral value
3. Cons case folds the head into `acc` and recurses
4. Seed `acc` at the call site

### The catch: order reverses

An accumulator consumes front-to-back and builds back-to-front. Addition doesn't care. **Building a list does.**

```ocaml
let map_double_tail lst =
  let rec go acc = function
    | [] -> List.rev acc
    | hd :: tl -> go ((hd * 2) :: acc) tl
  in
  go [] lst
```

`List.rev` is itself tail-recursive and a single cheap pass, so **"accumulate reversed, then `List.rev`"** is the standard idiom, not a workaround. Expect to write it constantly.

---

## Part 4 — `fold_left` vs `fold_right`

```
fold_left  f acc [a;b;c] = f (f (f acc a) b) c     tail-recursive
fold_right f [a;b;c] acc = f a (f b (f c acc))     NOT tail-recursive
```

`fold_right` has to reach the **end** of the list before it can apply `f` even once, so it holds the entire list on the stack. `fold_left` is just the accumulator pattern with the accumulator handed in.

```
List.fold_left                     ok (499999500000)
List.fold_right                    STACK OVERFLOW
```

**Prefer `fold_left`.** When you need `fold_right`'s right-to-left order, `List.fold_left` over `List.rev` is usually the safe equivalent.

---

## Part 5 — Which Stdlib Functions Are Safe

This is the part worth memorizing, because **the unsafe ones are the ones you reach for most.** Measured at one million elements:

| Function | 1M elements | Notes |
|---|---|---|
| `List.fold_left` | ✅ safe | the workhorse |
| `List.rev` | ✅ safe | cheap, tail-recursive |
| `List.rev_map` | ✅ safe | tail-recursive `map` |
| `List.filter` | ✅ safe | |
| `List.concat_map` | ✅ safe | |
| `List.map` | ❌ **overflows** | the one that surprises everyone |
| `List.append` / `@` | ❌ **overflows** | copies the left list |
| `List.fold_right` | ❌ **overflows** | |

`List.map` not being tail-recursive in 4.14 is the single most common trap. It's fine for puzzle-sized data and will bite on a million. The stack-safe equivalent is `List.rev_map f lst |> List.rev`, or the annotation in Part 6.

(OCaml 5 made several of these tail-recursive. You're on 4.14, so the table above is what applies.)

---

## Part 6 — `[@tail_mod_cons]`

OCaml **4.14 added tail recursion modulo cons**, which is worth knowing precisely because you're on the version that introduced it.

When the only thing left to do after the recursive call is **cons onto its result**, the compiler can build the list as it goes rather than on the way back out. You get the readable non-accumulator shape *and* constant stack, with no `List.rev`:

```ocaml
let[@tail_mod_cons] rec map_double = function
  | [] -> []
  | hd :: tl -> (hd * 2) :: map_double tl
```

```
map_double with [@tail_mod_cons]   ok (1000000)
identical code, no annotation      STACK OVERFLOW
```

Byte-for-byte the same code otherwise. But note the limit: it applies **only** to this specific pattern — a constructor wrapping the recursive call. It is not a general fix for deep recursion, and the compiler will tell you if it can't apply it.

---

## Part 7 — What This Looks Like in a Solve

Counting with a fold is the most common shape you'll write: one pass, constant stack, no intermediate list.

```ocaml
let count_increases lst =
  let rec go acc = function
    | a :: (b :: _ as rest) -> go (if b > a then acc + 1 else acc) rest
    | _ -> acc
  in
  go 0 lst
```

Same answer as Day 2's version (`7` on the sample), but it survives a million-element list.

And when you want several statistics, **accumulate a tuple in one pass** instead of walking the list once per statistic:

```ocaml
let summarize lst =
  List.fold_left
    (fun (count, total, largest) n -> (count + 1, total + n, max largest n))
    (0, 0, min_int) lst
```

---

## Running It

```bash
ocaml tutorial/day5/example.ml
```

```bash
dune exec tutorial/day5/example.exe
```

The example catches `Stack_overflow` so it can report failures without dying. **That is a demo technique, not a pattern to copy** — recovering from stack overflow in real code is unreliable, and the fix is always to remove the deep recursion rather than catch it.

---

## Key Takeaways for Day 5

| Concept | OCaml | Notes / Rust analogy |
|---|---|---|
| Tail call | recursive call is the final action | Rust does **not** guarantee TCO |
| Guarantee | language-level, always applied | Python has none at all |
| Accumulator | inner `let rec go acc = ...` | a `for` loop with a mutable total |
| Order flip | accumulate reversed, then `List.rev` | — |
| Safe fold | `List.fold_left` | `.iter().fold()` |
| Unsafe fold | `List.fold_right` | `.rev().fold()` instead |
| Unsafe map | `List.map` (4.14) | use `rev_map \|> rev` |
| Unsafe append | `@` | build with `::` instead |
| Natural + safe | `let[@tail_mod_cons] rec` | no equivalent |
| Broken by | wrapping the call in `try` | — |

The habit to build: **when a recursive function builds something, ask what happens after the recursive call returns.** If the answer is "nothing," you're already safe. If it's "one more operation," that operation is costing you a stack frame per element.

---

## Day 6 Preview

Tomorrow: **sets, maps, and grid/state modeling** — when a list stops being the right container, and what `Set`/`Map` functors look like (your first real encounter with OCaml's module system, which Day 7 takes up properly).
