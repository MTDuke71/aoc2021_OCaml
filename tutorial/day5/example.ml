(* Tutorial Day 5 — Tail recursion and accumulators
   Run with:  ocaml tutorial/day5/example.ml
          or: dune exec tutorial/day5/example.exe *)

(* Every measurement in this file uses a list big enough to break a naive
   recursion on a default 8 MB stack. On this machine the breaking point for
   the naive sum below is somewhere around 270,000 elements. *)
let big_n = 1_000_000
let big = List.init big_n (fun i -> i)

(* Report whether something survives, without letting the failure end the
   program. Catching Stack_overflow is fine for a demo; it is NOT a technique
   to rely on in real code. *)
let report name f =
  match f () with
  | value -> Printf.printf "  %-34s ok (%d)\n" name value
  | exception Stack_overflow -> Printf.printf "  %-34s STACK OVERFLOW\n" name

(* --------------------------------------------------------------------------
   Part 1: Why this matters — a frame per element
   -------------------------------------------------------------------------- *)

(* Day 2's shape. The recursive call is NOT the last thing that happens: the
   result comes back and then `+` runs. So every element needs a stack frame
   held open, waiting for the answer from deeper down. *)
let rec naive_sum = function [] -> 0 | hd :: tl -> hd + naive_sum tl

(* The accumulator version. `go` calls itself as the very last action, with
   nothing left to do afterwards, so OCaml reuses the frame instead of pushing
   a new one. Constant stack, no matter how long the list is. *)
let sum_tail lst =
  let rec go acc = function [] -> acc | hd :: tl -> go (acc + hd) tl in
  go 0 lst

let () =
  Printf.printf "-- Part 1: %d elements --\n" big_n;
  report "naive_sum (frame per element)" (fun () -> naive_sum big);
  report "sum_tail  (accumulator)" (fun () -> sum_tail big)

(* --------------------------------------------------------------------------
   Part 2: What counts as tail position
   -------------------------------------------------------------------------- *)

(* A call is in TAIL POSITION when its result is the result of the enclosing
   function — nothing is left to do with it. These are all tail positions:
     - the body of a match branch
     - either branch of an if
     - the body of a let ... in
   These are NOT:
     - an operand of an operator      (hd + f tl)
     - an argument to another call    (g (f tl))
     - the body of a try ... with     (the handler must stay on the stack) *)

let rec count_down n = if n = 0 then 0 else count_down (n - 1)

(* Same call, wrapped in try. The handler has to survive the call, so the frame
   cannot be reused and the tail call is destroyed. This surprises people. *)
let rec count_down_try n = if n = 0 then 0 else (try count_down_try (n - 1) with Not_found -> 0)

let () =
  Printf.printf "-- Part 2: %d self-calls --\n" big_n;
  report "plain tail call" (fun () -> count_down big_n);
  report "identical call inside try/with" (fun () -> count_down_try big_n)

(* --------------------------------------------------------------------------
   Part 3: The transformation, and the order it reverses
   -------------------------------------------------------------------------- *)

(* Recipe, mechanical once you have seen it:
     1. add an `acc` parameter to an inner `go`
     2. the base case returns acc instead of a neutral value
     3. the cons case folds the head into acc and recurses
     4. seed acc at the call site

   The catch: an accumulator consumes the list front-to-back and builds its
   result back-to-front, so anything ORDER-SENSITIVE comes out reversed.
   Addition does not care. Building a list does. *)

let map_double_tail lst =
  let rec go acc = function [] -> List.rev acc | hd :: tl -> go ((hd * 2) :: acc) tl in
  go [] lst

(* List.rev is itself tail-recursive and cheap, so "build reversed, then rev"
   is the standard idiom rather than a workaround. *)
let () =
  print_endline "-- Part 3: accumulate then reverse --";
  Printf.printf "  %-34s %s\n" "map_double_tail [1;2;3]"
    (String.concat ";" (List.map string_of_int (map_double_tail [ 1; 2; 3 ])));
  report "map_double_tail on the big list" (fun () -> List.length (map_double_tail big))

(* --------------------------------------------------------------------------
   Part 4: fold_left is safe, fold_right is not
   -------------------------------------------------------------------------- *)

