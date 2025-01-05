const std = @import("std");
const heap = @import("heap.zig");

const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

fn defragment(disk_array: *[]i16, puzzle_input: []const u8, heaps: *[10]heap.MinHeap(usize)) !void {
    var puzzle_input_index = puzzle_input.len;

    var file_id: i16 = @intCast(puzzle_input.len / 2);

    while (puzzle_input_index > 0) {
        puzzle_input_index -= 1;

        if (@mod(puzzle_input_index, 2) == 1) {
            continue;
        }

        const file_size = puzzle_input[puzzle_input_index];
        const block_size = getNextHeap(heaps, file_size);

        if (block_size == null or block_size == 0) {
            if (file_id > 0) {
                std.debug.print("No space for file id: {d} of size: {d}\n", .{ file_id, file_size });
                file_id -= 1;
            }
            continue;
        }
        var current_heap = &heaps[block_size.?];

        const disk_buffer_index = getIndex(puzzle_input_index, puzzle_input);

        if (current_heap.head().? > disk_buffer_index) {
            file_id -= 1;
            continue;
        }

        const block = try current_heap.*.delete();
        if (block == null) {
            unreachable;
        }

        const remaining_space_size: usize = block_size.? - file_size;
        const remaining_space_index: usize = block.? + file_size;

        try heaps[remaining_space_size].insert(remaining_space_index);

        var updated = false;
        var count: usize = 0;
        for (disk_array.*, 0..) |*ivalue, iii| {
            if (iii < block.? or iii >= block.? + file_size) {
                continue;
            }
            ivalue.* = file_id;
            updated = true;
            if (file_id == 5467) {
                count += 1;
            }
        }
        if (!updated) {
            unreachable;
        }
        assert(updated);

        for (disk_array.*[disk_buffer_index .. disk_buffer_index + file_size]) |*val| {
            val.* = -1;
        }

        if (file_id > 0) {
            file_id -= 1;
        }
    }
}

test defragment {
    const allocator = std.testing.allocator;

    const TestCase = struct {
        disk_array: []const i16,
        puzzle_input: []const u8,
        expected: []const i16,
    };

    const test_cases = [_]TestCase{
        .{
            .disk_array = &[_]i16{ 0, -1, -1, 1, 1, 1, -1, -1, -1, -1, 2, 2, 2, 2, 2 },
            .expected = &[_]i16{ 0, -1, -1, 1, 1, 1, -1, -1, -1, -1, 2, 2, 2, 2, 2 },
            .puzzle_input = &[_]u8{ 1, 2, 3, 4, 5 },
        },
        .{
            .disk_array = &[_]i16{ 0, -1, -1, -1, -1, -1, 1, 1, 1, -1, -1, -1, -1, 2, 2, 2, 2, 2 },
            .expected = &[_]i16{ 0, 2, 2, 2, 2, 2, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
            .puzzle_input = &[_]u8{ 1, 5, 3, 4, 5 },
        },
        .{
            .disk_array = &[_]i16{ 0, -1, 1, -1, 2, -1, 3, -1, 4, -1, 5, -1, 6, -1, 7, -1, 8, -1, 9, -1, 10, -1, 11, -1, 12 },
            .expected = &[_]i16{ 0, 12, 1, 11, 2, 10, 3, 9, 4, 8, 5, 7, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
            .puzzle_input = &[_]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }, // 0.1.2.3.4.5.6.7.8.9.10.11.12
        },
        .{
            .disk_array = &[_]i16{ 0, -1, 1, -1, 2, -1, 3, -1, 4, -1, 5, -1, 6, -1, 7, -1, 8, -1, 9, -1, 10, -1, 11, -1, 12 },
            .expected = &[_]i16{ 0, 12, 1, 11, 2, 10, 3, 9, 4, 8, 5, 7, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 },
            .puzzle_input = &[_]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }, // 0.1.2.3.4.5.6.7.8.9.10.11.12
        },
    };

    for (test_cases) |test_case| {
        var heaps: [10]heap.MinHeap(usize) = undefined;
        for (&heaps) |*value| {
            value.* = heap.MinHeap(usize).init(std.testing.allocator);
        }

        defer {
            for (&heaps) |*value| {
                value.*.deinit();
            }
        }

        try populateHeaps(test_case.puzzle_input, &heaps);

        var defragmented_array = try allocator.alloc(i16, test_case.disk_array.len);
        defer allocator.free(defragmented_array);

        @memcpy(defragmented_array, test_case.disk_array);

        try defragment(&defragmented_array, test_case.puzzle_input, &heaps);
        try std.testing.expectEqualSlices(i16, test_case.expected, defragmented_array);
    }
}

