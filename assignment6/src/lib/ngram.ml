open Core

type 'a t = 'a list [@@deriving sexp, compare]

let parse n tokens =
  let rec aux acc = function
    | l when List.length l < n -> List.rev acc
    | l ->
        let ng = List.take l n in
        aux (ng :: acc) (List.tl_exn l)
  in
  aux [] tokens

let split_last ngram =
  let prefix = List.drop_last_exn ngram in
  let last = List.last_exn ngram in
  (prefix, last)

let count_frequencies ngrams =
  (* Create a proper Map.Key module for string list comparison *)
  let module StringListComparator = struct
    module T = struct
      type t = string list [@@deriving sexp, compare]
    end
    include T
    include Comparator.Make(T)
  end in
  List.fold ngrams ~init:(Map.empty (module StringListComparator)) ~f:(fun acc ng ->
    Map.update acc ng ~f:(function
      | None -> 1
      | Some c -> c + 1))
  |> Map.to_alist
  |> List.map ~f:(fun (ngram, freq) -> (freq, ngram))

let k_most_to_string ~k freq_list =
  freq_list
  |> List.sort ~compare:(fun (f1, ng1) (f2, ng2) ->
       match Int.descending f1 f2 with
       | 0 -> [%compare: string list] ng1 ng2
       | c -> c)
  |> Fn.flip List.take k
  |> List.map ~f:(fun (freq, ngram) ->
       Printf.sprintf "((ngram(%s))(frequency %d))"
         (String.concat ~sep:" " ngram) freq)
  |> String.concat ~sep:""
  |> fun s -> "(" ^ s ^ ")\n"
