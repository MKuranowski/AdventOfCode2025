// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub fn main() !void {
    var input = h.InputLines.init();
    var total: u32 = 0;

    while (try input.next()) |line| {
        const tens_idx, const tens_digit = maxIdx(u8, line[0 .. line.len - 1], 0);
        const unit_digit = std.mem.max(u8, line[tens_idx + 1 ..]);
        const value = digitToInt(tens_digit) * 10 + digitToInt(unit_digit);
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
