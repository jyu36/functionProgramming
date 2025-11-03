open Core
open OUnit2

(* Test the monad operations *)
let test_state_monad _ =
  let module IntState = State_monad.Make (struct
    type t = int
  end) in
  let open IntState in
  (* Test get and return *)
  let value, state = run 42 get in
  assert_equal value 42;
  assert_equal state 42;

  (* Test modify *)
  let _, final_state = run 10 (modify (fun x -> x + 5)) in
  assert_equal final_state 15;

  (* Test bind and return *)
  let computation =
    let%bind x = get in
    let%bind () = modify (fun s -> s * 2) in
    let%bind y = get in
    return (x + y)
  in
  let result, final = run 5 computation in
  assert_equal result 15;
  (* 5 + 10 *)
  assert_equal final 10

(* Test the stack monad *)
let test_stack_monad _ =
  let module IntStack = Stack_monad.Make (struct
    type t = int
  end) in
  let open IntStack in
  (* Test push and pop *)
  let result =
    run
      (let%bind () = push 1 in
       let%bind () = push 2 in
       let%bind () = push 3 in
       let%bind top = pop in
       let%bind next = pop in
       return (top, next))
  in
  assert_equal result (3, 2);

  (* Test is_empty *)
  let empty_check = run is_empty in
  assert_equal empty_check true;

  let non_empty =
    run
      (let%bind () = push 42 in
       is_empty)
  in
  assert_equal non_empty false;

  (* Test that final stack is discarded *)
  let just_value =
    run
      (let%bind () = push 1 in
       let%bind () = push 2 in
       return 99)
  in
  assert_equal just_value 99

(* Test pop from empty stack raises exception *)
let test_stack_empty_pop _ =
  let module IntStack = Stack_monad.Make (struct
    type t = int
  end) in
  let open IntStack in
  assert_raises (Failure "pop from empty stack") (fun () -> run pop)

(* Test the balanced parentheses checker *)
let test_balanced_parens _ =
  (* Test balanced strings *)
  assert_equal (Main.are_balanced_monadic "") true;
  assert_equal (Main.are_balanced_monadic "()") true;
  assert_equal (Main.are_balanced_monadic "(())") true;
  assert_equal (Main.are_balanced_monadic "()()") true;
  assert_equal (Main.are_balanced_monadic "((()))") true;
  assert_equal (Main.are_balanced_monadic "(()())") true;

  (* Test unbalanced strings *)
  assert_equal (Main.are_balanced_monadic "(") false;
  assert_equal (Main.are_balanced_monadic ")") false;
  assert_equal (Main.are_balanced_monadic ")(") false;
  assert_equal (Main.are_balanced_monadic "(()") false;
  assert_equal (Main.are_balanced_monadic "())") false;
  assert_equal (Main.are_balanced_monadic "((())") false;

  (* Test that mutable and monadic versions agree *)
  let test_strings =
    [ ""; "()"; "(())"; "()()"; "("; ")"; ")("; "(()"; "())" ]
  in
  List.iter test_strings ~f:(fun s ->
      assert_equal
        (Main.are_balanced_mutable s)
        (Main.are_balanced_monadic s)
        ~msg:(Printf.sprintf "Mismatch on string: %s" s))

(* Test monad operations from Fpse_monad *)
let test_fpse_monad_ops _ =
  let module IntState = State_monad.Make (struct
    type t = int
  end) in
  let open IntState in
  (* Test map *)
  let computation = map (return 5) ~f:(fun x -> x * 2) in
  let result, _ = run 0 computation in
  assert_equal result 10;

  (* Test infix operators *)
  let comp2 = return 3 >>| fun x -> x + 1 in
  let result2, _ = run 0 comp2 in
  assert_equal result2 4;

  (* Test join *)
  let nested = return (return 42) in
  let flattened = join nested in
  let result3, _ = run 0 flattened in
  assert_equal result3 42;

  (* Test list_map_m *)
  let list_comp = list_map_m [ 1; 2; 3 ] ~f:(fun x -> return (x * 2)) in
  let result4, _ = run 0 list_comp in
  assert_equal result4 [ 2; 4; 6 ]

let suite =
  "Monad Tests"
  >::: [
         "test_state_monad" >:: test_state_monad;
         "test_stack_monad" >:: test_stack_monad;
         "test_stack_empty_pop" >:: test_stack_empty_pop;
         "test_balanced_parens" >:: test_balanced_parens;
         "test_fpse_monad_ops" >:: test_fpse_monad_ops;
       ]

let () = run_test_tt_main suite
