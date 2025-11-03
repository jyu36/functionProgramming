module Make (S : sig
  type t
end) =
struct
  (* Create a state monad where the state is a stack (list) *)
  module Stack_state = State_monad.Make (struct
    type t = S.t list
  end)

  (* Include all the state monad operations *)
  include Stack_state

  (* push: Add an element to the top of the stack *)
  let push a = modify (fun stack -> a :: stack)

  (* is_empty: Check if the stack is empty *)
  let is_empty = map get ~f:(function [] -> true | _ -> false)

  (* pop: Remove and return the top element (may raise exception if empty) *)
  let pop =
    bind get ~f:(function
      | [] -> failwith "pop from empty stack"
      | hd :: tl -> bind (modify (fun _ -> tl)) ~f:(fun () -> return hd))

  (* run: Execute with empty initial stack, discard final stack *)
  let run x =
    let result, _ = Stack_state.run [] x in
    result
end
