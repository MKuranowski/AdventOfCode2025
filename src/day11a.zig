// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub const NodeId = u24;

pub fn nodeIdFromStr(s: []const u8) NodeId {
    std.debug.assert(s.len == 3);
    return @as(u24, s[0]) | (@as(u24, s[1]) << 8) | (@as(u24, s[2]) << 16);
}

pub fn nodeIdToStr(id: NodeId) [3]u8 {
    return .{ @truncate(id), @truncate(id >> 8), @truncate(id >> 16) };
}

pub const Graph = struct {
    data: std.AutoHashMapUnmanaged(NodeId, []NodeId) = .{},

    pub fn deinit(self: *Graph) void {
        var it = self.data.valueIterator();
        while (it.next()) |slice| std.heap.smp_allocator.free(slice.*);
        self.data.deinit(std.heap.smp_allocator);
    }

    pub fn format(self: Graph, w: *std.Io.Writer) !void {
        var it = self.data.iterator();
        while (it.next()) |entry| {
            try w.print("{s}:", .{nodeIdToStr(entry.key_ptr.*)});
            for (entry.value_ptr.*) |to| try w.print(" {s}", .{nodeIdToStr(to)});
            try w.writeByte('\n');
        }
    }

    pub fn get(self: Graph, from: NodeId) []NodeId {
        return self.data.get(from) orelse @as([]NodeId, &.{});
    }

    pub fn put(self: *Graph, from: NodeId, owned_slice: []NodeId) std.mem.Allocator.Error!void {
        try self.data.putNoClobber(std.heap.smp_allocator, from, owned_slice);
    }
};

pub fn main() !void {
    var graph = try loadInput();
    defer graph.deinit();

    const result = totalPaths(graph, nodeIdFromStr("you"), nodeIdFromStr("out"));
    h.print("{d}\n", .{result});
}

fn totalPaths(g: Graph, from: NodeId, to: NodeId) usize {
    if (from == to) return 1;

    var total: usize = 0;
    for (g.get(from)) |via| {
        total += totalPaths(g, via, to);
    }
    return total;
}

pub fn loadInput() !Graph {
    var graph: Graph = .{};
    errdefer graph.deinit();

    var lines = h.InputLines.init();
    while (try lines.next()) |line| {
        const from = nodeIdFromStr(line[0..3]);

        const to_strings = line[5..];
        var to_strings_it = std.mem.splitScalar(u8, to_strings, ' ');

        var tos = try std.heap.smp_allocator.alloc(NodeId, std.mem.count(u8, to_strings, " ") + 1);
        errdefer std.heap.smp_allocator.free(tos);

        var i: usize = 0;
        while (to_strings_it.next()) |to_string| : (i += 1) {
            tos[i] = nodeIdFromStr(to_string);
        }

        try graph.put(from, tos);
    }

    return graph;
}
