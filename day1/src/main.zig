//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffer: [1000 * 100]u8 = undefined;
    const new = try file.readAll(&buffer);

    var left: [1000]i32 = undefined;
    var right: [1000]i32 = undefined;

    var n: usize = 0;
    var i: usize = 0;
    while (n < new) {
        const first = buffer[n .. n + 5];
        const second = buffer[n + 8 .. n + 13];

        const firstInt = try std.fmt.parseInt(i32, first, 10);
        const secondInt = try std.fmt.parseInt(i32, second, 10);

        left[i] = firstInt;
        right[i] = secondInt;

        n += 14;
        i += 1;
    }

    std.mem.sort(i32, &left, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, &right, {}, comptime std.sort.asc(i32));

    var sum: i32 = 0;
    var iter: usize = 0;
    var dif: i32 = 0;
    std.debug.print("length: {d}\n", .{left.len});
    while (iter < left.len) {
        dif = left[iter] - right[iter];
        if (dif < 0) {
            sum += -1 * dif;
        } else {
            sum += dif;
        }

        iter += 1;
    }

    std.debug.print("total: {d}\n", .{sum});

    var occurrences: i32 = 0;
    var similarity_score: i32 = 0;

    for (left) |number| {
        occurrences = numOccurrences(number, right);
        similarity_score += number * occurrences;
    }

    std.debug.print("Similarity Score: {d}\n", .{similarity_score});
}

fn numOccurrences(needle: i32, haystack: [1000]i32) i32 {
    var occurrences: i32 = 0;

    for (haystack) |number| {
        if (number == needle) {
            occurrences += 1;
        }
    }

    return occurrences;
}
