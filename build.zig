// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");

const days = [_][:0]const u8{
    "day01a",
    "day01b",
    "day02a",
    "day02b",
    "day03a",
    "day03b",
    "day04a",
    "day04b",
    "day05a",
    "day05b",
    "day06a",
    "day06b",
    "day07a",
    "day07b",
    "day08a",
    "day08b",
    "day09a",
    "day09b",
    "day10a",
    "day10b",
    "day11a",
    "day11b",
    "day12a",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("aoc2025-helper", .{
        .root_source_file = b.path("src/helper.zig"),
        .optimize = optimize,
        .target = target,
    });

    inline for (days) |day| {
        const exe = b.addExecutable(.{
            .name = "aoc2025" ++ day,
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/" ++ day ++ ".zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "helper", .module = mod },
                },
            }),
        });

        b.installArtifact(exe);

        const run_step = b.step("run-" ++ day, "Run solver for " ++ day);
        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
    }
}
