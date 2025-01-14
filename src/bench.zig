const std = @import("std");
const mem = std.mem;

const Timer = std.time.Timer;
const log = std.log.scoped(.bench);

const radix = @import("radix-trie.zig");
const Tree = radix.Tree;

const wordList = @embedFile("./words.txt");
const gpa = std.testing.allocator;

const loops = 10_000;

const words = [_][]const u8{
    "A",
    "a",
    "aa",
    "aal",
    "aalii",
    "aam",
    "Aani",
    "aardvark",
    "aardwolf",
    "Aaron",
    "Aaronic",
    "Aaronical",
    "Aaronite",
    "Aaronitic",
    "Aaru",
    "Ab",
    "aba",
    "Ababdeh",
    "Ababua",
    "abac",
    "abaca",
    "abacate",
    "abacay",
    "abacinate",
    "abacination",
    "abaciscus",
    "abacist",
    "aback",
    "abactinal",
    "abactinally",
    "abaction",
    "abactor",
    "abaculus",
    "abacus",
    "Abadite",
    "abaff",
    "abaft",
    "abaisance",
    "abaiser",
    "abaissed",
};

pub fn main() !void {
    @setEvalBranchQuota(1_000_000);
    // Init tree
    const tree = Tree.init(&words);

    // Init static map
    comptime var mapWords = [_]struct { []const u8 }{.{""}} ** words.len;
    comptime {
        for (words, 0..) |word, i| {
            mapWords[i] = .{word};
        }
    }

    const map = std.StaticStringMap(void).initComptime(mapWords);

    // Bench
    var res: [3]u64 = undefined;
    var it = mem.splitScalar(u8, wordList, '\n');

    log.debug("Start benching\t[0]\t[1]\t[2]", .{});

    // STree
    for (&res) |*r| {
        var timer = try Timer.start();
        for (0..loops) |_| {
            it.index = 0;
            while (it.next()) |val| {
                _ = tree.search(val, false);
            }
        }
        r.* = timer.read();
    }

    log.info("STree\t\t{:0>4}ms\t{:0>4}ms\t{:0>4}ms", .{
        res[0] / 1_000_000,
        res[1] / 1_000_000,
        res[2] / 1_000_000,
    });

    // StaticStringMap
    for (&res) |*r| {
        var timer = try Timer.start();
        for (0..loops) |_| {
            it.index = 0;
            while (it.next()) |val| {
                _ = map.getLongestPrefixIndex(val);
            }
        }
        r.* = timer.read();
    }

    log.info("StaticStringMap\t{:0>4}ms\t{:0>4}ms\t{:0>4}ms", .{
        res[0] / 1_000_000,
        res[1] / 1_000_000,
        res[2] / 1_000_000,
    });
}
