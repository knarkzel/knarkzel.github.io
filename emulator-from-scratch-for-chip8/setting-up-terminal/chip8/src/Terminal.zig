const std = @import("std");
const os = std.os;

const ICANON: u32 = 1 << 1;
const ECHO: u32 = 1 << 3;

const stdout = std.io.getStdOut().writer();

pub fn init() !void {
    var termios = try os.tcgetattr(os.STDIN_FILENO);
    termios.lflag &= ~(ECHO | ICANON);
    try os.tcsetattr(os.STDIN_FILENO, os.TCSA.FLUSH, termios);
}

pub fn write(bytes: []const u8) !void {
    try stdout.writeAll(bytes);
}

pub fn clear() !void {
    try write("\x1B[2J\x1B[H");
}

pub fn hideCursor() !void {
    try write("\x1b[?25l");
}
