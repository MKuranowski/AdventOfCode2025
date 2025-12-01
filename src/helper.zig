// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");

pub fn print(comptime fmt: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const f = std.fs.File.stdout();
    var w = f.writer(&buf);
    w.interface.print(fmt, args) catch {};
    w.interface.flush() catch {};
}

pub fn readInput() ![]const u8 {
    var buf: [4096]u8 = undefined;
    const stdin = std.fs.File.stdin();
    var reader = stdin.reader(&buf);
    return try reader.interface.allocRemaining(std.heap.smp_allocator, .unlimited);
}

pub const InputLines = struct {
    buf: [4096]u8 = undefined,
    r: std.fs.File.Reader,

    pub inline fn init() InputLines {
        var l: InputLines = undefined;
        l.r = std.fs.File.stdin().reader(&l.buf);
        return l;
    }

    pub fn next(self: *InputLines) !?[]const u8 {
        const line = self.r.interface.takeDelimiterInclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => {
                    const leftover = self.r.interface.buffered();
                    if (leftover.len > 0) {
                        self.r.interface.tossBuffered();
                        return std.mem.trimEnd(u8, leftover, "\r\n");
                    } else {
                        return null;
                    }
                },
                inline else => |e| return e,
            }
        };

        return std.mem.trimEnd(u8, line, "\r\n");
    }
};
