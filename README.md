[Advent of Code 2025](https://adventofcode.com/2025) in Zig.

As always, I try to come up with my own solutions, so they are probably not the most optimal.

Day-specific notes:

* Day 10 part B is awful, I just ended up deferring every machine to an ILP solver.
    [GLPK](https://www.gnu.org/software/glpk/) with its `glpsol` program is required.
