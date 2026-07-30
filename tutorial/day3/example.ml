(* Tutorial Day 3 — Records, variants, option, and result
   Run with:  ocaml tutorial/day3/example.ml
          or: dune exec tutorial/day3/example.exe *)

(* --------------------------------------------------------------------------
   Part 1: Records — a fixed set of named fields (an "AND" type)
   -------------------------------------------------------------------------- *)

(* A record type declares named, typed fields. A value of this type has an
   x AND a y — always both, never one. Rust would call this a struct. *)
type point = { x : int; y : int }

(* Construction names every field. Omit one and it is a compile error, not a
   silently-zeroed field. *)
let origin = { x = 0; y = 0 }

(* Field access uses a dot. *)
let dist_sq p = (p.x * p.x) + (p.y * p.y)

(* FUNCTIONAL UPDATE. `{ p with ... }` builds a NEW record, copying every field
   you did not mention. It does not mutate `p` — records are immutable by
   default, so `origin` is untouched below. *)
let shifted = { origin with x = 3 }

(* Field PUNNING: when a variable already has the field's name, `{ x; y }` is
   shorthand for `{ x = x; y = y }`. *)
let make_point x y = { x; y }

(* Patterns destructure records by field name. Listing every field is required
   unless you add `_` to say "deliberately ignoring the rest". *)
let describe_point { x; y } =
  if x = 0 && y = 0 then "the origin" else Printf.sprintf "(%d, %d)" x y

let x_only { x; _ } = x

let () =
  print_endline "-- Part 1: records --";
  Printf.printf "origin        = %s\n" (describe_point origin);
  Printf.printf "shifted       = %s\n" (describe_point shifted);
  Printf.printf "make_point    = %s\n" (describe_point (make_point 4 5));
  Printf.printf "dist_sq (3,4) = %d\n" (dist_sq (make_point 3 4));
  Printf.printf "x_only        = %d\n" (x_only shifted)

(* --------------------------------------------------------------------------
   Part 2: Variants — a choice between alternatives (an "OR" type)
   -------------------------------------------------------------------------- *)

(* A variant lists alternatives; a value is exactly ONE of them. This is Rust's
   enum, and it is why Day 2's exhaustiveness checking matters so much: the
   compiler knows the complete list of cases, so it can tell when you missed
   one. Constructors must be Capitalized. *)
type direction = North | South | East | West

let step = function
  | North -> make_point 0 1
  | South -> make_point 0 (-1)
  | East -> make_point 1 0
  | West -> make_point (-1) 0

(* Each constructor may carry a payload, and the payloads need not match. This
   is the part records cannot do: the shape of the data varies by case. *)
type shape =
  | Circle of float (* radius *)
  | Rect of float * float (* width, height *)
  | Square of float

(* Matching a variant binds the payload in the same step. *)
let area = function
  | Circle r -> Float.pi *. r *. r
  | Rect (w, h) -> w *. h
  | Square s -> s *. s

(* Variants may be RECURSIVE — a case can refer to the type being defined.
   This is how you build trees without any pointer or Box juggling. *)
type tree = Leaf | Node of tree * int * tree

let rec tree_sum = function Leaf -> 0 | Node (l, v, r) -> tree_sum l + v + tree_sum r

let sample_tree = Node (Node (Leaf, 1, Leaf), 2, Node (Leaf, 3, Leaf))

let () =
  print_endline "-- Part 2: variants --";
  List.iter
    (fun (name, d) -> Printf.printf "step %-5s     = %s\n" name (describe_point (step d)))
    [ ("North", North); ("South", South); ("East", East); ("West", West) ];
  Printf.printf "area (Circle 1) = %.4f\n" (area (Circle 1.0));
  Printf.printf "area (Rect 3 4) = %.1f\n" (area (Rect (3.0, 4.0)));
  Printf.printf "area (Square 5) = %.1f\n" (area (Square 5.0));
  Printf.printf "tree_sum        = %d\n" (tree_sum sample_tree)

(* --------------------------------------------------------------------------
   Part 3: option — "possibly absent", and just an ordinary variant
   -------------------------------------------------------------------------- *)

(* option is NOT special syntax. It is a plain variant in the standard library:
     type 'a option = None | Some of 'a
   Note the 'a from Day 2 — that is what makes it work for any element type.
   OCaml has no null, so this is how absence is expressed, and the type makes
   it impossible to forget. *)

let safe_div a b = if b = 0 then None else Some (a / b)

(* Consuming an option means matching it, and exhaustiveness means the compiler
   will not let you skip the None case. *)
let show_div a b =
  match safe_div a b with
  | None -> Printf.sprintf "%d / %d = undefined" a b
  | Some q -> Printf.sprintf "%d / %d = %d" a b q

