
(*
  The state monad is a function to allow you to "thread" the state through.
  Implement this signature in `state_monad.ml`, and use `Fpse_monad.Make`
  after writing your `bind` and `return` functions.

  Then, implement the state-specific `get`, `modify`, and `run` functions.

  See the lecture notes and the `State` module for a very similar implementation.
*)

(* The type of the state is S.t *) 
module Make (S : sig type t end) : sig
  include Fpse_monad.S with type 'a m = S.t -> 'a * S.t

  val get : S.t m
  (** [get] is a monadic value whose data is the state. *)

  val modify : (S.t -> S.t) -> unit m
  (** [modify f] applies [f] to the state. *)

  val run : S.t -> 'a m -> 'a * S.t
  (** [run init x] is the value and final state from [x], given the initial state [init]. *)
end
