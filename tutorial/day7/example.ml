(* Tutorial Day 7 — Modules and signatures
   Run with:  ocaml tutorial/day7/example.ml
          or: dune exec tutorial/day7/example.exe *)

(* --------------------------------------------------------------------------
   Part 1: Modules are just named scopes — and every file is already one
   -------------------------------------------------------------------------- *)

(* `src/day00.ml` IS the module `Day00`, with no declaration anywhere. Writing
   `module X = struct ... end` by hand is the same thing, done inline. *)

module Geometry = struct
  type point = { x : int; y : int }

  let origin = { x = 0; y = 0 }
  let make x y = { x; y }
  let to_string p = Printf.sprintf "(%d,%d)" p.x p.y
  let add a b = { x = a.x + b.x; y = a.y + b.y }
end

let () =
  print_endline "-- Part 1: modules and open --";
  (* Fully qualified: always unambiguous, and the default worth defaulting to. *)
  Printf.printf "  %-30s %s\n" "qualified" (Geometry.to_string Geometry.origin);
  (* LOCAL open, one expression wide. Idiomatic — you get brevity without
     dumping a module's names into the rest of the file. *)
  Printf.printf "  %-30s %s\n" "local open M.(...)"
    Geometry.(to_string (add (make 1 2) (make 3 4)));
  (* The other local form, for a whole let-body. *)
  let combined =
    let open Geometry in
    to_string (add origin (make 7 8))
  in
  Printf.printf "  %-30s %s\n" "let open ... in" combined

(* A global `open Geometry` here would work too, but it makes every later
   reference ambiguous to a reader and risks silently shadowing names. Prefer
   the two local forms above. *)

(* --------------------------------------------------------------------------
   Part 2: Signatures hide things
   -------------------------------------------------------------------------- *)

(* A signature (module type) lists what escapes. Anything omitted is private.
   When the signature declares `type t` WITHOUT a definition, the type becomes
   ABSTRACT: callers can hold a value of it but cannot see or fabricate its
   representation. That is what makes an invariant enforceable — Day 3's
   Positive example, now with a name for the mechanism. *)

module type INTERVAL = sig
  type t
  (* representation deliberately hidden *)

  val make : int -> int -> t option
  (* the ONLY way in, and it validates *)

  val low : t -> int
  val high : t -> int
  val length : t -> int
  val contains : int -> t -> bool
  val to_string : t -> string
end

module Interval : INTERVAL = struct
  type t = { low : int; high : int }

  (* The invariant low <= high is established here and, because `t` is abstract
     and this is the only constructor, it holds everywhere. No other code can
     build a malformed interval even by accident. *)
  let make low high = if low > high then None else Some { low; high }
  let low t = t.low
  let high t = t.high
  let length t = t.high - t.low
  let contains n t = n >= t.low && n <= t.high
  let to_string t = Printf.sprintf "[%d,%d]" t.low t.high

  (* Not in the signature, so invisible outside — the module can keep private
     helpers without them becoming API. *)
  let _debug t = Printf.sprintf "{low=%d; high=%d}" t.low t.high
end

let () =
  print_endline "-- Part 2: abstract types --";
  (match Interval.make 3 9 with
  | None -> print_endline "  unexpected"
  | Some i ->
      Printf.printf "  %-30s %s low=%d high=%d length=%d contains 5=%b\n" "valid interval"
        (Interval.to_string i) (Interval.low i) (Interval.high i) (Interval.length i)
        (Interval.contains 5 i));
  Printf.printf "  %-30s %s\n" "make 9 3 (invalid)"
    (match Interval.make 9 3 with None -> "rejected" | Some _ -> "accepted?!");
  (* These would NOT compile, which is the whole point:
       let fake = { Interval.low = 9; high = 3 }   (* representation is hidden *)
       Interval._debug i                            (* not in the signature *) *)
  print_endline "  representation and _debug are inaccessible from out here"

(* --------------------------------------------------------------------------
   Part 3: Writing a functor
   -------------------------------------------------------------------------- *)

(* Set.Make and Map.Make from Day 6 are functors: modules parameterized by
   modules. Here is one of our own, and the shape is the same.

   First, the signature the ARGUMENT must satisfy. Stdlib's Int and String
   both already match this, which is why they can be passed straight in. *)

module type ORDERED = sig
  type t

  val compare : t -> t -> int
end

(* Then the signature the RESULT will expose. *)
module type COUNTER = sig
  type key
  type t

  val empty : t
  val add : key -> t -> t
  val add_all : key list -> t -> t
  val count : key -> t -> int
  val distinct : t -> int
  val total : t -> int
  val most_common : t -> (key * int) list
end

(* And the functor itself.

   Note `with type key = Key.t`. Without it, `key` stays abstract in the result
   and the module is useless — you could never pass an actual int to `add`,
   because nothing would connect the caller's `int` to the counter's `key`.
   This SHARING CONSTRAINT is the piece everyone forgets the first time. *)

module MakeCounter (Key : ORDERED) : COUNTER with type key = Key.t = struct
  module M = Map.Make (Key)

  type key = Key.t
  type t = int M.t (* abstract to callers: they cannot see it is a Map *)

  let empty = M.empty
  let add k counter = M.update k (function None -> Some 1 | Some n -> Some (n + 1)) counter
  let add_all keys counter = List.fold_left (fun acc k -> add k acc) counter keys
  let count k counter = match M.find_opt k counter with None -> 0 | Some n -> n
  let distinct counter = M.cardinal counter
  let total counter = M.fold (fun _ n acc -> acc + n) counter 0

  (* Ties broken by key so the output is deterministic, not just sorted. *)
  let most_common counter =
    M.bindings counter
    |> List.sort (fun (k1, n1) (k2, n2) ->
           match Int.compare n2 n1 with 0 -> Key.compare k1 k2 | c -> c)
end

(* One functor, three instantiations. Int and String satisfy ORDERED already. *)
module IntCounter = MakeCounter (Int)
module StringCounter = MakeCounter (String)

(* And a hand-written argument module, exactly as on Day 6. *)
module Coord = struct
  type t = int * int

  let compare = compare
end

module CoordCounter = MakeCounter (Coord)

let () =
  print_endline "-- Part 3: a functor of our own --";
  let ic = IntCounter.(empty |> add_all [ 3; 1; 4; 1; 5; 9; 2; 6; 5; 3; 5 ]) in
  Printf.printf "  %-30s distinct=%d total=%d count(5)=%d\n" "IntCounter"
    (IntCounter.distinct ic) (IntCounter.total ic) (IntCounter.count 5 ic);
  Printf.printf "  %-30s %s\n" "most_common"
    (String.concat " "
       (List.map (fun (k, n) -> Printf.sprintf "%d:%d" k n) (IntCounter.most_common ic)));
  let sc = StringCounter.(empty |> add_all [ "up"; "down"; "up"; "forward"; "up" ]) in
  Printf.printf "  %-30s %s\n" "StringCounter most_common"
    (String.concat " "
       (List.map (fun (k, n) -> Printf.sprintf "%s:%d" k n) (StringCounter.most_common sc)));
  (* add_all is built from add; here is the single-key form directly. *)
  let cc = CoordCounter.(empty |> add (0, 9) |> add (1, 9) |> add (0, 9) |> add (2, 2)) in
  Printf.printf "  %-30s distinct=%d count(0,9)=%d\n" "CoordCounter" (CoordCounter.distinct cc)
    (CoordCounter.count (0, 9) cc)

(* --------------------------------------------------------------------------
   Part 4: include vs open
   -------------------------------------------------------------------------- *)

(* open  — brings names into SCOPE here; changes nothing about this module
   include — COPIES the contents INTO this module, re-exporting them
   Use include to extend a module; use open to shorten references. *)

module Base = struct
  let name = "base"
  let greet () = "hello from " ^ name
end

module Extended = struct
  include Base
  (* name and greet are now part of Extended *)

  let shout () = String.uppercase_ascii (greet ())
end

let () =
  print_endline "-- Part 4: include vs open --";
  Printf.printf "  %-30s %s\n" "Extended.greet (from include)" (Extended.greet ());
  Printf.printf "  %-30s %s\n" "Extended.shout (new)" (Extended.shout ());
  Printf.printf "  %-30s %s\n" "Extended.name (re-exported)" Extended.name

(* --------------------------------------------------------------------------
   Part 5: Where this lands in an AoC solve
   -------------------------------------------------------------------------- *)

(* Every src/dayNN.ml is already a module exposing parse_input/part1/part2/solve
   -- Day_registry depends on exactly that shape. Adding a dayNN.mli would turn
   that informal convention into a compiler-checked contract, and hide each
   day's helper functions from everything else.

   The payoff of an abstract type shows up when a day has an invariant worth
   protecting: a validated grid, a bounded coordinate, a parsed instruction.
   Below, the counter built above answers a typical question with no knowledge
   of how it stores anything. *)

let () =
  print_endline "-- Part 5: using it --";
  let commands = [ "forward"; "down"; "forward"; "up"; "down"; "forward" ] in
  let counter = StringCounter.(empty |> add_all commands) in
  List.iter
    (fun cmd -> Printf.printf "  %-30s %d\n" cmd (StringCounter.count cmd counter))
    [ "forward"; "down"; "up"; "sideways" ];
  Printf.printf "  %-30s %d commands, %d distinct\n" "totals" (StringCounter.total counter)
    (StringCounter.distinct counter)
