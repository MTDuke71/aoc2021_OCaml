let usage () =
  Printf.eprintf "Usage: dune exec ./bin/main.exe -- dayNN [input-path]\n\nDefault input path: inputs/dayNN.txt\n";
  exit 1

let load_input path = try Ok (Aoc2021.Io.read_file path) with Sys_error message -> Error message

let run day input_path =
  match Aoc2021.Day_registry.find day with
  | None ->
      Printf.eprintf "Unknown day '%s'. Expected day00 .. day25.\n" day;
      exit 1
  | Some entry -> (
      match load_input input_path with
      | Error message ->
          Printf.eprintf "Could not read %s: %s\n" input_path message;
          Printf.eprintf "Create %s locally (it is gitignored) or pass an explicit path.\n" input_path;
          exit 1
      | Ok raw ->
          let parsed = entry.parse_input raw in
          let part1 = entry.part1 parsed in
          let part2 = entry.part2 parsed in
          Printf.printf "%s\n  part1: %s\n  part2: %s\n" entry.name part1 part2)

let () =
  match Array.to_list Sys.argv with
  | _ :: [ day ] -> run day (Aoc2021.Day_registry.default_input_path day)
  | _ :: [ day; input_path ] -> run day input_path
  | _ -> usage ()
