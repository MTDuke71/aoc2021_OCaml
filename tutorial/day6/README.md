# Tutorial Day 6 — Sets, Maps, and Grid Modeling

Days 2 and 5 leaned on lists for everything. Today is about when a list stops being the right container, and what to reach for instead. It's also your first working encounter with **functors** — `Set.Make` and `Map.Make` are modules that take a module and return a module — which Day 7 then takes up properly.

---

## Part 1 — Why Not a List

A list is a linked list. `List.mem` walks it, so membership is **O(n)**. Do that inside a loop and you have an accidental **O(n²)**, which is the single most common reason an AoC solution that works on the sample hangs on the real input.

Measured on this machine — deduplicating a list two ways:

| n | `List.mem` dedup | `Set` dedup | ratio |
|---:|---:|---:|---:|
| 2,000 | 0.030 s | 0.002 s | 15× |
| 10,000 | 0.740 s | 0.011 s | 67× |
| 20,000 | 2.939 s | 0.022 s | **133×** |

Look at the shape, not just the ratio: **doubling n from 10k to 20k quadrupled the list time** (0.740 → 2.939) while the set time merely doubled. That's textbook quadratic versus linearithmic. The gap isn't a constant factor you can ignore — it grows.

Rule of thumb: **the moment you write `List.mem` inside a fold or a loop, switch to a `Set`.**

---

## Part 2 — `Set.Make`, Your First Functor

```ocaml
module IntSet = Set.Make (Int)
```

`Set.Make` is a **functor**: a function from modules to modules. Hand it a module providing a type `t` and a `compare`, and it returns a whole `Set` module specialized to that element type. Stdlib's `Int` module already provides both.

This is OCaml's answer to "generic over a comparison." Rust writes `BTreeSet<i32>` and picks the ordering up from the `Ord` trait automatically. OCaml has **no typeclasses**, so you supply the comparison explicitly, exactly once, at the point where you build the module. More typing; also more control, since nothing stops you building a second set module over the same type with a different ordering.

> **Heading toward Lean:** this is the fork in the road. Lean 4 went the typeclass route — you'd write `[Ord α]` and instance resolution finds the comparison, much like Rust traits. OCaml's functors are more explicit and more flexible; typeclasses are more concise and inferred. Same problem, two answers, and knowing OCaml's makes Lean's design choice legible rather than arbitrary.

### The operations worth knowing

```ocaml
IntSet.empty                     IntSet.of_list [3; 1; 4]
IntSet.add x s                   IntSet.remove x s
IntSet.mem x s                   IntSet.cardinal s
IntSet.union a b                 IntSet.inter a b        IntSet.diff a b
IntSet.elements s                (* sorted, deduped list *)
IntSet.fold f s init             IntSet.iter f s         IntSet.filter p s
```

Two things to internalize:

- **`elements` comes back sorted.** It's a balanced binary tree, not a hash table. Ordering is free.
- **Sets are persistent.** `IntSet.add 100 s` returns a *new* set; `s` is unchanged. Internally the two share almost all their structure, so this is cheap — not a copy. This is why Day 3's immutability claim holds even for large containers.

---

## Part 3 — `Map.Make`

Same functor pattern, with values attached:

```ocaml
module IntMap = Map.Make (Int)
```

### `update` is the one to learn

Insert-or-modify in a single traversal. It takes the key and a function from the **current binding** (an `option`, exactly as Day 3 taught) to the new binding:

```ocaml
let count_occurrences lst =
  List.fold_left
    (fun acc item ->
      IntMap.update item (function None -> Some 1 | Some n -> Some (n + 1)) acc)
    IntMap.empty lst
```

That's frequency counting — one of the two or three most reused shapes in all of AoC. Returning `None` from the function *deletes* the binding.

### Use `find_opt`, not `find`

`Map.find` raises `Not_found`. `Map.find_opt` returns an option. Day 3's `_opt` convention applies everywhere.

```ocaml
IntMap.empty        IntMap.add k v m       IntMap.remove k m
IntMap.find_opt k m IntMap.mem k m         IntMap.cardinal m
IntMap.bindings m   (* sorted (key, value) list *)
IntMap.fold f m init                       IntMap.filter p m
```

---

## Part 4 — Custom Key Modules

To key by something the stdlib has no module for — grid coordinates, most often — supply your own. The bar is low: a type and a `compare`.

```ocaml
module Coord = struct
  type t = int * int
  let compare = compare      (* polymorphic compare handles tuples structurally *)
end

module CoordSet = Set.Make (Coord)
module CoordMap = Map.Make (Coord)
```

`Stdlib.compare` is polymorphic and works structurally on tuples. It's convenient and somewhat slower than a hand-written comparison; for AoC that's the right trade. The explicit version, if you want it:

```ocaml
let compare (x1, y1) (x2, y2) =
  match Int.compare x1 x2 with 0 -> Int.compare y1 y2 | c -> c
```

One warning about polymorphic `compare`: it raises on functional values and can behave surprisingly on cyclic structures. On plain data — ints, tuples, strings, variants — it's fine.

---

## Part 5 — `Hashtbl`, and One Sharp Edge

