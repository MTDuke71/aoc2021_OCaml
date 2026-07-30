(* Tutorial Day 4 — String parsing and lightweight I/O helpers
   Run with:  ocaml tutorial/day4/example.ml
          or: dune exec tutorial/day4/example.exe *)

(* --------------------------------------------------------------------------
   Part 1: Strings are immutable
   -------------------------------------------------------------------------- *)

(* An OCaml `string` is an immutable, GC-managed sequence of BYTES. There is no
   borrowed-vs-owned distinction: no String/&str split, no lifetimes, no clone.
   You cannot assign to s.[i] — mutation requires the separate `Bytes` type. *)

let () =
  print_endline "-- Part 1: strings --";
  let s = "forward 5" in
  Printf.printf "length          = %d\n" (String.length s);
  Printf.printf "s.[0]           = %c\n" s.[0];
  Printf.printf "sub 0 7         = %S\n" (String.sub s 0 7);
  Printf.printf "concat with ^   = %S\n" ("a" ^ "-" ^ "b");
  Printf.printf "String.concat   = %S\n" (String.concat ", " [ "a"; "b"; "c" ]);
  (* Structural equality works directly on strings — no strcmp, no .equals. *)
  Printf.printf "equality        = %b\n" ("abc" = "abc");
  (* Indexing is BYTES, not characters. Fine for AoC (ASCII), wrong for UTF-8. *)
  Printf.printf "starts_with     = %b\n" (String.starts_with ~prefix:"for" s);
  Printf.printf "for_all is bit  = %b\n" (String.for_all (fun c -> c = '0' || c = '1') "10110")

(* --------------------------------------------------------------------------
   Part 2: Splitting and trimming — the daily workhorses
   -------------------------------------------------------------------------- *)

(* String.split_on_char is the one you will reach for constantly. Note it
   splits on a CHAR, not a string — the stdlib has no split-on-substring. *)

(* GOTCHA: splitting on ' ' produces EMPTY strings wherever separators repeat.
   AoC grids are often column-aligned with double spaces, so filter them out. *)
let ws_ints line =
  line |> String.trim |> String.split_on_char ' '
  |> List.filter (fun piece -> piece <> "")
  |> List.map int_of_string

(* String.trim removes leading/trailing whitespace INCLUDING '\r'. This is what
   makes parsing survive a Windows CRLF input file — without it, int_of_string
   chokes on the invisible carriage return at the end of every line. *)
let () =
  print_endline "-- Part 2: splitting and trimming --";
  let row = "22 13  17   11" in
  Printf.printf "naive split     = %d pieces (empties!)\n"
    (List.length (String.split_on_char ' ' row));
  Printf.printf "filtered        = %s\n"
    (String.concat "+" (List.map string_of_int (ws_ints row)));
  Printf.printf "CRLF with trim  = %d\n" (int_of_string (String.trim "42\r"));
  Printf.printf "CRLF no trim    = %s\n"
    (match int_of_string_opt "42\r" with None -> "None — would have raised" | Some n -> string_of_int n)

(* --------------------------------------------------------------------------
   Part 3: Converting text to values
   -------------------------------------------------------------------------- *)

(* Day 3's _opt convention applies here: prefer int_of_string_opt when the input
   might legitimately be malformed, and plain int_of_string when a bad line
   means YOUR bug and crashing is a fine report. *)

(* A digit character to its value. Chars are bytes, so subtract '0'. *)
let digit_of_char c = Char.code c - Char.code '0'

(* int_of_string understands 0b / 0o / 0x prefixes, which turns AoC's binary
   diagnostic lines into integers with no bit-twiddling at all. *)
let int_of_binary text = int_of_string ("0b" ^ String.trim text)

let () =
  print_endline "-- Part 3: converting --";
  (* IMPORTANT: int_of_string does NOT trim for you. Surrounding whitespace is
     a parse failure, which is why String.trim shows up in every parser here. *)
  Printf.printf "\"  17  \" raw      = %s\n"
    (match int_of_string_opt "  17  " with None -> "None — untrimmed!" | Some n -> string_of_int n);
  Printf.printf "\"  17  \" trimmed  = %s\n"
    (match int_of_string_opt (String.trim "  17  ") with
    | None -> "None"
    | Some n -> string_of_int n);
  Printf.printf "digit_of_char '7' = %d\n" (digit_of_char '7');
  Printf.printf "int_of_binary     = %d\n" (int_of_binary "10110");
  (* Walking characters: String.to_seq, or fold_left when accumulating. *)
  Printf.printf "digits of \"3141\"  = %s\n"
    (String.to_seq "3141" |> Seq.map digit_of_char |> List.of_seq |> List.map string_of_int
   |> String.concat ",");
  Printf.printf "count of '1'      = %d\n"
    (String.fold_left (fun acc c -> if c = '1' then acc + 1 else acc) 0 "10110")

