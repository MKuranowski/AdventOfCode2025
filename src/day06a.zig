// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub const Problem = struct {
    numbers: @Vector(4, u64) = @splat(0),
    op: u8 = 0,

    pub fn format(self: Problem, writer: *std.Io.Writer) !void {
        try writer.print("{c}\t{d}\t{d}\t{d}\t{d}", .{
            self.op,
            self.numbers[0],
            self.numbers[1],
            self.numbers[2],
            self.numbers[3],
        });
    }

    pub fn fix(self: *Problem) void {
        // HACK: The test input may not have 4 numbers in the input, so sum numbers may be left
        //       as zero. This works for addition, but not multiplication. We just swap zeros
        //       to ones when multiplying, as the input has no zeros.
        if (self.op == '*') {
            inline for (0..4) |i| {
                if (self.numbers[i] == 0) self.numbers[i] = 1;
            }
        }
    }

    pub fn push(self: *Problem, num: u64) void {
        inline for (0..4) |i| {
            if (self.numbers[i] == 0) {
                self.numbers[i] = num;
                return;
            }
        }
    }

    pub fn calculate(self: Problem) u64 {
        return switch (self.op) {
            '+' => @reduce(.Add, self.numbers),
            '*' => @reduce(.Mul, self.numbers),
            else => std.debug.panic("invalid op: {c}", .{self.op}),
        };
    }
};

pub fn main() !void {
    var problems = try loadInput();
    defer problems.deinit(std.heap.smp_allocator);

    var total: u64 = 0;
    for (problems.items) |p| {
        total += p.calculate();
    }
    h.print("{d}\n", .{total});
}

pub fn loadInput() !std.ArrayList(Problem) {
    var problems: std.ArrayList(Problem) = .{};
    errdefer problems.deinit(std.heap.smp_allocator);

    var lines = h.InputLines.init();
    var j: usize = 0;
    while (try lines.next()) |line| : (j += 1) {
        var split = std.mem.tokenizeScalar(u8, line, ' ');
        var i: usize = 0;
        while (split.next()) |cell| : (i += 1) {
            if (isOp(cell)) |op| {
                problems.items[i].op = op;
            } else {
                const num = try std.fmt.parseInt(u32, cell, 10);
                if (j == 0) try problems.append(std.heap.smp_allocator, .{});
                problems.items[i].numbers[j] = num;
            }
        }
    }

    for (problems.items) |*p| p.fix();
    return problems;
}

fn isOp(s: []const u8) ?u8 {
    if (s.len == 1 and (s[0] == '+' or s[0] == '*')) return s[0];
    return null;
}
