const std = @import("std");

const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

// const north: u8 = '^';
// const south: u8 = 'v';
// const east: u8 = '>';
// const west: u8 = '<';
const directions = enum(u8) {
    north = '^',
    south = 'v',
    east = '>',
    west = '<',
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 17030);
    defer allocator.free(bytes);

    const file_contents = try readFile(bytes, "input.txt");

    print("num_bytes: {d}\nlen: {d}\n", .{ file_contents.num_bytes, file_contents.contents.len });

    const result = try getResult(file_contents.contents);

    print("Answer: {d}\n", .{result});
}

const Location = struct {
    position: usize,
    direction: directions,
};

fn getResult(input: []u8) !i32 {
    var width: usize = 0;
    for (input, 0..) |char, index| {
        if (char == '\n') {
            width = index + 1;
            break;
        }
    }
    printLn("Width: {d}", .{width});

    const starting_position = getPosition(input);
    // printLn("Starting position: {any}, char: {c}", .{ location, input[location.position] });

    var num_loops: i32 = 0;

    outer: for (input, 0..) |char, index| {
        if (char != '.') {
            continue;
        }

        var location = Location{
            .position = starting_position,
            .direction = getDirection(@constCast(&input), starting_position),
        };

        var visited = [_]bool{false} ** 100_000;
        for (visited) |already_visited| {
            assert(!already_visited);
        }

        input[index] = '#';

        var position_next = location.position;

        while (position_next < input.len) {
            position_next = getNextPosition(@constCast(&input), location, width);

            var visited_index: usize = location.position * 4 + getDirectionIndex(location.direction);
            // printLn("Visited index: {d}", .{visited_index});
            if (visited[visited_index]) {
                num_loops += 1;
                location.position = starting_position;
                input[index] = '.';
                continue :outer;
            }
            visited[visited_index] = true;

            if (position_next == 0 or position_next >= input.len) {
                break;
            }
            if (input[position_next] == '\n') {
                break;
            }

            while (input[position_next] == '#') {
                const direction = rotate(location.direction);
                location.direction = direction;

                visited_index = location.position * 4 + getDirectionIndex(location.direction);
                // printLn("Visited iindex: {d}", .{visited_index});
                if (visited[visited_index]) {
                    num_loops += 1;
                    location.position = starting_position;
                    input[index] = '.';
                    continue :outer;
                }
                position_next = getNextPosition(@constCast(&input), location, width);
            }

            if (position_next == 0 or position_next >= input.len) {
                input[index] = '.';
                continue :outer;
            }

            if (input[position_next] == '\n') {
                input[index] = '.';
                continue :outer;
            }

            location.position = position_next;
        }
        // printLn("--------\n{s}", .{input});
        input[index] = '.';
    }
    // printLn("Finished path:\n{s}", .{input});
    return num_loops;
}

fn getDirectionIndex(direction: directions) usize {
    switch (direction) {
        directions.north => {
            return 0;
        },
        directions.south => {
            return 1;
        },
        directions.east => {
            return 2;
        },
        directions.west => {
            return 3;
        },
    }
}

fn getDirection(input: *[]u8, position: usize) directions {
    switch (input.*[position]) {
        @intFromEnum(directions.north) => {
            return directions.north;
        },
        @intFromEnum(directions.south) => {
            return directions.south;
        },
        @intFromEnum(directions.east) => {
            return directions.east;
        },
        @intFromEnum(directions.west) => {
            return directions.west;
        },
        else => {
            unreachable;
        },
    }
}

fn rotate(direction: directions) directions {
    switch (direction) {
        directions.north => {
            return directions.east;
        },
        directions.south => {
            return directions.west;
        },
        directions.east => {
            return directions.south;
        },
        directions.west => {
            return directions.north;
        },
    }
}

fn move(input: *[]u8, position: usize) void {
    _ = input;
    _ = position;
}

fn getNextPosition(input: *[]u8, location: Location, width: usize) usize {
    // printLn("Current: {c}", .{input.*[position_current]});
    switch (location.direction) {
        directions.north => {
            var coord = indexToCoord(location.position, width);
            if (coord.y == 0) {
                return input.len;
            }
            coord.y -= 1;
            // printLn("Coord: {any}", .{coord});
            return coordToIndex(coord, width);
        },
        directions.south => {
            var coord = indexToCoord(location.position, width);
            coord.y += 1;
            return coordToIndex(coord, width);
        },
        directions.east => {
            var coord = indexToCoord(location.position, width);
            coord.x += 1;
            return coordToIndex(coord, width);
        },
        directions.west => {
            var coord = indexToCoord(location.position, width);
            if (coord.x == 0) {
                return input.len;
            }
            coord.x -= 1;
            return coordToIndex(coord, width);
        },
    }
}

fn getPosition(input: []const u8) usize {
    for (input, 0..) |char, index| {
        switch (char) {
            @intFromEnum(directions.north),
            @intFromEnum(directions.south),
            @intFromEnum(directions.east),
            @intFromEnum(directions.west),
            => {
                return index;
            },
            else => {
                continue;
            },
        }
    }

    unreachable;
}

const Coord = struct {
    x: usize,
    y: usize,
};

fn indexToCoord(index: usize, width: usize) Coord {
    const resp = Coord{
        .x = @mod(index, width),
        .y = @divFloor(index, width),
    };

    // printLn("Converted index: {d} to coord: {any}", .{ index, resp });

    return resp;
}

fn coordToIndex(coord: Coord, width: usize) usize {
    return coord.y * width + coord.x;
}

test getPosition {
    const test_input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    const answer = getPosition(test_input);
    try std.testing.expectEqual(70, answer);
}

test coordToIndex {
    const coord = Coord{
        .x = 4,
        .y = 6,
    };
    const answer = coordToIndex(coord, 11);
    try std.testing.expectEqual(70, answer);
}

test getResult {
    var test_input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    .*;
    const answer = getResult(&test_input);
    try std.testing.expectEqual(6, answer);
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
