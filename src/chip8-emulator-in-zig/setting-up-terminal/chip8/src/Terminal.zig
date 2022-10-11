const std = @import("std");
const os = std.os;

// Flags
const ICANON: u32 = 1 << 1;
const ECHO: u32 = 1 << 4;

// State
var termios: ?os.termios = null;
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

fn enableRawMode() !void {
    termios = try os.tcgetattr(os.STDIN_FILENO);
    var raw = termios.?;
    raw.lflag &= ~(ECHO | ICANON);
    try os.tcsetattr(os.STDIN_FILENO, os.TCSA.FLUSH, raw);
}

fn disableRawMode() !void {
    if (termios) |raw|
        try os.tcsetattr(os.STDIN_FILENO, os.TCSA.FLUSH, raw);
}

pub fn clear() !void {
    try stdout.writeAll("\x1B[2J\x1B[H");
}

pub fn init() !void {
    try enableRawMode();
    try clear();
}

pub fn deinit() !void {
    try disableRawMode();
    try clear();
}

pub fn read() !u8 {
    return try stdin.readByte();
}

pub fn write(byte: u8) !void {
    try stdout.writeByte(byte);
}
