const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    const bytes = try allocator.alloc(u8, 19750);
    defer allocator.free(bytes);

    const file_contents = try readFile(bytes, "input.txt");

    std.debug.print("num_bytes: {d}\nlen: {d}\n", .{ file_contents.num_bytes, file_contents.contents.len });
    // std.debug.print("{any}\n", .{file_contents.contents});

    std.debug.print("Finding width...", .{});
    var width: usize = 0;
    for (file_contents.contents, 0..) |letter, index| {
        if (letter == '\n') {
            width = index + 1;
            break;
        }
    }
    std.debug.print("Width: {d}\n", .{width});

    std.debug.print("Finding Xmas...", .{});
    const total = findMas(file_contents.contents, width);
    std.debug.print("Answer: {d}\n", .{total});
}

fn readFile(bytes: []u8, filename: []const u8) !struct { num_bytes: usize, contents: []u8 } {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const num_bytes = try file.readAll(bytes);
    return .{ .num_bytes = num_bytes, .contents = bytes };
}

fn findMas(word_search: []const u8, width: usize) i32 {
    var num_mas: i32 = 0;

    const directions = [_]struct { i8, i8 }{
        .{ 1, -1 }, // up-right
        .{ 1, 1 }, // down-right
        .{ -1, 1 }, // down-left
        .{ -1, -1 }, // up-left
    };

    for (word_search, 0..) |letter, index| {
        var n: i8 = 0;
        if (letter != 'A') {
            continue;
        }

        const coord = pointToCoord(index, width);

        // std.debug.print("Found A at {any}\n", .{coord});

        for (directions) |direction| {
            // std.debug.print("Checking Direction: {any}\n", .{direction});
            const is_mas = coord.getWordIsMas(Direction{ .x = direction[0], .y = direction[1] }, word_search, width);
            if (is_mas) {
                // std.debug.print("Direction: {any}\n", .{direction});
                n += 1;
            }
        }
        if (n == 2) {
            num_mas += 1;
        }
    }
    return num_mas;
}

fn findXmas(word_search: []const u8, width: usize) !i32 {
    var num_xmas: i32 = 0;

    const directions = [_]struct { i8, i8 }{
        .{ 0, -1 }, // up
        .{ 1, -1 }, // up-right
        .{ 1, 0 }, // right
        .{ 1, 1 }, // down-right
        .{ 0, 1 }, // down
        .{ -1, 1 }, // down-left
        .{ -1, 0 }, // left
        .{ -1, -1 }, // up-left
    };

    var num_x: i32 = 0;

    for (word_search, 0..) |letter, index| {
        if (letter != 'X') {
            continue;
        }

        // std.debug.print("X found at index: {d}\n", .{index});
        num_x += 1;
        const coord = pointToCoord(index, width);

        // std.debug.print("Coord: {any}\n", .{coord});

        for (directions) |direction| {
            // std.debug.print("Checking Direction: {any}\n", .{direction});
            const is_xmas = coord.getWordIsXmas(Direction{ .x = direction[0], .y = direction[1] }, word_search, width);
            if (is_xmas) {
                // std.debug.print("Direction: {any}\n", .{direction});
                num_xmas += 1;
            }
        }
    }
    // std.debug.print("Num X: {d}", .{num_x});
    return num_xmas;
}

fn isXmas(search_array: []usize, word_search: []const u8, width: usize) bool {
    assert(search_array.len == 4);
    const printer = false;
    if (printer) {
        std.debug.print("Checking isXmas: {any} -> ", .{search_array});
    }
    if (search_array[0] >= word_search.len or word_search[search_array[0]] != 'X') {
        if (printer) {
            std.debug.print("False!\n", .{});
            std.debug.print("Letters: {c}, {c}, {c}, {c}\n", .{ word_search[search_array[0]], word_search[search_array[1]], word_search[search_array[2]], word_search[search_array[3]] });
        }
        return false;
    }

    if (search_array[1] >= word_search.len or word_search[search_array[1]] != 'M') {
        if (printer) {
            std.debug.print("False!\n", .{});
            std.debug.print("Letters: {c}, {c}, {c}, {c}\n", .{ word_search[search_array[0]], word_search[search_array[1]], word_search[search_array[2]], word_search[search_array[3]] });
        }
        return false;
    }

    if (search_array[2] >= word_search.len or word_search[search_array[2]] != 'A') {
        if (printer) {
            std.debug.print("False!\n", .{});
            std.debug.print("Letters: {c}, {c}, {c}, {c}\n", .{ word_search[search_array[0]], word_search[search_array[1]], word_search[search_array[2]], word_search[search_array[3]] });
        }
        return false;
    }

    if (search_array[3] >= word_search.len or word_search[search_array[3]] != 'S') {
        if (printer) {
            std.debug.print("False!\n", .{});
            std.debug.print("Letters: {c}, {c}, {c}, {c}\n", .{ word_search[search_array[0]], word_search[search_array[1]], word_search[search_array[2]], word_search[search_array[3]] });
        }
        return false;
    }

    if (printer) {
        std.debug.print("Found!\n", .{});
        std.debug.print("Letters: {c}, {c}, {c}, {c}\n", .{ word_search[search_array[0]], word_search[search_array[1]], word_search[search_array[2]], word_search[search_array[3]] });
        std.debug.print("Positions:\n", .{});
        for (search_array) |index| {
            std.debug.print("{d} > {any}\n", .{ index, pointToCoord(index, width) });
        }
    }

    return true;
}

const Direction = struct {
    x: i8,
    y: i8,
};

