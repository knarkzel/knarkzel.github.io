const std = @import("std");

const Pixel = struct {
    red: u8,
    green: u8,
    blue: u8,
};

const Sphere = struct {
    radius: f32,
    center: @Vector(3, f32),

    fn ray_intersect(self: Sphere, orig: @Vector(3, f32), dir: @Vector(3, f32)) ?f32 {
        const L = self.center - orig.*;
        const tca = L * dir.*;
        const d2 = L * L - tca * tca;
        if (d2 > self.radius * self.radius) return null;
        const thc = std.math.sqrt(self.radius * self.radius - d2);
        var t0 = tca - thc;
        var t1 = tca + thc;
        if (t0 < 0) t0 = t1;
        if (t0 < 0) return null;
        return t0;
    }
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
