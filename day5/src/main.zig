const std = @import("std");

const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 15142);
    defer allocator.free(bytes);

    const file_contents = try readFile(bytes, "input.txt");

    print("num_bytes: {d}\nlen: {d}\n", .{ file_contents.num_bytes, file_contents.contents.len });

    const result = try getResult(file_contents.contents, allocator);

    print("Answer: {d}\n", .{result});
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

const rand = std.crypto.random;
fn getRandomLetter() [1]u8 {
    const newInt = rand.intRangeAtMost(u8, 65, 90);
    const x: [1]u8 = [1]u8{newInt};
    return x;
}

fn getResult(input: []const u8, allocator: std.mem.Allocator) !i32 {
    var map = std.StringHashMap(std.ArrayList([]const u8)).init(allocator);
    defer {
        map.unlockPointers();
        map.deinit();
    }

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator();

    var i: usize = 0;
    for (input, 0..) |char, index| {
        if (char == '\n') {
            // When we have 2 consecutive \n\n these will be the same, and we are finished reading the updates
            if (i == index) {
                break;
            }

            const left = input[i .. i + 2];
            const right = input[i + 3 .. i + 5];
            var val = try map.getOrPut(left);
            if (val.found_existing) {
                try val.value_ptr.append(right);
            } else {
                var list = std.ArrayList([]const u8).init(arena_allocator);
                try list.append(right);
                val.value_ptr.* = list;
            }
            i = index + 1;
        }
    }
    map.lockPointers();

    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        print("{*} -> ", .{entry.value_ptr});
        print("{s}: ", .{entry.key_ptr.*});
        for (entry.value_ptr.*.items) |bigger| {
            print("{s}, ", .{bigger});
        }

        printLn("", .{});
    }

    // Start at second section of input.txt
    i += 1;
    var start = i;
    var sum: i32 = 0;
    while (i < input.len) : (i += 3) {
        if (input[i + 2] == '\n') {
            const update = input[start .. i + 2];
            if (input_is_correct(update, map)) {
                // printLn("Update length: {d}", .{update.len});
                // const middle_index = @divFloor(update.len, 2);
                // const middle_page = update[middle_index - 1 .. middle_index + 1];
                // printLn("Middle page: {s}", .{middle_page});
                // const middle_number = try std.fmt.parseInt(i32, middle_page, 10);
                // sum += middle_number;
            } else {
                const middle = try get_middle(allocator, update, map);
                sum += middle;
            }
            start = i + 3;
        }
    }

    return sum;
}

fn input_is_correct(update: []const u8, map: std.StringHashMap(std.ArrayList([]const u8))) bool {
    printLn("Update: {s}", .{update});

    var i: usize = 0;
    while (i < update.len - 3) : (i += 3) {
        const cur_page = update[i .. i + 2];
        const page_rules = map.get(cur_page);
        if (page_rules == null) {
            printLn("Page: {s} not found in map", .{cur_page});
            return false;
        }

        var j: usize = i + 3;
        while (j < update.len) : (j += 3) {
            if (!contains(page_rules.?, update[j .. j + 2])) {
                return false;
            }
        }
    }

    return true;
}

fn print_array(pages: [][2]u8) void {
    for (pages) |page| {
        std.debug.print("{s}, ", .{page});
    }
    printLn("", .{});
}

fn get_middle(allocator: std.mem.Allocator, update: []const u8, map: std.StringHashMap(std.ArrayList([]const u8))) !i32 {
    printLn("Update: {s}", .{update});
    const num_pages: usize = ((update.len - 2) / 3) + 1;
    printLn("Number of pages: {d}", .{num_pages});
    const pages = try allocator.alloc([2]u8, num_pages);
    defer allocator.free(pages);

    var j: usize = 0;
    var i: usize = 0;
    while (i < update.len) : (i += 3) {
        const page: *[2]u8 = @constCast(@ptrCast(update[i .. i + 2]));
        pages[j] = page.*;
        j += 1;
    }

    print_array(pages);

    i = 0;
    j = 0;
    outer: while (i < pages.len - 1) {
        var page = pages[i];
        var rules = map.get(&page);

        // If page not in map, add to end, shift everything back
        if (rules == null) {
            printLn("Page: {s} not found in map", .{page});
            std.debug.print("Before Shifted: ", .{});
            print_array(pages);
            j = i;
            while (j < pages.len - 1) : (j += 1) {
                pages[j] = pages[j + 1];
            }

            pages[pages.len - 1] = page;
            std.debug.print("After Shifted: ", .{});
            print_array(pages);
        }

        page = pages[i];
        rules = map.get(&page);

        // After swapping we should get rules
        assert(rules != null);

        // If any subsequent pages not in the list of rules, swap
        j = i + 1;
        while (j < pages.len) : (j += 1) {
            const cur_page = pages[j];
            if (!contains(rules.?, &pages[j])) {
                std.debug.print("Before Swapped: ", .{});
                print_array(pages);
                pages[j] = page;
                pages[i] = cur_page;

                std.debug.print("After Swapped: ", .{});
                print_array(pages);
                continue :outer;
            }
        }
        i += 1;
    }

    std.debug.print("Returning -> ", .{});
    print_array(pages);
    const middle_page = pages[@divFloor(pages.len, 2)];
    return try std.fmt.parseInt(i32, &middle_page, 10);
}

fn contains(haystack: std.ArrayList([]const u8), needle: []const u8) bool {
    for (haystack.items) |item| {
        if (std.mem.eql(u8, item, needle)) {
            return true;
        }
    }
    std.debug.print("Needle: {s} not found in haystack: ", .{needle});
    printList(haystack);
    return false;
}

fn printList(list: std.ArrayList([]const u8)) void {
    for (list.items) |element| {
        std.debug.print("{s}, ", .{element});
    }
    std.debug.print("\n", .{});
}

test "test" {
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
        \\
    ;
    const allocator = std.testing.allocator;

    const answer = try getResult(input, allocator);
    printLn("Answer: {d}", .{answer});
    try std.testing.expectEqual(123, answer);
}
