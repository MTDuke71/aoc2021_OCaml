let read_file path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () ->
      let length = in_channel_length channel in
      really_input_string channel length)

let nonempty_lines raw = raw |> String.split_on_char '\n' |> List.filter (fun line -> String.trim line <> "")

(* Not here yet: a blank-line paragraph splitter, [chunks : string -> string list
   list], for inputs that come in groups (AoC 2021 day 4's bingo boards, and
   several later days). A working implementation lives in
   tutorial/day4/example.ml -- promote it into this file on the first day that
   actually needs it, rather than carrying an unused helper. *)
