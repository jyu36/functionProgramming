Assignment 5: Functors
---------------------------------

In this assignment you will write various modules, module types, and functors.
You will get practice using these modules and functors by extensively testing
your code for good coverage.

### The file structure

* [Use this zip file](https://pl.cs.jhu.edu/fpse/assignments/assignment5.zip) for your assignment. 
* We are giving you an `.mli` file that describes the expected behavior. We only provide a very small and simple skeleton for *some* of your code.
  * Your implementation goes in `src/finite_group.ml`.
* You need to write a complete test suite to cover your implementation.
  * Some very basic tests are provided in `test/tests.ml` to help convey expected behavior. You are to add tests to this file.

### Coverage and Specifications
* You will need to incorporate the `Bisect` tool into your `dune` build file as was described in lecture and use its output to improve the coverage of your test suite.  Test coverage will be a component of your grade.
  * You must have at least 94% coverage of your code to get full points. Partial points will be given if you have less coverage.
* You also need to write a special suite of tests that assert five *different* specifications: either preconditions, postconditions, data structure invariants, or recursion invariants. These properties can be on *any* of the functions you implemented.  We gave several examples of such propertes [in lecture](https://pl.cs.jhu.edu/fpse/lecture/specification-test.html#specs), for example `List.rev @@ List.rev l` is `l` for any list `l` (hint: note the relation of `List.rev` to `inverse` in a finite group). Such properties are useful to verify with quick-checking, but here you need to just test each property on specific cases. For each spec include a comment stating what the general property is; the test(s) will only test a few instances of the property.

### Resources
Here are a few resources to keep in mind while you work on this assignment.

* Make sure to review the [More Modules lecture notes](https://pl.cs.jhu.edu/fpse/lecture/more-modules.html).
* If you feel like you need more on the subtleties of information hiding in functors, the [Real World OCaml book chapter on functors](https://dev.realworldocaml.org/functors.html) may be worth looking at.
* For test coverage, see the [Specification and Testing Lecture](https://pl.cs.jhu.edu/fpse/lecture/specification-test.html). These notes also contain links to `OUnit` and `Bisect` documentation.

### Submission and Grading
* As usual, run a final `dune clean; dune build` and then upload `_build/default/assignment5.zip` to Gradescope. Note we will be giving you very little information in our report since you need to provide good coverage on your own and not rely on Gradescope. We try not to test anything tricky--we only want to test the functionality as it is precisely described in the assignment, and your own tests should be able to cover this. Please ask on Courselore for clarification on anything described ambiguously in this assignment.
* You are graded on code coverage and code style, and there is an autograder on Gradescope.
* We will strictly grade code style as it pertains to duplicated code. Functors are helpful for code reuse. Make use of them to de-duplicate your code.