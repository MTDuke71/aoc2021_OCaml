type answer = string

module type Config = sig
  val day : string
end

module Make (Config : Config) = struct
  type parsed = string list

  let parse_input = Io.nonempty_lines

  let part1 _ = Printf.sprintf "TODO: %s part1" Config.day
  let part2 _ = Printf.sprintf "TODO: %s part2" Config.day

  let solve raw =
    let parsed = parse_input raw in
    (part1 parsed, part2 parsed)
end
