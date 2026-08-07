# Tutorial Day 7 — Modules and Signatures

Day 6 used `Set.Make` and `Map.Make` without explaining what they were. Today they stop being magic. The module system is OCaml's most distinctive feature — the thing OCaml programmers miss most in other languages — and it does two jobs: **namespacing** (dull but necessary) and **abstraction** (the interesting one).

Every error message quoted below was produced by your compiler, not recalled.

---

## Part 1 — Every File Is Already a Module

`src/day00.ml` **is** the module `Day00`. No declaration, no `export`, no header. The filename is the module name, capitalized. Writing one by hand inline is the same construct:

```ocaml
module Geometry = struct
  type point = { x : int; y : int }
  let origin = { x = 0; y = 0 }
  let to_string p = Printf.sprintf "(%d,%d)" p.x p.y
end
```

### `open`, and why to prefer the local forms

A top-level `open Geometry` dumps every name into the rest of the file. It works, but it makes later references ambiguous to a reader and can silently shadow things. Two better forms:

```ocaml
Geometry.(to_string (add (make 1 2) (make 3 4)))   (* one expression wide *)

let open Geometry in                                (* one let-body wide *)
to_string (add origin (make 7 8))
```

Both are idiomatic. Reach for global `open` rarely — the exception being a project-wide prelude, which this repo doesn't have.

---

## Part 2 — Signatures Hide Things

A **signature** (or *module type*) lists what escapes. Anything omitted is private:

```ocaml
module type INTERVAL = sig
  type t                              (* no definition -> ABSTRACT *)
  val make : int -> int -> t option   (* the only way in, and it validates *)
  val low : t -> int
  val contains : int -> t -> bool
end

module Interval : INTERVAL = struct
  type t = { low : int; high : int }
  let make low high = if low > high then None else Some { low; high }
  ...
  let _debug t = ...                  (* not in the signature -> invisible *)
end
```

When the signature declares `type t` **without a definition**, the type becomes **abstract**: callers can hold values of it, pass them around, and use the provided operations — but cannot see or fabricate the representation.

That's what makes an invariant *enforceable*. `Interval.make` is the only constructor and it rejects `low > high`, so **no malformed interval can exist anywhere in the program.** Not "shouldn't" — can't. This is Day 3's `Positive` example, now with a name for the mechanism.

### Verified: the door really is locked

Trying to build a value directly from its representation:

```
Error: Unbound record field M.v
```

Trying to call something the signature omitted:

```
Error: Unbound value M.secret
```

The representation and the private helper are simply not there from the outside. This is stronger than Rust's `pub`/private, which hides *fields* but still lets you name the type's shape within a module; OCaml's abstract type erases the shape entirely at the boundary.

---

## Part 3 — `.mli` Files

An `.mli` is the same thing at file scope. `counter.ml` paired with `counter.mli`:

```ocaml
(* counter.mli — the contract *)
type t
val empty : t
val add : int -> t -> t
val size : t -> int
val describe : t -> string
```

Dune picks this up automatically — no stanza needed. Everything in `counter.ml` not listed here is private, and `type t` is abstract to every other file.

This is the API contract, and it doubles as documentation: the `.mli` is what a reader should look at first, uncluttered by implementation.

### One wrinkle worth knowing

If you omit a helper from the `.mli` **and** never use it inside the module, dune's dev profile fails the build:

```
Error (warning 32 [unused-value-declaration]): unused value debug
```

Which is correct — a function neither exported nor used internally is dead code. But it means "hide it via the `.mli`" and "leave it unused" can't be combined. Use it internally, or delete it.

The repo has **no `.mli` files yet**. Each `src/dayNN.ml` informally exposes `parse_input`/`part1`/`part2`/`solve`, and `Day_registry` depends on exactly that shape. Adding a `dayNN.mli` would turn that convention into a compiler-checked contract and hide each day's helpers. Worth doing if a day grows a lot of scaffolding; not worth it for a twenty-line solve.

---

## Part 4 — Functors

A **functor** is a module parameterized by a module — a function from modules to modules. `Set.Make` and `Map.Make` are exactly this. Here's one of your own.

First, the signature the **argument** must satisfy:

```ocaml
module type ORDERED = sig
  type t
  val compare : t -> t -> int
end
```

Then the signature the **result** exposes:

