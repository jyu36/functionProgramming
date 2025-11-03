(*
  FPSE Assignment 5 

  Name                  : Jiaqi Yu
  List of collaborators :

  See `finite_group.mli` for a lengthy explanation of this assignment. Your answers go in this file.

  We provide a little bit of code here to help you get over the syntax hurdles.

  The total amount of code here can be very short. The difficulty is in understanding modules and functors.
*)

(* no Core import, use Stdlib equivalents *)

(*
  Copy all module types from `finite_group.mli` and put them here.   
*)

module type ENUMERABLE = sig
  type t [@@deriving sexp, compare]

  val zero : t
  val next : t -> t option
end

module type OPERABLE = sig
  include ENUMERABLE

  val op : t -> t -> t
end

module type S = sig
  include OPERABLE

  val id : unit -> t
  val inverse : t -> t
end

module type MAKE = functor (Operable : OPERABLE) -> S with type t = Operable.t

(*
  Now write your functors below. There will be errors for unbound module types until you put the module types above.
*)

module EnumUtils (E : ENUMERABLE) = struct
  let rec to_list_from x =
    match E.next x with None -> [ x ] | Some nxt -> x :: to_list_from nxt

  let all = to_list_from E.zero
  let for_all f = List.for_all f all

  let find_exn f =
    try List.find f all
    with Not_found -> failwith "EnumUtils.find_exn: no element found"
end

module Make : MAKE =
functor
  (Operable : OPERABLE)
  ->
  struct
    include Operable
    module U = EnumUtils (Operable)

    let id () =
      U.find_exn (fun e ->
          U.for_all (fun x -> Operable.op e x = x && Operable.op x e = x))

    let inverse x =
      let identity = id () in
      U.find_exn (fun y ->
          Operable.op x y = identity && Operable.op y x = identity)
  end

module Make_precomputed : MAKE =
functor
  (Operable : OPERABLE)
  ->
  struct
    include Operable
    module U = EnumUtils (Operable)

    module M = Map.Make (struct
      type t = Operable.t

      let compare = compare
    end)

    let all = U.all

    let op_table =
      List.fold_left
        (fun acc x ->
          let inner =
            List.fold_left
              (fun inner y -> M.add y (Operable.op x y) inner)
              M.empty all
          in
          M.add x inner acc)
        M.empty all

    let lookup_op x y =
      let inner = M.find x op_table in
      M.find y inner

    let id_elem =
      try
        List.find
          (fun e ->
            List.for_all (fun x -> lookup_op e x = x && lookup_op x e = x) all)
          all
      with
      | Not_found -> failwith "No identity found"

    let inverse_map =
      List.fold_left
        (fun acc x ->
          let inv =
            try
              List.find
                (fun y -> lookup_op x y = id_elem && lookup_op y x = id_elem)
                all
            with
            | Not_found -> failwith "No inverse found"
          in
          M.add x inv acc)
        M.empty all

    let op x y = lookup_op x y
    let id () = id_elem
    let inverse x = M.find x inverse_map
  end
