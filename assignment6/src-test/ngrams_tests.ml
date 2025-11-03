
(*
  Here are some incomplete tests to demonstrate basic uses of the n-grams executable.   
*)

open Core
open OUnit2

(* This has a non-exhaustive pattern match. Turn off warning: -8 *)
[@@@ocaml.warning "-8"]
let string_of_seq (s : char Seq.t) : string =
  let rec char_lst_of_seq (Seq.Cons (h, t)) lst =
    try
      char_lst_of_seq (t ()) (h :: lst)
    with _ ->
      List.rev lst
  in
  String.of_char_list
  @@ char_lst_of_seq (s ()) []
  
(* assert that the output is in the list of expected outputs *)
let assert_string_output (message: string) (expected : string list) (cseq : char Seq.t) : unit =
  let actual = String.filter ~f:(Char.(<>) '\n') @@ string_of_seq cseq |> String.strip in (* get string from char Seq.t *)
  assert_bool
    (Printf.sprintf
      "Failed on: %s\n- expected: %s\n- actual: %s\n"
      message (List.to_string ~f:Fn.id expected) actual)
    (List.mem ~equal:String.equal expected actual)

let exec_dir = "../src/bin/" (* note that cwd is _build/default/src-test *)
let test_dir = "../test/"

let exec_name = "ngrams.exe"
let exec_path = exec_dir ^ exec_name
  
let test_exec (args : string list) (expected : string list) (ctxt : test_ctxt) : unit =
  assert_command
    ~foutput:(assert_string_output (exec_name ^ " " ^ (String.concat ~sep:" " args)) expected)
    ~ctxt
    exec_path
    args

(*
  --------
  SAMPLING   
  --------

  Test that we generate a sequence correctly.
*)

let test_sample
  (n : int)                   (* size of ngrams *)
  (filename : string)         (* corpus file*)
  (max_length : int)          (* max length of output sequence *)
  (init : string list option) (* initial words of sequence *)
  (expected : string list)    (* list of possible outputs, any of which are correct *)
  : test_ctxt -> unit
  =
  let init_args = 
    match init with
    | Some ls -> [ "--initial-words" ; Format.sprintf "%s" (String.concat ~sep:" " ls) ]
    | None -> []
  in
  test_exec ([ Int.to_string n ; test_dir ^ filename ; "--sample" ; Int.to_string max_length ] @ init_args) expected

(*
  Example run with these arguments:
  $ dune exec -- ./src/bin/ngrams.exe 10 ./test/ddse.txt --sample 26 path explosion is a major shortcoming with symbolic execution
  path explosion is a major shortcoming with symbolic execution a vast number of the explored paths never get near the target program point in forward runs
*)
let sample_test1 =
  let words = "path explosion is a major shortcoming with symbolic execution" in
  let generated = "a vast number of the explored paths never get near the target program point in forward runs" in
  test_sample 10 "ddse.txt" 26 (Some (String.split ~on:' ' words)) [ words ^ " " ^ generated ]

(*
  Example runs with these arguments:
  $ dune exec -- ./src/bin/ngrams.exe 3 ./test/ddse.txt --sample 8 --initial-words "while it is"
  it is defined as a direct generalization
  $ dune exec -- ./src/bin/ngrams.exe 3 ./test/ddse.txt --sample 8 --initial_words "while it is"
  it is a fundamentally different approach that
*)
let sample_test2 ctxt =
  let words = "while it is" in
  let expected =
    List.map
      [ "a useful variation on standard"
      ; "a useful variation on symbolic"
      ; "a useful technique with real"
      ; "a major shortcoming with symbolic"
      ; "a fundamentally different approach that" (* this actually appears in the text *)
      ; "also applicable to other goal" 
      ; "also possible to formally prove" (* ... so does this ... *)
      ; "defined as a natural extension" (* ... and this, but the rest of the sentence fragments (along with "it is") are not in the text anywhere *)
      ; "defined as a direct and"
      ; "defined as a direct generalization" ]
      ~f:(fun s -> words ^ " " ^ s)
  in
  Fn.apply_n_times ~n:20 ( (* run this test several times because there is randomness involved *)
    fun () ->
      test_sample 3 "ddse.txt" 8 (Some (String.split ~on:' ' words)) expected ctxt
  ) ()

let sample_tests =
  "Sample" >:::
  [ test_case sample_test1
  ; test_case sample_test2 ]

(*
  --------- 
  FREQUENCY
  --------- 

  Check that we correctly find the most common ngrams.
*)

let test_frequency
  (n : int)           (* size of ngrams *)
  (filename : string) (* corpus file *)
  (k : int)           (* number of ngrams to show *)
  (expected : string) (* exact expected output *)
  : test_ctxt -> unit
  =
  test_exec ([ Int.to_string n ; test_dir ^ filename ; "--most-frequent" ; Int.to_string k ]) [ expected ]

(*
  Example run with these arguments:
  $ dune exec -- ./src/ngrams.exe 3 ./test/ddse.txt --most-frequent 4
  (((ngram(demand driven symbolic))(frequency 4))((ngram(driven symbolic evaluator))(frequency 3))((ngram(et al 2019))(frequency 3))((ngram(for imperative languages))(frequency 3)))
*)
let frequency_test =
  test_frequency 3 "ddse.txt" 4 "(((ngram(demand driven symbolic))(frequency 4))((ngram(driven symbolic evaluator))(frequency 3))((ngram(et al 2019))(frequency 3))((ngram(for imperative languages))(frequency 3)))"

let frequency_tests =
  "Frequency" >:::
  [ test_case frequency_test ]

let series =
  "Ngrams tests" >:::
  [ sample_tests
  ; frequency_tests ]