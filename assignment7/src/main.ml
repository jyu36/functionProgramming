(*
  FPSE Assignment 7

  Name                  : 
  List of Collaborators :

  In this file you use the `Stack_monad` module to refactor some stateful OCaml code.

  Only begin on this file after finishing the `Fpse_monad`, `State_monad`, and
  `Stack_monad` modules.
*)

open Core
module Char_stack_monad = Stack_monad.Make (Char)
open Char_stack_monad
(* this puts `m` and `Let_syntax` in scope for the char stack monad. *)

(*
  -------------
  EXAMPLE USAGE
  -------------

  This is an example usage of the stack monad. Note this doesn't run yet because
  the state monad puts a `fun ... ` around all of it.

  Because `Let_syntax` is in scope, we can use the let bindings from `ppx_let`.
*)
let simple_stack : 'a m =
  let%bind () = push 'a' in
  let%bind () = push 'b' in
  let%bind () = push 'c' in
  let%bind c = pop in
  return Char.(c = 'c')

(*
  Alternatively, we can use `let%map` to implicitly return the final line.
*)
let simple_stack' : 'a m =
  let%bind () = push 'a' in
  let%bind () = push 'b' in
  let%bind () = push 'c' in
  let%map c = pop in
  Char.(c = 'c')

(* This will now run each of the above and assert they worked correctly. *)
let _ = assert (run simple_stack && run simple_stack')

(*
  ---------------------
  MUTABLE STACK PROGRAM
  ---------------------

  We'll now look at a simple mutable-stack program.

  The program checks if a string `s` has all parentheses '(' and ')' balanced. It uses the
  `Core.Stack` module, which is an actual mutable stack, not a monadic encoding of one.
*)

(** [are_balanced_mutable s] is true if and only if the string [s] is a string
    of opening '(' and closing ')' parentheses that are balanced. This
    implementation returns [false] if we catch an exception from an illegal pop.
*)
let are_balanced_mutable (s : string) : bool =
  let stack_of_lefts = Stack.create () in
  let parse = function
    | '(' ->
        Stack.push stack_of_lefts '(';
        true
    | ')' -> Char.equal '(' (Stack.pop_exn stack_of_lefts)
    | _ -> true
  in
  try
    let r = String.fold ~init:true ~f:(fun b c -> b && parse c) s in
    r && Stack.is_empty stack_of_lefts
  with _ -> false

(*
  And now we'll refactor the mutable-stack program into a program with the same
  structure and functionality by using our `Char_stack_monad` in place of a mutable stack.

  Rewrite the above function by turning all of the mutable stack operations into
  `Char_stack_monad` ones. You can still use try/with because `Char_stack_monad.pop` may
  raise an exception that needs to be caught. However, you may not use any mutable
  state. You must use `Char_stack_monad` for all stack operations, and you must *not* use 
  `Core.Stack`; you must write the program monadically.

  To make things more clear, we will extract some of the auxiliary functions we had
  above as separate functions with types declared for your benefit. Pay close
  attention to those types: the auxiliary functions are returning monadic values.
*)

let parse (c : char) : bool m =
  match c with
  | '(' ->
      (* Push opening paren and return true *)
      let%bind () = push '(' in
      return true
  | ')' ->
      (* Pop and check if it matches opening paren *)
      let%bind popped = pop in
      return Char.(popped = '(')
  | _ ->
      (* Any other character is ignored *)
      return true

let main_monadic (s : string) : bool m =
  (* Convert string to list of chars and fold monadically *)
  let char_list = String.to_list s in
  let%bind r =
    list_fold_m char_list ~init:(return true) ~f:(fun acc c ->
        let%bind parsed = parse c in
        return (acc && parsed))
  in
  (* Also check that the stack is empty at the end *)
  let%bind empty = is_empty in
  return (r && empty)

let are_balanced_monadic (s : string) : bool =
  try run @@ main_monadic s with _ -> false

(*
  And that's it! Now go test your code thoroughly in `test/tests.ml` and answer
  the discussion question in `discussion.txt`.
*)
