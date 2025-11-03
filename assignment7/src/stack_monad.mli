(*
  Use `State_monad` and `Fpse_monad` to implement a stateful monadic stack. 
  Note you shouldn't have to write new `bind` and `return` functions but can 
  instead include those from `State_monad`.
*)

module Make (S : sig
  type t
end) : sig
  (** A stack monad is a state monad where the state is [S.t list]. *)
  include module type of State_monad.Make (struct
    type t = S.t list
  end)

  (*
    We'll need a few extra functions to use this monad practically, so
    we have the following in addition to the above signature.
  *)

  val push : S.t -> unit m
  (** [push a] is a monadic unit value that has [a] on the top of the stack. *)

  val is_empty : bool m
  (** [is_empty] is a monadic value whose underlying data is true if and only if
      the stack is empty *)

  val pop : S.t m
  (** [pop] is a monadic value whose underlying data is the top value of the
      stack, and the new state no longer has the top value. This may throw an
      exception when the stack is already empty. *)

  val run : 'a m -> 'a
  (** [run x] takes [x] out of monad-land by providing an initial empty stack
      and throwing away the final stack. Recall that ['a] is the underlying data
      type. From this signature, we see that the data in the stack is thrown
      away, and the underlying data is kept. *)
end
