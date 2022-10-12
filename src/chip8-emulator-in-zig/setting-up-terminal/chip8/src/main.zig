const std = @import("std");
const Thread = std.Thread;
const Terminal = @import("Terminal.zig");

const CTRL_C = 3;
const CTRL_Z = 26;

var stop = false;
var keyboard: [16]bool = undefined;
var screen: [32][64]bool = undefined;

fn handleInput() !void {
    while (true) {
        const key = try Terminal.read();
        switch (key) {
            CTRL_C, CTRL_Z => stop = true,
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
    // Initialize terminal
    try Terminal.init();

    // Input
    const input = try Thread.spawn(.{}, handleInput, .{});
    input.detach();

    // Draw to screen
    while (true) {
        try Terminal.clear();
        for (screen) |row| {
            for (row) |block| {
                const bytes = if (block) "█" else " ";
                try Terminal.write(bytes);
            }
            try Terminal.write("\n");
        }
        if (stop) break;
    }
    try Terminal.deinit();
}
