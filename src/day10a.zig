// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

const Indicators = std.bit_set.IntegerBitSet(10);

fn parseIndicatorsFromHashes(s: []const u8) Indicators {
    var set = Indicators.initEmpty();
    for (s, 0..) |c, i| {
        if (c == '#') set.set(i);
    }
    return set;
}

fn parseIndicatorsFromIntegers(s: []const u8) !Indicators {
    var set = Indicators.initEmpty();

    var split = std.mem.splitScalar(u8, s, ',');
    while (split.next()) |num_text| {
        const num = try std.fmt.parseInt(u4, num_text, 10);
        set.set(num);
    }

    return set;
}

const Machine = struct {
    lights: Indicators = Indicators.initEmpty(),
    buttons: [13]Indicators = std.mem.zeroes([13]Indicators),

    pub fn format(self: Machine, writer: *std.Io.Writer) !void {
        // Print the lights
        try writer.writeByte('[');
        for (0..10) |i| try writer.writeByte(if (self.lights.isSet(i)) '#' else '.');
        try writer.writeByte(']');

        // Print the button sets
        for (self.buttons) |buttons| {
            if (buttons.count() == 0) continue;
            try writer.writeByte(' ');
            try writer.writeByte('(');
            var it = buttons.iterator(.{});
            var is_first = true;
            while (it.next()) |num| : (is_first = false) {
                if (!is_first) try writer.writeByte(',');
                try writer.print("{d}", .{num});
            }
            try writer.writeByte(')');
        }
    }

    pub fn parse(line: []const u8) !Machine {
        var self: Machine = .{};

        var split = std.mem.tokenizeScalar(u8, line, ' ');
        var buttons_idx: u8 = 0;
        while (split.next()) |part| {
            switch (part[0]) {
                '[' => self.lights = parseIndicatorsFromHashes(part[1 .. part.len - 1]),
                '(' => {
                    self.buttons[buttons_idx] = try parseIndicatorsFromIntegers(part[1 .. part.len - 1]);
                    buttons_idx += 1;
                },
                else => {},
            }
        }

        return self;
    }
};

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

const SolverQueueItem = struct { Indicators, u32 };

fn compareSolverQueueItem(context: void, a: SolverQueueItem, b: SolverQueueItem) std.math.Order {
    _ = context;
    return std.math.order(a[1], b[1]);
}

fn solve(m: Machine) !u32 {
    var cache: std.AutoHashMapUnmanaged(Indicators, u32) = .{};
    defer cache.deinit(std.heap.smp_allocator);

    var queue = std.PriorityQueue(SolverQueueItem, void, compareSolverQueueItem).init(std.heap.smp_allocator, {});
    defer queue.deinit();

    // Push the initial state
    try queue.add(.{ Indicators.initEmpty(), 0 });

    // Process queue until we get to the target states
    while (queue.removeOrNull()) |elem| {
        const lights, const presses = elem;

        // Found the solution - return it
        if (lights.eql(m.lights)) return presses;

        // Stop expanding if there's a better path to this state
        const entry = try cache.getOrPut(std.heap.smp_allocator, lights);
        if (entry.found_existing and entry.value_ptr.* <= presses) {
            continue;
        } else {
            entry.value_ptr.* = presses;
        }

        // Expand the queue
        for (m.buttons) |button_set| {
            var new_lights = lights;
            new_lights.toggleSet(button_set);
            try queue.add(.{ new_lights, presses + 1 });
        }
    }

    return error.NoSolution;
}

pub fn main() !void {
    const machines = try loadInput();
    defer std.heap.smp_allocator.free(machines);

    var total: usize = 0;
    for (machines) |m| {
        const solution = try solve(m);
        total += solution;
    }

    h.print("{d}\n", .{total});
}
