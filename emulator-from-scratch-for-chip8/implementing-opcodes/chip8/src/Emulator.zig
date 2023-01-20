// Emulator
var ram: [4096]u16 = .{0} ** 4096;
var stack: [16]u16 = .{0} ** 16;
var v: [16]u16 = .{0} ** 16;
var i: u16 = 0;
var dt: u16 = 0;
var st: u16 = 0;
var sp: u16 = 0;
var pc: u16 = 0x200;

// Screen
pub var update: bool = false;
pub var screen: [64 * 32]u1 = .{0} ** (64 * 32);

pub fn init(bytes: []const u8) void {
    // Load font into memory
    const font: [80]u8 = .{
        0xF0, 0x90, 0x90, 0x90, 0xF0, 0x20, 0x60, 0x20, 0x20, 0x70, 0xF0, 0x10, 0xF0, 0x80, 0xF0, 0xF0,
        0x10, 0xF0, 0x10, 0xF0, 0x90, 0x90, 0xF0, 0x10, 0x10, 0xF0, 0x80, 0xF0, 0x10, 0xF0, 0xF0, 0x80,
        0xF0, 0x90, 0xF0, 0xF0, 0x10, 0x20, 0x40, 0x40, 0xF0, 0x90, 0xF0, 0x90, 0xF0, 0xF0, 0x90, 0xF0,
        0x10, 0xF0, 0xF0, 0x90, 0xF0, 0x90, 0x90, 0xE0, 0x90, 0xE0, 0x90, 0xE0, 0xF0, 0x80, 0x80, 0x80,
        0xF0, 0xE0, 0x90, 0x90, 0x90, 0xE0, 0xF0, 0x80, 0xF0, 0x80, 0xF0, 0xF0, 0x80, 0xF0, 0x80, 0x80,
    };
    for (font) |byte, index|
        ram[index] = byte;

    // Load bytes into memory
    for (bytes) |byte, index|
        ram[index + 0x200] = byte;
}

pub fn cycle() void {
    // Fetch current opcode
    const opcode = (ram[pc] << 8) | ram[pc + 1];

    // Helpers for opcode
    const x = (opcode & 0x0F00) >> 8;
    const y = (opcode & 0x00F0) >> 4;
    const n = (opcode & 0x000F);
    const kk = (opcode & 0x00FF);
    const nnn = (opcode & 0x0FFF);

    // Emulate current opcode
    switch (opcode & 0xF000) {
        0x0000 => switch (kk) {
            // 00E0 - CLS: Clear the display.
            0x00E0 => {
                for (screen) |*byte|
                    byte.* = 0;
                pc += 2;
            },
            else => return,
        },
        // 6xkk - LD Vx, byte: The interpreter puts the value kk into
        // register Vx.
        0x6000 => {
            v[x] = kk;
            pc += 2;
        },
        // Annn - LD I, addr: The value of register I is set to nnn.
        0xA000 => {
            i = nnn;
            pc += 2;
        },
        // Dxyn - DRW Vx, Vy, nibble: The interpreter reads n bytes from
        // memory, starting at the address stored in I. These bytes are
        // then displayed as sprites on screen at coordinates (Vx,
        // Vy). Sprites are XORed onto the existing screen. If this causes
        // any pixels to be erased, VF is set to 1, otherwise it is set to
        // 0. If the sprite is positioned so part of it is outside the
        // coordinates of the display, it wraps around to the opposite side
        // of the screen.
        0xD000 => {
            v[0xF] = 0;
            var yline: u8 = 0;
            while (yline < n) : (yline += 1) {
                const pixel = ram[i + yline];
                var xline: u8 = 0;
                while (xline < 8) : (xline += 1) {
                    const px = v[x] + xline;
                    const py = v[y] + yline;
                    const color = &screen[px % 64 + (py % 32) * 64];
                    if ((pixel & (@as(u8, 0x80) >> @intCast(u3, xline))) != 0) {
                        if (color.* == 1)
                            v[0xF] = 1;
                        color.* ^= 1;
                    }
                }
            }
            update = true;
            pc += 2;
        },
        else => return,
    }
}
