(** Utility functions for reading and sanitizing corpus files *)

open Core

(** [get_sanitized_words filename] reads a file and returns a list of sanitized words.
    Sanitization includes:
    - Converting to lowercase
    - Splitting on whitespace characters (space, newline, tab, carriage return)
    - Filtering out non-alphanumeric characters
    - Removing empty strings *)
val get_sanitized_words : Filename.t -> string list

