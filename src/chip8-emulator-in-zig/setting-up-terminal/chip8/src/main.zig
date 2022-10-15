const std = @import("std");
const Emulator = @import("Emulator.zig");
const Terminal = @import("Terminal.zig");

var running = true;
var keys: [16]u1 = undefined;
var screen: [64 * 32]u1 = undefined;

fn handleInput() !void {
    const CTRL_C = 3;
    const CTRL_Z = 26;
    while (true) {
        const key = try Terminal.read();
        keys = .{0} ** 16;
        switch (key) {
            CTRL_C, CTRL_Z => running = false,
            '1' => keys[0] = 1,
            '2' => keys[1] = 1,
            '3' => keys[2] = 1,
            '4' => keys[3] = 1,
            'q' => keys[4] = 1,
            'w' => keys[5] = 1,
            'f' => keys[6] = 1,
            'p' => keys[7] = 1,
            'a' => keys[8] = 1,
            'r' => keys[9] = 1,
            's' => keys[10] = 1,
            't' => keys[11] = 1,
            'z' => keys[12] = 1,
            'x' => keys[13] = 1,
            'c' => keys[14] = 1,
            'v' => keys[15] = 1,
            else => continue,
        }
    }
}

pub fn main() !void {
    // Initialize emulator
    const bytes = @embedFile("../roms/tests.ch8");
    Emulator.init(bytes);

    // Initialize terminal
    try Terminal.init();

    // Input
    const input = try std.Thread.spawn(.{}, handleInput, .{});
    input.detach();

    // Main loop
    while (running) : (std.time.sleep(10 * std.time.ns_per_ms)) {
        Emulator.cycle(&keys, &screen);
        if (Emulator.update) {
            try Terminal.clear();
            for (screen) |byte, i| {
                const output = if (byte > 0) "█" else " ";
                try Terminal.write(output);
                if (i % 64 == 0) try Terminal.write("\n");
            }
            Emulator.update = false;
        }
    }
    try Terminal.deinit();
}
