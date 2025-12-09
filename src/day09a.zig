// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

pub const Tile = struct {
    data: @Vector(2, i64),

    pub fn eql(self: Tile, other: Tile) bool {
        return @reduce(.And, self.data == other.data);
    }

    pub fn area(self: Tile, other: Tile) u64 {
        return @reduce(.Mul, @abs(self.data - other.data) + @Vector(2, u64){ 1, 1 });
    }

    pub fn format(self: Tile, writer: *std.Io.Writer) !void {
        try writer.print("{d},{d}", .{ self.data[0], self.data[1] });
    }

    pub fn parse(s: []const u8) !Tile {
        var split = std.mem.splitScalar(u8, s, ',');
        const x = try std.fmt.parseInt(i64, split.next() orelse "", 10);
        const y = try std.fmt.parseInt(i64, split.next() orelse "", 10);
        return .{ .data = .{ x, y } };
    }
};

pub fn main() !void {
    var tiles = try loadInput();
    defer tiles.deinit(std.heap.smp_allocator);

    // Try all combinations of tiles
    var largest_area: u64 = 0;
    for (tiles.items, 1..) |a, offset| {
        for (tiles.items[offset..]) |b| {
            largest_area = @max(largest_area, a.area(b));
        }
    }

    h.print("{d}\n", .{largest_area});
}

pub fn loadInput() !std.ArrayList(Tile) {
    var tiles: std.ArrayList(Tile) = .{};
    errdefer tiles.deinit(std.heap.smp_allocator);

    var lines = h.InputLines.init();
    while (try lines.next()) |line| {
        try tiles.append(std.heap.smp_allocator, try Tile.parse(line));
    }

    return tiles;
}
