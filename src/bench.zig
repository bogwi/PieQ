const std = @import("std");
const PieQ = @import("pieq.zig").PieQ;
const stdout = std.io.getStdOut().writer();

const HELP =
    \\pieQ benchmark [options]
    \\
    \\info: 
    \\      default test runs 1_000_000 pairs
    \\
    \\Options:
    \\      [size], unsigned integer, 
    \\      the number of randomly ordered pairs of u64 PieQ is tested with.
    \\      Can be formatted as 1_234_567
;

fn compareU32(isMin: bool, a: u32, b: u32) bool {
    while (isMin)
        return a <= b;
    return a >= b;
}
fn toSeconds(t: i128) f64 {
    return @as(f64, @floatFromInt(t)) / 1_000_000_000;
}
fn prettyNumber(N: usize, alloc: std.mem.Allocator) !void {
    var stack = std.ArrayList(u8).init(alloc);
    defer stack.deinit();
    var N_ = N;

    var counter: u8 = 0;
    while (N_ > 0) : (counter += 1) {
        const rem: u8 = @intCast(N_ % 10);
        if (counter == 3) {
            stack.append(0x5F) catch unreachable;
            counter = 0;
        }
        stack.append(rem + 48) catch unreachable;
        N_ = @divFloor(N_, 10);
    }
    counter = @intCast(stack.items.len);
    while (counter > 0) : (counter -= 1) {
        try stdout.print("{c}", .{stack.pop()});
    }
}
fn writeTimestamps(header: []const u8, stamps: []i128, N: usize, alloc: std.mem.Allocator) !void {
    const actions = [_][]const u8{ "action", "push", "pop", "sum" };
    try stdout.print("\n{s}", .{header});
    try prettyNumber(N, alloc);
    try stdout.print(" items\n", .{});
    for (actions) |action| {
        try stdout.print("|{s: <8}", .{action});
    }
    try stdout.print("|\n", .{});

    try stdout.print("|time:sec", .{});
    for (stamps) |stamp| {
        try stdout.print("|{d: <8.4}", .{toSeconds(stamp)});
    }
    try stdout.print("|\n", .{});

    try stdout.print("|ns:item ", .{});
    for (stamps) |stamp| {
        try stdout.print("|{d: <8.4}", .{@as(f64, @floatFromInt(stamp)) / @as(f64, @floatFromInt(N))});
    }
    try stdout.print("|\n\n", .{});
}

pub fn benchmark(N: usize) !void {
    var sum: i128 = 0;
    var stamps = [_]i128{0} ** 3;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("memory leak ...");
    };
    const allocator = gpa.allocator();

    // get an array of size N of randomly ordered integers
    var keys = std.ArrayList(u32).init(allocator);
    defer keys.deinit();

    var rng = std.rand.DefaultPrng.init(0);
    const random = rng.random();

    var int: u32 = 0;
    while (int < N) : (int += 1) {
        keys.append(int) catch unreachable;
    }
    random.shuffle(u32, keys.items);

    // initiate PieQ
    var minQueue = PieQ(u32, u32, .min, compareU32).init(allocator);
    defer minQueue.deinit();

    // run the test
    const Timestamp = std.time.nanoTimestamp;
    var time: i128 = Timestamp();
    for (keys.items) |num| {
        try minQueue.push(.{ .key = num, .val = num });
    }
    time = Timestamp() - time;
    sum += time;
    stamps[0] = time;

    int = 0;
    time = Timestamp();
    while (int < N) : (int += 1) {
        std.debug.assert((try minQueue.pop()).key == int);
    }
    time = Timestamp() - time;
    sum += time;
    stamps[1] = time;
    stamps[2] = sum;
    try writeTimestamps("PieQ:        ", &stamps, N, allocator);
}

pub fn main() !void {
    // get args
    var buffer: [1024]u8 = undefined;
    var fixed = std.heap.FixedBufferAllocator.init(buffer[0..]);
    const args = try std.process.argsAlloc(fixed.allocator());
    defer std.process.argsFree(fixed.allocator(), args);

    // default testing size
    var N: usize = 1_000_000;

    var i: usize = 1;
    if (args.len > 2) {
        std.debug.print(HELP ++ "\n", .{});
        return;
    }
    while (i < args.len) : (i += 1) {
        var integer: bool = true;

        for (args[i]) |char| {
            if (char < 48 or char > 57 and char != 95) integer = false;
        }

        if (integer) {
            N = try std.fmt.parseUnsigned(usize, args[i], 10);
        } else if (std.mem.eql(u8, args[i], "-h")) {
            std.debug.print(HELP ++ "\n", .{});
            return;
        } else {
            std.debug.print(HELP ++ "\n", .{});
            return;
        }
    }
    try benchmark(N);
}
