const std = @import("std");
const Screen = @import("Screen.zig");

// Imports
const time = std.time;

pub fn main() !void {
    // Setup screen
    try Screen.init();

    // Game loop
    while (true) {
        // Get current time for maintaining smooth 10 fps
        const before_time = time.milliTimestamp();

        // Draw rectangle
        try Screen.draw(1, 1, 10, 5);
        try Screen.draw(5, 5, 10, 5);

        // Update screen with new content
        try Screen.flush();

        // Sleep for rest of time
        const after_time = time.milliTimestamp();
        const delta = after_time - before_time;
        time.sleep(time.ns_per_s / 10 - (@intCast(u64, delta) * 1000));
    }
}
