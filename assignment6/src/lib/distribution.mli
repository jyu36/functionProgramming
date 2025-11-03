(** N-gram distribution for sampling sequences *)

open Core

(** Functor for creating distribution modules for any comparable token type *)
module Make (Token : sig
  type t [@@deriving sexp, compare]
  include Comparator.S with type t := t
end) : sig
  (** Type representing a distribution that maps n-gram prefixes to possible next tokens *)
  type t

  (** [make ngrams] builds a distribution from a list of n-grams.
      The distribution maps each (n-1)-prefix to all tokens that followed it. *)
  val make : Token.t Ngram.t list -> t

  (** [sample dist ~max_length ~init] samples a sequence from the distribution.
      - [max_length]: Maximum length of the output sequence
      - [init]: Optional initial tokens to seed the sequence. If None, a random prefix is chosen.
      Returns a list of sampled tokens. Sampling stops when max_length is reached or
      when no continuation is possible from the current context. *)
  val sample : t -> max_length:int -> init:Token.t list option -> Token.t list
end

