// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub fn main() !void {
    var input = h.InputLines.init();
    var total: u64 = 0;

    while (try input.next()) |line| {
        var value: u64 = 0;
        var multiplier: u64 = comptime std.math.powi(u64, 10, 11) catch unreachable;
        var start_offset: usize = 0;

        for ([_]usize{ 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }) |end_offset| {
            const idx, const digit = maxIdx(u8, line[0 .. line.len - end_offset], start_offset);

            value += digitToInt(digit) * multiplier;
            multiplier /= 10;
            start_offset = idx + 1;
        }

        total += value;
    }

    h.print("{d}\n", .{total});
}

fn maxIdx(comptime T: type, slice: []const T, start_pos: usize) struct { usize, T } {
    std.debug.assert(slice.len > start_pos);
    var best = slice[start_pos];
    var best_idx: usize = start_pos;
    for (slice[start_pos + 1 ..], start_pos + 1..) |item, idx| {
        if (item > best) {
            best = item;
            best_idx = idx;
        }
    }
    return .{ best_idx, best };
}

fn digitToInt(digit: u8) u32 {
    return switch (digit) {
        '0' => 0,
        '1' => 1,
        '2' => 2,
        '3' => 3,
        '4' => 4,
        '5' => 5,
        '6' => 6,
        '7' => 7,
        '8' => 8,
        '9' => 9,
        else => unreachable,
    };
}
