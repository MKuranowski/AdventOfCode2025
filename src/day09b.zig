// © Copyright 2025 Mikołaj Kuranowski
// SPDX-License-Identifier: MIT

const std = @import("std");
const h = @import("helper");

const Point = @Vector(2, f64);
const Edge = struct { Point, Point };

pub fn main() !void {
    const boundary_vertices = try loadInput();
    defer std.heap.smp_allocator.free(boundary_vertices);

    const boundary = try computeBoundary(boundary_vertices);
    defer std.heap.smp_allocator.free(boundary);

    var largest_area: f64 = 0;
    for (boundary_vertices, 1..) |a, offset| {
        rectangles: for (boundary_vertices[offset..]) |b| {
            // Assume a thin rectangle won't be the largest. They break the coordinate offsets.
            if (@reduce(.Or, a == b)) continue;

            const area = computeArea(a, b);
            if (area <= largest_area) continue;

            const top_left = @min(a, b) + Point{ 0.25, 0.25 };
            const bottom_right = @max(a, b) - Point{ 0.25, 0.25 };
            const top_right = @select(f64, @Vector(2, bool){ false, true }, top_left, bottom_right);
            const bottom_left = @select(f64, @Vector(2, bool){ true, false }, top_left, bottom_right);

            const rect_edges = [4]Edge{
                .{ bottom_left, top_left },
                .{ top_left, top_right },
                .{ top_right, bottom_right },
                .{ bottom_right, bottom_left },
            };

            // If any edge intersects - inadmissable rectangle
            // Test from: https://stackoverflow.com/questions/4833802/check-if-polygon-is-inside-a-polygon/4833823
            // 1. Any point is inside the boundary (guaranteed because of how we pick rect vertices)
            // 2. None of the edges intersect.
            //
            // Actually the test above breaks if any edges overlap, hence for the edge overlap test
            // the rectangle indices are moved inward by a small epsilon (0.25).
            for (&rect_edges) |edge_a| {
                for (boundary) |edge_b| {
                    if (intersects(edge_a, edge_b)) continue :rectangles;
                }
            }

            largest_area = area;
        }
    }

    h.print("{d}\n", .{largest_area});
}

fn loadInput() ![]Point {
    var points: std.ArrayList(Point) = .{};
    defer points.deinit(std.heap.smp_allocator);

    var lines = h.InputLines.init();
    while (try lines.next()) |line| {
        var split = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(u32, split.next() orelse "", 10);
        const y = try std.fmt.parseInt(u32, split.next() orelse "", 10);
        const p = Point{ @floatFromInt(x), @floatFromInt(y) };
        try points.append(std.heap.smp_allocator, p);
    }

    return try points.toOwnedSlice(std.heap.smp_allocator);
}

fn computeArea(a: Point, b: Point) f64 {
    return @reduce(.Mul, @abs(a - b) + Point{ 1, 1 });
}

fn computeBoundary(vertices: []const Point) ![]Edge {
    var edges = try std.heap.smp_allocator.alloc(Edge, vertices.len);
    errdefer std.heap.smp_allocator.free(edges);

    edges[0] = .{ vertices[vertices.len - 1], vertices[0] };
    for (1..vertices.len) |i| {
        edges[i] = .{ vertices[i - 1], vertices[i] };
    }

    return edges;
}

/// Given line segments a[0] to a[1] and b[0] to b[1], returns true if they intersect
fn intersects(a: Edge, b: Edge) bool {
    // Direction vectors
    const da = a[1] - a[0];
    const db = b[1] - b[0];

    // Cross product in 2D: da.x * db.y - da.y * db.x
    const cross = da[0] * db[1] - da[1] * db[0];

    // Parallel or collinear lines
    if (cross == 0) return false;

    // Vector from a[0] to b[0]
    const ab = b[0] - a[0];

    // Parameter t for line a: a[0] + t * da
    const t = (ab[0] * db[1] - ab[1] * db[0]) / cross;

    // Parameter u for line b: b1 + u * db
    const u = (ab[0] * da[1] - ab[1] * da[0]) / cross;

    // Check if intersection is within both line segments
    return t >= 0 and t <= 1 and u >= 0 and u <= 1;
}

/// Given a boundary of a Polygon and an arbitrary Point,
/// uses the even-odd rule to check if the point is inside of the polygon.
///
/// Implementation from https://en.wikipedia.org/wiki/Even%E2%80%93odd_rule#Implementation
fn isInside(boundary: []const Edge, p: Point) bool {
    var contained = false;

    for (boundary) |edge| {
        const a = edge[0];
        const b = edge[1];

        if (p == a) return true; // point is a corner

        if ((a[1] > p[1]) != (b[1] > p[1])) {
            const slope = (p[0] - a[0]) * (b[1] - a[1]) - (b[0] - a[0]) * (p[1] - a[1]);
            if (slope == 0) return true; // point is on boundary
            if ((slope < 0) != (b[1] < a[1])) contained = !contained;
        }
    }

    return contained;
}
