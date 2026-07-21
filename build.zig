const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const mod_utils = b.addModule("utils", .{
    //     .root_source_file = b.path("src/uitls.zig"),
    //     .target = target,
    // });

    // const mod_io = b.addModule("io", .{
    //     .root_source_file = b.path("src/perf_io.zig"),
    //     .target = target,
    // });

    const exe_io = b.addExecutable(.{
        .name = "perf_io",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/perf_io.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                // .{ .name = "utils", .module = mod_utils },
            },
        }),
    });

    // const exe_conv = b.addExecutable(.{
    //     .name = "perf_conv",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("src/perf_conv.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //         .imports = &.{
    //             .{ .name = "utils", .module = mod_utils },
    //             .{ .name = "mod_io", .module = mod_io },
    //         },
    //     }),
    // });

    b.installArtifact(exe_io);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe_io);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();
}
