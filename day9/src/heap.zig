const std = @import("std");

pub fn MinHeap(comptime T: type) type {
    return struct {
        const Self = @This();

        data: std.ArrayList(T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            const list = std.ArrayList(T).init(allocator);

            return Self{
                .data = list,
                .allocator = allocator,
            };
        }

        pub fn head(self: *const Self) ?usize {
            if (self.data.items.len == 0) {
                return null;
            }
            return self.data.items[0];
        }

        pub fn deinit(self: *Self) void {
            self.data.deinit();
        }

        pub fn insert(self: *Self, value: T) !void {
            try self.data.append(value);
            try self.heapifyUp(self.data.items.len - 1);
        }

        pub fn delete(self: *Self) !?T {
            // std.debug.print("\n", .{});
            // std.debug.print("delete\n", .{});
            if (self.data.items.len == 0) {
                return null;
            }

            if (self.data.items.len == 1) {
                return self.data.pop();
            }

            const out = self.data.items[0];
            // std.debug.print("out: {d}\n", .{out});
            self.data.items[0] = self.data.pop();
            // std.debug.print("self.data.items[0]: {d}\n", .{self.data.items[0]});
            try self.heapifyDown(0);
            // std.debug.print("\n", .{});
            return out;
        }

        fn heapifyDown(self: *Self, index: usize) !void {
            // std.debug.print("\n", .{});
            // std.debug.print("heapifyDown\n", .{});
            if (index >= self.data.items.len) {
                // std.debug.print("returning early\n", .{});
                return;
            }

            const left_index = self.leftChildIndex(index);
            const right_index = self.rightChildIndex(index);

            // std.debug.print("Left Index: {d}, left value: {d}\n", .{ left_index, self.data.items[left_index] });

            if (left_index >= self.data.items.len) {
                // std.debug.print("returning here\n", .{});
                return;
            }

            const value = self.data.items[index];
            const left_value = self.data.items[left_index];

            if (left_index == self.data.items.len - 1) {
                if (left_value < value) {
                    // std.debug.print("Hi\n", .{});
                    self.data.items[index] = left_value;
                    self.data.items[left_index] = value;
                }
                return;
            }
            // std.debug.print("right Index: {d}, right value: {d}\n", .{ right_index, self.data.items[right_index] });

            // const left_value = self.data.items[left_index];
            const right_value = self.data.items[right_index];

            if (left_value > right_value and value > right_value) {
                self.data.items[index] = right_value;
                self.data.items[right_index] = value;

                try self.heapifyDown(right_index);
            } else if (right_value > left_value and value > left_value) {
                self.data.items[index] = left_value;
                self.data.items[left_index] = value;

                try self.heapifyDown(left_index);
            }
        }

        fn heapifyUp(self: *Self, index: usize) !void {
            if (index == 0) {
                return;
            }

            const value = self.data.items[index];

            const parent_index = self.parentIndex(index);
            const parent_value = self.data.items[parent_index];

            if (parent_value > value) {
                self.data.items[index] = parent_value;
                self.data.items[parent_index] = value;

                try self.heapifyUp(parent_index);
            }
        }

        fn parentIndex(self: *Self, index: usize) usize {
            _ = self;

            return (index - 1) / 2;
        }

        fn leftChildIndex(self: *Self, index: usize) usize {
            _ = self;
            return index * 2 + 1;
        }

        fn rightChildIndex(self: *Self, index: usize) usize {
            _ = self;

            return index * 2 + 2;
        }

        pub fn format(
            self: Self,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;

            try writer.print("[{}] -> {any}\n", .{ T, self.data.items });
        }
    };
}

fn check(heap: MinHeap(usize)) !void {
    var num_checked: usize = 0;
    if (heap.data.items.len == 0) {
        return;
    }
    for (heap.data.items, 0..) |value, index| {
        if (index < 1) {
            continue;
        }
        try std.testing.expect(value > heap.data.items[(index - 1) / 2]);
        num_checked += 1;
    }

    try std.testing.expectEqual(heap.data.items.len - 1, num_checked);
}

test MinHeap {
    var heap = MinHeap(usize).init(std.testing.allocator);
    defer heap.deinit();

    try heap.insert(8);
    try heap.insert(2);
    try heap.insert(12);

    // std.debug.print("{any}\n", .{heap});

    _ = try heap.delete();
    // std.debug.print("{d}\n{any}\n", .{ val.?, heap });

    try std.testing.expectEqual(8, heap.data.items[0]);
    try std.testing.expectEqual(12, heap.data.items[1]);

    try heap.insert(60);
    try check(heap);
    try heap.insert(600);
    try check(heap);
    try heap.insert(500);
    try check(heap);
    try heap.insert(80);
    try check(heap);
    try heap.insert(82);
    try check(heap);
    try heap.insert(2);
    try check(heap);

    _ = try heap.delete();
    try check(heap);
    try heap.insert(69);
    try check(heap);
    _ = try heap.delete();
    try check(heap);
    _ = try heap.delete();
    try check(heap);
    _ = try heap.delete();
    try check(heap);
    _ = try heap.delete();
    try check(heap);
    _ = try heap.delete();
    try check(heap);
    _ = try heap.delete();
    try check(heap);
    _ = try heap.delete();
    try check(heap);
    _ = try heap.delete();
    try check(heap);
    _ = try heap.delete();
    try check(heap);
}
