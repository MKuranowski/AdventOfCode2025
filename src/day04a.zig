// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub const Position = struct { y: u8, x: u8 };

pub const PositionSet = struct {
    m: std.AutoArrayHashMapUnmanaged(Position, void) = .{},

    pub fn deinit(self: *PositionSet) void {
        self.m.deinit(std.heap.smp_allocator);
    }

    pub fn clearRetainingCapacity(self: *PositionSet) void {
        self.m.clearRetainingCapacity();
    }

    pub fn len(self: PositionSet) usize {
        return self.m.count();
    }

    pub fn add(self: *PositionSet, pos: Position) std.mem.Allocator.Error!void {
        try self.m.put(std.heap.smp_allocator, pos, {});
    }

    pub fn remove(self: *PositionSet, pos: Position) void {
        _ = self.m.swapRemove(pos);
    }

    pub fn has(self: PositionSet, pos: Position) bool {
        return self.m.contains(pos);
    }

    pub fn iter(self: PositionSet) []Position {
        return self.m.keys();
    }

    pub fn loadFromInput() !PositionSet {
        var lines = h.InputLines.init();

        var positions: PositionSet = .{};
        errdefer positions.deinit();

        var y: u8 = 1;
        while (try lines.next()) |line| : (y += 1) {
            for (line, 1..) |c, x_big| {
                const x = @as(u8, @intCast(x_big));
                if (c == '@') {
                    try positions.add(.{ .y = y, .x = x });
                }
            }
        }

        return positions;
    }
};

pub fn main() !void {
    var rolls = try PositionSet.loadFromInput();
    defer rolls.deinit();

    var accessible: u32 = 0;
    for (rolls.iter()) |pos| {
        accessible += @intFromBool(isAccessible(pos, rolls));
    }
    h.print("{d}\n", .{accessible});
}

fn countNeighbors(pos: Position, others: PositionSet) u32 {
    var neighbors: u32 = 0;

    const candidates = [_]Position{
        .{ .y = pos.y - 1, .x = pos.x - 1 },
        .{ .y = pos.y - 1, .x = pos.x },
        .{ .y = pos.y - 1, .x = pos.x + 1 },
        .{ .y = pos.y, .x = pos.x - 1 },
        .{ .y = pos.y, .x = pos.x + 1 },
        .{ .y = pos.y + 1, .x = pos.x - 1 },
        .{ .y = pos.y + 1, .x = pos.x },
        .{ .y = pos.y + 1, .x = pos.x + 1 },
    };

    for (candidates) |candidate| {
        neighbors += @intFromBool(others.has(candidate));
    }

    return neighbors;
}

pub fn isAccessible(pos: Position, others: PositionSet) bool {
    return countNeighbors(pos, others) < 4;
}
