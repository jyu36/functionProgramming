(*
  You will need to create and run your own tests. Tests should cover both common
  cases and edge cases. In previous assignments, we asked for a specified number
  of additional tests, but in this assignment we will be grading based on code
  coverage.
 
  Aim for complete code coverage on all functions. We will check coverage by
  running the bisect tool on your code. For that reason, you need to add the
  following line in the dune file for your library:
      
      (preprocess (pps bisect_ppx))
 
  or else your tests will not run in the autograder.

 Additionally, you will need to write a special suite of tests here which
 verifies some specifications. See the `Readme` for details.
*)

open Core
open OUnit2

(*
  We give you one working `OPERABLE` module and two `assert_equal`s with it. You'll likely
  need to write more modules to get good coverage.
*)

module Given_tests = struct
  module Op1 : Finite_group.OPERABLE with type t = int = struct
    type t = int [@@deriving sexp, compare]

    let zero = 0
    let next x = if x = 4 then None else Some (x + 1)
    let op x y = (x + y) mod 5
  end

  let op1_tests _ =
    let module G = Finite_group.Make (Op1) in
    assert_equal 0 (G.id ());
    assert_equal 2 (G.inverse 3)

  let series = "Given tests" >::: [ "op1 tests" >:: op1_tests ]
end

module Student_tests = struct
  module Op2 : Finite_group.OPERABLE with type t = int = struct
    type t = int [@@deriving sexp, compare]

    let zero = 0
    let next x = if x = 2 then None else Some (x + 1)
    let op x y = (x + y) mod 3
  end

  let test_make_and_precomputed _ =
    let module G = Finite_group.Make (Op2) in
    let module Gp = Finite_group.Make_precomputed (Op2) in
    assert_equal 0 (G.id ());
    assert_equal 0 (Gp.id ());

    assert_equal 0 (G.inverse 0);
    assert_equal 2 (G.inverse 1);
    assert_equal 1 (Gp.inverse 2);

    assert_equal 1 (G.op 0 1);
    assert_equal 2 (Gp.op 1 1);
    assert_equal 0 (Gp.op 2 1)

  module OpTrivial : Finite_group.OPERABLE with type t = int = struct
    type t = int [@@deriving sexp, compare]

    let zero = 0
    let next _ = None
    let op _ _ = 0
  end

  let test_trivial_group _ =
    let module G = Finite_group.Make (OpTrivial) in
    assert_equal 0 (G.id ());
    assert_equal 0 (G.inverse 0);
    assert_equal 0 (G.op 0 0)

  module OpInvalid : Finite_group.OPERABLE with type t = int = struct
    type t = int [@@deriving sexp, compare]

    let zero = 0
    let next x = if x = 1 then None else Some (x + 1)
    let op x y = (x + y + 1) mod 3
  end

  let test_error_cases _ =
    let module U = Finite_group.EnumUtils (OpInvalid) in
    assert_raises (Failure "EnumUtils.find_exn: no element found") (fun () ->
        U.find_exn (fun _ -> false))

  let test_make_error_cases _ =
    assert_raises (Failure "EnumUtils.find_exn: no element found") (fun () ->
        let module G = Finite_group.Make (OpInvalid) in
        G.id ())

  let test_make_precomputed_error_cases _ =
    assert_raises (Failure "No identity found") (fun () ->
        let module G = Finite_group.Make_precomputed (OpInvalid) in
        G.id ())

  let series =
    "Student tests"
    >::: [
           "make_and_precomputed" >:: test_make_and_precomputed;
           "trivial group" >:: test_trivial_group;
           "error cases" >:: test_error_cases;
           "make error cases" >:: test_make_error_cases;
           "make_precomputed error cases" >:: test_make_precomputed_error_cases;
         ]
end

module Specification_tests = struct
  module Op3 : Finite_group.OPERABLE with type t = int = struct
    type t = int [@@deriving sexp, compare]

    let zero = 0
    let next x = if x = 2 then None else Some (x + 1)
    let op x y = (x + y) mod 3
  end

  module G = Finite_group.Make (Op3)

  let test_left_identity _ =
    let e = G.id () in
    List.iter [ 0; 1; 2 ] ~f:(fun x -> assert_equal x (G.op e x))

  let test_right_identity _ =
    let e = G.id () in
    List.iter [ 0; 1; 2 ] ~f:(fun x -> assert_equal x (G.op x e))

  let test_inverse_property _ =
    let e = G.id () in
    List.iter [ 0; 1; 2 ] ~f:(fun x -> assert_equal e (G.op x (G.inverse x)))

  let test_double_inverse _ =
    List.iter [ 0; 1; 2 ] ~f:(fun x -> assert_equal x (G.inverse (G.inverse x)))

  let test_associativity _ =
    List.iter [ 0; 1; 2 ] ~f:(fun x ->
        List.iter [ 0; 1; 2 ] ~f:(fun y ->
            List.iter [ 0; 1; 2 ] ~f:(fun z ->
                assert_equal (G.op (G.op x y) z) (G.op x (G.op y z)))))

  let series =
    "Specification tests"
    >::: [
           "left identity" >:: test_left_identity;
           "right identity" >:: test_right_identity;
           "inverse property" >:: test_inverse_property;
           "double inverse" >:: test_double_inverse;
           "associativity" >:: test_associativity;
         ]
end

let series =
  "Finite group tests"
  >::: [ Given_tests.series; Student_tests.series; Specification_tests.series ]

let () = run_test_tt_main series
