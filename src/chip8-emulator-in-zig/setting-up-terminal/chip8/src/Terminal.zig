const std = @import("std");
const os = std.os;
const ECHO: u32 = 1 << 4;

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

// https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html
pub fn enableRawMode() !void {
    var raw = try os.tcgetattr(os.STDIN_FILENO);
    raw.lflag &= ~(ECHO);
    try os.tcsetattr(os.STDIN_FILENO, os.TCSA.FLUSH, raw);
}

pub fn clear() !void {
    try stdout.writeAll("\x1B[2J\x1B[H");
}
