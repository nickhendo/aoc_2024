const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 19499);
    defer allocator.free(bytes);

    const file_contents = try readFile(bytes, "input.txt");

    std.debug.print("num_bytes: {d}\nlen: {d}\n", .{ file_contents.num_bytes, file_contents.contents.len });
    std.debug.print("{}", .{file_contents.num_bytes});

    _ = sumOfMuls(file_contents.contents);
}

fn readFile(bytes: []u8, filename: []const u8) !struct { num_bytes: usize, contents: []u8 } {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const num_bytes = try file.readAll(bytes);
    return .{ .num_bytes = num_bytes, .contents = bytes };
}

fn sumOfMuls(corrupted_data: []const u8) i32 {
    var i: usize = 0;
    var total: i32 = 0;

    std.debug.print("Corrupted Data: {any}", .{corrupted_data});

    var do = true;
    // mul(n,m) == 8 chars
    while (i < corrupted_data.len - 8) : (i += 1) {
        if (std.mem.eql(u8, corrupted_data[i .. i + 4], "do()")) {
            do = true;
        }
        if (std.mem.eql(u8, corrupted_data[i .. i + 7], "don't()")) {
            do = false;
        }
        // std.debug.print("Checking: {s}\n", .{corrupted_data[i .. i + 4]});
        if (std.mem.eql(u8, corrupted_data[i .. i + 4], "mul(")) {
            i += 4;
            var left_nums: [3]u8 = [3]u8{ 'x', 'x', 'x' };
            // var left_nums: []u8 = "xxx";
            var left_int: i32 = 0;

            var right_nums: [3]u8 = [3]u8{ 'x', 'x', 'x' };
            var right_int: i32 = 0;

            var ii: usize = 0;

            // std.debug.print("At: {d} -> {c}\n", .{ i, corrupted_data[i] });

            // Check if each of up to the next three chars is an integer
            // std.debug.print("Checking right side characters\n", .{});
            while ('0' <= corrupted_data[i + ii] and corrupted_data[i + ii] <= '9' and ii < 3) : (ii += 1) {
                // std.debug.print("Checking digit: {d}, {d}, {c}\n", .{ i, ii, corrupted_data[i + ii] });
                left_nums[ii] = corrupted_data[i + ii];
            }

            // If the captured digits can't be converted to an integer, increment and move on
            // std.debug.print("Checking left side is integer\n", .{});
            left_int = std.fmt.parseInt(i32, left_nums[0..ii], 10) catch {
                i += 1;
                continue;
            };
            // std.debug.print("Left side integer: {d}\nLeft nums: {s}\n", .{ left_int, left_nums });

            i += ii;

            // std.debug.print("Checking comma seperation\nchar: {c}\nindex: {d}\n", .{ corrupted_data[i], i });
            if (corrupted_data[i] != ',') {
                continue;
            }

            i += 1;
            ii = 0;

            // Check if each of up to the next three chars is an integer
            // std.debug.print("Checking right side characters\n", .{});
            while ('0' <= corrupted_data[i + ii] and corrupted_data[i + ii] <= '9' and ii < 3) : (ii += 1) {
                right_nums[ii] = corrupted_data[i + ii];
            }
            // std.debug.print("Right side integer: {d}\n", .{right_int});

            // If the captured digits can't be converted to an integer, increment and move on
            // std.debug.print("Checking right side is integer\n", .{});
            right_int = std.fmt.parseInt(i32, right_nums[0..ii], 10) catch {
                i += ii;
                continue;
            };

            i += ii;

            // std.debug.print("Checking final bracket\n", .{});
            if (corrupted_data[i] != ')') {
                continue;
            }

            // std.debug.print("Totalling\n", .{});
            if (do) {
                total += left_int * right_int;
            }
        }
    }

    std.debug.print("Total: {d}", .{total});
    return total;
}

fn stringFind(needle: []const u8, haystack: []const u8) ?usize {
    for (haystack, 0..) |_, index| {
        if (std.mem.eql(u8, needle, haystack[index .. index + needle.len])) {
            return index;
        }
    }
    return null;
}

test stringFind {
    const TestData = struct {
        needle: []const u8,
        haystack: []const u8,
        expected_value: ?usize,
    };

    const test_data = [_]TestData{
        .{
            .needle = "m",
            .haystack = "hello, my name is nick",
            .expected_value = 7,
        },
        .{
            .needle = "x",
            .haystack = "hello, my name is nick",
            .expected_value = null,
        },
    };

    for (test_data) |test_case| {
        const response = stringFind(test_case.needle, test_case.haystack);
        try std.testing.expectEqual(response, test_case.expected_value);
    }
}

test sumOfMuls {
    const TestData = struct {
        string: []const u8,
        expected_value: i32,
    };

    const test_data = [_]TestData{
        .{
            .string = "mul(3,10)",
            .expected_value = 30,
        },
        .{
            .string = "mul(300,20)",
            .expected_value = 6000,
        },
        .{
            .string = "alksdjlaskjdhaamul(300,20)laksjdfhasldkfjh",
            .expected_value = 6000,
        },
        .{
            .string = "alksdmul(2,40)jlaskjdhaamul(3,20)laksjdfhasldkfjh",
            .expected_value = 140,
        },
    };
    for (test_data) |test_case| {
        const total = sumOfMuls(test_case.string);
        std.debug.print("total: {d}\n", .{total});
        try std.testing.expectEqual(total, test_case.expected_value);
    }
}
