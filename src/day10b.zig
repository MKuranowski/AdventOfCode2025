// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT
// cspell: words glpsol

const std = @import("std");
const h = @import("helper");

const max_counters = 10;
const max_buttons = 13;

const Levels = [max_counters]u16;
const Button = std.bit_set.IntegerBitSet(max_counters);
const Buttons = [max_buttons]Button;

fn parseButton(s: []const u8) !Button {
    var b = Button.initEmpty();

    var split = std.mem.splitScalar(u8, s, ',');
    while (split.next()) |num_text| {
        const i = try std.fmt.parseInt(u16, num_text, 10);
        b.set(i);
    }

    return b;
}

fn parseLevels(s: []const u8) !struct { Levels, usize } {
    var set: Levels = .{0} ** max_counters;

    var split = std.mem.splitScalar(u8, s, ',');
    var i: usize = 0;
    while (split.next()) |num_text| : (i += 1) {
        set[i] = try std.fmt.parseInt(u16, num_text, 10);
    }

    return .{ set, i };
}

const Machine = struct {
    target_buf: Levels,
    target_len: std.math.IntFittingRange(0, max_counters),

    buttons_buf: Buttons,
    buttons_len: std.math.IntFittingRange(0, max_buttons),

    pub inline fn target(self: Machine) []const u16 {
        return self.target_buf[0..self.target_len];
    }

    pub inline fn buttons(self: Machine) []const Button {
        return self.buttons_buf[0..self.buttons_len];
    }

    pub fn format(self: Machine, writer: *std.Io.Writer) !void {
        // Print the target set
        try writer.writeByte('{');
        for (self.target(), 0..) |num, i| {
            if (i > 0) try writer.writeByte(',');
            try writer.print("{d}", .{num});
        }
        try writer.writeByte('}');

        // Print the button sets
        for (self.buttons()) |button| {
            try writer.writeByte(' ');
            try writer.writeByte('(');
            var is_first = true;
            for (0..self.target_len) |i| {
                if (button.isSet(i)) {
                    if (!is_first) try writer.writeByte(',');
                    try writer.print("{d}", .{i});
                    is_first = false;
                }
            }
            try writer.writeByte(')');
        }
    }

    pub fn parse(line: []const u8) !Machine {
        var self: Machine = .{
            .target_buf = undefined,
            .target_len = 0,
            .buttons_buf = undefined,
            .buttons_len = 0,
        };

        var split = std.mem.tokenizeScalar(u8, line, ' ');
        var buttons_idx: u8 = 0;
        while (split.next()) |part| {
            switch (part[0]) {
                '(' => {
                    self.buttons_buf[buttons_idx] = try parseButton(part[1 .. part.len - 1]);
                    buttons_idx += 1;
                },
                '{' => {
                    const t, const len = try parseLevels(part[1 .. part.len - 1]);
                    self.target_buf = t;
                    self.target_len = @intCast(len);
                },
                else => {},
            }
        }

        self.buttons_len = @intCast(buttons_idx);
        return self;
    }

    pub fn solve(self: Machine, i: usize) !usize {
        var data_filename_buf: [16]u8 = undefined;
        var data_path_buf: [64]u8 = undefined;

        const data_filename = std.fmt.bufPrintZ(&data_filename_buf, "{:03}.dat", .{i}) catch unreachable;
        const data_path = std.fmt.bufPrintZ(&data_path_buf, "10b/{s}", .{data_filename}) catch unreachable;

        // 1. Create a .dat file for GLPSOL
        try self.writeGlpsolDataToFile(data_path);

        // 2. Call the solver
        const result = try std.process.Child.run(.{
            .allocator = std.heap.smp_allocator,
            .argv = &.{ "glpsol", "-m", "src/day10b.mod", "-d", data_path },
            .expand_arg0 = .expand,
        });
        defer std.heap.smp_allocator.free(result.stdout);
        defer std.heap.smp_allocator.free(result.stderr);

        // 3. Check that the solver exited successfully
        const ok = switch (result.term) {
            .Exited => |exit_code| exit_code == 0,
            else => false,
        };
        if (!ok) {
            dumpGlpsolError(result, data_path) catch {};
            return error.NoSolution;
        }

        // 4. Ensure glpsol found the optimal solution
        if (std.mem.indexOf(u8, result.stdout, "INTEGER OPTIMAL SOLUTION FOUND") == null) {
            std.debug.print("{d}: no optimal integer solution\n", .{i});
            dumpGlpsolError(result, data_path) catch {};
            return error.NoSolution;
        }

        // 5. Extract the total number of clicks from output
        const needle = "total clicks: ";
        if (std.mem.indexOf(u8, result.stdout, needle)) |needle_idx| {
            const start = needle_idx + needle.len;
            const end = std.mem.indexOfAnyPos(u8, result.stdout, start, "\r\n") orelse result.stdout.len;
            const clicks_str = result.stdout[start..end];
            return try std.fmt.parseInt(usize, clicks_str, 10);
        } else {
            std.debug.print("{d}: no \"total clicks: \" in the output\n", .{i});
            dumpGlpsolError(result, data_path) catch {};
            return error.NoSolution;
        }
    }

    pub fn writeGlpsolDataToFile(self: Machine, path: [:0]const u8) !void {
        var buf: [2048]u8 = undefined;

        var f = try std.fs.cwd().createFileZ(path, .{ .truncate = true });
        defer f.close();

        var w = f.writer(&buf);
        try self.writeGlpsolData(&w.interface);
        try w.interface.flush();
    }

    pub fn writeGlpsolData(self: Machine, w: *std.Io.Writer) !void {
        try w.writeAll("data;\n\nset counters :=");
        for (0..self.target_len) |i| try w.print(" C{d}", .{i});
        try w.writeAll(";\nset buttons :=");
        for (0..self.buttons_len) |i| try w.print(" B{d}", .{i});
        try w.writeAll(";\n\nparam target :=\n");
        for (self.target(), 0..) |t, i| try w.print("    C{d} {d}\n", .{ i, t });
        try w.writeAll("    ;\n\nparam wiring :=\n    :   ");
        for (0..self.target_len) |i| try w.print(" C{d}", .{i});
        try w.writeAll(" :=\n");
        for (self.buttons(), 0..) |b, i| {
            try w.print("    B{d} ", .{i});
            if (i >= 10) try w.writeByte(' ');
            try w.writeByte(' ');
            for (0..self.target_len) |t| {
                try w.writeAll(if (b.isSet(t)) "  1" else "  0");
            }
            try w.writeByte('\n');
        }
        try w.writeAll("    ;\n\nend;\n");
    }
};

