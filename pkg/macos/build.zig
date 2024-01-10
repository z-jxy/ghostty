const std = @import("std");
const builtin = @import("builtin");
const apple_sdk = @import("apple_sdk");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("macos", .{ .root_source_file = .{ .path = "main.zig" } });

    const lib = b.addStaticLibrary(.{
        .name = "macos",
        .target = target,
        .optimize = optimize,
    });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    defer flags.deinit();
    lib.addCSourceFile(.{
        .file = .{ .path = "os/log.c" },
        .flags = flags.items,
    });
    lib.addCSourceFile(.{
        .file = .{ .path = "text/ext.c" },
        .flags = flags.items,
    });
    lib.linkFramework("Carbon");
    lib.linkFramework("CoreFoundation");
    lib.linkFramework("CoreGraphics");
    lib.linkFramework("CoreText");
    lib.linkFramework("CoreVideo");

    if (target.result.isDarwin()) {
        module.linkFramework("Carbon", .{});
        module.linkFramework("CoreFoundation", .{});
        module.linkFramework("CoreGraphics", .{});
        module.linkFramework("CoreText", .{});
        module.linkFramework("CoreVideo", .{});

        if (!target.query.isNative()) {
            try apple_sdk.addPaths(b, &lib.root_module);
            try apple_sdk.addPaths(b, module);
        }
    }
    b.installArtifact(lib);

    {
        const test_exe = b.addTest(.{
            .name = "test",
            .root_source_file = .{ .path = "main.zig" },
            .target = target,
            .optimize = optimize,
        });
        test_exe.linkLibrary(lib);
        var it = module.import_table.iterator();
        while (it.next()) |entry| test_exe.root_module.addImport(entry.key_ptr.*, entry.value_ptr.*);

        const tests_run = b.addRunArtifact(test_exe);
        const test_step = b.step("test", "Run tests");
        test_step.dependOn(&tests_run.step);
    }
}
