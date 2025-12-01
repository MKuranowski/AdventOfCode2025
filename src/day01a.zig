// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub fn main() !void {
    var input = h.InputLines.init();
    var dial: i32 = 50;
    var hit_zero: u32 = 0;

    while (try input.next()) |line| {
        const dir = line[0];
        const num = try std.fmt.parseInt(i32, line[1..], 10);

        dial += if (dir == 'L') -num else num;
        dial = @mod(dial, 100);
        hit_zero += @intFromBool(dial == 0);
    }

    h.print("{d}\n", .{hit_zero});
}
