const std = @import("std");
const mem = std.mem;

const Node = struct {
    const Self = @This();

    children: []Self,
    keys: []const u8,
    part: []const u8,
    value: u8,

    pub fn init(key: []const u8, val: u8) Self {
        return .{ .children = &.{}, .keys = &.{}, .part = key, .value = val };
    }

    pub fn split(self: *Self, idx: usize) void {
        // Move the current node up
        var newNode = Self.init(self.part[idx + 1 ..], self.value);

        newNode.children = self.children;
        newNode.keys = self.keys;

        // Bruh wtf is this
        var newChildren: [1]Self = undefined;
        std.mem.copyForwards(Self, &newChildren, &[_]Self{newNode});
        self.children = &newChildren;

        var newKeys: [1]u8 = undefined;
        std.mem.copyForwards(u8, &newKeys, &[_]u8{self.part[idx]});
        self.keys = &newKeys;

        // Reset that later
        self.part = self.part[0..idx];
        self.value = 0;
    }

    pub fn insert(self: *Self, key: []const u8, val: u8) void {
        // Compare the current key
        if (mem.indexOfDiff(u8, key, self.part)) |diff| {
            // Split a new node
            if (diff == key.len) {
                self.split(diff);
                self.value = val;
            }

            // Cut the key
            else if (diff == self.part.len) {
                self.insertKey(key[self.part.len..], val);
            }

            // Split to two nodes
            else {
                self.split(diff);
                self.appendChild(key[diff..], val);
            }
        } else self.value = val;
    }

    pub fn appendChild(self: *Self, key: []const u8, val: u8) void {
        self.keys = self.keys ++ [_]u8{key[0]};

        // I'm forced to do this I cannot do otherwise
        var newChildren: [self.children.len + 1]Self = undefined;
        std.mem.copyForwards(Self, &newChildren, self.children ++ &[_]Self{Self.init(key[1..], val)});
        self.children = &newChildren;
    }

    pub fn insertKey(self: *Self, key: []const u8, val: u8) void {
        // Next children
        for (self.keys, 0..) |k, i| {
            if (key[0] == k) {
                self.children[i].insert(key[1..], val);
                return;
            }
        }

        self.appendChild(key, val);
    }

    pub fn insertRoot(self: *Self, key: []const u8, val: u8) void {
        if (key.len == 0) {
            self.val = val;
        } else {
            self.insertKey(key, val);
        }
    }

    pub fn compress(self: Self) []const u8 {
        const keys = self.keys;
        const keysLen: u8 = @intCast(keys.len);

        var str: []const u8 = &[_]u8{@intCast(self.part.len)} ++ self.part ++ &[_]u8{ self.value, keysLen };
        if (keysLen == 0) return str;

        var compressedChildren: []const u8 = &[0]u8{};

        var jmp: u8 = keysLen * 2;
        str = str ++ &[_]u8{ keys[0], jmp };
        compressedChildren = compressedChildren ++ self.children[0].compress();

        for (self.children[1..], 1..) |child, i| {
            jmp -= 2;
            str = str ++ &[_]u8{ keys[i], @intCast(jmp + compressedChildren.len) };
            compressedChildren = compressedChildren ++ child.compress();
        }

        return str ++ compressedChildren;
    }
};

// I need this later
pub const Tree = struct {
    const Self = @This();

    root: []const u8,
    pub fn init(comptime keys: []const []const u8) Self {
        comptime var root = Node.init("", 0);

        comptime {
            for (keys, 1..) |key, i| {
                root.insertRoot(key, i);
            }
        }

        return .{ .root = comptime root.compress() };
    }

    pub fn search(self: Self, k: []const u8, comptime exact: bool) u8 {
        var root: []const u8 = self.root;
        var key: []const u8 = k;
        var maxIt: u8 = undefined;

        blk: while (true) {
            // Length check
            if (key.len < root[0] or !mem.startsWith(u8, key, root[1 .. 1 + root[0]])) return 0;

            // Cut the key and move the root up to the value position
            key = key[root[0]..];
            root = root[1 + root[0] ..];

            // Key ended
            if (key.len == 0) return root[0];

            maxIt = root[1];
            for (0..maxIt) |_| {
                // Key check
                if (key[0] == root[2]) {
                    // Remove the first character
                    key = key[1..];
                    // Move to the position of the children
                    root = root[2 + root[3] ..];
                    continue :blk;
                }

                // Move to next key
                root = root[2..];
            }

            return if (exact) 0 else root[0];
        }
    }
};

const words = [_][]const u8{ "aa", "aalii", "aam", "aardvark", "aardwolf", "Aaron", "Aaronic", "Aaronical", "Aaronite", "Aaronitic", "Aaru", "Ab", "aba", "Ababdeh", "Ababua", "abac", "abaca", "abacate", "abacay", "abacinate", "abacination", "abaciscus", "abacist", "aback", "abactinal", "abactinally", "abaction", "abactor", "abaculus", "abacus", "Abadite", "abaff", "abaft", "abaisance", "abaiser", "abaissed" };
const testing = std.testing;
test "node" {
    const stree = Tree.init(&words);
    for (stree.root) |i| {
        if (i > 64) {
            std.debug.print("{c} ", .{i});
        } else {
            std.debug.print("{d} ", .{i});
        }
    }
    std.debug.print("\nTesting:\n", .{});

    for (words, 1..) |word, i| {
        try testing.expectEqual(i, stree.search(word, true));
    }
}