fn dumpGlpsolError(r: std.process.Child.RunResult, data_path: []const u8) !void {
    var buf: [2048]u8 = undefined;
    var f = std.fs.File.stderr();
    var fw = f.writer(&buf);
    var w = &fw.interface;

    try w.print("glpsol -m src/day10b.mod -d {s} failed with ", .{data_path});
    switch (r.term) {
        .Exited => |exit_code| try w.print("exit code {d}\n", .{exit_code}),
        .Signal => |signal| try w.print("signal {d}\n", .{signal}),
        .Stopped => try w.writeAll("\"stopped\"\n"),
        .Unknown => try w.writeAll("\"unknown\"\n"),
    }

    try w.writeAll("--- STDOUT ---\n");
    try w.writeAll(r.stdout);
    try w.writeAll("\n--- STDERR ---\n");
    try w.writeAll(r.stderr);
    try w.writeAll("\n--------------\n");

    try w.flush();
}

fn loadInput() ![]Machine {
    var machines: std.ArrayList(Machine) = .{};
    defer machines.deinit(std.heap.smp_allocator);

    var lines = h.InputLines.init();
    while (try lines.next()) |line| {
        const m = try Machine.parse(line);
        try machines.append(std.heap.smp_allocator, m);
    }

    return try machines.toOwnedSlice(std.heap.smp_allocator);
}

pub fn main() !void {
    const machines = try loadInput();
    defer std.heap.smp_allocator.free(machines);

    // Ensure the directory for .dat files for the solver exists
    try std.fs.cwd().makePath("10b");

    var total: usize = 0;
    for (machines, 0..) |m, i| {
        const solution = try m.solve(i);
        total += solution;
    }
    h.print("{d}\n", .{total});
}