`Hashtbl` is the **mutable**, hash-based alternative: O(1) average instead of O(log n), but no persistence and no ordering. Use it when you're building state imperatively and will never want an earlier version.

### `add` does not overwrite

This is the trap, and it's worth seeing the actual numbers:

```ocaml
Hashtbl.add h "k" 1;
Hashtbl.add h "k" 2;
(* length = 2, find returns 2 *)

Hashtbl.remove h "k";
(* length = 1, find returns 1  <- the shadowed binding is REVEALED *)
```

`add` **shadows** the previous binding rather than replacing it, so one `remove` uncovers the older value. That's deliberate — it makes `Hashtbl` usable as a multi-map — but it is almost never what you want.

**Use `Hashtbl.replace`.** Two `replace` calls leave `length = 1`.

### Choosing a container

| Need | Use |
|---|---|
| Membership, ordering, persistence | `Set` |
| Key → value, ordering, persistence | `Map` |
| Fastest mutable key → value, no history | `Hashtbl` |
| Dense fixed-size indexed data | `Array` |
| Sequence you only traverse | `list` |

---

## Part 6 — Modeling a Grid

Two representations, and the choice is about **density**:

**Dense and fixed size → array of strings.** O(1) indexing, minimal allocation. A 100×100 heightmap.

```ocaml
let grid = [| "..#.."; "..#.."; "###.."; "..#.."; "..#.." |]
let height = Array.length grid
let width = String.length grid.(0)
```

**Sparse or unbounded → `Map` keyed by coordinate.** O(log n), but you never need to know the extent of the plane in advance, and empty space costs nothing.

### The bounds-checked accessor

Write this once per grid problem and most off-by-one bugs disappear:

```ocaml
let at (x, y) =
  if x < 0 || y < 0 || x >= width || y >= height then None else Some grid.(y).[x]
```

Returning an `option` means callers *cannot* forget the edges — the compiler makes them handle `None`. Note the index order: `grid.(y).[x]`, row first, then column. Getting that backwards is the other classic grid bug.

### Flood fill

The single most reused AoC shape. A `Set` tracks what's been seen, a list is the frontier, and it's tail-recursive per Day 5:

```ocaml
let reachable_from start =
  let rec go seen = function
    | [] -> seen
    | pos :: rest ->
        if CoordSet.mem pos seen then go seen rest
        else if not (is_open pos) then go seen rest
        else go (CoordSet.add pos seen) (neighbors pos @ rest)
  in
  go CoordSet.empty [ start ]
```

The `seen` set is doing two jobs at once: recording the answer *and* preventing infinite loops. Without it this never terminates, since neighbors point back at each other.

The example grid has three disconnected regions, and the fill finds a different one from each start — 4, 4, and 10 cells, totalling the grid's 18 open cells:

```
..#..
..#..
###..     from (0,0) -> 4     from (0,4) -> 4
..#..     from (4,0) -> 10    from a wall -> 0
..#..
```

---

## Part 7 — Sparse Counting

The other half of grid work. When points are scattered rather than packed, count them into a `Map` instead of allocating a grid:

```ocaml
let mark_points points =
  List.fold_left
    (fun acc p -> CoordMap.update p (function None -> Some 1 | Some n -> Some (n + 1)) acc)
    CoordMap.empty points

let overlapping = CoordMap.filter (fun _ count -> count >= 2) marks
```

"How many cells are covered more than once" without ever bounding the plane. You'll want this.

---

## Running It

```bash
ocaml tutorial/day6/example.ml
```

```bash
dune exec tutorial/day6/example.exe
```

---

## Key Takeaways for Day 6

| Concept | OCaml | Rust analogy |
|---|---|---|
| Build a set type | `module S = Set.Make (Int)` | `BTreeSet<i32>` |
| Build a map type | `module M = Map.Make (Int)` | `BTreeMap<i32, V>` |
| Where ordering comes from | a `compare` you supply to the functor | the `Ord` trait, found automatically |
| Persistence | `add` returns a new set, sharing structure | needs `im`/`rpds` crates |
| Sorted output | `elements` / `bindings` | `BTreeSet` iteration |
| Lookup | `find_opt` (not `find`, which raises) | `.get()` |
| Insert-or-update | `Map.update k (function ...)` | `.entry(k).and_modify().or_insert()` |
| Mutable table | `Hashtbl` | `HashMap` |
| Overwrite in `Hashtbl` | **`replace`**, never `add` | `.insert()` |
| Dense grid | `string array`, `grid.(y).[x]` | `Vec<Vec<char>>` |
| Sparse grid | `Map` keyed by `(int * int)` | `HashMap<(i32,i32), V>` |
| Bounds check | accessor returning `option` | `.get()` returning `Option` |

The habit to build: **pick the container from the access pattern, not from familiarity.** If you're testing membership repeatedly, that's a `Set`. If you're counting, that's a `Map` with `update`. Lists are for sequences you traverse once.

---

## Day 7 Preview

Tomorrow: **modules and signatures** — what `Set.Make` actually is, how to write your own functor, and how `.mli` files turn a module into an enforced abstraction boundary. Day 3's `Positive` type, generalized.
