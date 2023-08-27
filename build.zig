const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    // Module
    _ = b.addModule("PieQ", .{ .source_file = .{ .path = "src/pie_queue.zig" } });

    // Library
    const lib = b.addStaticLibrary(.{
        .name = "PieQ",
        .root_source_file = .{ .path = "src/pie_queue.zig" },
        .target = target,
        .optimize = .ReleaseSafe,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });

    b.installArtifact(lib);

    // Benchmark
    const bench_step = b.step("bench", "Run benchmarks");

    const bench = b.addExecutable(.{
        .name = "pieQ_bench",
        .root_source_file = .{ .path = "src/bench.zig" },
        .target = target,
        .optimize = .ReleaseFast,
    });

    const bench_run = b.addRunArtifact(bench);
    if (b.args) |args| {
        bench_run.addArgs(args);
    }

    bench_step.dependOn(&bench_run.step);

    // Tests
    const test_step = b.step("test", "Run library tests");

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/pie_queue.zig" },
        .target = target,
        .optimize = .ReleaseFast,
    });

    const run_main_tests = b.addRunArtifact(main_tests);
    test_step.dependOn(&run_main_tests.step);
}
