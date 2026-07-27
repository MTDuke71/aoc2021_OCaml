# Day 00 Function Guide — The Tyranny of the Rocket Equation

> Tutorial **dry run** (it's AoC 2019 Day 1, reused — the same puzzle the Prolog
> repo used for its dry run). Besides solving the puzzle, this day's job is to
> exercise the whole per-day pipeline — [src/day00.ml](../../src/day00.ml),
> [test/day00_tests.ml](../../test/day00_tests.ml),
> [src/day_registry.ml](../../src/day_registry.ml),
> [bench/main.ml](../../bench/main.ml), this guide, and a
> [python/day00.py](../../python/day00.py) cross-check — once, end to end,
> before AoC 2021 proper begins on 2026-08-10. Because the answers are already
> known (locked in `../aoc2020_Prolog`), any mismatch here is a *plumbing* bug,
> not an algorithm bug. That's the whole point of running it first.
>
> The Prolog counterpart is
> [aoc2020_Prolog/Problem_Statements/days/day00_function_guide.md](../../../aoc2020_Prolog/Problem_Statements/days/day00_function_guide.md);
> reading them side by side is the cheapest Prolog→OCaml diff you'll get.

## The puzzle in one paragraph

Input is a list of module masses, one integer per line. **Part 1:** for each
module, `fuel = floor(mass / 3) - 2`; sum them. **Part 2:** fuel has mass too,
so it needs its own fuel, which needs its own fuel, … Keep applying the same
formula to each newly-added chunk of fuel until a step yields nothing positive,
and sum the whole chain per module.

---

## Reading OCaml: the forms this day uses

Day 0 is deliberately tiny, which makes it the right place to pin the mechanics
every later day leans on.

**1. A file *is* a module.** `src/day00.ml` defines module `Day00`, with no
`module Day00 = ...` wrapper anywhere. Every top-level `let` in it is public
unless a `day00.mli` interface file restricts it — which is why the tests can
reach `Day00.fuel` and `Day00.total_fuel` directly. The library is named
`aoc2021` (see [src/dune](../../src/dune)), so from outside it's
`Aoc2021.Day00.fuel`. Inside the library, siblings are just `Io` and `Day_stub`.

**2. `let` binds; there is no `return`.** A function body is one expression and
its value is the result:

```ocaml
let fuel mass = (mass / 3) - 2
```

No type annotations needed — inference reads `/` and `-` as `int` operations and
concludes `fuel : int -> int`. Hover in your editor to see what was inferred;
that habit replaces Rust's explicit signatures.

**3. `let rec` is opt-in recursion.** A plain `let` can't see the name being
bound, so self-recursion must say `let rec`. `total_fuel` needs it; nothing else
here does.

**4. `if … then … else` is an expression, not a statement.** Both branches must
have the same type, and the whole form has that type — this *is* the Part 2 stop
guard:

```ocaml
if step <= 0 then 0 else step + total_fuel step
```

There is no `else`-less form when the branches produce a value (an `if` without
`else` is only legal at type `unit`).

**5. `/` on `int` truncates toward zero.** Same as Rust's `/` on `i64`, same as
Prolog's `//`. For non-negative masses that coincides with the puzzle's "divide
by three and round down"; flooring division would differ only on negatives,
which this input never has. Note also that `/` on ints *is* integer division —
there is no silent promotion to float. Float division is a **different
operator**, `/.`, and mixing them is a type error rather than a surprise.

**6. `|>` is the pipeline operator.** `x |> f` is `f x`, and it associates left,
so a chain reads in execution order:

```ocaml
masses lines |> List.fold_left (fun acc mass -> acc + f mass) 0
```

Read: take the masses, then fold `+` over them. It's Rust's method-chain
ergonomics recovered for plain functions.

**7. `List.fold_left f init list` is the workhorse fold.** Argument order is
`f acc element`, accumulator first. It is tail-recursive (unlike
`List.fold_right`), which is why sums are written this way rather than as
`List.map` followed by a separate summation.

**8. Partial application is how helpers get shared.** `sum_by` takes the
per-module function as its first argument, so `part1` and `part2` differ only in
which kernel they hand it:

```ocaml
let part1 lines = string_of_int (sum_by fuel lines)
let part2 lines = string_of_int (sum_by total_fuel lines)
```

**9. Answers are strings.** [src/common/day_stub.ml](../../src/common/day_stub.ml)
defines `type answer = string`, so every day's parts return `string` and
`string_of_int` is the last step. That keeps the registry monomorphic across all
26 days at the cost of one conversion — see the scaffold note below.

---

## The Day 0 code, function by function

### `type parsed` and `parse_input`

```ocaml
type parsed = string list

let parse_input : string -> parsed = Io.nonempty_lines
```

