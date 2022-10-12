const std = @import("std");
const os = std.os;

// Flags
const ISIG: u32 = 1 << 0;
const ICANON: u32 = 1 << 1;
const ECHO: u32 = 1 << 3;

// State
var termios: ?os.termios = null;
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

fn enableRawMode() !void {
    termios = try os.tcgetattr(os.STDIN_FILENO);
    var raw = termios.?;
    raw.lflag &= ~(ECHO | ICANON | ISIG);
    try os.tcsetattr(os.STDIN_FILENO, os.TCSA.FLUSH, raw);
}

fn disableRawMode() !void {
    if (termios) |raw|
        try os.tcsetattr(os.STDIN_FILENO, os.TCSA.FLUSH, raw);
}

fn hideCursor() !void {
    try stdout.writeAll("\x1b[?25l");
}

fn showCursor() !void {
    try stdout.writeAll("\x1b[?25h");
}

pub fn clear() !void {
    try stdout.writeAll("\x1B[2J\x1B[H");
}

pub fn init() !void {
    try enableRawMode();
    try hideCursor();
}

pub fn deinit() !void {
    try disableRawMode();
    try showCursor();
}

pub fn read() !u8 {
    return stdin.readByte();
}

pub fn write(bytes: []const u8) !void {
    try stdout.writeAll(bytes);
}
