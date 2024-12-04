const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const bytes = try allocator.alloc(u8, 20000);
    defer allocator.free(bytes);

    const file_contents = try readFile(bytes, "input.txt");

    std.debug.print("num_bytes: {d}\nlen: {d}\n", .{ file_contents.num_bytes, file_contents.contents.len });

    var n: usize = 0;
    var m: usize = 0;
    var i: usize = 0;

    var level: i32 = 0;
    var num_safe: i32 = 0;

    var current_report = [_]i32{ -1, -1, -1, -1, -1, -1, -1, -1 };

    while (n < file_contents.num_bytes) {
        if (file_contents.contents[m] == ' ') {
            const level_string = file_contents.contents[n..m];
            level = try std.fmt.parseInt(i32, level_string, 10);
            n = m + 1;
            current_report[i] = level;
            i += 1;
        } else if (file_contents.contents[m] == '\n') {
            level = try std.fmt.parseInt(i32, file_contents.contents[n..m], 10);
            n = m + 1;
            current_report[i] = level;
            if (reportIsSafeWithDampener(current_report[0 .. i + 1])) {
                num_safe += 1;
            }
            i = 0;
        }

        m += 1;
    }

    std.debug.print("\nNumber of safe reports: {d}\n", .{num_safe});
}

fn readFile(bytes: []u8, filename: []const u8) !struct { num_bytes: usize, contents: []u8 } {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const num_bytes = try file.readAll(bytes);
    return .{ .num_bytes = num_bytes, .contents = bytes };
}

fn allIncreasing(report: []const i32) bool {
    var level_index: usize = 1;
    while (level_index < report.len) : (level_index += 1) {
        if (report[level_index] <= report[level_index - 1]) {
            return false;
        }
    }
    return true;
}

fn allDecreasing(report: []const i32) bool {
    var level_index: usize = 1;
    while (level_index < report.len) : (level_index += 1) {
        if (report[level_index] >= report[level_index - 1]) {
            return false;
        }
    }
    return true;
}

fn diffLessThanThree(report: []const i32) bool {
    var level_index: usize = 1;
    while (level_index < report.len) : (level_index += 1) {
        const difference: i32 = report[level_index] - report[level_index - 1];
        if (difference < -3) return false;
        if (difference > 3) return false;
    }
    return true;
}

fn reportIsSafeWithDampener(report: []const i32) bool {
    if (reportIsSafe(report)) return true;

    for (report, 0..) |_, outer_index| {
        var new_report = [7]i32{ -1, -1, -1, -1, -1, -1, -1 };
        var idx: usize = 0;
        var iidx: usize = 0;

        while (iidx < report.len - 1) {
            if (idx == outer_index) {
                idx += 1;
                continue;
            }

            new_report[iidx] = report[idx];
            idx += 1;
            iidx += 1;
        }

        if (reportIsSafe(new_report[0 .. report.len - 1])) return true;
    }
    return false;
}

fn reportIsSafe(report: []const i32) bool {
    for (report) |level| {
        assert(level != -1);
    }
    const all_decreasing = allDecreasing(report);
    const all_increasing = allIncreasing(report);
    if (!all_increasing and !all_decreasing) {
        std.debug.print("Report: {any} \t\t\t inc: {}, dec: {}, safe: {} \n", .{ report, all_increasing, all_decreasing, false });
        return false;
    }

    if (!diffLessThanThree(report)) {
        std.debug.print("Report: {any} \t\t\t inc: {}, dec: {}, safe: {} \n", .{ report, all_increasing, all_decreasing, false });
        return false;
    }

    std.debug.print("Report: {any} \t\t\t inc: {}, dec: {}, safe: {} \n", .{ report, all_increasing, all_decreasing, true });
    return true;
}

const TestData = struct {
    report: []const i32,
    is_safe: bool,
};

test reportIsSafe {
    const test_data = [_]TestData{
        .{
            .report = &[_]i32{ 7, 6, 4, 2, 1 },
            .is_safe = true,
        },
        .{
            .report = &[_]i32{ 1, 2, 7, 8, 9 },
            .is_safe = false,
        },
        .{
            .report = &[_]i32{ 9, 7, 6, 2, 1 },
            .is_safe = false,
        },
        .{
            .report = &[_]i32{ 1, 3, 2, 4, 5 },
            .is_safe = false,
        },
        .{
            .report = &[_]i32{ 8, 6, 4, 4, 1 },
            .is_safe = false,
        },
        .{
            .report = &[_]i32{ 1, 3, 6, 7, 9 },
            .is_safe = true,
        },
    };
    for (test_data) |test_case| {
        if (test_case.is_safe) {
            try expect(reportIsSafe(test_case.report));
        } else {
            try expect(!reportIsSafe(test_case.report));
        }
    }
}
