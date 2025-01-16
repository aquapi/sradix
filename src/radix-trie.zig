const std = @import("std");
const mem = std.mem;

pub inline fn tree(comptime T: type) type {
    const String = []const T;

    return struct {
        const Self = @This();

        children: []Self,
        keys: String,
        part: String,
        value: ?usize,

        pub fn initNode(key: String, val: ?usize) Self {
            return .{ .children = &.{}, .keys = &.{}, .part = key, .value = val };
        }

        pub fn split(comptime self: *Self, comptime idx: usize) void {
            // Move the current node up
            var newNode = Self.initNode(self.part[idx + 1 ..], self.value);

            newNode.children = self.children;
            newNode.keys = self.keys;

            // Bruh wtf is this
            var newChildren: [1]Self = undefined;
            std.mem.copyForwards(Self, &newChildren, &[_]Self{newNode});
            self.children = &newChildren;

            var newKeys: [1]T = undefined;
            std.mem.copyForwards(T, &newKeys, &[_]T{self.part[idx]});
            self.keys = &newKeys;

            // Reset that later
            self.part = self.part[0..idx];
            self.value = 0;
        }

        pub fn insert(comptime self: *Self, comptime key: String, comptime val: ?usize) void {
            // Compare the current key
            if (mem.indexOfDiff(T, key, self.part)) |diff| {
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

        pub fn appendChild(comptime self: *Self, comptime key: String, comptime val: ?usize) void {
            self.keys = self.keys ++ [_]T{key[0]};

            // I'm forced to do this I cannot do otherwise
            var newChildren: [self.children.len + 1]Self = undefined;
            std.mem.copyForwards(Self, &newChildren, self.children ++ &[_]Self{Self.initNode(key[1..], val)});
            self.children = &newChildren;
        }

        pub fn insertKey(comptime self: *Self, comptime key: String, comptime val: ?usize) void {
            // Next children
            for (self.keys, self.children) |k, *child| {
                if (key[0] == k) {
                    child.insert(key[1..], val);
                    return;
                }
            }

            self.appendChild(key, val);
        }

        pub fn insertRoot(comptime self: *Self, comptime key: String, comptime val: ?usize) void {
            if (key.len == 0) {
                self.val = val;
            } else {
                self.insertKey(key, val);
            }
        }

        // Inline everything
        pub inline fn find(comptime self: Self, key: String, comptime exact: bool) ?usize {
            // Prefix check
            const partLen = self.part.len;
            if (partLen != 0 and !mem.startsWith(T, key, self.part)) return null;
            if (key.len == partLen) return self.value;

            inline for (self.keys, self.children) |k, child| {
                if (key[partLen] == k)
                    // Recursive inlining
                    return if (find(child, key[partLen + 1 ..], exact)) |val| val
                        else if (exact) null
                        else self.value;
            }

            return if (exact) null
                else self.value;
        }

        pub inline fn init(comptime keys: []const []const T) Self {
            comptime {
                var root = Self.initNode("", null);

                for (keys, 0..) |key, i| {
                    root.insertRoot(key, i);
                }

                return root;
            }
        }
    };
}

const words = [_][]const u8{ "aa", "aalii", "aam", "aardvark", "aardwolf", "Aaron", "Aaronic", "Aaronical", "Aaronite", "Aaronitic", "Aaru", "Ab", "aba", "Ababdeh", "Ababua", "abac", "abaca", "abacate", "abacay", "abacinate", "abacination", "abaciscus", "abacist", "aback", "abactinal", "abactinally", "abaction", "abactor", "abaculus", "abacus", "Abadite", "abaff", "abaft", "abaisance", "abaiser", "abaissed" };
const testing = std.testing;
test "node" {
    const stree = tree(u8).init(&words);

    for (words, 0..) |word, i| {
        try testing.expectEqual(i, stree.find(word, true));
    }
}