(* --------------------------------------------------------------------------
   Part 4: Scanf — format strings that parse
   -------------------------------------------------------------------------- *)

(* Scanf.sscanf reads a string against a FORMAT and hands the pieces to a
   function. For AoC's fixed-shape lines this beats hand-splitting by a mile:
   the literal text in the format (here ',' and " -> ") must match exactly. *)

type segment = { x1 : int; y1 : int; x2 : int; y2 : int }

(* Scanf RAISES on a mismatch, so wrap it to get Day 3's result type back. *)
let parse_segment line =
  try Ok (Scanf.sscanf (String.trim line) "%d,%d -> %d,%d" (fun x1 y1 x2 y2 -> { x1; y1; x2; y2 }))
  with Scanf.Scan_failure msg -> Error msg | Failure msg -> Error msg | End_of_file -> Error "ran out"

let string_of_segment { x1; y1; x2; y2 } = Printf.sprintf "(%d,%d)->(%d,%d)" x1 y1 x2 y2

let () =
  print_endline "-- Part 4: Scanf --";
  (* CAUTION: %s in Scanf reads up to the next WHITESPACE, not the whole line. *)
  Scanf.sscanf "forward 5" "%s %d" (fun word n -> Printf.printf "command       = %s/%d\n" word n);
  (match parse_segment "0,9 -> 5,9" with
  | Ok seg -> Printf.printf "segment       = %s\n" (string_of_segment seg)
  | Error msg -> Printf.printf "segment failed: %s\n" msg);
  match parse_segment "not a segment" with
  | Ok seg -> Printf.printf "unexpected %s\n" (string_of_segment seg)
  | Error _ -> print_endline "bad line      = rejected, as a result"

(* --------------------------------------------------------------------------
   Part 5: I/O helpers, and the one this repo is missing
   -------------------------------------------------------------------------- *)

(* src/common/io.ml already gives you two:
     Io.read_file       : string -> string        (whole file, binary mode)
     Io.nonempty_lines  : string -> string list   (split, drop blank lines)
   Reading in BINARY mode is deliberate — it avoids the platform newline
   translation, and String.trim cleans up the '\r' instead.

   The helper AoC needs constantly and io.ml does NOT have yet is "split into
   paragraphs on blank lines". AoC 2021 needs it on day 4 (bingo boards), and
   several later days. Here it is: *)

let chunks raw =
  let flush current groups = if current = [] then groups else List.rev current :: groups in
  let current, groups =
    raw |> String.split_on_char '\n' |> List.map String.trim
    |> List.fold_left
         (fun (current, groups) line ->
           if line = "" then ([], flush current groups) else (line :: current, groups))
         ([], [])
  in
  List.rev (flush current groups)

(* A quoted string literal {| ... |} takes its contents RAW — no backslash
   escaping, no quote doubling. Ideal for embedding sample input verbatim. *)
let sample_input =
  {|
7,4,9,5,11

22 13 17 11  0
 8  2 23  4 24

 3 15  0  2 22
 9 18 13 17  5
|}

let () =
  print_endline "-- Part 5: chunks and a full parse --";
  let paragraphs = chunks sample_input in
  Printf.printf "paragraphs        = %d\n" (List.length paragraphs);
  match paragraphs with
  | [] -> print_endline "no input"
  | draws_block :: board_blocks ->
      (* First paragraph: one line of comma-separated draws. *)
      let draws =
        String.concat "" draws_block |> String.split_on_char ',' |> List.map int_of_string
      in
      Printf.printf "draws             = %s\n"
        (String.concat "," (List.map string_of_int draws));
      (* Remaining paragraphs: each a grid of whitespace-separated ints. *)
      List.iteri
        (fun i block ->
          let rows = List.map ws_ints block in
          let total = List.fold_left (fun acc row -> acc + List.fold_left ( + ) 0 row) 0 rows in
          Printf.printf "board %d           = %d rows, sum %d\n" i (List.length rows) total)
        board_blocks
