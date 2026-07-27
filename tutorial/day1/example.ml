(* Tutorial Day 1 — values, expressions, bindings, and function definitions
   Run with:  ocaml tutorial/day1/example.ml  *)

(* --------------------------------------------------------------------------
   Part 1: Values and expressions
   -------------------------------------------------------------------------- *)

let () =
  (* Integer arithmetic *)
  let sum  = 3 + 4 in
  let diff = 10 - 6 in
  let prod = 5 * 7 in
  let quot = 17 / 5 in   (* integer division — truncates toward zero *)
  let rem  = 17 mod 5 in
  Printf.printf "sum=%d diff=%d prod=%d quot=%d rem=%d\n"
    sum diff prod quot rem;

  (* Float arithmetic — operators have a trailing dot *)
  let avg = (1.5 +. 2.5 +. 3.0) /. 3.0 in
  Printf.printf "average=%.4f\n" avg;

  (* String concatenation *)
  let greeting = "Hello" ^ ", " ^ "OCaml!" in
  Printf.printf "%s\n" greeting

(* --------------------------------------------------------------------------
   Part 2: Let bindings — local names with let ... in
   -------------------------------------------------------------------------- *)

(* A top-level binding: visible to all code below in this file. *)
let speed_of_light_m_per_s = 299_792_458   (* underscores are allowed in int literals *)

(* A function that uses a local binding *)
let light_travel_km (seconds : float) : float =
  let c_km = float_of_int speed_of_light_m_per_s /. 1000.0 in
  c_km *. seconds

let () =
  Printf.printf "Light travels %.0f km in 1 second\n"
    (light_travel_km 1.0)

(* --------------------------------------------------------------------------
   Part 3: Function definitions
   -------------------------------------------------------------------------- *)

(* Single-parameter function *)
let square x = x * x

(* Two-parameter function *)
let hypotenuse a b =
  sqrt (float_of_int (square a + square b))

(* Recursive function — requires the `rec` keyword *)
let rec factorial n =
  if n <= 1 then 1
  else n * factorial (n - 1)

(* Fuel cost for a module: AoC 2019 day 1 style formula.
   Fuel = (mass / 3), rounded down, minus 2.
   This is purely for illustration — it is not AoC 2021 puzzle data. *)
let fuel_for_mass mass = (mass / 3) - 2

(* Recursive version: also counts the fuel needed to carry the fuel itself. *)
let rec fuel_for_mass_recursive mass =
  let f = fuel_for_mass mass in
  if f <= 0 then 0
  else f + fuel_for_mass_recursive f

let () =
  Printf.printf "square 7 = %d\n" (square 7);
  Printf.printf "hypotenuse 3 4 = %.1f\n" (hypotenuse 3 4);
  Printf.printf "5! = %d\n" (factorial 5);
  Printf.printf "fuel for mass 100  = %d\n" (fuel_for_mass 100);
  Printf.printf "fuel (recursive) for mass 100 = %d\n"
    (fuel_for_mass_recursive 100)

(* --------------------------------------------------------------------------
   Part 4: Anonymous functions and higher-order usage
   -------------------------------------------------------------------------- *)

(* List.map applies a function to every element of a list.
   We pass an anonymous function (fun x -> ...) as the first argument. *)
let doubles = List.map (fun x -> x * 2) [1; 2; 3; 4; 5]

let () =
  (* Print each element *)
  List.iter (fun n -> Printf.printf "%d " n) doubles;
  print_newline ()