pub fn getResult(allocator: std.mem.Allocator, input: []const u8) !i64 {
    // Convert puzzle input to an integer array that is easier to work with
    var input_buffer = try allocator.alloc(u8, input.len);
    defer allocator.free(input_buffer);
    const size_of_disk = convertInputToArray(&input_buffer, input);

    // Setup array of heaps for tracking empty blocks
    var heaps: [10]heap.MinHeap(usize) = undefined;
    for (&heaps) |*value| {
        value.* = heap.MinHeap(usize).init(allocator);
    }
    defer {
        for (&heaps) |*value| {
            value.*.deinit();
        }
    }

    // Set up disk with array of blocks and fragments
    var disk = Disk{
        .array = try allocator.alloc(i16, size_of_disk),
    };
    defer allocator.free(disk.array);

    try populateHeaps(input_buffer, &heaps);
    try populateDiskData(&disk, input_buffer);

    // std.debug.print("Disk array before:\n{any}\n", .{disk.array});

    var counts_before = std.AutoHashMap(i16, usize).init(
        allocator,
    );
    defer counts_before.deinit();

    var counts_after = std.AutoHashMap(i16, usize).init(
        allocator,
    );
    defer counts_after.deinit();

    const before = try allocator.alloc(i16, disk.array.len);
    defer allocator.free(before);

    @memcpy(before, disk.array);

    for (before) |val| {
        if (counts_before.get(val) != null) {
            counts_before.getEntry(val).?.value_ptr.* += 1;
        } else {
            try counts_before.put(val, 1);
        }
    }

    try defragment(&disk.array, input_buffer, &heaps);

    for (disk.array) |val| {
        if (counts_after.get(val) != null) {
            counts_after.getEntry(val).?.value_ptr.* += 1;
        } else {
            try counts_after.put(val, 1);
        }
    }

    // std.debug.print("Disk array after:\n{any}\n", .{disk.array});

    for (before, 0..) |before_val, index| {
        if (before_val != disk.array[index] and before_val != -1) {
            print("Found values that do not match. Before: {d}, after: {d}, index: {d}\n", .{ before_val, disk.array[index], index });
            break;
        }
    }

    const cb = counts_before.get(-1);
    if (cb == null) {
        std.debug.print("-1 not found in before\n", .{});
    }

    const ca = counts_after.get(-1);
    if (ca == null) {
        std.debug.print("-1 not found in after\n", .{});
    }

    if (cb != null and ca != null and cb.? != ca.?) {
        std.debug.print("{d} count for -1 in before, does not equal {d} count in after\n", .{ cb.?, ca.? });
    }

    std.debug.print("-1 Counts: Before: {d}, after: {d}\n", .{ cb.?, ca.? });

    for (0..20) |val| {
        const find_val: i16 = @intCast(val);
        const before_count = counts_before.get(find_val);
        if (before_count == null) {
            std.debug.print("{d} not found in before\n", .{find_val});
        }

        const after_count = counts_after.get(find_val);
        if (after_count == null) {
            std.debug.print("{d} not found in after\n", .{find_val});
        }

        if (before_count != null and after_count != null and before_count.? != after_count.?) {
            std.debug.print("{d} does not equal {d} for val={d}", .{ before_count.?, after_count.?, val });
            if (before_count.? > after_count.?) {
                std.debug.print(" -> Decreasing.\n", .{});
            }

            if (after_count.? > before_count.?) {
                std.debug.print(" -> Increasing.\n", .{});
            }

            continue;
        }
    }

    // std.debug.print("Before Counts:\n{any}\n", .{counts_before});

    return calculateChecksum(disk.array);
}

test getResult {
    var test_input: []const u8 = "2333133121414131402";
    var answer = try getResult(std.testing.allocator, test_input);
    try std.testing.expectEqual(2858, answer);

    test_input = "23331331214141314029123";
    answer = try getResult(std.testing.allocator, test_input);
    try std.testing.expectEqual(3356, answer);
}

const Disk = struct {
    array: []i16,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        for (self.array) |val| {
            if (val == -1) {
                try writer.print("{s: >3}", .{"."});
            } else {
                try writer.print("{d: >3}", .{val});
            }
        }
    }
};

fn convertInputToArray(input_buffer: *[]u8, input: []const u8) usize {
    var size: usize = 0;

    for (input, 0..) |char, index| {
        const val: u8 = char - 48;
        input_buffer.*[index] = val;
        size += @intCast(val);
    }

    return size;
}

