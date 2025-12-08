// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const a = @import("day08a.zig");
const h = @import("helper");

pub fn main() !void {
    var boxToCircuit = try a.loadInput();
    defer boxToCircuit.deinit(std.heap.smp_allocator);

    var distances = try a.BoxDist.computeAll(boxToCircuit.keys());
    defer distances.deinit(std.heap.smp_allocator);

    // Compute circuits
    var total_circuits = boxToCircuit.count();
    var new_circuit_id: u32 = 1;
    for (0..distances.len) |i| {
        const a_box = distances.items(.a)[i];
        const b_box = distances.items(.b)[i];
        const a_circuit = boxToCircuit.getPtr(a_box) orelse unreachable;
        const b_circuit = boxToCircuit.getPtr(b_box) orelse unreachable;

        if (a_circuit.* == 0 and b_circuit.* == 0) {
            a_circuit.* = new_circuit_id;
            b_circuit.* = new_circuit_id;
            new_circuit_id += 1;
            total_circuits -= 1;
        } else if (b_circuit.* == 0) {
            b_circuit.* = a_circuit.*;
            total_circuits -= 1;
        } else if (a_circuit.* == 0) {
            a_circuit.* = b_circuit.*;
            total_circuits -= 1;
        } else if (a_circuit.* != b_circuit.*) {
            // Merge circuit b into a
            const dst = a_circuit.*;
            const src = b_circuit.*;
            for (boxToCircuit.values()) |*candidate| {
                if (candidate.* == src) candidate.* = dst;
            }
            total_circuits -= 1;
        } else {
            // a and b in the same circuit - nothing to do
        }

        std.debug.assert(a_circuit.* == b_circuit.*);

        if (total_circuits == 1) {
            h.print("\ta: {any}\n\tb: {any}\n", .{ a_box, b_box });
            const result = @as(i64, a_box.data[0]) * @as(i64, b_box.data[0]);
            h.print("{d}\n", .{result});
            return;
        }
    }

    std.debug.panic("left with more than one circuit", .{});
}
