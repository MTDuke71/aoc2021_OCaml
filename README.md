# aoc2021_OCaml

This is Matt LaDuke's AoC 2021 / OCaml repo, the fourth leg of a planned language-rotation run.
Use this file to orient on conventions, working style, and cross-repo context before helping on a
first request in a new session.

## The language rotation

| Year | Language | Repo |
| --- | --- | --- |
| 2017 | Rust + Python side-by-side | `../rust_study/advent_of_code/aoc2017/` |
| 2018 | Haskell | `../aoc2018_Haskell/` |
| 2019 | Racket | `../aoc2019_racket/` |
| 2020 | Prolog | `../aoc2020_Prolog/` |
| 2021 | OCaml | this repo |
| all other years | Rust | scattered |

Why this rotation exists: breadth-first language exposure across paradigms. The goal is reading
fluency and transferable problem solving, not deep specialization in one language.

## Timeline and cadence

- Tutorial phase: 11 days.
- AoC 2021 proper starts: 2026-08-10.
- Tutorial is expected to run from 2026-07-27 through 2026-08-09.

## About the user

- 20+ year engineer; senior-level depth.
- Rust is the anchor language for comparisons.
- Comfortable with compiler/VM and algorithmic vocabulary.
- Workflow preference: assistant writes code, user reads and reviews.

## Working style

- Language-first on initial walkthroughs: focus on OCaml mechanics, type inference, algebraic data
  types, pattern matching, recursion, modules, and immutable data modeling.
- Algorithm-depth on demand: if asked "why this works" or "prove it", go all the way down with
  correctness arguments and performance tradeoffs.
- Name algorithms in standard literature terms so techniques transfer.
- If syntax frustration appears, pivot back to algorithmic structure.

## Project shape (scaffold)

```text
aoc2021_OCaml/
  bin/
    main.ml
  tutorial/
    day1/ ... day11/
  src/
    day00.ml .. day25.ml
    common/
      day_stub.ml
      io.ml
  test/
    day00_tests.ml .. day25_tests.ml
    main.ml
  bench/
    main.ml
  Problem_Statements/
    days/
      dayNN.md
      dayNN_function_guide.md
      summary_2021.md
  python/
    dayNN.py
  inputs/
    README.md
  dune-project
```

Notes:

- Keep one main source file per day in `src/`.
- Use `dune` as the default build/test runtime unless explicitly changed.
- Mirror the Prolog repo's discoverable top-level day layout, but use dune-friendly OCaml modules
  and executables for the actual entry points.
- Keep personal Advent of Code inputs as local `inputs/dayNN.txt` files; those filenames are
  intentionally gitignored.

## Scaffold commands

Build everything:

```bash
dune build
```

Run the scaffold tests:

```bash
dune runtest
```

Run a day stub against the default input path:

```bash
dune exec ./bin/main.exe -- day01
```

Run a day stub against an explicit file:

```bash
dune exec ./bin/main.exe -- day01 /tmp/day01.txt
```

Run the timing harness:

```bash
dune exec ./bench/main.exe -- day01 /tmp/day01.txt
```

Run the Python cross-check reference for the same day:

```bash
python3 python/day01.py /tmp/day01.txt
```

Like `bin/main.exe`, it falls back to `inputs/dayNN.txt` when no path is given.

Format the OCaml sources (`dune fmt` rewrites files in place; `dune build @fmt`
only reports differences):

```bash
dune fmt
```

Style is pinned in `.ocamlformat` (profile `default`, margin 120). Files under
`tutorial/` are exempt via `.ocamlformat-ignore` so their hand-formatted teaching
layout survives.

## Mapping from `aoc2020_Prolog`

- `src/dayNN.pl` -> `src/dayNN.ml`
- `test/dayNN_tests.pl` -> `test/dayNN_tests.ml`
- `bench/main.pl` -> `bench/main.ml`
- `tutorial/dayN/` remains `tutorial/dayN/`
- `Problem_Statements/days/` remains `Problem_Statements/days/`
- `python/dayNN.py` remains `python/dayNN.py`
- `inputs/dayNN.txt` remains the local input-file convention

## Per-day deliverable

Each solved day should include:

1. Source file in `src/dayNN.ml` with clear function contracts in comments, plus a consistent shape:
   - `parse_input : string -> parsed_input`
   - `part1 : parsed_input -> int` (or `string`, depending on puzzle output)
   - `part2 : parsed_input -> int` (or `string`, depending on puzzle output)
   - `solve : string -> answer * answer` (or equivalent returning both answers)
2. Test file in `test/dayNN_tests.ml`:
   - puzzle example tests
   - real-input answer locks for part 1 and part 2
3. Bench hook in `bench/main.ml` with parse/part timings when practical.
4. Function guide at `Problem_Statements/days/dayNN_function_guide.md`.
5. Python algorithm reference in `python/dayNN.py` for every day (cross-validates the OCaml
   answers in a second language).
6. Summary row in `Problem_Statements/days/summary_2021.md`.

## Function guides are the durable artifact

Guides should be written for a reader who is cold after 12+ months. Restate key OCaml forms and
cross-link days aggressively.

Each guide should include:

- Problem framing and representation choices.
- Function-by-function walkthrough.
- Why the algorithm is correct.
- Complexity discussion.
- "If I were writing this in Rust" bridge section.
- Optional optimization sidebar without forcing premature rewrites.

## Optimization policy

- Shipping source should be idiomatic and readable OCaml first.
- Faster alternatives can be documented in the function guide as "Possible optimization" sidebars.
- Prefer correctness + clarity in `src/`; keep deep optimization experimental unless required.

## Tutorial policy (11 days)

Tutorial outputs live under `tutorial/dayN/README.md` and small, working `.ml` examples.

Goals of tutorial phase:

- Build fast reading fluency for core OCaml constructs.
- Establish daily solve/test/guide rhythm.
- Prepare directly for AoC day files starting 2026-08-10.

## What not to do

- Do not suggest abandoning the language rotation.
- Do not force write-drill exercises unless explicitly requested.
- Do not skip guides just to increase day throughput.
- Do not replace readable source with clever but opaque tricks by default.

## Likely first requests

Expect requests to:

- Scaffold the repo layout.
- Settle OCaml toolchain details (compiler/runtime, test command, bench script).
- Create tutorial day 1 with code + guide.
- Set up a repeatable solve/test template for upcoming AoC days.