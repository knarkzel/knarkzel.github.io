const std = @import("std");
const Terminal = @import("Terminal.zig");

pub fn main() !void {
    try Terminal.enableRawMode();
    try Terminal.clear();
    while (true) {}
}
