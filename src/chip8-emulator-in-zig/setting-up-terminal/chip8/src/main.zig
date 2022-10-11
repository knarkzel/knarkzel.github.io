const std = @import("std");
const ansi = @import("ansi.zig");
const Terminal = @import("Terminal.zig");

var screen: [32][64]bool = undefined;

pub fn main() !void {
    screen[0][3] = true;
    screen[0][4] = true;
    screen[0][5] = true;
    try Terminal.init();

    while (true) {
        try Terminal.clear();
        for (screen) |row| {
            for (row) |block| {
                if (block) {
                    for ("█") |byte|
                        try Terminal.write(byte);
                } else {
                    try Terminal.write(' ');
                }
            }
            try Terminal.write('\n');
        }
        const key = try Terminal.read();
        if (key == ansi.CTRL_C) break;
    }
    try Terminal.deinit();
}
