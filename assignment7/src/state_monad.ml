module Make (S : sig
  type t
end) =
struct
  (* The monad type: a function from state to (value, new_state) *)
  type 'a m = S.t -> 'a * S.t

  (* bind: Thread state through sequential computations *)
  let bind x ~f =
   fun s ->
    let a, s' = x s in
    f a s'

  (* return: Wrap a value without changing state *)
  let return a = fun s -> (a, s)

  (* Use the Fpse_monad.Make functor to get all extended operations *)
  (* We use type equality constraint to avoid redefining the type *)
  include (
    Fpse_monad.Make (struct
      type nonrec 'a m = 'a m

      let bind = bind
      let return = return
    end) :
      Fpse_monad.S with type 'a m := 'a m)

  (* get: Retrieve the current state as the value *)
  let get = fun s -> (s, s)

  (* modify: Apply a function to the state *)
  let modify f = fun s -> ((), f s)

  (* run: Execute the stateful computation with an initial state *)
  let run init x = x init
end
