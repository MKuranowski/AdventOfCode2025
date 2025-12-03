// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const a = @import("day03a.zig");
const h = @import("helper");

pub fn main() !void {
    var input = h.InputLines.init();
    var total: u64 = 0;

    while (try input.next()) |line| {
        var value: u64 = 0;
        var multiplier: u64 = comptime std.math.powi(u64, 10, 11) catch unreachable;
        var start_offset: usize = 0;

        for ([_]usize{ 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }) |end_offset| {
            const idx, const digit = a.maxIdx(u8, line[0 .. line.len - end_offset], start_offset);

            value += a.digitToInt(digit) * multiplier;
            multiplier /= 10;
            start_offset = idx + 1;
        }

        total += value;
    }

    h.print("{d}\n", .{total});
}
