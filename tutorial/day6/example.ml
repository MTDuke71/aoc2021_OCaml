(* Tutorial Day 6 — Sets, maps, and grid/state modeling
   Run with:  ocaml tutorial/day6/example.ml
          or: dune exec tutorial/day6/example.exe *)

(* --------------------------------------------------------------------------
   Part 1: Set.Make — your first functor
   -------------------------------------------------------------------------- *)

(* Set.Make is a FUNCTOR: a module that takes a module and returns a module.
   Feed it something providing `type t` and `compare`, and you get a Set
   specialized to that element type. Stdlib's `Int` module already qualifies.

   This is OCaml's answer to generics-over-a-comparison. Rust would write
   BTreeSet<i32> and get the ordering from the Ord trait; OCaml has no
   typeclasses, so you hand the comparison over explicitly, once, here. *)

module IntSet = Set.Make (Int)

let show_ints label lst =
  Printf.printf "  %-32s %s\n" label (String.concat "," (List.map string_of_int lst))

let () =
  print_endline "-- Part 1: sets --";
  let s = IntSet.of_list [ 3; 1; 4; 1; 5; 9; 2; 6; 5 ] in
  (* elements comes back SORTED and DEDUPED -- it is a balanced tree, not a hash *)
  show_ints "of_list |> elements" (IntSet.elements s);
  Printf.printf "  %-32s %d\n" "cardinal" (IntSet.cardinal s);
  Printf.printf "  %-32s %b\n" "mem 4" (IntSet.mem 4 s);
  let t = IntSet.of_list [ 4; 5; 6; 7 ] in
  show_ints "union" (IntSet.elements (IntSet.union s t));
  show_ints "inter" (IntSet.elements (IntSet.inter s t));
  show_ints "diff" (IntSet.elements (IntSet.diff s t));
  (* Sets are PERSISTENT: add returns a new set, the original is untouched. *)
  let bigger = IntSet.add 100 s in
  Printf.printf "  %-32s original=%d new=%d\n" "add is persistent" (IntSet.cardinal s)
    (IntSet.cardinal bigger)

(* --------------------------------------------------------------------------
   Part 2: Map.Make — the same idea, with values attached
   -------------------------------------------------------------------------- *)

module IntMap = Map.Make (Int)

(* `update` is the one to learn. It takes the key and a function from the
   CURRENT binding (an option, per Day 3) to the new binding, so insert-or-
   increment is a single traversal instead of a find followed by an add. *)
let count_occurrences lst =
  List.fold_left
    (fun acc item -> IntMap.update item (function None -> Some 1 | Some n -> Some (n + 1)) acc)
    IntMap.empty lst

