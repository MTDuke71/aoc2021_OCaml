let failf fmt = Printf.ksprintf failwith fmt

let check_equal label expected actual =
  if actual <> expected then failf "%s: expected %S but got %S" label expected actual

let check_lines day lines =
  if lines <> [ "alpha"; "beta" ] then
    failf "%s parse_input: expected [\"alpha\"; \"beta\"] but got a different shape" day

let run_stub day parse_input solve =
  let lines = parse_input "alpha\n\nbeta\n" in
  check_lines day lines;
  let part1, part2 = solve "alpha\nbeta\n" in
  check_equal (day ^ " part1") (Printf.sprintf "TODO: %s part1" day) part1;
  check_equal (day ^ " part2") (Printf.sprintf "TODO: %s part2" day) part2