const Coord = struct {
    x: usize,
    y: usize,
    width: usize,

    fn init(x: usize, y: usize, width: usize) Coord {
        return Coord{
            .x = x,
            .y = y,
            .width = width,
        };
    }

    fn getWordIsXmas(self: *const Coord, dir: Direction, word_search: []const u8, width: usize) bool {
        var indices = [4]usize{ 0, 0, 0, 0 };

        var i: usize = 0;
        var x: i32 = @intCast(self.x);
        var y: i32 = @intCast(self.y);

        var ux: usize = undefined;
        var uy: usize = undefined;

        // std.debug.print("Starting: {any}\n", .{self});

        while (i < 4) : (i += 1) {
            ux = @intCast(x);
            uy = @intCast(y);
            indices[i] = toPoint(ux, uy, self.width);
            if ((dir.x != -1 or x > 0) and (dir.y != -1 or y > 0)) {
                x += dir.x;
                y += dir.y;
            }
        }

        return isXmas(&indices, word_search, width);
    }

    fn getWordIsMas(self: *const Coord, dir: Direction, word_search: []const u8, width: usize) bool {
        const x: i32 = @intCast(self.x);
        const y: i32 = @intCast(self.y);

        var new_x: i32 = 0;
        var new_y: i32 = 0;

        if ((dir.x != -1 or x > 0) and (dir.y != -1 or y > 0)) {
            new_x = x + dir.x;
            new_y = y + dir.y;
        }

        // std.debug.print("({d}, {d})\n", .{ dir.x, dir.y });
        // std.debug.print("({d}, {d})\n", .{ x, y });
        // std.debug.print("({d}, {d})\n", .{ new_x, new_y });
        var ux: usize = @intCast(new_x);
        var uy: usize = @intCast(new_y);

        const new_point = toPoint(ux, uy, width);
        // std.debug.print("Checking point: {d} > {d}, {d}\n", .{ new_point, new_x, new_y });

        if (new_point < word_search.len and word_search[new_point] == 'M') {
            if ((-1 * dir.x != -1 or x > 0) and (-1 * dir.y != -1 or y > 0)) {
                new_x = x - 1 * dir.x;
                new_y = y - 1 * dir.y;
            }
            ux = @intCast(new_x);
            uy = @intCast(new_y);

            const opposite_point = toPoint(ux, uy, width);
            // std.debug.print("Checking opposite point: {d} > {d}, {d}\n", .{ opposite_point, new_x, new_y });
            // std.debug.print("Opposite: {c}\n", .{word_search[opposite_point]});
            if (opposite_point < word_search.len and word_search[opposite_point] == 'S') {
                return true;
            }
        }

        return false;
    }
};

fn toPoint(x: usize, y: usize, width: usize) usize {
    return y * width + x;
}

fn pointToCoord(point: usize, width: usize) Coord {
    return Coord.init(@mod(point, width), @divFloor(point, width), width);
}

test pointToCoord {
    const TestData = struct {
        point: usize,
        width: usize,
        expected_value: Coord,
    };

    const test_data = [_]TestData{
        .{
            .point = 4,
            .width = 7,
            .expected_value = Coord{
                .x = 4,
                .y = 0,
                .width = 7,
            },
        },
        .{
            .point = 11,
            .width = 7,
            .expected_value = Coord{
                .x = 4,
                .y = 1,
                .width = 7,
            },
        },
    };

    for (test_data) |test_case| {
        try std.testing.expectEqual(test_case.expected_value, pointToCoord(test_case.point, test_case.width));
    }
}

test Coord {
    const TestData = struct {
        coord: Coord,
        expected_value: usize,
    };

    const test_data = [_]TestData{
        .{
            .coord = Coord{
                .x = 4,
                .y = 0,
                .width = 4,
            },
            .expected_value = 4,
        },
        .{
            .coord = Coord{
                .x = 4,
                .y = 2,
                .width = 4,
            },
            .expected_value = 12,
        },
        .{
            .coord = Coord{
                .x = 2,
                .y = 1,
                .width = 4,
            },
            .expected_value = 6,
        },
    };

    for (test_data) |test_case| {
        // test_case.coord.toPoint() -> *const main.Coord within
        // var test_case.coord -> *main.Coord
        const got = test_case.coord;
        try std.testing.expectEqual(test_case.expected_value, toPoint(got.x, got.y, got.width));
    }
}

test findMas {
    const TestData = struct {
        string: []const u8,
        expected_value: i32,
    };

    const test_data = [_]TestData{
        .{
            .string =
            \\.M.S......
            \\..A..MSMS.
            \\.M.S.MAA..
            \\..A.ASMSM.
            \\.M.S.M....
            \\..........
            \\S.S.S.S.S.
            \\.A.A.A.A..
            \\M.M.M.M.M.
            \\..........
            ,
            .expected_value = 9,
        },
    };
    for (test_data) |test_case| {
        // std.debug.print("{any}", .{test_case.string});
        try std.testing.expectEqual(test_case.expected_value, findMas(test_case.string, 11));
    }
}

test findXmas {
    const TestData = struct {
        string: []const u8,
        expected_value: i32,
    };

    const test_data = [_]TestData{
        .{
            .string =
            \\SXXSXXSXMAS
            \\XAXAXAXMXXA
            \\XXMMMXXAXXM
            \\SAMXMASSXXX
            \\XXMMMXXMXXX
            \\XAXAXAXSXXX
            \\SXXSXXSAXXX
            \\somethigXXX
            ,
            .expected_value = 11,
        },
    };
    for (test_data) |test_case| {
        // std.debug.print("{any}", .{test_case.string});
        try std.testing.expectEqual(test_case.expected_value, findXmas(test_case.string, 12));
    }
}
