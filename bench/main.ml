let time label thunk =
  let started = Unix.gettimeofday () in
  let result = thunk () in
  let elapsed_ms = (Unix.gettimeofday () -. started) *. 1000.0 in
  Printf.printf "  %-5s %8.3f ms\n" label elapsed_ms;
  result

let run day input_path =
  match Aoc2021.Day_registry.find day with
  | None ->
      Printf.eprintf "Unknown day '%s'. Expected day00 .. day25.\n" day;
      exit 1
  | Some entry -> (
      try
        let raw = Aoc2021.Io.read_file input_path in
        let parsed = time "parse" (fun () -> entry.parse_input raw) in
        let part1 = time "part1" (fun () -> entry.part1 parsed) in
        let part2 = time "part2" (fun () -> entry.part2 parsed) in
        Printf.printf "%s\n  result part1=%s\n  result part2=%s\n" entry.name part1 part2
      with
      | Sys_error message ->
          Printf.eprintf "Could not read %s: %s\n" input_path message;
          exit 1)

let () =
  match Array.to_list Sys.argv with
  | _ :: [ day ] -> run day (Aoc2021.Day_registry.default_input_path day)
  | _ :: [ day; input_path ] -> run day input_path
  | _ ->
      Printf.eprintf
        "Usage: dune exec ./bench/main.exe -- dayNN [input-path]\n";
      exit 1
