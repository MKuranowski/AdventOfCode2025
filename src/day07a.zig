// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub const Position = struct { y: u8, x: u8 };

pub fn main() !void {
    var splitters, const start, const last_row = try loadInput();
    defer splitters.deinit();

    var beams: h.HashSet(Position) = .{};
    var new_beams: h.HashSet(Position) = .{};
    defer beams.deinit();
    defer new_beams.deinit();

    try beams.add(start);

    var total: usize = 0;

    for (0..last_row) |row| {
        new_beams.clearRetainingCapacity();

        for (beams.iter()) |b| {
            std.debug.assert(b.y == row);
            if (splitters.has(b)) {
                total += 1;
                try new_beams.add(.{ .y = b.y + 1, .x = b.x - 1 });
                try new_beams.add(.{ .y = b.y + 1, .x = b.x + 1 });
            } else {
                try new_beams.add(.{ .y = b.y + 1, .x = b.x });
            }
        }

        beams.swap(&new_beams);
    }

    h.print("{d}\n", .{total});
}

pub fn loadInput() !struct { h.HashSet(Position), Position, usize } {
    var start: Position = .{ .y = 0, .x = 0 };
    var splitters: h.HashSet(Position) = .{};
    errdefer splitters.deinit();

    var lines = h.InputLines.init();
    var y: usize = 0;
    while (try lines.next()) |line| : (y += 1) {
        for (line, 0..) |c, x| {
            const p: Position = .{ .y = @intCast(y), .x = @intCast(x) };

            switch (c) {
                'S' => start = p,
                '^' => try splitters.add(p),
                else => {},
            }
        }
    }

    return .{ splitters, start, y };
}
