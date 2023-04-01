const Terminal = @import("Terminal.zig");

var current_screen: usize = 0;
var screens: [2][64 * 32]u1 = undefined;

pub fn init() !void {
    try Terminal.init();
    try Terminal.hideCursor();
    try Terminal.clear();
}

/// Draw rectangle at column, line with width, height
pub fn draw(column: usize, line: usize, width: usize, height: usize) !void {
    var j: usize = 0;
    while (j < height) : (j += 1) {
        var i: usize = 0;
        while (i < width) : (i += 1) {
            const x = column + i;
            if (x < 64) {
                const y = line + j;
                if (y < 32) {
                    const position = x + y * 64;
                    screens[current_screen][position] ^= 1;
                }
            }
        }
    }
}

pub fn flush() !void {
    // Draw delta
    var i: usize = 0;
    while (i < 64 * 32) : (i += 1) {
        if (screens[current_screen][i] != screens[(current_screen + 1) % 2][i]) {
            // Move cursor and draw
            try Terminal.moveCursor(i % 64, i / 64);
            if (screens[current_screen][i] == 1) {
                try Terminal.write("█");
            } else {
                try Terminal.write(" ");
            }
        }
    }
    current_screen = (current_screen + 1) % 2;
    screens[current_screen] = .{0} ** (64 * 32);
}