`Io.nonempty_lines` (in [src/common/io.ml](../../src/common/io.ml)) splits on
`'\n'` and drops lines that are blank after trimming. Note what it does *not*
do: convert to `int`.

That's forced by [src/day_registry.ml](../../src/day_registry.ml), which declares
`type parsed = string list` **once, for all 26 days**, so that `bin/main.exe` and
`bench/main.exe` can look a day up by name and run it uniformly. A day cannot yet
choose its own parsed representation, so Day 0 carries lines and converts on use:

```ocaml
let masses lines = List.map (fun line -> int_of_string (String.trim line)) lines
```

`String.trim` is doing real work: inputs downloaded on Windows carry `\r`, and
`int_of_string "108356\r"` raises `Failure`. Trimming per line is the cheap fix,
and the same defensive move the Prolog version makes by trimming `" \t\r"` in
`split_string/4`.

> **Scaffold note — the parsed-type ceiling.** Because conversion happens inside
> the parts, `bench` charges `int` parsing to `part1`/`part2` rather than to
> `parse`, and both parts re-convert the same 100 strings. Harmless at this size;
> wrong-shaped for a day whose parse is expensive (a grid, an interpreter's
> program, a graph). The fix, when a later day needs it, is to make the registry
> entry existential in the parsed type instead of fixing it globally:
>
> ```ocaml
> type t =
>   | Entry : {
>       name : string;
>       parse_input : string -> 'p;
>       part1 : 'p -> answer;
>       part2 : 'p -> answer;
>     } -> t
> ```
>
> A consumer that destructures `Entry e` can pipe `e.parse_input raw` into
> `e.part1`: the type is unknown to the caller but known to be *consistent*,
> which is exactly what parse-then-run needs. Left undone deliberately — Day 0
> doesn't need it, and the repo's optimization policy says don't rebuild the
> scaffold on speculation.

### `fuel` — the Part 1 kernel

```ocaml
let fuel mass = (mass / 3) - 2
```

A direct transcription of the spec, and the whole of Part 1's arithmetic.

### `total_fuel` — the Part 2 fixed-point iteration

```ocaml
let rec total_fuel mass =
  let step = fuel mass in
  if step <= 0 then 0 else step + total_fuel step
```

