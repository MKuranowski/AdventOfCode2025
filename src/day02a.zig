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

    h.print("{d}\n", .{total});
}

pub fn parseRange(r: []const u8) !struct { u64, u64 } {
    var it = std.mem.splitScalar(u8, r, '-');
    const start = try std.fmt.parseInt(u64, it.next() orelse "", 10);
    const end = try std.fmt.parseInt(u64, it.next() orelse "", 10);
    return .{ start, end };
}

fn isValid(i: u64) bool {
    const str_len = std.math.log10_int(i) + 1;
    const modulus = std.math.powi(u64, 10, str_len / 2) catch unreachable;
    const a = i % modulus;
    const b = i / modulus;
    return a != b;
}
