
Assignment 7: Monads and more functors
--------------------------------------

In this assignment you will write a functor and a monad module, and then you'll use the module to refactor some stateful OCaml code to use a state monad.

### The file structure

* [Use this zip file](http://pl.cs.jhu.edu/fpse/assignments/assignment7.zip) for your assignment. 
* Provided are three `.mli` files `src/fpse_monad.mli`, `src/state_monad.mli`, and `src/stack_monad.mli`. Look at the files in this order, and implement an appropriately named `.ml` file for each of them.
  * Do not edit the `.mli` files. You will not submit them.
  * Note you may not use `Core` in `src/fpse_monad.ml`. You will not submit a `dune` file for `src/`, so you cannot add any libraries to what is in the given `dune` file.
* A library using your `Stack_monad` module is in `src/main.ml`. See that file and follow the instructions to complete the implementation.
* There is an empty `test/tests.ml` in which you will put your tests.
  * You won't be graded on your tests.
  * You need to fill in the `test/dune` file to run your tests.
* Answer a quick discussion question in `discussion.txt`.

### Submission and Grading
* As usual, run a final `dune clean; dune build` and then upload `_build/default/assignment7.zip` to Gradescope.
* You will be graded with an autograder and on your discussion question.
* We will check that you actually used the monad in your implementation instead of cheating with mutation.