test convertInputToArray {
    const allocator = std.testing.allocator;

    const test_input = "234567891234";
    var input_buffer = try allocator.alloc(u8, test_input.len);
    defer allocator.free(input_buffer);

    const size = convertInputToArray(&input_buffer, test_input);
    const expected = [_]u8{ 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4 };

    try std.testing.expectEqual(54, size);
    try std.testing.expectEqualSlices(u8, &expected, input_buffer);
}

fn populateHeaps(input: []const u8, heaps: *[10]heap.MinHeap(usize)) !void {
    var disk_index: usize = 0;

    for (input, 0..) |block_size, block_index| {
        // Odd block indexes indicate gaps in the disk, i.e. '...'
        if (@mod(block_index, 2) == 1) {
            try heaps[block_size].insert(disk_index);
        }

        for (0..block_size) |_| {
            disk_index += 1;
        }
    }
}

test populateHeaps {
    const allocator = std.testing.allocator;

    const TestCase = struct {
        input: []const u8,
        size: usize,
        expected: [10]?usize,
    };
    const test_cases = [_]TestCase{
        .{
            .input = &[_]u8{ 1, 2, 3, 4, 5 }, // 0..111....22222
            .size = 15,
            .expected = [10]?usize{ null, null, 1, null, 6, null, null, null, null, null },
        },
        .{
            .input = &[_]u8{ 4, 4, 4, 4, 4 }, // 0000....0000....0000
            .size = 15,
            .expected = [10]?usize{ null, null, null, null, 4, null, null, null, null, null },
        },
        .{
            .input = &[_]u8{ 9, 9, 9, 9, 9, 9, 9 }, // 000000000.........1111111111...[etc]
            .size = 15,
            .expected = [10]?usize{ null, null, null, null, null, null, null, null, null, 9 },
        },
    };

    for (test_cases) |test_case| {
        var heaps: [10]heap.MinHeap(usize) = undefined;
        for (&heaps) |*value| {
            value.* = heap.MinHeap(usize).init(allocator);
        }

        defer {
            for (&heaps) |*value| {
                value.*.deinit();
            }
        }

        try populateHeaps(test_case.input, &heaps);

        for (test_case.expected, 0..) |expected_size, expected_index| {
            try std.testing.expectEqual(expected_size, heaps[expected_index].head());
        }
    }
}

fn populateDiskData(disk: *Disk, input: []const u8) !void {
    // Index of element on the disk, i.e. '0...111.2[2]2...3'.
    var disk_index: usize = 0;

    var block_id: i16 = 0;

    for (input, 0..) |block_size, block_index| {
        // Create a series of elements aligning to the size of the current block.
        // If the block index is even, this a solid block, filled in with its ID,
        // otherwise it is a gap block, filled in with -1, corresponding to '.'.
        for (0..block_size) |_| {
            if (@mod(block_index, 2) == 0) {
                disk.array[disk_index] = block_id;
            } else {
                disk.array[disk_index] = -1;
            }

            disk_index += 1;
        }

        if (@mod(block_index, 2) == 0) {
            block_id += 1;
        }
    }
}

test populateDiskData {
    const allocator = std.testing.allocator;

    const TestCase = struct {
        input: []const u8,
        size: usize,
        expected: []const i16,
    };
    const test_cases = [_]TestCase{
        .{
            .input = &[_]u8{ 1, 2, 3, 4, 5 },
            .size = 15,
            .expected = &[_]i16{ 0, -1, -1, 1, 1, 1, -1, -1, -1, -1, 2, 2, 2, 2, 2 },
        },
        .{
            .input = &[_]u8{ 1, 0, 1, 0, 1 },
            .size = 3,
            .expected = &[_]i16{ 0, 1, 2 },
        },
        .{
            .input = &[_]u8{ 2, 3, 3, 3, 1, 3, 3, 1, 2, 1, 4, 1, 4, 1, 3, 1, 4, 0, 2, 9, 1, 2, 3 },
            .size = 57,
            .expected = &[_]i16{ 0, 0, -1, -1, -1, 1, 1, 1, -1, -1, -1, 2, -1, -1, -1, 3, 3, 3, -1, 4, 4, -1, 5, 5, 5, 5, -1, 6, 6, 6, 6, -1, 7, 7, 7, -1, 8, 8, 8, 8, 9, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, 10, -1, -1, 11, 11, 11 },
        },
    };

    for (test_cases) |test_case| {
        var disk = Disk{
            .array = try allocator.alloc(i16, test_case.size),
        };
        defer allocator.free(disk.array);

        try populateDiskData(&disk, test_case.input);
        try std.testing.expectEqualSlices(i16, test_case.expected, disk.array);
    }
}

