open Core

module Make (Token : sig
  type t [@@deriving sexp, compare]
  include Comparator.S with type t := t
end) = struct
  (* Create a proper Map.Key module for lists of tokens *)
  module TokenListComparator = struct
    module T = struct
      type t = Token.t list [@@deriving sexp, compare]
    end
    include T
    include Comparator.Make(T)
  end
  
  module PrefixMap = Map.M(TokenListComparator)
  type t = Token.t list PrefixMap.t

  let make ngrams =
    List.fold ngrams ~init:(Map.empty (module TokenListComparator)) ~f:(fun acc ng ->
      let prefix, next = Ngram.split_last ng in
      Map.update acc prefix ~f:(function
        | None -> [next]
        | Some lst -> next :: lst))

  let sample dist ~max_length ~init =
    let prefixes = Map.keys dist in
    let start =
      match init with
      | Some lst when List.length lst >= 1 -> lst
      | _ ->
          let random_prefix =
            List.random_element_exn prefixes in
          random_prefix
    in
    let rec loop seq =
      if List.length seq >= max_length then List.take seq max_length
      else
        let context_len = List.length (List.hd_exn prefixes) in
        let context =
          List.drop seq (List.length seq - context_len)
        in
        match Map.find dist context with
        | None -> seq
        | Some nexts ->
            let next = List.random_element_exn nexts in
            loop (seq @ [next])
    in
    loop start
end
