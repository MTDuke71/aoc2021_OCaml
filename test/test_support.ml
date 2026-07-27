let failf fmt = Printf.ksprintf failwith fmt

let check_equal label expected actual =
  if actual <> expected then failf "%s: expected %S but got %S" label expected actual

let check_int label expected actual =
  if actual <> expected then failf "%s: expected %d but got %d" label expected actual

let check_lines day lines =
  if lines <> [ "alpha"; "beta" ] then
    failf "%s parse_input: expected [\"alpha\"; \"beta\"] but got a different shape" day

let run_stub day parse_input solve =
  let lines = parse_input "alpha\n\nbeta\n" in
  check_lines day lines;
  let part1, part2 = solve "alpha\nbeta\n" in
  check_equal (day ^ " part1") (Printf.sprintf "TODO: %s part1" day) part1;
  check_equal (day ^ " part2") (Printf.sprintf "TODO: %s part2" day) part2

(* Locate a real puzzle input for an answer-lock test.

   dune runs the test executable with cwd = _build/default/test, so walk up
   looking for an [inputs/] directory. Inputs are gitignored, so this returns
   [None] on a fresh clone and answer-lock tests skip instead of failing. *)
let find_input name =
  let rec search dir remaining =
    if remaining = 0 then None
    else
      let candidate = Filename.concat (Filename.concat dir "inputs") name in
      if Sys.file_exists candidate then Some candidate
      else search (Filename.concat dir Filename.parent_dir_name) (remaining - 1)
  in
  search Filename.current_dir_name 6
