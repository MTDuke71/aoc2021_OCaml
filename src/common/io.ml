let read_file path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () ->
      let length = in_channel_length channel in
      really_input_string channel length)

let nonempty_lines raw = raw |> String.split_on_char '\n' |> List.filter (fun line -> String.trim line <> "")
