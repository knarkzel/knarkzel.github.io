const std = @import("std");
const Emulator = @import("Emulator.zig");
const Terminal = @import("Terminal.zig");

const step = 3 * std.time.ns_per_ms;
var running = true;
var keys: [16]u1 = undefined;
var screens: [2][64 * 32]u1 = undefined;
var screen: *[64 * 32]u1 = &screens[0];
var index: usize = 0;

fn drawDiff(allocator: std.mem.Allocator) !void {
    var commands = std.ArrayList(u8).init(allocator);
    defer commands.deinit();
    const before = screens[(index + 1) % 2];
    const after = screen.*;
    var y: usize = 0;
    while (y < 32) : (y += 1) {
        var x: usize = 0;
        while (x < 64) : (x += 1) {
            const i = y * 64 + x;
            if (after[i] != before[i]) {
                const output = if (after[i] > 0) "█" else " ";
                const command = try std.fmt.allocPrint(allocator, "\x1b[{d};{d}H{s}", .{ y + 1, x + 1, output });
                defer allocator.free(command);
                try commands.appendSlice(command);
            }
        }
    }
    try Terminal.write(commands.items);
}

fn handleInput() !void {
    const CTRL_C = 3;
    const CTRL_Z = 26;
    while (running) : (std.time.sleep(step)) {
        const key = try Terminal.read();
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
    // Allocator
    var buffer: [64 * 32 * 15]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // Initialize emulator
    Emulator.init(@embedFile("../roms/tests.ch8"));

    // Initialize terminal
    try Terminal.init();

    // Input
    const input = try std.Thread.spawn(.{}, handleInput, .{});
    input.detach();

    // Main loop
    while (running) : (std.time.sleep(step)) {
        Emulator.cycle(&keys, screen);
        if (Emulator.update) {
            try drawDiff(allocator);
            fba.reset();
            index = (index + 1) % 2;
            screens[index] = screen.*;
            screen = &screens[index];
            Emulator.update = false;
        }
    }
    try Terminal.deinit();
}
