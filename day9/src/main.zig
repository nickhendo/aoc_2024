const std = @import("std");
const part1 = @import("part1.zig");
const part2 = @import("part2.zig");

const expect = std.testing.expect;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 20000);
    defer allocator.free(bytes);

    const file_contents = try readFile(bytes, "input.txt");

    print("num_bytes: {d}\nlen: {d}\n", .{ file_contents.num_bytes, file_contents.contents.len });

    // const result = try part1.getResult(file_contents.contents[0 .. file_contents.contents.len - 1]);
    const result = try part2.getResult(allocator, file_contents.contents[0 .. file_contents.contents.len - 1]);

    print("Answer: {d}\n", .{result});
}

fn readFile(bytes: []u8, filename: []const u8) !struct { num_bytes: usize, contents: []u8 } {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const num_bytes = try file.readAll(bytes);
    return .{ .num_bytes = num_bytes, .contents = bytes };
}