```ocaml
module type COUNTER = sig
  type key
  type t
  val empty : t
  val add : key -> t -> t
  val count : key -> t -> int
  val most_common : t -> (key * int) list
end
```

And the functor:

```ocaml
module MakeCounter (Key : ORDERED) : COUNTER with type key = Key.t = struct
  module M = Map.Make (Key)
  type key = Key.t
  type t = int M.t          (* abstract to callers: they can't see it's a Map *)
  ...
end
```

Instantiate it as many times as you like. `Int` and `String` already satisfy `ORDERED`:

```ocaml
module IntCounter = MakeCounter (Int)
module StringCounter = MakeCounter (String)
module CoordCounter = MakeCounter (Coord)
```

### The sharing constraint is the part everyone misses

Look again at `with type key = Key.t`. **Without it the module is useless.** `key` stays abstract in the result, so nothing connects your `int` to the counter's `key`:

```
Error: This expression has type int but an expression was expected of type IC.key
```

That's the real error from omitting it. You have a counter you can create and never put anything into. When a functor result should expose a type from its argument, you must say so explicitly — this is the price of not having typeclasses.

---

## Part 5 — `include` vs `open`

| | Effect |
|---|---|
| `open M` | brings `M`'s names into **scope** here; this module is unchanged |
| `include M` | **copies** `M`'s contents **into** this module, re-exporting them |

```ocaml
module Extended = struct
  include Base              (* Base's name and greet are now Extended's too *)
  let shout () = String.uppercase_ascii (greet ())
end
```

Use `include` to **extend** a module, `open` to **shorten references**. `include` is how you build "Stdlib plus my helpers" modules, and how libraries like Jane Street's `Core` layer over the standard library.

---

## Part 6 — Functors vs Typeclasses

Worth pinning down now, since it's the design fork you'll meet again immediately in Lean.

Both solve the same problem: *how does generic code get the operations it needs for a type it doesn't know?* Both answers pass a **dictionary** of operations. They differ in **who** passes it.

| | OCaml | Rust / Lean 4 / Haskell |
|---|---|---|
| Mechanism | functor | typeclass / trait |
| Dictionary | **you pass it, explicitly** | **inferred**, by instance resolution |
| Syntax | `Set.Make (Int)` | `BTreeSet<i32>`, `[Ord α]` |
| Per type | as many instances as you like, each with different behavior | normally one instance per type |
| Verbosity | higher | lower |

Typeclasses win on concision — you never write the dictionary. Functors win on control: nothing stops you building **two** set modules over the same type with different orderings, which a typeclass system makes awkward on purpose (coherence).

> **Heading toward Lean:** Lean 4 went the typeclass route, so `[Ord α]` will look like Rust's `T: Ord`. Having written a functor by hand, you'll recognize what instance resolution is doing for you — it's constructing and passing the same dictionary `MakeCounter (Int)` passes by hand. That makes Lean's `instance` declarations legible rather than magical, and it explains why Lean sometimes can't find an instance: it's searching for an argument you'd otherwise have supplied yourself.

---

## Running It

```bash
ocaml tutorial/day7/example.ml
```

```bash
dune exec tutorial/day7/example.exe
```

---

## Key Takeaways for Day 7

| Concept | OCaml | Rust analogy |
|---|---|---|
| Module | every `.ml` file, or `module M = struct ... end` | `mod` |
| Signature | `module type S = sig ... end` | `trait` (loosely) |
| Constrain a module | `module M : S = struct ... end` | `impl Trait for T` |
| Abstract type | `type t` with no definition in the signature | newtype with private fields |
| File-level contract | `foo.mli` | `pub` markers in `foo.rs` |
| Scoped reference | `M.(...)`, `let open M in` | `use` inside a block |
| Extend a module | `include M` | no direct equivalent |
| Parameterized module | `module Make (X : S) = struct ... end` | generics + trait bounds |
| Expose the arg's type | `S with type key = Key.t` | associated types |
| Unused private helper | warning 32, error under dune | `dead_code` lint |

The habit to build: **decide what callers are allowed to know.** A signature isn't paperwork — it's the difference between an invariant you hope holds and one the compiler guarantees.

---

## Day 8 Preview

Tomorrow: **folds, pipelines, and composition** — `|>`, `@@`, partial application, and building a solve as a chain of small transformations rather than one big recursive function.
