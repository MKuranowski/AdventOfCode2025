// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub fn main() !void {
    const input = try h.readInput();
    defer std.heap.smp_allocator.free(input);

    var ranges = std.mem.splitScalar(u8, std.mem.trimEnd(u8, input, "\r\n"), ',');
    var total: u64 = 0;
    while (ranges.next()) |range| {
        const start, const end = try parseRange(range);

        for (start..end + 1) |i| {
            if (!isValid(i)) {
                total += i;
            }
        }
    }
}

fn parseRange(r: []const u8) !struct { u64, u64 } {
    var it = std.mem.splitScalar(u8, r, '-');
    const start = try std.fmt.parseInt(u64, it.next() orelse "", 10);
    const end = try std.fmt.parseInt(u64, it.next() orelse "", 10);
    return .{ start, end };
}

fn isValid(i: u64) bool {
    var modulus: u64 = 10;
    while (modulus < i) {
        if (isRepeating(i, modulus)) return false;
        modulus *= 10;
    }
    return true;
}

fn isRepeating(i: u64, modulus: u64) bool {
    const expected = i % modulus;
    var rest = i / modulus;

    while (rest > 0) {
        const part = rest % modulus;
        rest = rest / modulus;
        if (part < (modulus / 10) or part != expected) return false;
    }

    return true;
}
