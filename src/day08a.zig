// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub const Box = struct {
    data: @Vector(3, i32),

    pub fn eql(self: Box, other: Box) bool {
        return @reduce(.And, self.data == other.data);
    }

    pub fn dist(self: Box, other: Box) f32 {
        const delta = self.data - other.data;
        const delta_f: @Vector(3, f32) = @floatFromInt(delta);
        return @sqrt(@reduce(.Add, delta_f * delta_f));
    }

    pub fn parse(s: []const u8) !Box {
        var split = std.mem.splitScalar(u8, s, ',');
        const x = try std.fmt.parseInt(i32, split.next() orelse "", 10);
        const y = try std.fmt.parseInt(i32, split.next() orelse "", 10);
        const z = try std.fmt.parseInt(i32, split.next() orelse "", 10);
        return .{ .data = .{ x, y, z } };
    }
};

pub const BoxDist = struct {
    a: Box,
    b: Box,
    dist: f32,

    pub fn compute(a: Box, b: Box) BoxDist {
        return .{ .a = a, .b = b, .dist = a.dist(b) };
    }

    pub fn computeAll(boxes: []const Box) !std.MultiArrayList(BoxDist) {
        var distances: std.MultiArrayList(BoxDist) = .{};
        errdefer distances.deinit(std.heap.smp_allocator);

        // Compute distances for each combination of boxes
        for (boxes, 0..) |a, offset| {
            for (boxes[offset + 1 ..]) |b| {
                try distances.append(std.heap.smp_allocator, BoxDist.compute(a, b));
            }
        }

        // Sort the distances ascending
        const SortContext = struct {
            items: []f32,

            pub fn lessThan(self: @This(), a_index: usize, b_index: usize) bool {
                return self.items[a_index] < self.items[b_index];
            }
        };
        distances.sortUnstable(SortContext{ .items = distances.items(.dist) });

        return distances;
    }
};

pub fn main() !void {
    var boxToCircuit = try loadInput();
    defer boxToCircuit.deinit(std.heap.smp_allocator);

    var distances = try BoxDist.computeAll(boxToCircuit.keys());
    defer distances.deinit(std.heap.smp_allocator);

    // Compute circuits
    const is_test = boxToCircuit.contains(.{ .data = .{ 162, 817, 812 } });
    const limit: usize = if (is_test) 10 else 1000;

    var new_circuit_id: u32 = 1;
    for (0..limit) |i| {
        const a_box = distances.items(.a)[i];
        const b_box = distances.items(.b)[i];
        const a = boxToCircuit.getPtr(a_box) orelse unreachable;
        const b = boxToCircuit.getPtr(b_box) orelse unreachable;

        if (a.* == 0 and b.* == 0) {
            a.* = new_circuit_id;
            b.* = new_circuit_id;
            new_circuit_id += 1;
        } else if (b.* == 0) {
            b.* = a.*;
        } else if (a.* == 0) {
            a.* = b.*;
        } else if (a.* != b.*) {
            // Merge circuit b into a
            const dst = a.*;
            const src = b.*;
            for (boxToCircuit.values()) |*candidate| {
                if (candidate.* == src) candidate.* = dst;
            }
        } else {
            // a and b in the same circuit - nothing to do
        }

        std.debug.assert(a.* == b.*);
    }

    // Compute the lengths of each circuit
    var lengths = try std.heap.smp_allocator.alloc(u32, new_circuit_id);
    defer std.heap.smp_allocator.free(lengths);
    for (lengths) |*l| l.* = 0;
    for (boxToCircuit.values()) |circuit| {
        if (circuit != 0) lengths[circuit] += 1;
    }

    // Extract the 3 largest circuits
    std.mem.sort(u32, lengths, {}, std.sort.desc(u32));
    const total = lengths[0] * lengths[1] * lengths[2];
    h.print("{d}\n", .{total});
}

pub fn loadInput() !std.AutoArrayHashMapUnmanaged(Box, u32) {
    var boxes: std.AutoArrayHashMapUnmanaged(Box, u32) = .{};
    errdefer boxes.deinit(std.heap.smp_allocator);

    var lines = h.InputLines.init();
    while (try lines.next()) |line| {
        try boxes.put(std.heap.smp_allocator, try Box.parse(line), 0);
    }

    return boxes;
}
