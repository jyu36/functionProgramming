(** N-gram representation and parsing module *)

(** Type representing an n-gram as a list of tokens *)
type 'a t = 'a list [@@deriving sexp, compare]

(** [parse n tokens] parses a list of tokens into n-grams of length n.
    Returns a list of all consecutive n-grams found in the token sequence. *)
val parse : int -> 'a list -> 'a t list

(** [split_last ngram] splits an n-gram into its prefix (all but last element)
    and its last element. Raises an exception if the n-gram is empty. *)
val split_last : 'a t -> 'a list * 'a

(** [count_frequencies ngrams] counts the frequency of each string n-gram.
    Returns a list of (frequency, ngram) pairs. *)
val count_frequencies : string t list -> (int * string t) list

(** [k_most_to_string ~k freq_list] formats the top k most frequent n-grams
    as a sexp-formatted string. N-grams are sorted by frequency (descending)
    and then alphabetically for ties. *)
val k_most_to_string : k:int -> (int * string list) list -> string