This is the **algorithm hiding inside Day 0**: a *fixed-point iteration* (a.k.a.
"iterate to convergence"). Apply `fuel` to its own output, accumulate each
positive result, stop when the map leaves the positive region. Naming it matters
— the same shape recurs whenever you apply a step function until it stabilizes
(Newton's method; the stabilization passes in later AoC grid puzzles).

**Why it terminates:** the orbit `mass → fuel mass → fuel (fuel mass) → …`
strictly decreases — each step is roughly `m/3` — so it is geometric decay with
ratio ≈ 1/3. That same ratio is why Part 2's total is only ~1.5× Part 1's rather
than unbounded (`1 + 1/3 + 1/9 + … = 3/2`). Check it against the locked answers:
5218616 / 3481005 ≈ 1.499.

**A note on tail calls:** this is *not* tail-recursive — the `step + …` addition
happens *after* the recursive call returns, so each level keeps a frame. An
accumulator version would be tail-recursive and constant-stack. At `O(log mass)`
≈ 11 frames deep it makes no practical difference, so the readable form wins —
see the optimization sidebar.

### `sum_by`, `part1`, `part2`, `solve`

```ocaml
let sum_by f lines = masses lines |> List.fold_left (fun acc mass -> acc + f mass) 0
let part1 lines = string_of_int (sum_by fuel lines)
let part2 lines = string_of_int (sum_by total_fuel lines)

let solve raw =
  let parsed = parse_input raw in
  (part1 parsed, part2 parsed)
```

`sum_by` is "map then sum" fused into one fold — one traversal, no intermediate
list. `solve` parses once and returns a tuple of both answers, which is the shape
[test/day00_tests.ml](../../test/day00_tests.ml) locks and every later day
reuses.

---

## Correctness notes

- `fuel` verified on all four worked examples: `12→2`, `14→2`, `1969→654`,
  `100756→33583`.
- `total_fuel` verified on `14→2`, `1969→966`, `100756→50346`; termination
  argued above.
- Locked real-input answers: **Part 1 = 3481005**, **Part 2 = 5218616** —
  identical to the Prolog and Python results on the same input, which is the
  cross-language check this dry run exists to perform.

## Tests — what's pinned and why

[test/day00_tests.ml](../../test/day00_tests.ml) replaces the scaffold's
`run_stub` call with four layers, all green under `dune runtest` (26/26 day
suites, Day 0 being the only non-stub one):

1. **Parser** — `parse_input "12\n\n14\n1969\n" = ["12"; "14"; "1969"]`, locking
   the blank-line drop.
2. **Every worked example** from the puzzle text, for both `fuel` and
   `total_fuel`, driven by `List.iter` over a list of `(input, expected)` pairs —
   the OCaml stand-in for the Prolog test's `member/2`-over-pairs trick.
3. **Part sums** over the example lists.
4. **The real answers** — `3481005` / `5218616`. Pinning the actual answer means
   any future refactor that changes the result fails loudly instead of silently.

One wrinkle worth remembering: **dune runs the test executable with
`cwd = _build/default/test`**, so a bare `inputs/day00.txt` does not resolve the
way it does for `plunit` in the Prolog repo. `Test_support.find_input` walks up
parent directories looking for `inputs/<name>`. Since inputs are gitignored, it
returns `None` on a fresh clone and the answer-lock layer *skips with a printed
note* instead of failing — a clone with no personal inputs still gets a green
suite.

Run: `dune runtest` (add `--force` to defeat dune's result caching).

## Complexity & benchmarks

- Part 1: `O(n)` over `n` modules, each `O(1)`.
- Part 2: `O(n · log mass)` — each module's fuel chain has `O(log mass)` steps.
- Space: `O(n)` for the parsed lines and the `int` list per part; `total_fuel`
  recursion depth `O(log mass)`.

`dune exec ./bench/main.exe -- day00`, three consecutive runs on the 100-line
input:

| Phase | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) |
|-------|-----------:|-----------:|-----------:|
| parse | 0.008 | 0.008 | 0.007 |
| part1 | 0.005 | 0.010 | 0.006 |
| part2 | 0.003 | 0.006 | 0.004 |

Calibration for the cold reader: the whole day is **single-digit microseconds**,
and at that scale this harness measures noise, not algorithms. Read nothing into
part2 landing below part1 — part1 runs first and absorbs cache and
first-allocation costs, and the spread *within* a row exceeds the difference
*between* rows. The Prolog guide could report a real ~13× part2/part1 ratio
because `bench/main.pl` averages 100,000 iterations and also reports exact
inference counts; `bench/main.ml` is a single-shot wall-clock timer. **If a later
day matters for timing, add repetition to the bench harness before quoting a
number.** What this table *does* establish: anything in a later day that is not
sub-millisecond is doing real algorithmic work.

## If I were writing this in Rust

```rust
fn fuel(mass: i64) -> i64 { mass / 3 - 2 }

fn total_fuel(mass: i64) -> i64 {
    std::iter::successors(Some(fuel(mass)), |&f| Some(fuel(f)))
        .take_while(|&f| f > 0)   // stop at the first non-positive step
        .sum()
}
```

- `string list` ↔ `Vec<&str>`; `masses` ↔
  `lines.iter().map(|l| l.trim().parse().unwrap()).collect::<Vec<i64>>()`.
- Rust `/` on `i64` truncates toward zero, matching OCaml's `/` on `int`.
- `List.fold_left (fun acc m -> acc + f m) 0` ↔ `.map(f).sum()`. Rust's iterator
  adapters fuse lazily; OCaml's `List.map` would allocate an intermediate list,
  which is why the fold is written directly. OCaml's lazy equivalent is the `Seq`
  module — see the sidebar.
- The interesting correspondence is `total_fuel`: OCaml spells the fixed-point
  iteration as explicit recursion with an `if … <= 0` guard; Rust says the same
  thing declaratively — `successors(seed, step)` *is* "iterate this function,"
  and `take_while(|&f| f > 0)` *is* the guard. Two spellings of one idea.
- OCaml's `int` is 63-bit on a 64-bit platform (one bit goes to the GC tag), not
  64-bit like `i64`. Nowhere near mattering here, but it is the one arithmetic
  surprise waiting in a later day that overflows or does bit tricks near the top
  of the range.
- See [python/day00.py](../../python/day00.py) for the same logic in the
  imperative `while f > 0: total += f; f = fuel(f)` shape.

## Possible optimization

None of this is needed at `n = 100`; readable OCaml wins here per the repo's
optimization policy. Recorded as transferable technique only:

- **Accumulator/tail-recursive `total_fuel`** for constant stack:
  `let rec go acc mass = let s = fuel mass in if s <= 0 then acc else go (acc + s) s`.
  Irrelevant at depth ≈ 11.
- **`Seq`-based chain** — `Seq.unfold` + `Seq.take_while` + `Seq.fold_left`
  mirrors the Rust `successors` version almost line for line, if you would rather
  read the declarative spelling.
- **Existential registry entry** (sketched above) so a day owns its parsed type
  and `bench` attributes parse cost honestly. This is the one item here likely to
  graduate from "possible" to "needed" during AoC proper.
- **Repetition in `bench/main.ml`** so timings mean something at microsecond
  scale — arguably a correctness fix for the harness rather than an
  optimization.
