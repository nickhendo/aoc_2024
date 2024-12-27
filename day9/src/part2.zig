const std = @import("std");

const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn getResult(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var input_buffer = try allocator.alloc(u8, input.len);
    defer allocator.free(input_buffer);

    for (input, 0..) |char, index| {
        input_buffer[index] = char - 48;
    }

    return 0;
}

const DiskMapReverseIterator = struct {
    disk_map: []const u8,
    index: usize = 0,
    inner_block: usize = 0,
    string_buffer: *[20]u8,

    fn init(disk_map: []const u8, buf: *[20]u8) DiskMapReverseIterator {
        return DiskMapReverseIterator{
            .disk_map = disk_map,
            .index = disk_map.len - 1,
            .string_buffer = buf,
        };
    }

    fn next(self: *DiskMapReverseIterator) !?u8 {
        while (self.index >= 0) {
            // printLn("{d}, {d}, {d}, {c}", .{ self.index, self.index / 2 + 48, self.disk_map[self.index], self.disk_map[self.index] });
            const block_int: usize = self.disk_map[self.index] - 48;

            while (self.inner_block < block_int) {
                self.inner_block += 1;

                if (@mod(self.index, 2) == 0) {
                    // printLn("self.index -> {d}", .{self.index});
                    // printLn("self.index / 2 + 48 -> {d}", .{self.index / 2 + 48});
                    intToSlice(@intCast(self.index / 2), self.string_buffer);
                    // printLn("> {s}", .{self.string_buffer});
                    // return @intCast(self.index / 2 + 48);
                    return 'a';
                }
            }
            self.inner_block = 0;
            if (self.index == 0) {
                break;
            }
            self.index -= 1;
        }

        return null;
    }
};

fn sliceToInt(slice: []const u8) i64 {
    var i: usize = 0;
    for (slice, 0..) |char, index| {
        // printLn("{}", .{char});
        if (char == 170) {
            i = index;
            break;
        }
    }

    // printLn("{any}", .{slice[0..i]});

    return std.fmt.parseInt(i64, slice[0..i], 10) catch {
        printLn("{s}", .{slice});
        unreachable;
    };
}

fn intToSlice(int: i64, buf: *[20]u8) void {
    _ = std.fmt.bufPrint(buf, "{}", .{int}) catch {
        unreachable;
    };
}

const DiskMapIterator = struct {
    disk_map: []const u8,
    index: usize = 0,
    inner_block: usize = 0,
    limit: usize = 0,
    counter: usize = 0,
    string_buffer: *[20]u8,

    fn init(disk_map: []const u8, buf: *[20]u8) DiskMapIterator {
        var limit: usize = 0;
        for (disk_map, 0..) |char, index| {
            if (@mod(index, 2) == 0) {
                // printLn("index: {d}", .{index});
                limit += char - 48;
            }
        }

        // printLn("Setting limit to: {d}", .{limit});

        return DiskMapIterator{
            .disk_map = disk_map,
            .limit = limit,
            .string_buffer = buf,
        };
    }

    fn next(self: *DiskMapIterator) !?u8 {
        if (self.counter >= self.limit) {
            return null;
        }

        for (self.disk_map[self.index..]) |char| {
            const block_int: usize = char - 48;

            while (self.inner_block < block_int) {
                self.inner_block += 1;

                self.counter += 1;
                if (@mod(self.index, 2) == 0) {
                    intToSlice(@intCast(self.index / 2), self.string_buffer);
                    // return @intCast(self.index / 2 + 48);
                    return 'a';
                } else {
                    // self.limit += 1;
                    // printLn("Limit: {d}", .{self.limit});
                    return '.';
                }
            }
            self.inner_block = 0;
            self.index += 1;
        }

        return null;
    }
};

test getResult {
    const test_input = "2333133121414131402";
    const answer = try getResult(std.testing.allocator, test_input);
    try std.testing.expectEqual(2858, answer);
}

fn printLn(comptime fmt: []const u8, args: anytype) void {
    const fmt_with_newline = fmt ++ "\n";
    print(fmt_with_newline, args);
}

// 00...111...2...333.44.5555.6666.777.888899
// 009..111...2...333.44.5555.6666.777.88889.
// 0099.111...2...333.44.5555.6666.777.8888..
// 00998111...2...333.44.5555.6666.777.888...
// 009981118..2...333.44.5555.6666.777.88....
// 0099811188.2...333.44.5555.6666.777.8.....
// 009981118882...333.44.5555.6666.777.......
// 0099811188827..333.44.5555.6666.77........
// 00998111888277.333.44.5555.6666.7.........
// 009981118882777333.44.5555.6666...........
// 009981118882777333644.5555.666............
// 00998111888277733364465555.66.............
// 0099811188827773336446555566..............
