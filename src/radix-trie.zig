const std = @import("std");
const mem = std.mem;

const Node = struct {
    const Self = @This();

    children: []Self,
    keys: []const u8,
    part: []const u8,
    value: ?usize,

    pub fn init(key: []const u8, val: ?usize) Self {
        return .{ .children = &.{}, .keys = &.{}, .part = key, .value = val };
    }

    pub fn split(comptime self: *Self, comptime idx: usize) void {
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

    pub fn insert(comptime self: *Self, comptime key: []const u8, comptime val: ?usize) void {
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

    pub fn appendChild(comptime self: *Self, comptime key: []const u8, comptime val: ?usize) void {
        self.keys = self.keys ++ [_]u8{key[0]};

        // I'm forced to do this I cannot do otherwise
        var newChildren: [self.children.len + 1]Self = undefined;
        std.mem.copyForwards(Self, &newChildren, self.children ++ &[_]Self{Self.init(key[1..], val)});
        self.children = &newChildren;
    }

    pub fn insertKey(comptime self: *Self, comptime key: []const u8, comptime val: ?usize) void {
        // Next children
        for (self.keys, 0..) |k, i| {
            if (key[0] == k) {
                self.children[i].insert(key[1..], val);
                return;
            }
        }

        self.appendChild(key, val);
    }

    pub fn insertRoot(comptime self: *Self, comptime key: []const u8, comptime val: ?usize) void {
        if (key.len == 0) {
            self.val = val;
        } else {
            self.insertKey(key, val);
        }
    }

    pub inline fn find(comptime self: Self, key: []const u8, comptime exact: bool) ?usize {
        // Prefix check
        const partLen = self.part.len;
        if (partLen != 0 and !mem.startsWith(u8, key, self.part)) return null;

        if (key.len == partLen) return self.value;

        inline for (self.keys, self.children) |k, child| {
            if (key[partLen] == k)
                return find(child, key[partLen + 1 ..], exact);
        }

        return if (exact) null else self.value;
    }
};

pub inline fn tree(comptime keys: []const []const u8) Node {
    comptime {
        var root = Node.init("", 0);

        for (keys, 1..) |key, i| {
            root.insertRoot(key, i);
        }

        return root;
    }
}

const words = [_][]const u8{ "aa", "aalii", "aam", "aardvark", "aardwolf", "Aaron", "Aaronic", "Aaronical", "Aaronite", "Aaronitic", "Aaru", "Ab", "aba", "Ababdeh", "Ababua", "abac", "abaca", "abacate", "abacay", "abacinate", "abacination", "abaciscus", "abacist", "aback", "abactinal", "abactinally", "abaction", "abactor", "abaculus", "abacus", "Abadite", "abaff", "abaft", "abaisance", "abaiser", "abaissed" };
const testing = std.testing;
test "node" {
    const stree = tree(&words);

    for (words, 1..) |word, i| {
        try testing.expectEqual(i, stree.find(word, true));
    }
}
