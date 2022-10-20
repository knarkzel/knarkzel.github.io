const Terminal = @import("Terminal.zig");

var screen: [64 * 32]u1 = undefined;

pub fn main() !void {
    try Terminal.init();
    try Terminal.hideCursor();

    // Clear the terminal
    try Terminal.clear();

    // Modify screen
    for (screen) |*bit, i| {
        if ((i + 1) % 2 == 0) bit.* = 1;
    }

    // Show in terminal
    for (screen) |bit, i| {
        if (bit == 1) try Terminal.write("█") else try Terminal.write(" ");
        if ((i + 1) % 64 == 0) try Terminal.write("\n");
    }

    while (true) {}
}