let () =
  print_endline "-- Part 2: maps --";
  let counts = count_occurrences [ 3; 1; 4; 1; 5; 9; 2; 6; 5; 3; 5 ] in
  Printf.printf "  %-32s %s\n" "frequency count"
    (String.concat " "
       (List.map (fun (k, v) -> Printf.sprintf "%d:%d" k v) (IntMap.bindings counts)));
  (* find_opt, not find -- find raises Not_found. Day 3's _opt convention. *)
  Printf.printf "  %-32s %s\n" "find_opt 5"
    (match IntMap.find_opt 5 counts with None -> "absent" | Some n -> string_of_int n);
  Printf.printf "  %-32s %s\n" "find_opt 42"
    (match IntMap.find_opt 42 counts with None -> "absent" | Some n -> string_of_int n)

(* --------------------------------------------------------------------------
   Part 3: Custom key modules — grid coordinates
   -------------------------------------------------------------------------- *)

(* To key a Set or Map by something the stdlib has no module for, supply your
   own. The requirement is small: a type and a compare returning </=/> 0. *)

module Coord = struct
  type t = int * int

  (* Stdlib's polymorphic compare handles tuples structurally. It is convenient
     and slightly slower than a hand-written one; for AoC that is the right
     trade. Writing it out by hand would be:
       let compare (x1, y1) (x2, y2) =
         match Int.compare x1 x2 with 0 -> Int.compare y1 y2 | c -> c *)
  let compare = compare
end

module CoordSet = Set.Make (Coord)

let show_coords label coords =
  Printf.printf "  %-32s %s\n" label
    (String.concat " " (List.map (fun (x, y) -> Printf.sprintf "(%d,%d)" x y) coords))

let () =
  print_endline "-- Part 3: coordinate keys --";
  let visited = CoordSet.of_list [ (1, 2); (0, 0); (1, 2); (0, 1) ] in
  show_coords "deduped and ordered" (CoordSet.elements visited)

(* --------------------------------------------------------------------------
   Part 4: Hashtbl — mutable, and one sharp edge
   -------------------------------------------------------------------------- *)

(* Hashtbl is the mutable, hash-based alternative: O(1) average instead of
   O(log n), but no persistence and no ordering. Reach for it when you are
   building state imperatively and never need an old version.

   THE TRAP: Hashtbl.add does not overwrite. It SHADOWS, keeping the previous
   binding underneath, so a later remove uncovers it. Use `replace` unless you
   specifically want a multi-map. *)

let () =
  print_endline "-- Part 4: Hashtbl add vs replace --";
  let h = Hashtbl.create 16 in
  Hashtbl.add h "k" 1;
  Hashtbl.add h "k" 2;
  Printf.printf "  %-32s length=%d find=%d\n" "after two adds" (Hashtbl.length h)
    (Hashtbl.find h "k");
  Hashtbl.remove h "k";
  Printf.printf "  %-32s length=%d find=%s\n" "after ONE remove" (Hashtbl.length h)
    (match Hashtbl.find_opt h "k" with None -> "gone" | Some v -> string_of_int v);
  let h2 = Hashtbl.create 16 in
  Hashtbl.replace h2 "k" 1;
  Hashtbl.replace h2 "k" 2;
  Printf.printf "  %-32s length=%d find=%d\n" "after two replaces" (Hashtbl.length h2)
    (Hashtbl.find h2 "k")

(* --------------------------------------------------------------------------
   Part 5: Modeling a grid
   -------------------------------------------------------------------------- *)

(* Two representations, and the choice is about DENSITY:
     - dense and fixed size  -> an array of strings, O(1) indexing
     - sparse or unbounded   -> a Map keyed by coordinate, O(log n)
   AoC uses both. A 100x100 heightmap wants the array; a few thousand scattered
   points on a notionally huge plane wants the map. *)

(* Column 2 is a solid wall, and row 2 walls off the left half, so this grid
   holds exactly three disconnected open regions: top-left, bottom-left, and
   the whole right side. *)
let grid = [| "..#.."; "..#.."; "###.."; "..#.."; "..#.." |]
let height = Array.length grid
let width = String.length grid.(0)

(* Bounds-checked lookup returning an option, so callers cannot forget the edge
   cases. This one function removes most off-by-one grid bugs. *)
let at (x, y) = if x < 0 || y < 0 || x >= width || y >= height then None else Some grid.(y).[x]

let neighbors (x, y) = [ (x + 1, y); (x - 1, y); (x, y + 1); (x, y - 1) ]

(* Out of bounds and "wall" collapse to the same answer here, which is exactly
   what the option forces you to decide explicitly. *)
let is_open pos = match at pos with Some '.' -> true | Some _ | None -> false

(* Flood fill: the single most common AoC shape. A Set tracks what has been
   seen, a list acts as the frontier. Tail-recursive, per Day 5. *)
let reachable_from start =
  let rec go seen = function
    | [] -> seen
    | pos :: rest ->
        if CoordSet.mem pos seen then go seen rest
        else if not (is_open pos) then go seen rest
        else go (CoordSet.add pos seen) (neighbors pos @ rest)
  in
  go CoordSet.empty [ start ]

let () =
  print_endline "-- Part 5: grid modeling --";
  Array.iter (fun row -> Printf.printf "    %s\n" row) grid;
  Printf.printf "  %-32s %dx%d\n" "dimensions" width height;
  Printf.printf "  %-32s %s\n" "at (2,0)"
    (match at (2, 0) with None -> "out of bounds" | Some c -> Printf.sprintf "%c" c);
  Printf.printf "  %-32s %s\n" "at (99,0)"
    (match at (99, 0) with None -> "out of bounds" | Some c -> Printf.sprintf "%c" c);
  (* Three starts, three disjoint regions -- the walls really do separate them,
     and the same fill finds a different region from each. *)
  List.iter
    (fun start ->
      let x, y = start in
      Printf.printf "  %-32s %d cells\n"
        (Printf.sprintf "flood fill from (%d,%d)" x y)
        (CoordSet.cardinal (reachable_from start)))
    [ (0, 0); (0, 4); (4, 0) ];
  (* And a start that is itself a wall reaches nothing at all. *)
  Printf.printf "  %-32s %d cells\n" "flood fill from a wall (2,0)"
    (CoordSet.cardinal (reachable_from (2, 0)))

(* --------------------------------------------------------------------------
   Part 6: Sparse counting — the other half of grid work
   -------------------------------------------------------------------------- *)

(* When points are scattered rather than packed, count them into a Map instead
   of allocating a grid. This is the shape for "how many cells are covered more
   than once", without ever knowing the extent of the plane in advance. *)

module CoordMap = Map.Make (Coord)

let mark_points points =
  List.fold_left
    (fun acc p -> CoordMap.update p (function None -> Some 1 | Some n -> Some (n + 1)) acc)
    CoordMap.empty points

let () =
  print_endline "-- Part 6: sparse counting --";
  let points = [ (0, 9); (1, 9); (2, 9); (1, 9); (2, 9); (2, 9) ] in
  let marks = mark_points points in
  Printf.printf "  %-32s %d\n" "distinct points" (CoordMap.cardinal marks);
  let overlapping = CoordMap.filter (fun _ count -> count >= 2) marks in
  Printf.printf "  %-32s %d\n" "covered 2+ times" (CoordMap.cardinal overlapping);
  show_coords "those points" (List.map fst (CoordMap.bindings overlapping))
