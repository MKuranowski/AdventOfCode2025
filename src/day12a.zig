// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

const Tree = struct {
    rows: u32 = 0,
    cols: u32 = 0,
    presents: [6]u32 = .{0} ** 6,

    pub fn format(self: Tree, w: *std.Io.Writer) !void {
        try w.print("{d}x{d}:", .{ self.rows, self.cols });
        for (self.presents) |i| try w.print(" {d}", .{i});
    }

    pub fn hasEnoughSpace(self: Tree, present_sizes: [6]u32) bool {
        const space = self.rows * self.cols;
        var required: u32 = 0;

        for (self.presents, 0..) |count, i| {
            const sz = present_sizes[i];
            required += sz * count;
        }

        return required <= space;
    }
};

pub fn main() !void {
    const trees, const present_sizes = try loadInput();
    defer std.heap.smp_allocator.free(trees);

    var total: usize = 0;
    for (trees) |tree| {
        total += @intFromBool(tree.hasEnoughSpace(present_sizes));
    }
    h.print("{d}\n", .{total});
}

fn loadInput() !struct { []Tree, [6]u32 } {
    var present_sizes: [6]u32 = .{0} ** 6;
    var trees: std.ArrayList(Tree) = .{};
    defer trees.deinit(std.heap.smp_allocator);

    var present_row: u32 = 0;

    var lines = h.InputLines.init();
    while (try lines.next()) |line| {
        if (std.mem.indexOfScalar(u8, line, 'x') != null) {
            var tree: Tree = .{};
            var parts = std.mem.splitScalar(u8, line, ' ');

            const size_str = std.mem.trimEnd(u8, parts.next() orelse "", ":");
            const size_sep = std.mem.indexOfScalar(u8, size_str, 'x') orelse 0;
            tree.rows = try std.fmt.parseInt(u32, size_str[0..size_sep], 10);
            tree.cols = try std.fmt.parseInt(u32, size_str[size_sep + 1 ..], 10);

            var i: u32 = 0;
            while (parts.next()) |presents_str| : (i += 1) {
                tree.presents[i] = try std.fmt.parseInt(u32, presents_str, 10);
            }

            try trees.append(std.heap.smp_allocator, tree);
        } else if (line.len == 3 and (line[0] == '#' or line[0] == '.')) {
            const present = present_row / 3;
            present_sizes[present] += @intCast(h.countScalar(u8, line, '#'));
            present_row += 1;
        }
    }

    return .{ try trees.toOwnedSlice(std.heap.smp_allocator), present_sizes };
}
