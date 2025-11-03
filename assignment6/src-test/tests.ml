open Core
open OUnit2
open Base_quickcheck

module Student_tests = struct
  
  let test_sanitize_words _ =
    let content = "Hello, World!\nTEST 123." in
    let filename = Filename_unix.temp_file "test" ".txt" in
    Out_channel.write_all filename ~data:content;
    let words = Utils.get_sanitized_words filename in
    assert_equal ["hello"; "world"; "test"; "123"] words;
    Sys_unix.remove filename

  let test_sanitize_all_non_alphanumeric _ =
    let content = "!!! ??? ,,, ..." in
    let filename = Filename_unix.temp_file "test_empty" ".txt" in
    Out_channel.write_all filename ~data:content;
    let words = Utils.get_sanitized_words filename in
    assert_equal [] words;
    Sys_unix.remove filename

  let test_parse_basic _ =
    let tokens = ["a"; "b"; "c"; "d"] in
    let ngrams = Ngram.parse 2 tokens in
    assert_equal [["a"; "b"]; ["b"; "c"]; ["c"; "d"]] ngrams
  
  let test_parse_trigrams _ =
    let tokens = ["a"; "b"; "c"; "d"] in
    let ngrams = Ngram.parse 3 tokens in
    assert_equal [["a"; "b"; "c"]; ["b"; "c"; "d"]] ngrams
  
  let test_parse_single _ =
    let tokens = ["hello"] in
    let ngrams = Ngram.parse 1 tokens in
    assert_equal [["hello"]] ngrams
  
  let test_parse_exact_size _ =
    let tokens = ["a"; "b"; "c"] in
    let ngrams = Ngram.parse 3 tokens in
    assert_equal [["a"; "b"; "c"]] ngrams
  
  let test_parse_large_n _ =
    let tokens = List.init 10 ~f:Int.to_string in
    let ngrams = Ngram.parse 5 tokens in
    assert_equal 6 (List.length ngrams);
    assert_equal ["0";"1";"2";"3";"4"] (List.hd_exn ngrams)
  
  let test_ngram_compare _ =
    let ng1 = ["a"; "b"] in
    let ng2 = ["a"; "c"] in
    let ng3 = ["a"; "b"] in
    let ng4 = ["a"] in
    let ng5 = ["a"; "b"; "c"] in
    assert_bool "ng1 < ng2" (List.compare String.compare ng1 ng2 < 0);
    assert_bool "ng1 = ng3" (List.compare String.compare ng1 ng3 = 0);
    assert_bool "ng2 > ng1" (List.compare String.compare ng2 ng1 > 0);
    assert_bool "ng4 < ng1 (shorter)" (List.compare String.compare ng4 ng1 < 0);
    assert_bool "ng5 > ng1 (longer)" (List.compare String.compare ng5 ng1 > 0)
  
  let test_split_last _ =
    let ngram = ["a"; "b"; "c"] in
    let prefix, last = Ngram.split_last ngram in
    assert_equal ["a"; "b"] prefix;
    assert_equal "c" last
  
  let test_split_last_two _ =
    let ngram = ["x"; "y"] in
    let prefix, last = Ngram.split_last ngram in
    assert_equal ["x"] prefix;
    assert_equal "y" last

  let test_split_last_singleton _ =
    let ngram = ["only"] in
    let prefix, last = Ngram.split_last ngram in
    assert_equal [] prefix;
    assert_equal "only" last
  
  let test_count_frequencies _ =
    let ngrams = [["a"; "b"]; ["a"; "b"]; ["c"; "d"]] in
    let freqs = Ngram.count_frequencies ngrams in
    assert_bool "Should have frequency 2 for [a;b]"
      (List.exists freqs ~f:(fun (freq, ng) -> freq = 2 && List.equal String.equal ng ["a"; "b"]));
    assert_bool "Should have frequency 1 for [c;d]"
      (List.exists freqs ~f:(fun (freq, ng) -> freq = 1 && List.equal String.equal ng ["c"; "d"]))
  
  let test_count_frequencies_all_unique _ =
    let ngrams = [["a"]; ["b"]; ["c"]] in
    let freqs = Ngram.count_frequencies ngrams in
    assert_equal 3 (List.length freqs);
    List.iter freqs ~f:(fun (freq, _) -> assert_equal 1 freq)
  
  let test_k_most_to_string _ =
    let freq_list = [(3, ["hello"; "world"]); (2, ["foo"; "bar"])] in
    let output = Ngram.k_most_to_string ~k:2 freq_list in
    assert_bool "Should contain hello world"
      (String.is_substring output ~substring:"hello world");
    assert_bool "Should contain frequency 3"
      (String.is_substring output ~substring:"frequency 3")
  
  let test_k_most_sorted_ties _ =
    (* Test tie-breaking logic with same frequencies *)
    let freq_list = [(5, ["zoo"]); (5, ["apple"]); (3, ["banana"])] in
    let output = Ngram.k_most_to_string ~k:3 freq_list in
    let apple_pos = String.substr_index_exn output ~pattern:"apple" in
    let zoo_pos = String.substr_index_exn output ~pattern:"zoo" in
    assert_bool "apple before zoo (alphabetical tie-break)" (apple_pos < zoo_pos)
  
  let test_count_frequencies_with_duplicates _ =
    (* Test the Some branch in count_frequencies *)
    let ngrams = [["a"]; ["a"]; ["a"]; ["b"]; ["b"]] in
    let freqs = Ngram.count_frequencies ngrams in
    assert_bool "Has frequency 3" (List.exists freqs ~f:(fun (f, _) -> f = 3));
    assert_bool "Has frequency 2" (List.exists freqs ~f:(fun (f, _) -> f = 2))


  let test_distribution_multiple_choices _ =
    let ngrams = [
      ["a"; "b"; "x"];
      ["a"; "b"; "y"];
      ["a"; "b"; "z"];
    ] in
    let module D = Distribution.Make(String) in
    let dist = D.make ngrams in
    let sample = D.sample dist ~max_length:5 ~init:(Some ["a"; "b"]) in
    assert_equal ["a"; "b"] (List.take sample 2);
    assert_bool "Third word is one of x/y/z"
      (List.mem ["x"; "y"; "z"] (List.nth_exn sample 2) ~equal:String.equal)

  let test_distribution_short_max_length _ =
    let ngrams = [["x"; "y"; "z"]] in
    let module D = Distribution.Make(String) in
    let dist = D.make ngrams in
    let sample = D.sample dist ~max_length:1 ~init:(Some ["x"; "y"]) in
    assert_equal 1 (List.length sample)
  
  let test_distribution_no_continuation _ =
    (* Test the None branch when no continuation exists *)
    let ngrams = [["a"; "b"; "c"]] in
    let module D = Distribution.Make(String) in
    let dist = D.make ngrams in
    let sample = D.sample dist ~max_length:10 ~init:(Some ["x"; "y"]) in
    (* Should stop immediately since ["x";"y"] has no continuation *)
    assert_equal 2 (List.length sample)
  
  let test_distribution_random_start _ =
    (* Test None init path *)
    let ngrams = [["a"; "b"]; ["b"; "c"]] in
    let module D = Distribution.Make(String) in
    let dist = D.make ngrams in
    let sample = D.sample dist ~max_length:3 ~init:None in
    assert_bool "Produces output" (List.length sample > 0)

  (* INVARIANT: This Base_quickcheck property test verifies that parsing n-grams 
     always produces the correct number: num_words - n + 1 for any valid random input.
     The invariant is that for any list of words with length >= n, the number of 
     n-grams produced should equal (length words) - n + 1. *)
  let test_parse_length_invariant _ =
    Test.run_exn
      (module struct
        type t = int * string list [@@deriving quickcheck, sexp]
        
        let quickcheck_generator =
          Generator.both
            (Int.gen_incl 1 10)
            (Generator.list_non_empty Generator.string)
          |> Generator.filter ~f:(fun (n, words) -> List.length words >= n)
        
        let quickcheck_shrinker = Shrinker.atomic
      end)
      ~f:(fun (n, words) ->
        let ngrams = Ngram.parse n words in
        let expected_count = List.length words - n + 1 in
        let actual_count = List.length ngrams in
        if actual_count <> expected_count then
          failwith (Printf.sprintf 
            "Ngram count mismatch: n=%d, words_len=%d, expected=%d, actual=%d"
            n (List.length words) expected_count actual_count))

  (* INVARIANT: This property test verifies that split_last followed by
     reconstruction always preserves the original n-gram *)
  let test_split_last_invariant _ =
    let test_cases = [
      ["a"; "b"];
      ["x"; "y"; "z"];
      ["one"; "two"; "three"; "four"];
      List.init 5 ~f:Int.to_string;
      List.init 10 ~f:(fun i -> "word" ^ Int.to_string i);
    ] in
    List.iter test_cases ~f:(fun words ->
      let prefix, last = Ngram.split_last words in
      assert_equal words (prefix @ [last])
        ~msg:"split_last then reconstruct should give original")
  
  let test_distribution_empty_init _ =
    (* Test when init is Some [] - should pick random prefix *)
    let ngrams = [["a"; "b"]; ["b"; "c"]] in
    let module D = Distribution.Make(String) in
    let dist = D.make ngrams in
    let sample = D.sample dist ~max_length:3 ~init:(Some []) in
    assert_bool "Should produce output with empty init" (List.length sample > 0)

  let test_ngram_type_sexp _ =
    (* Test the Ngram.t type's sexp derivation *)
    let ng : string Ngram.t = ["hello"; "world"] in
    let sexp = Ngram.sexp_of_t String.sexp_of_t ng in
    let sexp_str = Core.Sexp.to_string sexp in
    assert_bool "Sexp should contain hello" (String.is_substring sexp_str ~substring:"hello")

  let test_ngram_type_compare _ =
    (* Test the Ngram.t type's compare derivation *)
    let ng1 : string Ngram.t = ["a"; "b"] in
    let ng2 : string Ngram.t = ["a"; "c"] in
    let ng3 : string Ngram.t = ["a"; "b"] in
    assert_bool "ng1 < ng2" (Ngram.compare String.compare ng1 ng2 < 0);
    assert_bool "ng1 = ng3" (Ngram.compare String.compare ng1 ng3 = 0)

  let series =
    "Student tests" >::: [
      "test_sanitize_words" >:: test_sanitize_words;
      "test_sanitize_all_non_alphanumeric" >:: test_sanitize_all_non_alphanumeric;
      "test_parse_basic" >:: test_parse_basic;
      "test_parse_trigrams" >:: test_parse_trigrams;
      "test_parse_single" >:: test_parse_single;
      "test_parse_exact_size" >:: test_parse_exact_size;
      "test_parse_large_n" >:: test_parse_large_n;
      "test_ngram_compare" >:: test_ngram_compare;
      "test_split_last" >:: test_split_last;
      "test_split_last_two" >:: test_split_last_two;
      "test_split_last_singleton" >:: test_split_last_singleton;
      "test_count_frequencies" >:: test_count_frequencies;
      "test_count_frequencies_all_unique" >:: test_count_frequencies_all_unique;
      "test_count_frequencies_with_duplicates" >:: test_count_frequencies_with_duplicates;
      "test_k_most_to_string" >:: test_k_most_to_string;
      "test_k_most_sorted_ties" >:: test_k_most_sorted_ties;
      "test_distribution_multiple_choices" >:: test_distribution_multiple_choices;
      "test_distribution_short_max_length" >:: test_distribution_short_max_length;
      "test_distribution_no_continuation" >:: test_distribution_no_continuation;
      "test_distribution_random_start" >:: test_distribution_random_start;
      "test_distribution_empty_init" >:: test_distribution_empty_init;
      "test_parse_length_invariant" >:: test_parse_length_invariant;
      "test_split_last_invariant" >:: test_split_last_invariant;
      "test_ngram_type_sexp" >:: test_ngram_type_sexp;
      "test_ngram_type_compare" >:: test_ngram_type_compare;
    ]
end

let series =
  "Assignment 6 tests" >:::
  [ Student_tests.series
  ; Ngrams_tests.series ]

let () = run_test_tt_main series
