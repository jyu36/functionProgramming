open Core

let get_sanitized_words filename =
  In_channel.read_all filename
  |> String.lowercase
  |> String.split_on_chars ~on:[' '; '\n'; '\t'; '\r']
  |> List.filter_map ~f:(fun w ->
       let cleaned = String.filter w ~f:Char.is_alphanum in
       if String.is_empty cleaned then None else Some cleaned)

