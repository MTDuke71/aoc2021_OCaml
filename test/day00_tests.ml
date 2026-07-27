(* Day 0 tests: puzzle examples plus real-input answer locks.
   Mirrors ../aoc2020_Prolog/test/day00_tests.pl. *)

let day = "day00"

let test_parse_input () =
  let parsed = Aoc2021.Day00.parse_input "12\n\n14\n1969\n" in
  if parsed <> [ "12"; "14"; "1969" ] then Test_support.failf "%s parse_input: unexpected shape" day

(* Every worked example from the problem statement. *)
let test_fuel () =
  List.iter
    (fun (mass, expected) ->
      Test_support.check_int (Printf.sprintf "%s fuel %d" day mass) expected (Aoc2021.Day00.fuel mass))
    [ (12, 2); (14, 2); (1969, 654); (100756, 33583) ]

let test_total_fuel () =
  List.iter
    (fun (mass, expected) ->
      Test_support.check_int (Printf.sprintf "%s total_fuel %d" day mass) expected (Aoc2021.Day00.total_fuel mass))
    [ (14, 2); (1969, 966); (100756, 50346) ]

let test_part_examples () =
  Test_support.check_equal (day ^ " part1 example")
    (string_of_int (2 + 2 + 654 + 33583))
    (Aoc2021.Day00.part1 (Aoc2021.Day00.parse_input "12\n14\n1969\n100756\n"));
  Test_support.check_equal (day ^ " part2 example")
    (string_of_int (2 + 966 + 50346))
    (Aoc2021.Day00.part2 (Aoc2021.Day00.parse_input "14\n1969\n100756\n"))

(* Answer locks: any refactor that changes the real answers fails loudly. *)
let test_real_input () =
  match Test_support.find_input "day00.txt" with
  | None -> Printf.printf "  skip %s answer locks (inputs/day00.txt not present)\n" day
  | Some path ->
      let part1, part2 = Aoc2021.Day00.solve (Aoc2021.Io.read_file path) in
      Test_support.check_equal (day ^ " part1 real") "3481005" part1;
      Test_support.check_equal (day ^ " part2 real") "5218616" part2

let run () =
  test_parse_input ();
  test_fuel ();
  test_total_fuel ();
  test_part_examples ();
  test_real_input ()
