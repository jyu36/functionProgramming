module type BASIC = sig
  type 'a m

  val bind : 'a m -> f:('a -> 'b m) -> 'b m
  val return : 'a -> 'a m
end

module type S = sig
  include BASIC

  val map : 'a m -> f:('a -> 'b) -> 'b m
  val ( >>= ) : 'a m -> ('a -> 'b m) -> 'b m
  val ( >>| ) : 'a m -> ('a -> 'b) -> 'b m
  val join : 'a m m -> 'a m
  val list_fold_m : 'a list -> init:'acc m -> f:('acc -> 'a -> 'acc m) -> 'acc m
  val list_map_m : 'a list -> f:('a -> 'b m) -> 'b list m

  module Let_syntax : sig
    val bind : 'a m -> f:('a -> 'b m) -> 'b m
    val map : 'a m -> f:('a -> 'b) -> 'b m
  end
end

module type MAKE = functor (M : BASIC) -> S with type 'a m = 'a M.m

module Make : MAKE =
functor
  (M : BASIC)
  ->
  struct
    include M

    (* map: Apply a pure function in monadic context *)
    let map x ~f = bind x ~f:(fun a -> return (f a))

    (* Infix bind operator *)
    let ( >>= ) x f = bind x ~f

    (* Infix map operator *)
    let ( >>| ) x f = map x ~f

    (* join: Flatten nested monads *)
    let join x = bind x ~f:(fun a -> a)

    (* list_fold_m: Fold a list with monadic accumulator *)
    let rec list_fold_m lst ~init ~f =
      match lst with
      | [] -> init
      | hd :: tl ->
          bind init ~f:(fun acc ->
              let next_acc = f acc hd in
              list_fold_m tl ~init:next_acc ~f)

    (* list_map_m: Map a list with monadic function *)
    let rec list_map_m lst ~f =
      match lst with
      | [] -> return []
      | hd :: tl ->
          bind (f hd) ~f:(fun result ->
              bind (list_map_m tl ~f) ~f:(fun rest -> return (result :: rest)))

    (* Let_syntax module for ppx_let *)
    module Let_syntax = struct
      let bind = bind
      let map = map
    end
  end
