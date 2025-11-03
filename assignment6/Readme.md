Assignment 6: N-Grams and a real app
------------------------------------

You will write an executable for an n-gram model generator. This is a large assignment, so you have two weeks to do it. All expectations for this assignment are written here. There is nothing notable shared in the `.ml` or `.mli` files.

### The file structure

* [Use this zip file](http://pl.cs.jhu.edu/fpse/assignments/assignment6.zip) for your assignment. 
* There is `src/bin/ngrams.ml` that compiles to an executable. Your code with side-effects will go here.
* There is `src/lib/`, which is where you will put your library code.
  * For each new file you create, you need to add it to the `dune` rule in the top-level directory to submit them in your zip file.
  * Your library modules must have well-documented `.mli` files. See the provided `.mli` files in this or previous assignments for what we consider to be well-documented.
* The code to test your library and the executable is in `src-test/`. We provide some tests to convey functionality expectations and to kick off the testing of the executable.
  * All of your tests will go in `src-test/tests.ml`.
  * When testing the executable, you should use the helper functions from `src-test/ngrams_tests.ml` to avoid duplicate code.
* The resources to test are in `test/`. Provided is one corpus file `test/ddse.txt`. If you're curious about its source, see [here](https://www.pl.cs.jhu.edu/projects/demand-driven-symbolic-execution/papers/icfp20-ddse-full.pdf). Add any resources you want to `test/`.

### Motivation

#### Broad overview

In this assignment you will implement a simple n-gram model.

You will have some library routines and a command-line tool to build and use an n-gram model which makes use of your library.

Using the n-gram model of sequences and probabilities, we'll take in some sequence of items, and then use it as a basis to generate more similar sequences (for example, sentences of words, lists of numbers, etc.), or evaluate the likelihood of seeing particular sequences.

There is a lot to read in this file, and you should read it all. The information is better found here than in student questions on Courselore.

#### Background

The general intuition is simple: if we want to predict what comes next in a sequence of items, we can probably do so on the basis of the elements which preceded it. Moreover, we can probably ignore parts of the sequence which came _far_ before the element we want to predict and focus our attention on the immediately previous couple of items.

Consider sentences of words in English text, a very common type of sequence to apply this approach to. If we are given that the word we want to predict came after:

  "take this boat for a spin out on the" ???

Then we could say that "water" is more likely than "town" to follow. If we have less context, say only 2 words:

  "on the" ???

We will naturally make a poorer approximation of the true distribution, but it may be sufficient for some purposes anyway and will be easier to estimate. How can we estimate the actual distribution of words efficiently, then?

We will need to take in some observed sequence of words or tokens, called a _corpus_.  Let's say we want to keep two words of context when predicting what comes next, based on the provided corpus. Then we can just keep track of every 3-tuple of consecutive words in the input, and count how often they appear.

For example, say we observe the triples (i.e. 3-grams)

("take", "this", "boat"), ("this", "boat", "for"), ... ("on", "the", "water").

Then, if we index these properly, we can predict what should follow ("on", "the") by just sampling randomly from among all the tuples which started with that prefix, and using the last element of the tuple as our prediction. Naturally, words which appear more frequently in the context specified should then be given more weight, and words which do not appear in our corpus after the given sequence will not be chosen at all, so our prediction should be a reasonable estimate for the empirical distribution.

If we instead count 5-tuples rather than 3-tuples, we can make better predictions with the greater context, which will then more closely match the true sequence properties. However, we will also be able to observe fewer unique 5-tuples overall than 3-tuples, which will mean we need greater amounts of data to properly use a larger n-gram size.

Feel free to read these useful resources to better understand n-grams:
- https://blog.xrds.acm.org/2017/10/introduction-n-grams-need/
- https://web.stanford.edu/~jurafsky/slp3/slides/LM_4.pdf
- https://medium.com/mti-technology/n-gram-language-model-b7c2fc322799

In this document we follow the standard terminology and refer to an "n-gram" as a list of n items, which has n-1 items of prefix/context. For example, a 3-gram has two items of context, and the context plus the one item of prediction gives a 3-gram.

#### Sampling

You'll sample from a distribution until the desired output length is hit, or until there is no possible following item. Let's see an example.

If the corpus is this list of integers

```
[1; 2; 3; 4; 4; 4; 2; 2; 3; 1]
```

Then we might describe the distribution using bigrams (2-grams) like this:

```
{ 
  [1] -> {2}; 
  [2] -> {3; 2; 3};
  [3] -> {4; 1};
  [4] -> {4; 4; 2};
    |        |
    |        \------------------------ ...was followed by each of these elements
    \-- this sequence (of length 1 in this example)  ...
}
```

Suppose instead there are two items of context because the model used 3-grams. Then the distribution would look like...

```
{
  [1; 2] -> {3};
  [2; 3] -> {4; 1};
  [3; 4] -> {4};
  [4; 4] -> {4; 2};
  [4; 2] -> {2};
  [2; 2] -> {3};
    |        |
    |        \------- ...was followed by each of these elements
    \-- this sequence...
}
```

We will walk you through one example of sampling from this distribution (the 3-gram, two-items-of-context distribution) with input ngram `[1; 2]` and a desired 5-length sequence.

The only possible item to sample first is `3` (because `[1; 2] -> {3}` above), and the running sequence is

```
[1; 2; 3].
```

Now the context is

```
[2; 3].
```

Look at the above distribution to see what can follow this context (here, `[2; 3] -> {4; 1}`). So we sample from

```
{4; 1}
```

at random. Say this comes out as 4. So the running sequence is now

```
[1; 2; 3; 4]
```

and the new context is

```
[3; 4].
```

So we sample from

```
{4}
```

which makes the running sequence

```
[1; 2; 3; 4; 4]
```

which has length `k = 5`, and we're done because we hit the desired length.

If from `{4; 1}` we pulled the item `1`, then the sequence would have become `[1; 2; 3; 1]`, and the new context is `[3; 1]`, which never appears in the original sequence, and hence there's no appropriate next item, so we stop at length 4, which is short of `k = 5`. That's okay, and it's a valid output.


### Functionality

You will implement an executable `ngrams.exe` which can use n-gram models in several ways. It should expect to be called with the following arguments, with bracketed ones optional:

  $ ngrams.exe N CORPUS-FILE [--sample SAMPLE-LENGTH] [--initial-words "INITIAL-WORDS"] [--most-frequent K-MOST-FREQUENT]

See `src-test/ngrams_tests.ml` for example uses. See `src/bin/ngrams.ml` for the argument parser.

Functionality should be as follows:

- Load the file specified by `CORPUS-FILE` and split its contents into a sequence of strings based on whitespace. Treat newlines and spaces, etc. equally.

- Sanitize each of the strings in this sequence by sending to lowercase and removing non-alphanumeric characters. Say a "sanitized" word is lowercase and uses only alphanumeric characters.

- Parse all n-grams from the corpus file using `N` and the sanitized sequence of words. The `N` is the length of the n-grams, and it is positive. You may assume the corpus file contains enough words to form at least one n-gram of the specified size `N`.

If the option `--sample SAMPLE-LENGTH` is provided:

  Initilize a distribution from the parsed n-grams. The `N` is the length of the n-grams used to build the distribution, so there are `N - 1` items of context for sampling. For example, `N = 3` means two items of context because the last item is used for sampling, and the first two are used for context of the sampled element.

  To stdout, output a sequence of `SAMPLE-LENGTH` words randomly sampled from the n-gram model as described in the "sampling" section above. Print them out separated by single spaces, followed finally by a newline.
  
  To begin the sequence, use the `INITIAL-WORDS` arguments provided after `--initial-words` to seed the sequence, or if none are provided, choose a random starting n-gram to begin. You may assume that the words provided as `INITIAL-WORDS` are already sanitized, and that there are **at least** `N - 1` of them if they are provided. There may be more, in which case you should keep all of them for the output but begin sampling with the final `N - 1` of them as context, just as you would if you had already sampled some words.

  Sample the words according to the description in the "sampling" section above. If too many words are provided, then output the first `SAMPLE-LENGTH` of them, and ignore anything else.

If the option `--most-frequent K-MOST-FREQUENT` is provided:

  To stdout, output a sorted sexp-formatted list of length `K-MOST-FREQUENT` containing information about the most common n-grams seen in the `CORPUS-FILE`, like so:

    (((ngram(hello world goodbye))(frequency 5))((ngram(lexicographically greater ngram))(frequency 5))((ngram(less frequent ngram))(frequency 4))((ngram(lesser frequent ngram))(frequency 3)))

  Where the ["hello"; "world"; "goodbye"] n-gram showed up 5 times, as did ["lexicographically"; "greater"; "ngram"], and so on. In this example, `N` = 3, and `K-MOST-FREQUENT` = 4.

  If there are fewer unique n-grams than `K-MOST-FREQUENT`, then print as many as possible.

  Higher frequency n-grams should be shown first, and frequency ties should be broken by n-gram alphabetical order. Print the sexp-formatted list, followed by a newline.

You may assume that exactly one of `--sample` or `--most-frequent` will be supplied at a time. `--initial-words` may be ignored if the `--most-frequent` argument is used.

Some command line argument parsing is done for you. You should feel free to change the provided code in any way.

We will reveal only a few tests to help you get the right output format, but you are expected to thoroughly test your own code. Testing is an important part of software development. The same tests are revealed on Gradescope as are provided in `src-test/ngrams_tests.ml`. If you feel the desired functionality is still ambiguous, then please ask on Courselore for clarification after reading this entire file.

### Implementation requirements.

There are several requirements to receive full credit for this assignment. You are at risk of losing many points if you don't follow any of these requirements. They are in place to help you write good code and to prepare you for the project.

#### Architecture requirements
* You must have a library, so only a very, very small portion of your code is in `src/bin/ngrams.ml`.
* All library code exposed by the `.mli` files should be well-documented (just like how the `.mli` files provided with each prior assignment have been well-documented), and all library modules have an `.mli` file.
* You need a type to represent an n-gram.
* You need a type to represent a distribution of many n-grams: how the first "n minus 1" items can be followed by a next item.
* This must be done with a functor such that the n-gram distributions can be of any item type--strings, ints, anything comparable--even though the executable will only use it with strings.
* Your code is modular with separation of responsibilities and good use of abstraction.

#### Code quality requirements
* Your code is functional with no mutation.
* You choose efficient data structures and reasonable, clear types.
  * e.g. if you have something like `type 'tok t = int * 'tok Ngram.t`, you should probably instead have `type 'tok t = { frequency : int ; ngram : 'tok Ngram.t }`.

#### Testing requirements

We also expect that you sufficiently test your code.

* We expect good code coverage.
  * Anything testable should be in your library instead of your executable. You must use `Bisect` to show at least 94% code coverage.
  * In addition, write at least one `Base_quickcheck` random test for one of your OUnit2 tests following the [Quickcheck lecture](https://pl.cs.jhu.edu/fpse/lecture/specification-test.html#quickcheck). Since the input data is random, you may not necessarily know the correct answer, but it suffices to perform sanity checks. For example, for any n-gram used to create the distribution, it's possible to sample _something_ from the distribution using the n-gram's context.
    * Indicate with a very clear comment containing the capitalized word "INVARIANT" somewhere inside of it to help the graders find your invariant test.
* Notice that only library functions are susceptible to coverage. You should test your executable as well to increase your chances at a good autograder score, but you will not be graded on executable testing.

If you're about to ask a question on Courselore like "Am I allowed to do x?", first ask yourself if it is in direct conflict with any of the requirements above. What is given above is what must *at least* be in your code; it is not what *only* may be in your code. You can do whatever you'd like outside of the above requirements. Just fulfill those requirements, and you're fine.

### Example interfaces

We do not provide you any starter code for your library, but here, we give you just part of an example interface that might be used to solve this assignment. You do not have to use anything from this interface, and if you do, then you will probably have to add to it. It is not complete.

These interfaces are intentionally not commented or explained. Notice that they are small and modular, and they hide the implementation details.

```ocaml
(* ngram.mli *)
open Core
type 'token t [@@deriving sexp, compare]
val parse : int -> 'token list -> 'token t list
val split_last : 'token t -> 'token list * 'token
module Make (Token : Map.Key) : sig
  type nonrec t = Token.t t [@@deriving sexp, compare]
  val k_most_to_string : k:int -> t list -> string
end

(* distribution.mli *)
open Core
module Make (Token : Map.Key) : sig
  type t 
  val make : Token.t Ngram.t list -> t
  val sample : t -> max_length:int -> init:Token.t list option -> Token.t list
end

(* utils.mli *)
open Core
val get_sanitized_words : Filename.t -> string list
```

Do not get caught up trying to write a solution with exactly this interface. Write your own libraries to best implement your own solution, but take from this as you wish.

### Submission and grading

* Make sure your `dune` files are updated for each library you make. Your libraries should be dependencies of each other or the `ngrams` executable.
* Any file you create should be added to the zip rule in the top-level `dune`. The provided files are all automatically submitted. If you choose to not use any of them, then delete them from the zip rule.
  - If you do not update your `dune` files, then the autograder will not give you any output. Make sure you've updated everything before you submit.
* Run a final `dune clean ; dune build`, and upload `_build/default/assignment6.zip` to Gradescope.
* Any requirement expressed or suggested in this file is subject to grading. Make sure you've read it carefully. Design and implement your solution with all requirements in mind.
