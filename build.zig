const std = @import("std");

pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "hello",
        .root_source_file = b.path("hello.zig"),
        .target = b.host,
        .optimize = optimize,
    });

    // Choose the OpenGL API, version, profile and extensions you want to generate bindings for.
    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.1",
        .profile = .core,
        .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });

    // Import the generated module.
    exe.root_module.addImport("gl", gl_bindings);

    //Mach glfw for ease of use.
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = b.host,
        .optimize = optimize,
    });
    exe.root_module.addImport("mach-glfw", glfw_dep.module("mach-glfw"));

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
