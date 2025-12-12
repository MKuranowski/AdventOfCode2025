[Advent of Code 2025](https://adventofcode.com/2025) in Zig.

As always, I try to come up with my own solutions, so they are probably not the most optimal.

Day-specific notes:

* Day 10 part B is awful, I just ended up deferring every machine to an ILP solver.
    [GLPK](https://www.gnu.org/software/glpk/) with its `glpsol` program is required.
* Day 12 was also pretty bad. Implementing a proper solver that would finish running
    in reasonable time was beyond my pay grade. I decide to first get an upper bound
    on which trees are even viable, and turns out that was the correct answer to the real puzzle;
    even if that doesn't work on the test input.
