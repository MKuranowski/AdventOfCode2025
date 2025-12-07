// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub const Position = struct { y: u8, x: u8 };

pub fn main() !void {
    var rolls = try loadInput();
    defer rolls.deinit();

    var accessible: u32 = 0;
    for (rolls.iter()) |pos| {
        accessible += @intFromBool(isAccessible(pos, rolls));
    }
    h.print("{d}\n", .{accessible});
}

pub fn loadInput() !h.HashSet(Position) {
    var lines = h.InputLines.init();

    var positions: h.HashSet(Position) = .{};
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

fn countNeighbors(pos: Position, others: h.HashSet(Position)) u32 {
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

pub fn isAccessible(pos: Position, others: h.HashSet(Position)) bool {
    return countNeighbors(pos, others) < 4;
}
