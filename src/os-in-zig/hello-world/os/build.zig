const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = .{ .cpu_arch = .i386, .os_tag = .freestanding };

    const os = b.addExecutable("os.elf", "src/main.zig");
    os.setLinkerScriptPath(.{ .path = "linker.ld" });
    os.setBuildMode(mode);
    os.setTarget(target);
    os.install();

    const run_cmd = b.addSystemCommand(&.{
        "qemu-system-i386",
        "-kernel",
        "zig-out/bin/os.elf",
        "-display",
        "gtk,zoom-to-fit=on",
    });
    run_cmd.step.dependOn(&os.install_step.?.step);

    const run_step = b.step("run", "Run the os");
    run_step.dependOn(&run_cmd.step);
}