(* The Option module carries combinators for the routine shapes, so you do not
   write a match every time. *)
let () =
  print_endline "-- Part 3: option --";
  print_endline (show_div 10 2);
  print_endline (show_div 10 0);
  Printf.printf "Option.value ~default   = %d\n" (Option.value (safe_div 10 0) ~default:(-1));
  Printf.printf "Option.map (( * ) 2)    = %s\n"
    (match Option.map (( * ) 2) (safe_div 10 2) with None -> "None" | Some n -> string_of_int n);
  Printf.printf "int_of_string_opt \"42\"  = %d\n" (Option.value (int_of_string_opt "42") ~default:0);
  Printf.printf "int_of_string_opt \"4x\"  = %b\n" (Option.is_none (int_of_string_opt "4x"));
  (* Stdlib functions ending in _opt return an option instead of raising. *)
  Printf.printf "List.find_opt (> 3)     = %s\n"
    (match List.find_opt (fun n -> n > 3) [ 1; 2; 5; 7 ] with
    | None -> "none"
    | Some n -> string_of_int n)

(* --------------------------------------------------------------------------
   Part 4: result — "failed, and here is why"
   -------------------------------------------------------------------------- *)

(* result is also an ordinary variant, with TWO type parameters:
     type ('a, 'b) result = Ok of 'a | Error of 'b
   Reach for result when the failure has something to say, and option when
   "absent" is the whole story. Note OCaml spells the failure case `Error`,
   where Rust spells it `Err`. *)

let parse_int text =
  match int_of_string_opt (String.trim text) with
  | Some n -> Ok n
  | None -> Error (Printf.sprintf "not a number: %S" text)

let render = function Ok n -> Printf.sprintf "Ok %d" n | Error msg -> "Error: " ^ msg

let () =
  print_endline "-- Part 4: result --";
  print_endline (render (parse_int " 42 "));
  print_endline (render (parse_int "twelve"))

(* --------------------------------------------------------------------------
   Part 5: All three together — the shape of AoC 2021 day 2, part one
   -------------------------------------------------------------------------- *)

(* The puzzle input is lines like "forward 5" / "down 5" / "up 3". This is the
   canonical combination you will reach for over and over:
     - a VARIANT for the command, because a line is one of three things
     - a RECORD for the accumulated state, because it is several things at once
     - a RESULT for parsing, because a bad line should explain itself *)

type command = Forward of int | Down of int | Up of int
type position = { horizontal : int; depth : int }

(* Parsing narrows an untrusted string into a value that cannot be wrong. Once
   a line is a `command`, no later code has to re-check it — that is the payoff
   of defining the type. *)
let parse_command line =
  match String.split_on_char ' ' (String.trim line) with
  | [ word; amount ] -> (
      match int_of_string_opt amount with
      | None -> Error (Printf.sprintf "bad amount in %S" line)
      | Some n -> (
          match word with
          | "forward" -> Ok (Forward n)
          | "down" -> Ok (Down n)
          | "up" -> Ok (Up n)
          | other -> Error (Printf.sprintf "unknown command %S" other)))
  | _ -> Error (Printf.sprintf "expected two words in %S" line)

(* Applying a command returns a NEW position via functional update. *)
let apply pos = function
  | Forward n -> { pos with horizontal = pos.horizontal + n }
  | Down n -> { pos with depth = pos.depth + n }
  | Up n -> { pos with depth = pos.depth - n }

(* Turn a list of results into a result of a list: all commands, or the first
   error. Note the shape — this is Day 2's recursion over a list, with the two
   result cases threaded through. *)
let rec sequence = function
  | [] -> Ok []
  | line :: rest -> (
      match parse_command line with
      | Error msg -> Error msg
      | Ok cmd -> (
          match sequence rest with Error msg -> Error msg | Ok cmds -> Ok (cmd :: cmds)))

(* The sample course from the puzzle text. *)
let sample = [ "forward 5"; "down 5"; "forward 8"; "up 3"; "down 8"; "forward 2" ]

let () =
  print_endline "-- Part 5: AoC 2021 day 2 (part one) shape --";
  (match sequence sample with
  | Error msg -> Printf.printf "parse failed: %s\n" msg
  | Ok commands ->
      let final = List.fold_left apply { horizontal = 0; depth = 0 } commands in
      Printf.printf "horizontal=%d depth=%d product=%d  (expected 150)\n" final.horizontal
        final.depth (final.horizontal * final.depth));
  (* One bad line rejects the whole course, with a reason. *)
  match sequence [ "forward 5"; "sideways 4" ] with
  | Ok _ -> print_endline "unexpectedly accepted"
  | Error msg -> Printf.printf "rejected: %s\n" msg
