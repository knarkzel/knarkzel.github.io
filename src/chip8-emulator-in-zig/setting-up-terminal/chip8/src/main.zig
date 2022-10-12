const std = @import("std");
const Emulator = @import("Emulator.zig");
const Terminal = @import("Terminal.zig");

var running = true;
var keys: [16]bool = undefined;
var screen: [64 * 32]bool = undefined;

fn handleInput() !void {
    const CTRL_C = 3;
    const CTRL_Z = 26;
    while (true) {
        const key = try Terminal.read();
        switch (key) {
            CTRL_C, CTRL_Z => running = false,
            '1' => keys[0] = true,
            '2' => keys[1] = true,
            '3' => keys[2] = true,
            '4' => keys[3] = true,
            'q' => keys[4] = true,
            'w' => keys[5] = true,
            'f' => keys[6] = true,
            'p' => keys[7] = true,
            'a' => keys[8] = true,
            'r' => keys[9] = true,
            's' => keys[10] = true,
            't' => keys[11] = true,
            'z' => keys[12] = true,
            'x' => keys[13] = true,
            'c' => keys[14] = true,
            'v' => keys[15] = true,
            else => continue,
        }
    }
}

pub fn main() !void {
    // Initialize emulator
    const bytes = @embedFile("../roms/opcode.ch8");
    Emulator.init(bytes);

    // Initialize terminal
    try Terminal.init();

    // Input
    const input = try std.Thread.spawn(.{}, handleInput, .{});
    input.detach();

    // Draw to screen
    while (true) {
        try Terminal.clear();
        for (screen) |byte, i| {
            const output = if (byte) "█" else " ";
            try Terminal.write(output);
            if (i % 64 == 0) try Terminal.write("\n");
        }
        if (!running) break;
    }
    try Terminal.deinit();
}
