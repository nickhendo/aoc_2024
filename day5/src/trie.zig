const std = @import("std");

const NodeChild = [100]?*Node;

pub const Node = struct {
    child: NodeChild,
    arena: *std.heap.ArenaAllocator,

    /// Create a new Trie Node, with child set to a null array
    pub fn init(arena: *std.heap.ArenaAllocator) !*Node {
        var child: [100]?*Node = undefined;
        @memset(&child, null);

        const node = try arena.allocator().create(Node);
        node.arena = arena;
        node.child = child;

        return node;
    }

    /// Free all memory for entire tree
    pub fn deinit(self: *Node) void {
        self.arena.deinit();
    }

    /// Ensure a child is set for the given node. If the child is null,
    /// create a new array of nulls (indicating the child relationship),
    /// otherwise return
    pub fn insert(self: *Node, child: usize) !*Node {
        var node: *Node = undefined;
        if (self.child[child] == null) {
            node = try Node.init(self.arena);
            self.child[child] = node;
        } else {
            node = self.child[child].?;
        }

        return node;
    }
};
