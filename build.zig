const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const mod = b.addModule("pixel_utils", .{ .root_source_file = b.path("src/root.zig"), .optimize = optimize, .target = target });

    const sdl3_dep = b.dependency("sdl3", .{ .optimize = optimize, .target = target });

    const tests = b.addTest(.{ .name = "tests", .root_module = b.createModule(.{ .root_source_file = b.path("src/tests.zig"), .optimize = optimize, .target = target }) });
    b.installArtifact(tests);

    tests.root_module.addImport("utils", mod);
    tests.root_module.addImport("sdl3", sdl3_dep.module("sdl3"));

    const run_arti = b.addRunArtifact(tests);
    const step = b.step("test", "Run the tests");
    step.dependOn(&run_arti.step);
}
