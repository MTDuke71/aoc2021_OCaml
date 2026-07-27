(* Day 0: The Tyranny of the Rocket Equation (tutorial dry run).

   Input is one integer module mass per line. This day is the pipeline smoke
   test: it exercises parse -> part1 -> part2 -> registry -> bench -> tests once,
   end to end, against a puzzle whose answers are already locked in
   ../aoc2020_Prolog (src/day00.pl). *)

type parsed = string list
(* [Day_registry] fixes [parsed] as [string list] for every day, so
   [parse_input] keeps the raw lines and [masses] does the int conversion. *)

let parse_input : string -> parsed = Io.nonempty_lines

(* [String.trim] is what makes this robust to Windows CRLF inputs; without it
   [int_of_string] would choke on a trailing carriage return. *)
let masses lines = List.map (fun line -> int_of_string (String.trim line)) lines

(* Part 1 kernel, straight from the spec: floor (mass / 3) - 2. Masses are
   positive, so OCaml's truncating [/] agrees with flooring here. *)
let fuel mass = (mass / 3) - 2

(* Part 2: fuel has mass, so it needs its own fuel, and so on. A fixed-point
   iteration -- apply [fuel] to its own output, accumulate each positive step,
   and stop once a step asks for nothing positive. *)
let rec total_fuel mass =
  let step = fuel mass in
  if step <= 0 then 0 else step + total_fuel step

let sum_by f lines = masses lines |> List.fold_left (fun acc mass -> acc + f mass) 0
let part1 lines = string_of_int (sum_by fuel lines)
let part2 lines = string_of_int (sum_by total_fuel lines)

(* Parse once, produce both answers -- the shape every later day reuses. *)
let solve raw =
  let parsed = parse_input raw in
  (part1 parsed, part2 parsed)
