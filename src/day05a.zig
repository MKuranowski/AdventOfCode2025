// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub const Range = struct {
    start: u64,
    end: u64,

    pub fn format(self: Range, w: *std.Io.Writer) !void {
        try w.print("{d}-{d}", .{ self.start, self.end - 1 });
    }

    pub fn contains(self: Range, item: u64) bool {
        return item >= self.start and item < self.end;
    }

    pub fn len(self: Range) u64 {
        return self.end - self.start;
    }

    pub fn is_disjoint(self: Range, o: Range) bool {
        return self.start > o.end or self.end < o.start;
    }

    pub fn @"union"(self: *Range, o: Range) bool {
        if (self.is_disjoint(o)) {
            return false;
        } else {
            self.start = @min(self.start, o.start);
            self.end = @max(self.end, o.end);
            return true;
        }
    }
};

pub fn main() !void {
    var ranges, var numbers = try loadInput();
    defer ranges.deinit(std.heap.smp_allocator);
    defer numbers.deinit(std.heap.smp_allocator);

    var total: u64 = 0;
    outer: for (numbers.items) |i| {
        for (ranges.items) |r| {
            if (r.contains(i)) {
                total += 1;
                continue :outer;
            }
        }
    }
    h.print("{d}\n", .{total});
}

pub fn loadInput() !struct { std.ArrayList(Range), std.ArrayList(u64) } {
    var ranges: std.ArrayList(Range) = .{};
    var numbers: std.ArrayList(u64) = .{};
    errdefer ranges.deinit(std.heap.smp_allocator);
    errdefer numbers.deinit(std.heap.smp_allocator);

    var lines = h.InputLines.init();
    while (try lines.next()) |line| {
        if (line.len == 0) continue;

        var split = std.mem.splitScalar(u8, line, '-');
        const first_s = split.next() orelse "";
        const first = try std.fmt.parseInt(u64, first_s, 10);

        if (split.next()) |second_s| {
            const second = try std.fmt.parseInt(u64, second_s, 10);
            try ranges.append(std.heap.smp_allocator, .{ .start = first, .end = second + 1 });
        } else {
            try numbers.append(std.heap.smp_allocator, first);
        }
    }

    return .{ ranges, numbers };
}
