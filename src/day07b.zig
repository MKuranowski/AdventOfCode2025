// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const a = @import("day07a.zig");
const h = @import("helper");

const PositionSet = h.HashSet(a.Position);
const Cache = std.AutoHashMapUnmanaged(a.Position, u64);

pub fn main() !void {
    var splitters, const start, const last_row = try a.loadInput();
    defer splitters.deinit();

    var cache: Cache = .{};
    defer cache.deinit(std.heap.smp_allocator);

    const total = try computeTimelines(start, splitters, &cache, last_row);
    h.print("{d}\n", .{total});
}

fn computeTimelines(at: a.Position, splitters: PositionSet, cache: *Cache, last_row: usize) std.mem.Allocator.Error!u64 {
    if (at.y == last_row) return 1;
    if (cache.get(at)) |cached| return cached;

    var total: u64 = 0;
    if (splitters.has(at)) {
        total += try computeTimelines(.{ .y = at.y + 1, .x = at.x - 1 }, splitters, cache, last_row);
        total += try computeTimelines(.{ .y = at.y + 1, .x = at.x + 1 }, splitters, cache, last_row);
    } else {
        total += try computeTimelines(.{ .y = at.y + 1, .x = at.x }, splitters, cache, last_row);
    }

    try cache.put(std.heap.smp_allocator, at, total);
    return total;
}
