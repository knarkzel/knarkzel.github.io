const std = @import("std");
const Sdk = @import("vendor/SDL.zig/Sdk.zig");

pub fn build(b: *std.build.Builder) void {
    const sdk = Sdk.init(b);
    const chip8 = b.addExecutable("chip8", "src/main.zig");
    chip8.setTarget(b.standardTargetOptions(.{}));
    sdk.link(chip8, .dynamic);
    chip8.addPackage(sdk.getNativePackage("sdl2"));
    chip8.setBuildMode(b.standardReleaseOptions());
    chip8.install();

    const run_cmd = chip8.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
