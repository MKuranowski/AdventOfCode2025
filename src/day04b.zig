// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const a = @import("day04a.zig");
const h = @import("helper");

pub fn main() !void {
    var rolls = try a.loadInput();
    defer rolls.deinit();

    var to_remove = h.HashSet(a.Position){};
    defer to_remove.deinit();

    var total: u32 = 0;
    var done = false;
    while (!done) {
        to_remove.clearRetainingCapacity();
        for (rolls.iter()) |pos| {
            if (a.isAccessible(pos, rolls)) {
                try to_remove.add(pos);
            }
        }

        total += @intCast(to_remove.len());
        done = to_remove.len() == 0;

        for (to_remove.iter()) |pos| {
            rolls.remove(pos);
        }
    }

    h.print("{d}\n", .{total});
}