fn calculateChecksum(array: []const i16) i64 {
    var checksum: i64 = 0;

    for (array, 0..) |val, index| {
        if (val == -1) {
            continue;
        }
        const i64_index: i64 = @intCast(index);
        checksum += i64_index * val;
    }

    return checksum;
}

test calculateChecksum {
    const array = [_]i16{ 0, 1, 0, -1, 2, 3, 4, 5, 8, 100 };
    const answer = calculateChecksum(&array);
    try std.testing.expectEqual(1047, answer);
}

/// Iterate through array of heaps. Of the heaps with a suitable head,
/// return the smallest, implying the furthest left in the disk buffer
fn getNextHeap(heaps: []heap.MinHeap(usize), size: usize) ?usize {
    var min: ?usize = null;
    var min_val: ?usize = null;

    for (heaps[size..], size..) |cur_heap, index| {
        const head = cur_heap.head();

        // Skip empty heaps
        if (head == null) {
            continue;
        }

        // Set initial minimum values when not already set
        if (min == null) {
            min = index;
            min_val = head.?;
            continue;
        }

        // Update minimum values as we find smaller values
        if (head.? < min_val.?) {
            min = index;
            min_val = head.?;
        }
    }

    return min;
}

test getNextHeap {
    var heaps: [10]heap.MinHeap(usize) = undefined;
    for (&heaps) |*value| {
        value.* = heap.MinHeap(usize).init(std.testing.allocator);
    }

    defer {
        for (&heaps) |*value| {
            value.*.deinit();
        }
    }
    var answer = getNextHeap(&heaps, 3);
    try std.testing.expectEqual(null, answer);

    try heaps[0].insert(40);
    try heaps[0].insert(30);
    try heaps[0].insert(20);
    try heaps[0].insert(50);

    answer = getNextHeap(&heaps, 3);
    try std.testing.expectEqual(null, answer);

    try heaps[3].insert(20);

    answer = getNextHeap(&heaps, 3);
    try std.testing.expectEqual(3, answer);

    try heaps[2].insert(100);
    try heaps[2].insert(10);
    try heaps[2].insert(50);

    try heaps[1].insert(15);

    // std.debug.print("Heaps:\n{any}\n", .{heaps});

    answer = getNextHeap(&heaps, 3);
    try std.testing.expectEqual(3, answer);

    try heaps[5].insert(25);

    try heaps[6].insert(15);
    try heaps[6].insert(30);
    try heaps[6].insert(1);

    try heaps[9].insert(30);

    answer = getNextHeap(&heaps, 3);
    try std.testing.expectEqual(6, answer);

    answer = getNextHeap(&heaps, 9);
    try std.testing.expectEqual(9, answer);

    answer = getNextHeap(&heaps, 1);
    try std.testing.expectEqual(6, answer);
}

/// Return the calculate disk buffer index.
/// I.e. the index from 23412 to 00...1111.22
fn getIndex(i: usize, array: []const u8) usize {
    var sum: usize = 0;
    for (array[0..i]) |val| {
        sum += val;
    }
    return sum;
}

test getIndex {
    const TestCase = struct {
        array: []const u8,
        index: usize,
        expected: usize,
    };
    const test_cases = [_]TestCase{
        .{
            .array = &[_]u8{ 2, 3, 4, 1, 2 },
            .index = 3,
            .expected = 9,
        },
        .{
            .array = &[_]u8{ 2, 3, 4, 1, 2 },
            .index = 0,
            .expected = 0,
        },
        .{
            .array = &[_]u8{ 2, 3, 4, 1, 2 },
            .index = 4,
            .expected = 10,
        },
        .{
            .array = &[_]u8{ 2, 3, 4, 1, 2, 9, 8, 4, 3, 4, 5, 9 },
            .index = 11,
            .expected = 45,
        },
    };

    for (test_cases) |test_case| {
        const answer = getIndex(test_case.index, test_case.array);
        try std.testing.expectEqual(test_case.expected, answer);
    }
}

fn printLn(comptime fmt: []const u8, args: anytype) void {
    const fmt_with_newline = fmt ++ "\n";
    print(fmt_with_newline, args);
}

// 00...111...2...333.44.5555.6666.777.888899
// 0099.111...2...333.44.5555.6666.777.8888..
// 0099.1117772...333.44.5555.6666.....8888..
// 0099.111777244.333....5555.6666.....8888..
// 00992111777.44.333....5555.6666.....8888..

// 6389911791746 <- Correct answer
// 6394601446686 <- Prev cursed incorrect answer
