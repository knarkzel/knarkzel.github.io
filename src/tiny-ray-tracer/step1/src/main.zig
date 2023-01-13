const std = @import("std");

const Pixel = struct {
    red: u8,
    green: u8,
    blue: u8,
};

pub fn main() !void {
    const width = 640;
    const height = 480;
    const screen: [width * height]Pixel = .{.{ .red = 0, .green = 150, .blue = 250 }} ** (width * height);

    const file = try std.fs.cwd().createFile("output.ppm", .{});
    defer file.close();

    var buffer = std.io.bufferedWriter(file.writer());
    var writer = buffer.writer();

    const header = std.fmt.comptimePrint("P6\n{d} {d}\n255\n", .{ width, height });
    try writer.writeAll(header);
    for (screen) |pixel|
        try writer.writeAll(&.{ pixel.red, pixel.green, pixel.blue });
    try buffer.flush();
}