(* fold_left  f acc [a;b;c] = f (f (f acc a) b) c    -- tail-recursive
   fold_right f [a;b;c] acc = f a (f b (f c acc))    -- NOT tail-recursive

   fold_right must reach the END of the list before it can apply f even once,
   so it holds the whole list on the stack. fold_left is just the accumulator
   pattern with the accumulator passed in. Prefer fold_left. *)

let () =
  Printf.printf "-- Part 4: folds over %d elements --\n" big_n;
  report "List.fold_left" (fun () -> List.fold_left ( + ) 0 big);
  report "List.fold_right" (fun () -> List.fold_right ( + ) big 0)

(* --------------------------------------------------------------------------
   Part 5: Which stdlib list functions are safe (OCaml 4.14)
   -------------------------------------------------------------------------- *)

(* This is the part worth memorizing, because the unsafe ones are the ones you
   reach for most. In particular List.map and (@) are NOT tail-recursive in
   4.14 -- they are fine for puzzle-sized data and will bite on a million. *)

let () =
  Printf.printf "-- Part 5: stdlib on %d elements --\n" big_n;
  report "List.map" (fun () -> List.length (List.map succ big));
  report "List.rev_map" (fun () -> List.length (List.rev_map succ big));
  report "List.append (@)" (fun () -> List.length (big @ [ 0 ]));
  report "List.filter" (fun () -> List.length (List.filter (fun _ -> true) big));
  report "List.concat_map" (fun () -> List.length (List.concat_map (fun x -> [ x ]) big));
  report "List.rev" (fun () -> List.length (List.rev big))

(* --------------------------------------------------------------------------
   Part 6: [@tail_mod_cons] — keep the natural shape, lose the stack cost
   -------------------------------------------------------------------------- *)

(* OCaml 4.14 added TAIL RECURSION MODULO CONS. When the only thing left to do
   after the recursive call is to cons onto its result, the compiler can build
   the list as it goes instead of on the way back out. The annotation gives you
   the readable non-accumulator shape AND constant stack, with no List.rev.

   It only applies to this specific pattern -- a constructor wrapping the
   recursive call. It is not a general fix for deep recursion. *)

let[@tail_mod_cons] rec map_double_trmc = function
  | [] -> []
  | hd :: tl -> (hd * 2) :: map_double_trmc tl

(* Identical code, no annotation. *)
let rec map_double_plain = function [] -> [] | hd :: tl -> (hd * 2) :: map_double_plain tl

let () =
  print_endline "-- Part 6: tail recursion modulo cons --";
  report "map_double with [@tail_mod_cons]" (fun () -> List.length (map_double_trmc big));
  report "identical code, no annotation" (fun () -> List.length (map_double_plain big))

(* --------------------------------------------------------------------------
   Part 7: What this looks like in an AoC solve
   -------------------------------------------------------------------------- *)

(* Real puzzle inputs are usually a few thousand lines, so none of this is
   load-bearing for correctness on day 1. It starts to matter when a day has
   you generating or simulating millions of items -- and the accumulator style
   costs nothing extra once it is a habit.

   Counting with a fold is the single most common shape: one pass, constant
   stack, no intermediate list. *)

let count_increases lst =
  let rec go acc = function a :: (b :: _ as rest) -> go (if b > a then acc + 1 else acc) rest | _ -> acc in
  go 0 lst

(* Several statistics in ONE pass by accumulating a tuple, instead of walking
   the list once per statistic. *)
let summarize lst =
  List.fold_left
    (fun (count, total, largest) n -> (count + 1, total + n, max largest n))
    (0, 0, min_int) lst

let () =
  print_endline "-- Part 7: the AoC shape --";
  let depths = [ 199; 200; 208; 210; 200; 207; 240; 269; 260; 263 ] in
  Printf.printf "  %-34s %d  (Day 2 said 7)\n" "count_increases, tail-recursive"
    (count_increases depths);
  let count, total, largest = summarize depths in
  Printf.printf "  %-34s count=%d total=%d max=%d\n" "one-pass summarize" count total largest;
  report "count_increases on the big list" (fun () -> count_increases big)
