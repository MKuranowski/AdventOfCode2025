// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const a = @import("day05a.zig");
const h = @import("helper");

pub fn main() !void {
    var ranges, var numbers = try a.loadInput();
    defer ranges.deinit(std.heap.smp_allocator);
    numbers.deinit(std.heap.smp_allocator);

    // Union ranges until they are all disjoint
    var start: usize = 0;
    outer: while (true) {
        for (start..ranges.items.len) |i| {
            for (i + 1..ranges.items.len) |j| {
                if (ranges.items[i].@"union"(ranges.items[j])) {
                    _ = ranges.swapRemove(j);
                    continue :outer;
                }
            }

            start = i + 1; // `i` is disjoint with every other range, no need to look at it further
        }

        break :outer; // nothing was combined
    }

    var total: u64 = 0;
    for (ranges.items) |r| {
        total += r.len();
    }
    h.print("{d}\n", .{total});
}
