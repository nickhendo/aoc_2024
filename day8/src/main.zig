const std = @import("std");

const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 2550);
    defer allocator.free(bytes);

    const file_contents = try readFile(bytes, "input.txt");

    print("num_bytes: {d}\nlen: {d}\n", .{ file_contents.num_bytes, file_contents.contents.len });

    const result = try getResult(allocator, file_contents.contents);

    print("Answer: {d}\n", .{result});
}

const Coord = struct {
    x: isize,
    y: isize,
};

fn getResult(allocator: std.mem.Allocator, input: []u8) !i64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator();

    var map = std.AutoHashMap(u8, std.ArrayList(usize)).init(arena_allocator);

    var width: usize = 0;
    for (input, 0..) |letter, index| {
        if (letter == '\n') {
            width = index + 1;
            break;
        }
    }

    for (input, 0..) |char, index| {
        if (char != '\n' and char != '.') {
            var val = try map.getOrPut(char);
            if (val.found_existing) {
                try val.value_ptr.append(index);
            } else {
                var list = std.ArrayList(usize).init(arena_allocator);
                try list.append(index);
                val.value_ptr.* = list;
            }
        }
    }

    var num_antinodes: i32 = 0;
    var iterator = map.iterator();

    var modifiable_input = try allocator.dupe(u8, input);
    defer allocator.free(modifiable_input);

    printLn("Length: {d}", .{modifiable_input.len});

    while (iterator.next()) |entry| {
        var i: usize = 0;

        while (i < entry.value_ptr.*.items.len) : (i += 1) {
            var j: usize = i + 1;
            const cur_len = entry.value_ptr.*.items.len;
            while (j < cur_len) : (j += 1) {
                const index1: isize = @intCast(entry.value_ptr.*.items[i]);
                const index2: isize = @intCast(entry.value_ptr.*.items[j]);

                const iwidth: isize = @intCast(width);

                const coord1 = indexToCoord(index1, iwidth);
                const coord2 = indexToCoord(index2, iwidth);

                const x_dist: isize = @intCast(coord2.x - coord1.x);
                const y_dist: isize = @intCast(coord2.y - coord1.y);

                var coord1_new = coord1;
                var coord2_new = coord2;

                coord1_new.x -= x_dist;
                coord1_new.y -= y_dist;

                coord2_new.x += x_dist;
                coord2_new.y += y_dist;

                const ilen: isize = @intCast(input.len);
                const height: isize = @divFloor(ilen, iwidth);
                while (0 <= coord1_new.y and coord1_new.y < height and 0 <= coord1_new.x and coord1_new.x < width) {
                    const new_index: usize = @intCast(coord1_new.y * iwidth + coord1_new.x);
                    if (modifiable_input[new_index] != '#' and modifiable_input[new_index] != '\n') {
                        num_antinodes += 1;
                        modifiable_input[new_index] = '#';
                    }

                    coord1_new.x -= x_dist;
                    coord1_new.y -= y_dist;
                }

                while (0 <= coord2_new.y and coord2_new.y < height and 0 <= coord2_new.x and coord2_new.x < width) {
                    const new_index: usize = @intCast(coord2_new.y * iwidth + coord2_new.x);
                    if (modifiable_input[new_index] != '#' and modifiable_input[new_index] != '\n') {
                        num_antinodes += 1;
                        modifiable_input[new_index] = '#';
                    }

                    coord2_new.x += x_dist;
                    coord2_new.y += y_dist;
                }
            }
        }
    }

    for (modifiable_input) |char| {
        if (char == '\n') {
            continue;
        }

        if (char == '.') {
            continue;
        }

        if (char == '#') {
            continue;
        }

        num_antinodes += 1;
    }

    printLn("Mod:\n{s}", .{modifiable_input});

    return num_antinodes;
}

fn indexToCoord(index: isize, width: isize) Coord {
    return Coord{
        .x = @mod(index, width),
        .y = @divFloor(index, width),
    };
}

test getResult {
    var test_input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
        \\
    .*;
    const allocator = std.testing.allocator;
    const answer = try getResult(allocator, &test_input);
    try std.testing.expectEqual(34, answer);
}

fn readFile(bytes: []u8, filename: []const u8) !struct { num_bytes: usize, contents: []u8 } {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const num_bytes = try file.readAll(bytes);
    return .{ .num_bytes = num_bytes, .contents = bytes };
}

fn printLn(comptime fmt: []const u8, args: anytype) void {
    const fmt_with_newline = fmt ++ "\n";
    print(fmt_with_newline, args);
}
