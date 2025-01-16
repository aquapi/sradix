const std = @import("std");
const mem = std.mem;

pub inline fn tree(comptime T: type) type {
    const String = []const T;

    return struct {
        const Self = @This();

        children: []Self,
        keys: String,
        part: String,
        value: usize,

        pub fn initNode(key: String, val: usize) Self {
            return .{ .children = &.{}, .keys = &.{}, .part = key, .value = val };
        }

        // Split the current node to two nodes and keep the reference to the parent node
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

        /// Append a new item to the tree with checking
        pub fn append(comptime self: *Self, comptime key: String, comptime val: usize) void {
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

        /// Append a new children without checking
        pub fn appendChild(comptime self: *Self, comptime key: String, comptime val: usize) void {
            self.keys = self.keys ++ [_]T{key[0]};

            // I'm forced to do this I cannot do otherwise
            var newChildren: [self.children.len + 1]Self = undefined;
            std.mem.copyForwards(Self, &newChildren, self.children ++ &[_]Self{Self.initNode(key[1..], val)});
            self.children = &newChildren;
        }

        /// Append a new children with checking
        pub fn appendChildSafe(comptime self: *Self, comptime key: String, comptime val: usize) void {
            // Next children
            for (self.keys, self.children) |k, *child| {
                if (key[0] == k) {
                    child.append(key[1..], val);
                    return;
                }
            }

            self.appendChild(key, val);
        }

        /// Append a new child to a root node with checking
        pub fn appendToRoot(comptime self: *Self, comptime key: String, comptime val: usize) void {
            if (key.len == 0) {
                self.val = val;
            } else {
                self.appendChildSafe(key, val);
            }
        }

        /// Search an item in the tree
        pub inline fn find(comptime self: Self, key: String, comptime exact: bool, comptime fallback: usize) usize {
            // Prefix check
            const partLen = self.part.len;

            // Skip check if part is empty
            // If part doesn't match then return the fallback
            if (partLen != 0 and !mem.startsWith(T, key, self.part))
                return fallback;

            // Exact match
            if (key.len == partLen) return self.value;

            // Inline children checks
            inline for (self.keys, self.children) |k, child| {
                if (key[partLen] == k)
                    // Recursive inlining
                    return find(child, key[partLen + 1 ..], exact, self.value);
            }

            // Path matched but no children matched
            return if (exact) fallback else self.value;
        }

        /// Returns the 1-based index for the key if any, else 0.
        pub inline fn get(comptime self: Self, key: String) usize {
            return self.find(key, true, 0);
        }

        /// Returns the 1-based index of the key that is the longest prefix of `str`
        /// else null.
        pub inline fn getLongestPrefix(comptime self: Self, key: String) usize {
            return self.find(key, false, self.value);
        }

        pub inline fn init(comptime keys: anytype) Self {
            comptime {
                var root = Self.initNode("", 0);
                for (keys, 1..) |key, i|
                    root.appendToRoot(key, i);
                return root;
            }
        }
    };
}

const words = [_][]const u8{ "aa", "aalii", "aam", "aardvark", "aardwolf", "Aaron", "Aaronic", "Aaronical", "Aaronite", "Aaronitic", "Aaru", "Ab", "aba", "Ababdeh", "Ababua", "abac", "abaca", "abacate", "abacay", "abacinate", "abacination", "abaciscus", "abacist", "aback", "abactinal", "abactinally", "abaction", "abactor", "abaculus", "abacus", "Abadite", "abaff", "abaft", "abaisance", "abaiser", "abaissed" };
const testing = std.testing;
test "node" {
    const stree = tree(u8).init(words);

    for (words, 1..) |word, i| {
        try testing.expectEqual(i, stree.get(word));
    }
}
