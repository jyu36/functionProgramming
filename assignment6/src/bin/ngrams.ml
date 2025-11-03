(*
  FPSE Assignment 6

  Name                  :
  List of Collaborators :
*)

open Core

(*
  The following two functions `sample` and `most_frequent` are stubs
  for your implementation.
*)

let sample n corpus_filename max_length init =
  let words = Utils.get_sanitized_words corpus_filename in
  let ngrams = Ngram.parse n words in
  let module D = Distribution.Make(String) in
  let dist = D.make ngrams in
  let output = D.sample dist ~max_length ~init in
  printf "%s\n" (String.concat ~sep:" " output)

let most_frequent n corpus_filename k =
  let words = Utils.get_sanitized_words corpus_filename in
  let ngrams = Ngram.parse n words in
  let freqs = Ngram.count_frequencies ngrams in
  let out = Ngram.k_most_to_string ~k freqs in
  printf "%s" out
  
(*
  The following code parses command line arguments and calls the `sample`
  and `most_frequent` functions above as appropriate.

  Note that Cmdliner is not from Core. It must be added as a dependency
  in the dune file.

  You may change it however you'd like, but it's expected that you won't
  need to.
*)

let cmd_main =
  let open Cmdliner.Term.Syntax in
  let open Cmdliner.Arg in
  Cmdliner.Cmd.v (Cmdliner.Cmd.info "ngrams.exe") @@
  let+ n = 
    let doc = "Length of n-grams to read from file. Must be positive." in
    required & pos 0 (some' int) None & info [] ~docv:"N" ~doc
  and+ corpus_filename = 
    let doc = "Corpus filename from which to read n-grams" in
    required & pos 1 (some' file) None & info [] ~docv:"CORPUS" ~doc
  and+ max_sample_length =
    let doc = "Maximum length of outputted sample" in
    value & opt (some int) None & info ["sample"] ~docv:"MAX-SAMPLE-LENGTH" ~doc
  and+ initial_words = 
    let doc = "Initial words for sampling" in
    value & opt (some (list ~sep:' ' string)) None & info ["initial-words"] ~docv:"INITIAL-WORDS" ~doc
  and+ k_most_frequent =
    let doc = "Number of most frequent ngrams to output" in
    value & opt (some int) None & info ["most-frequent"] ~docv:"K-MOST-FREQUENT" ~doc
  in
  if n <= 0 then eprintf "Invalid argument: n=%d is not positive\n" n else
  match max_sample_length, k_most_frequent with
  | Some max_length, None -> sample n corpus_filename max_length initial_words
  | None, Some k -> most_frequent n corpus_filename k
  | _ -> eprintf "Invalid arguments: exactly one of --sample or --most-frequent is expected.\n"

let () = 
  match Cmdliner.Cmd.eval_value' cmd_main with
  | `Ok _ -> ()         (* executed cmd_main *)
  | `Exit i -> exit i   (* cmd_main failed *)
