(* Tutorial Day 2 — Lists, pattern matching, and recursion
   Run with:  ocaml tutorial/day2/example.ml
          or: dune exec tutorial/day2/example.exe *)

(* A small printing helper used throughout this file. *)
let show name lst =
  Printf.printf "%-10s = [%s]\n" name (String.concat "; " (List.map string_of_int lst))

(* --------------------------------------------------------------------------
   Part 1: Building lists
   -------------------------------------------------------------------------- *)

(* A list literal. Elements are separated by ';' — see Day 1 on semicolons.
   A comma here would NOT be an error: [1, 2, 3] is a ONE-element list holding
   the tuple (1, 2, 3). That mistake compiles silently, so watch for it. *)
let primes = [ 2; 3; 5; 7; 11 ]

(* Every list is built from just two constructors:
     []        the empty list
     hd :: tl  the element `hd` in front of the list `tl`   (pronounced "cons")
   So [1; 2; 3] is literally 1 :: (2 :: (3 :: [])). The literal is sugar. *)
let small = 1 :: 2 :: 3 :: []

(* Cons is O(1) and SHARES the tail: `bigger` does not copy `small`, it just
   points at it. Both remain valid — lists are immutable, so sharing is safe. *)
let bigger = 0 :: small

(* Append (@) must copy the whole left-hand list, so it is O(n). Building a
   list by repeated appending is a classic accidental O(n^2). Prefer cons. *)
let joined = [ 1; 2 ] @ [ 3; 4 ]

let () =
  print_endline "-- Part 1: building lists --";
  show "primes" primes;
  show "small" small;
  show "bigger" bigger;
  show "joined" joined

(* --------------------------------------------------------------------------
   Part 2: Pattern matching
   -------------------------------------------------------------------------- *)

(* `match` inspects the SHAPE of a value. A list has two possible shapes, so
   covering [] and (_ :: _) makes a match exhaustive. More specific patterns
   may come first; they are tried top to bottom. *)
let describe lst =
  match lst with
  | [] -> "empty"
  | [ _ ] -> "exactly one element"
  | [ _; _ ] -> "exactly two elements"
  | _ :: _ -> "three or more"

(* Patterns BIND names as they match, so no accessor functions are needed.
   Here `hd` names the first element and `_` discards the rest. *)
let head_or_zero lst = match lst with [] -> 0 | hd :: _ -> hd

(* A `when` guard adds a boolean test to a pattern. The compiler cannot see
   through a guard when checking exhaustiveness, so always leave a catch-all. *)
let classify n =
  match n with
  | 0 -> "zero"
  | n when n < 0 -> "negative"
  | n when n mod 2 = 0 -> "positive even"
  | _ -> "positive odd"

(* An or-pattern matches several shapes with one branch. *)
let is_vowel c = match c with 'a' | 'e' | 'i' | 'o' | 'u' -> true | _ -> false

let () =
  print_endline "-- Part 2: pattern matching --";
  Printf.printf "describe []        = %s\n" (describe []);
  Printf.printf "describe [7]       = %s\n" (describe [ 7 ]);
  Printf.printf "describe [7;8;9]   = %s\n" (describe [ 7; 8; 9 ]);
  Printf.printf "head_or_zero prime = %d\n" (head_or_zero primes);
  Printf.printf "classify (-4)      = %s\n" (classify (-4));
  Printf.printf "classify 9         = %s\n" (classify 9);
  Printf.printf "is_vowel 'e'       = %b\n" (is_vowel 'e')

(* --------------------------------------------------------------------------
   Part 3: Recursion over lists
   -------------------------------------------------------------------------- *)

(* The standard shape of a recursive list function:
     - a base case answering the empty list
     - a cons case that uses the head and recurses on the tail
   Note `rec`: without it, the name is not in scope in its own body (Day 1). *)
let rec sum lst = match lst with [] -> 0 | hd :: tl -> hd + sum tl

(* `function` is shorthand for `fun x -> match x with`, and is idiomatic when
   the function does nothing but match its last argument. *)
let rec length = function [] -> 0 | _ :: tl -> 1 + length tl

(* Same shape, but building a list on the way back out instead of a number. *)
let rec map_double = function [] -> [] | hd :: tl -> (hd * 2) :: map_double tl

(* An ACCUMULATOR carries the answer down the recursion instead of building it
   up on the way back. This version is tail-recursive, so it runs in constant
   stack space no matter how long the list is. Day 5 covers why that matters. *)
let sum_tail lst =
  let rec go acc lst = match lst with [] -> acc | hd :: tl -> go (acc + hd) tl in
  go 0 lst

let () =
  print_endline "-- Part 3: recursion --";
  Printf.printf "sum primes      = %d\n" (sum primes);
  Printf.printf "length primes   = %d\n" (length primes);
  Printf.printf "sum_tail primes = %d\n" (sum_tail primes);
  show "doubled" (map_double primes)

(* --------------------------------------------------------------------------
   Part 4: Patterns nest, and work on tuples
   -------------------------------------------------------------------------- *)

(* Matching a PAIR of lists at once. The or-pattern `[], _ | _, []` says
   "if either list ran out, stop" — neither side binds a name, which is what
   lets the two alternatives share one branch. *)
let rec zip a b =
  match (a, b) with
  | [], _ | _, [] -> []
  | x :: xs, y :: ys -> (x, y) :: zip xs ys

let () =
  print_endline "-- Part 4: tuples in patterns --";
  let pairs = zip [ 1; 2; 3 ] [ 'a'; 'b'; 'c' ] in
  List.iter (fun (n, c) -> Printf.printf "(%d,%c) " n c) pairs;
  print_newline ()

(* --------------------------------------------------------------------------
   Part 5: Worked example — the shape of AoC 2021 Day 1
   -------------------------------------------------------------------------- *)

(* "How many readings are larger than the one immediately before them?"

   The pattern `a :: (b :: _ as rest)` does three jobs at once:
     a     the first reading
     b     the second reading
     rest  the list FROM the second reading onward
   Recursing on `rest` (not `tl`) steps the window forward by exactly one.
   The `as` keyword names a sub-pattern while still matching inside it. *)
let rec count_increases = function
  | a :: (b :: _ as rest) -> (if b > a then 1 else 0) + count_increases rest
  | _ -> 0

(* Part 2 of that puzzle sums each three-measurement sliding window first.
   Same trick: match three elements, but recurse on the tail starting at the
   second one so the windows overlap. *)
let rec window3_sums = function
  | a :: (b :: c :: _ as rest) -> (a + b + c) :: window3_sums rest
  | _ -> []

(* The sample data from the puzzle text. *)
let depths = [ 199; 200; 208; 210; 200; 207; 240; 269; 260; 263 ]

let () =
  print_endline "-- Part 5: AoC 2021 day 1 shape --";
  show "depths" depths;
  show "windows" (window3_sums depths);
  Printf.printf "increases            = %d  (expected 7)\n" (count_increases depths);
  Printf.printf "window-sum increases = %d  (expected 5)\n"
    (count_increases (window3_sums depths))
