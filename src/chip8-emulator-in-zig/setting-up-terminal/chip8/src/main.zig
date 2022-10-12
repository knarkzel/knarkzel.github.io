const std = @import("std");
const Emulator = @import("Emulator.zig");
const Terminal = @import("Terminal.zig");

var running = true;
var keyboard: [16]bool = undefined;
var screen: [64 * 32]bool = undefined;

fn handleInput() !void {
    const CTRL_C = 3;
    const CTRL_Z = 26;
    while (true) {
        const key = try Terminal.read();
        switch (key) {
            CTRL_C, CTRL_Z => running = false,
            '1' => keyboard[0] = true,
            '2' => keyboard[1] = true,
            '3' => keyboard[2] = true,
            '4' => keyboard[3] = true,
            'q' => keyboard[4] = true,
            'w' => keyboard[5] = true,
            'f' => keyboard[6] = true,
            'p' => keyboard[7] = true,
            'a' => keyboard[8] = true,
            'r' => keyboard[9] = true,
            's' => keyboard[10] = true,
            't' => keyboard[11] = true,
            'z' => keyboard[12] = true,
            'x' => keyboard[13] = true,
            'c' => keyboard[14] = true,
            'v' => keyboard[15] = true,
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
