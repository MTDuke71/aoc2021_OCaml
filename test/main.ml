let suites =
  [
    ("day00", Day00_tests.run);
    ("day01", Day01_tests.run);
    ("day02", Day02_tests.run);
    ("day03", Day03_tests.run);
    ("day04", Day04_tests.run);
    ("day05", Day05_tests.run);
    ("day06", Day06_tests.run);
    ("day07", Day07_tests.run);
    ("day08", Day08_tests.run);
    ("day09", Day09_tests.run);
    ("day10", Day10_tests.run);
    ("day11", Day11_tests.run);
    ("day12", Day12_tests.run);
    ("day13", Day13_tests.run);
    ("day14", Day14_tests.run);
    ("day15", Day15_tests.run);
    ("day16", Day16_tests.run);
    ("day17", Day17_tests.run);
    ("day18", Day18_tests.run);
    ("day19", Day19_tests.run);
    ("day20", Day20_tests.run);
    ("day21", Day21_tests.run);
    ("day22", Day22_tests.run);
    ("day23", Day23_tests.run);
    ("day24", Day24_tests.run);
    ("day25", Day25_tests.run);
  ]

let () =
  List.iter
    (fun (day, run) ->
      try
        run ();
        Printf.printf "ok %s\n" day
      with exn ->
        Printf.eprintf "FAILED %s: %s\n" day (Printexc.to_string exn);
        raise exn)
    suites;
  Printf.printf "Ran %d scaffold day tests\n" (List.length suites)
