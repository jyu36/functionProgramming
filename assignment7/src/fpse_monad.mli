(*
  ----------
  BACKGROUND
  ----------

  In this assignment you'll create and use a stateful stack monad. This will be done by
  writing a functor that makes most of a monad module's functions for you.

  You'll then use the functor to make your stack monad module, write a few extra helpful
  functions, and use that module in a simple program.

  Recall the monads lecture here:

    https://pl.cs.jhu.edu/fpse/lecture/encoding_effects.ml 

  To write the FPSE Monad `Make` module, you will follow a type-directed programming approach. 
  It may seem challenging to implement everything described by this `mli`, but if you
  follow the types and think about the only way to implement the functions, you'll get there.
  Think about what you are given (the inputs to the function), what you have at your disposal
  (only what is passed in as the `BASIC` module), and what you need to construct.
*)

(*
  -----------
  BASIC MONAD
  -----------

  Our basic monad will have a parametrized type and two functions:
  * [bind] "maps" the given monad by [f]
  * [return] creates a monad from the given underlying value

  Note that in lecture we say a monad is anything matching some different general
  module type than `BASIC` below (it is the `Monadic` module in the lecture notes),
  but we are simplifying it for this assignment and also adding two polymorphic 
  parameters instead of one.
*)
module type BASIC = sig
  (* In this assignment, we'll go against the `Core` convention and call any monad type `m`. *)
  type 'a m

  val bind : 'a m -> f:('a -> 'b m) -> 'b m
  val return : 'a -> 'a m
end

(*
  ---------------
  MONAD SIGNATURE
  ---------------

  Provided the type and functions in the `BASIC` monad, we can create
  all of the following functions in the signature `S` to give ourselves
  more operations on the monad.

  Note that this extension operation is built into `Core` as the `Monad.Make`
  functor; here we are asking you to implement this extension yourselves to
  better understand how they work. For this reason, `Core` is not allowed
  in the implementation of this module, and it is not put in the `dune` file.

  We give you some hints for which functions from `BASIC` you might use to 
  implement each function in `S`.
*)
module type S = sig
  include BASIC

  val map : 'a m -> f:('a -> 'b) -> 'b m
  (** [map] is implemented using [bind] and [return]. *)

  val ( >>= ) : 'a m -> ('a -> 'b m) -> 'b m
  (** [>>=] is infix [bind]. *)

  val ( >>| ) : 'a m -> ('a -> 'b) -> 'b m
  (** [>>|] is infix [map]. *)

  val join : 'a m m -> 'a m
  (** [join] is implemented using [bind]. *)

  val list_fold_m : 'a list -> init:'acc m -> f:('acc -> 'a -> 'acc m) -> 'acc m
  (** [list_fold_m a ~init ~f] folds left-to-right through the list, binding on
      the accumulated value at each step. *)

  val list_map_m : 'a list -> f:('a -> 'b m) -> 'b list m
  (** Like [List.map], but applies [f] in monadic context and collects results.
      Items in the list are mapped with [f] from left to right, so monadic
      effects from the start of the list happen first. *)

  (*
    We have this for the `let%bind` and `let%map` rewritings from `ppx_let`.
    These `bind` and `map` are the same as they are above.

    The rewritings can be used if there is a properly loaded `Let_syntax` module in scope.
  *)
  module Let_syntax : sig
    val bind : 'a m -> f:('a -> 'b m) -> 'b m
    val map : 'a m -> f:('a -> 'b) -> 'b m
  end
end

(*
  ------------
  MAKE FUNCTOR
  ------------

  The functor `Make` has the signature `MAKE`, which takes a `BASIC` module and
  produces an `S` module. Use the hints above to implement this in `fpse_monad.ml`.
*)
module type MAKE = functor (M : BASIC) -> S with type 'a m = 'a M.m

module Make : MAKE
