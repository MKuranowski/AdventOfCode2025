// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const a = @import("day06a.zig");
const h = @import("helper");

pub fn main() !void {
    var problems = try loadInput();
    defer problems.deinit(std.heap.smp_allocator);

    var total: u64 = 0;
    for (problems.items) |p| {
        h.print("\t{f}\n", .{p});
        total += p.calculate();
    }
    h.print("{d}\n", .{total});
}

pub fn loadInput() !std.ArrayList(a.Problem) {
    var problems: std.ArrayList(a.Problem) = .{};
    errdefer problems.deinit(std.heap.smp_allocator);

    var lines = try loadInputLinesTransposed();
    defer lines.deinit(std.heap.smp_allocator);

    var problem: a.Problem = .{};
    for (lines.items) |line| {
        const start = std.mem.indexOfNone(u8, &line, " ") orelse {
            // Everything is a space - we have a problem separator
            problem.fix();
            try problems.append(std.heap.smp_allocator, problem);
            problem = .{};
            continue;
        };

        const end = std.mem.indexOfAnyPos(u8, &line, start, " +*") orelse 5;

        const num = try std.fmt.parseInt(u64, line[start..end], 10);
        problem.push(num);

        if (std.mem.indexOfAny(u8, &line, "+*")) |op_idx| {
            problem.op = line[op_idx];
        }
    }

    if (problem.op != 0) {
        problem.fix();
        try problems.append(std.heap.smp_allocator, problem);
    }
    return problems;
}

pub fn loadInputLinesTransposed() !std.ArrayList([5]u8) {
    var cols: std.ArrayList([5]u8) = .{};
    errdefer cols.deinit(std.heap.smp_allocator);

    var lines = h.InputLines.init();
    var row: usize = 0;
    while (try lines.next()) |line| : (row += 1) {
        for (line, 0..) |c, col| {
            if (row == 0) {
                std.debug.assert(cols.items.len == col);
                try cols.append(std.heap.smp_allocator, .{ c, ' ', ' ', ' ', ' ' });
            } else {
                cols.items[col][row] = c;
            }
        }
    }

    return cols;
}
