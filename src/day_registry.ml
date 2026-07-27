type answer = Day_stub.answer
type parsed = string list

type t = {
  name : string;
  parse_input : string -> parsed;
  part1 : parsed -> answer;
  part2 : parsed -> answer;
  solve : string -> answer * answer;
}

let normalize_day day = String.lowercase_ascii day

let all =
  [
    { name = "day00"; parse_input = Day00.parse_input; part1 = Day00.part1; part2 = Day00.part2; solve = Day00.solve };
    { name = "day01"; parse_input = Day01.parse_input; part1 = Day01.part1; part2 = Day01.part2; solve = Day01.solve };
    { name = "day02"; parse_input = Day02.parse_input; part1 = Day02.part1; part2 = Day02.part2; solve = Day02.solve };
    { name = "day03"; parse_input = Day03.parse_input; part1 = Day03.part1; part2 = Day03.part2; solve = Day03.solve };
    { name = "day04"; parse_input = Day04.parse_input; part1 = Day04.part1; part2 = Day04.part2; solve = Day04.solve };
    { name = "day05"; parse_input = Day05.parse_input; part1 = Day05.part1; part2 = Day05.part2; solve = Day05.solve };
    { name = "day06"; parse_input = Day06.parse_input; part1 = Day06.part1; part2 = Day06.part2; solve = Day06.solve };
    { name = "day07"; parse_input = Day07.parse_input; part1 = Day07.part1; part2 = Day07.part2; solve = Day07.solve };
    { name = "day08"; parse_input = Day08.parse_input; part1 = Day08.part1; part2 = Day08.part2; solve = Day08.solve };
    { name = "day09"; parse_input = Day09.parse_input; part1 = Day09.part1; part2 = Day09.part2; solve = Day09.solve };
    { name = "day10"; parse_input = Day10.parse_input; part1 = Day10.part1; part2 = Day10.part2; solve = Day10.solve };
    { name = "day11"; parse_input = Day11.parse_input; part1 = Day11.part1; part2 = Day11.part2; solve = Day11.solve };
    { name = "day12"; parse_input = Day12.parse_input; part1 = Day12.part1; part2 = Day12.part2; solve = Day12.solve };
    { name = "day13"; parse_input = Day13.parse_input; part1 = Day13.part1; part2 = Day13.part2; solve = Day13.solve };
    { name = "day14"; parse_input = Day14.parse_input; part1 = Day14.part1; part2 = Day14.part2; solve = Day14.solve };
    { name = "day15"; parse_input = Day15.parse_input; part1 = Day15.part1; part2 = Day15.part2; solve = Day15.solve };
    { name = "day16"; parse_input = Day16.parse_input; part1 = Day16.part1; part2 = Day16.part2; solve = Day16.solve };
    { name = "day17"; parse_input = Day17.parse_input; part1 = Day17.part1; part2 = Day17.part2; solve = Day17.solve };
    { name = "day18"; parse_input = Day18.parse_input; part1 = Day18.part1; part2 = Day18.part2; solve = Day18.solve };
    { name = "day19"; parse_input = Day19.parse_input; part1 = Day19.part1; part2 = Day19.part2; solve = Day19.solve };
    { name = "day20"; parse_input = Day20.parse_input; part1 = Day20.part1; part2 = Day20.part2; solve = Day20.solve };
    { name = "day21"; parse_input = Day21.parse_input; part1 = Day21.part1; part2 = Day21.part2; solve = Day21.solve };
    { name = "day22"; parse_input = Day22.parse_input; part1 = Day22.part1; part2 = Day22.part2; solve = Day22.solve };
    { name = "day23"; parse_input = Day23.parse_input; part1 = Day23.part1; part2 = Day23.part2; solve = Day23.solve };
    { name = "day24"; parse_input = Day24.parse_input; part1 = Day24.part1; part2 = Day24.part2; solve = Day24.solve };
    { name = "day25"; parse_input = Day25.parse_input; part1 = Day25.part1; part2 = Day25.part2; solve = Day25.solve };
  ]

let find day =
  let normalized = normalize_day day in
  List.find_opt (fun entry -> String.equal entry.name normalized) all

let default_input_path day = Printf.sprintf "inputs/%s.txt" (normalize_day day)
