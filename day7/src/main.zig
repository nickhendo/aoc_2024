const std = @import("std");

const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 25144);
    defer allocator.free(bytes);

    const file_contents = try readFile(bytes, "input.txt");

    print("num_bytes: {d}\nlen: {d}\n", .{ file_contents.num_bytes, file_contents.contents.len });

    const result = try getResult(allocator, file_contents.contents);

    print("Answer: {d}\n", .{result});
}

fn getResult(allocator: std.mem.Allocator, input: []u8) !i64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator();

    var map = std.AutoHashMap(i64, std.ArrayList(i64)).init(arena_allocator);

    var i: usize = 0;
    var j: usize = 0;

    var current_key: i64 = undefined;
    var current_list = std.ArrayList(i64).init(arena_allocator);
    defer current_list.deinit();

    while (j < input.len) : (j += 1) {
        if (input[j] == ':') {
            current_key = try std.fmt.parseInt(i64, input[i..j], 10);
            // Skip the first space after the colon
            j += 1;
            i = j + 1;
            continue;
        }

        if (input[j] == ' ') {
            const value = try std.fmt.parseInt(i64, input[i..j], 10);
            try current_list.append(value);
            i = j + 1;
            continue;
        }

        if (input[j] == '\n') {
            const value = try std.fmt.parseInt(i64, input[i..j], 10);
            try current_list.append(value);

            try map.put(current_key, current_list);
            current_key = undefined;
            current_list = std.ArrayList(i64).init(arena_allocator);
            i = j + 1;
        }
    }

    var sum_correct_equations: i64 = 0;
    var iterator = map.iterator();
    const buffer = try allocator.alloc(u8, 30);
    defer allocator.free(buffer);

    while (iterator.next()) |entry| {
        const num_combinations = try foo(buffer, entry.value_ptr.*, 1, entry.value_ptr.*.items[0], entry.key_ptr.*);
        if (num_combinations > 0) {
            sum_correct_equations += entry.key_ptr.*;
        }
    }

    return sum_correct_equations;
}

fn foo(buffer: []u8, items: std.ArrayList(i64), index: usize, total: i64, expected: i64) !i64 {
    var num: i64 = 0;
    if (index == items.items.len - 1) {
        if (total * items.items[index] == expected) {
            num += 1;
        }

        if (total + items.items[index] == expected) {
            num += 1;
        }

        const extra_val = try concat(buffer, total, items.items[index]);
        if (extra_val == expected) {
            num += 1;
        }

        return num;
    }

    const val_times = try foo(buffer, items, index + 1, total * items.items[index], expected);
    const val_plus = try foo(buffer, items, index + 1, total + items.items[index], expected);

    const concated = try concat(buffer, total, items.items[index]);
    const val_concat = try foo(buffer, items, index + 1, concated, expected);
    return val_times + val_plus + val_concat;
}

fn concat(buffer: []u8, num1: i64, num2: i64) !i64 {
    const str = try std.fmt.bufPrint(buffer, "{d}{d}", .{ num1, num2 });
    return try std.fmt.parseInt(i64, str, 10);
}

test getResult {
    var test_input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
        \\
    .*;
    const allocator = std.testing.allocator;
    const answer = try getResult(allocator, &test_input);
    try std.testing.expectEqual(11387, answer);
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
