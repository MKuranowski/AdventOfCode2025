// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const a = @import("day11a.zig");
const h = @import("helper");

pub fn main() !void {
    var graph = try a.loadInput();
    defer graph.deinit();

    const result = try totalPaths(graph, a.nodeIdFromStr("svr"), a.nodeIdFromStr("out"));
    h.print("{d}\n", .{result});
}

const State = struct {
    node: a.NodeId,
    hit_dac: bool = false,
    hit_fft: bool = false,
};

const Cache = struct {
    data: std.AutoArrayHashMapUnmanaged(State, usize) = .{},

    pub fn deinit(self: *Cache) void {
        self.data.deinit(std.heap.smp_allocator);
    }

    pub fn get(self: Cache, s: State) ?usize {
        return self.data.get(s);
    }

    pub fn put(self: *Cache, s: State, paths: usize) std.mem.Allocator.Error!void {
        try self.data.put(std.heap.smp_allocator, s, paths);
    }
};

fn totalPaths(g: a.Graph, from: a.NodeId, to: a.NodeId) std.mem.Allocator.Error!usize {
    var c: Cache = .{};
    defer c.deinit();

    return try totalPathsRecursive(g, &c, .{ .node = from }, to);
}

fn totalPathsRecursive(g: a.Graph, c: *Cache, from: State, to: a.NodeId) std.mem.Allocator.Error!usize {
    if (from.node == to) return if (from.hit_dac and from.hit_fft) 1 else 0;
    if (c.get(from)) |cached| return cached;

    const new_hit_dac = from.hit_dac or from.node == comptime a.nodeIdFromStr("dac");
    const new_hit_fft = from.hit_fft or from.node == comptime a.nodeIdFromStr("fft");

    var total: usize = 0;
    for (g.get(from.node)) |via| {
        total += try totalPathsRecursive(g, c, .{ .node = via, .hit_dac = new_hit_dac, .hit_fft = new_hit_fft }, to);
    }

    try c.put(from, total);
    return total;
}
