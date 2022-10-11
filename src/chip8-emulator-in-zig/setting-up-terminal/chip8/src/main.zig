const std = @import("std");
const ansi = @import("ansi.zig");
const Terminal = @import("Terminal.zig");

pub fn main() !void {
    try Terminal.init();
    while (true) {
        const key = try Terminal.read();
        if (key == ansi.CTRL_C) break;
    }
    try Terminal.deinit();
}
