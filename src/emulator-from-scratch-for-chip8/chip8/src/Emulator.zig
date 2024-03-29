const std = @import("std");

var ram: [4096]u16 = .{0} ** 4096;
var stack: [16]u16 = .{0} ** 16;
var v: [16]u16 = .{0} ** 16;
var i: u16 = 0;
var dt: u16 = 0;
var st: u16 = 0;
var pc: u16 = 0x200;
var sp: u16 = 0;
pub var update: bool = false;

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

    ram[0x1FF] = 2;

    // Load bytes into memory
    for (bytes) |byte, index|
        ram[index + 0x200] = byte;
}

pub fn cycle(keys: *[16]u1, screen: *[64 * 32]u1) void {
    // Decrement timers
    if (dt > 0) dt -= 1;
    if (st > 0) st -= 1;

    const opcode = (ram[pc] << 8) | ram[pc + 1];
    const x = (opcode & 0x0F00) >> 8;
    const y = (opcode & 0x00F0) >> 4;
    const n = (opcode & 0x000F);
    const nnn = (opcode & 0x0FFF);
    const kk = (opcode & 0x00FF);
    switch (opcode & 0xF000) {
        0x0000 => switch (opcode & 0x0FF) {
            // 00E0 - CLS: Clear the display.
            0x00E0 => {
                for (screen) |*byte|
                    byte.* = 0;
                update = true;
                pc += 2;
            },
            // 00EE - RET: The interpreter sets the program counter to the address at
            // the top of the stack, then subtracts 1 from the stack pointer.
            0x00EE => {
                pc = stack[sp] + 2;
                sp -= 1;
            },
            else => @panic("Invalid opcode in 0x0000 branch"),
        },
        // 1nnn - JP addr: The interpreter sets the program counter to nnn.
        0x1000 => pc = nnn,
        // 2nnn - CALL addr: The interpreter increments the stack pointer, then
        // puts the current PC on the top of the stack. The PC is then set
        // to nnn.
        0x2000 => {
            sp += 1;
            stack[sp] = pc;
            pc = nnn;
        },
        // 3xkk - SE Vx, byte: The interpreter compares register Vx to kk,
        // and if they are equal, increments the program counter by 2.
        0x3000 => {
            if (v[x] == kk)
                pc += 4
            else
                pc += 2;
        },
        // 4xkk - SNE Vx, byte: The interpreter compares register Vx to kk,
        // and if they are not equal, increments the program counter by 2.
        0x4000 => {
            if (v[x] != kk)
                pc += 4
            else
                pc += 2;
        },
        // 5xy0 - SE Vx, Vy: The interpreter compares register Vx to register
        // Vy, and if they are equal, increments the program counter by 2.
        0x5000 => {
            if (v[x] == v[y])
                pc += 4
            else
                pc += 2;
        },
        // 6xkk - LD Vx, byte: The interpreter puts the value kk into
        // register Vx.
        0x6000 => {
            v[x] = kk;
            pc += 2;
        },
        // 7xkk - ADD Vx, byte: Adds the value kk to the value of register
        // Vx, then stores the result in Vx.
        0x7000 => {
            v[x] = (v[x] + kk) % 256;
            pc += 2;
        },
        0x8000 => switch (opcode & 0x000F) {
            // 8xy0 - LD Vx, Vy: Stores the value of register Vy in register Vx.
            0x0000 => {
                v[x] = v[y];
                pc += 2;
            },
            // 8xy1 - OR Vx, Vy: Performs a bitwise OR on the values of Vx and
            // Vy, then stores the result in Vx.
            0x0001 => {
                v[x] |= v[y];
                pc += 2;
            },
            // 8xy2 - AND Vx, Vy: Performs a bitwise AND on the values of Vx and
            // Vy, then stores the result in Vx.
            0x0002 => {
                v[x] &= v[y];
                pc += 2;
            },
            // 8xy3 - XOR Vx, Vy: Performs a bitwise exclusive OR on the values
            // of Vx and Vy, then stores the result in Vx.
            0x0003 => {
                v[x] ^= v[y];
                pc += 2;
            },
            // 8xy4 - ADD Vx, Vy: The values of Vx and Vy are added together. If
            // the result is greater than 8 bits (i.e., > 255,) VF is set to 1,
            // otherwise 0.
            0x0004 => {
                if (v[x] + v[y] > 255) v[0xF] = 1 else v[0xF] = 0;
                v[x] = (v[x] + v[y]) % 256;
                pc += 2;
            },
            // 8xy5 - SUB Vx, Vy: If Vx > Vy, then VF is set to 1, otherwise
            // 0. Then Vy is subtracted from Vx, and the results stored in Vx.
            0x0005 => {
                if (v[x] > v[y]) {
                    v[0xF] = 1;
                    v[x] -= v[y];
                } else {
                    v[0xF] = 0;
                    v[x] = 256 - (v[y] - v[x]);
                }
                pc += 2;
            },
            // 8xy6 - SHR Vx {, Vy}: If the least-significant bit of Vx is 1,
            // then VF is set to 1, otherwise 0. Then Vx is divided by 2.
            0x0006 => {
                v[x] = v[y] >> 1;
                v[0xF] = v[y] & 1;
                pc += 2;
            },
            // 8xy7 - SUBN Vx, Vy: If Vy > Vx, then VF is set to 1, otherwise
            // 0. Then Vx is subtracted from Vy, and the results stored in Vx.
            0x0007 => {
                if (v[y] > v[x]) v[0xF] = 1 else v[0xF] = 0;
                v[x] = v[y] - v[x];
                pc += 2;
            },
            // 8xyE - SHL Vx {, Vy}: If the most-significant bit of Vx is 1,
            // then VF is set to 1, otherwise to 0. Then Vx is multiplied by 2.
            0x000E => {
                v[x] = v[y] << 1;
                v[0xF] = v[y] & 0b1000000;
                pc += 2;
            },
            else => @panic("Invalid opcode in 0x8000 branch"),
        },
        // 9xy0 - SNE Vx, Vy: The values of Vx and Vy are compared, and if
        // they are not equal, the program counter is increased by 2.
        0x9000 => {
            if (v[x] != v[y])
                pc += 4
            else
                pc += 2;
        },
        // Annn - LD I, addr: The value of register I is set to nnn.
        0xA000 => {
            i = nnn;
            pc += 2;
        },
        // Bnnn - JP V0, addr: The program counter is set to nnn plus the
        // value of V0.
        0xB000 => pc = nnn + v[0],
        // Cxkk - RND Vx, byte: The interpreter generates a random number
        // from 0 to 255, which is then ANDed with the value kk. The results
        // are stored in Vx.
        0xC000 => {
            const rnd = std.crypto.random.int(u8);
            v[x] = rnd & kk;
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
        0xE000 => switch (opcode & 0x00F0) {
            // Ex9E - SKP Vx: Checks the keyboard, and if the key corresponding
            // to the value of Vx is currently in the down position, PC is
            // increased by 2.
            0x0090 => {
                if (keys[v[x]] > 0) {
                    pc += 4;
                    keys[v[x]] = 0;
                } else pc += 2;
            },
            // ExA1 - SKNP Vx: Checks the keyboard, and if the key corresponding
            // to the value of Vx is currently in the up position, PC is
            // increased by 2.
            0x00A0 => {
                if (keys[v[x]] == 0)
                    pc += 4
                else {
                    keys[v[x]] = 0;
                    pc += 2;
                }
            },
            else => @panic("Invalid opcode in 0xE000 branch"),
        },
        0xF000 => switch (opcode & 0x00FF) {
            // Fx07 - Ld Vx, DT: The value of DT is placed into Vx.
            0x0007 => {
                v[x] = dt;
                pc += 2;
            },
            // Fx0A - LD Vx, K: All execution stops until a key is pressed, then
            // the value of that key is stored in Vx.
            0x000A => {
                for (keys) |key, index| {
                    if (key > 0) {
                        v[x] = @truncate(u16, index);
                        pc += 2;
                        break;
                    }
                }
                keys[v[x]] = 0;
            },
            // Fx15 - LD DT, Vx: DT is set equal to the value of Vx.
            0x0015 => {
                dt = v[x];
                pc += 2;
            },
            // Fx18 - LD ST, Vx: ST is set equal to the value of Vx.
            0x0018 => {
                st = v[x];
                pc += 2;
            },
            // Fx1E - ADD I, Vx: The values of I and Vx are added, and the
            // results are stored in I.
            0x001E => {
                i += v[x];
                pc += 2;
            },
            // Fx29 - LD F, Vx: The value of I is set to the location for the
            // hexadecimal sprite corresponding to the value of Vx.
            0x0029 => {
                i = v[x] * 5;
                pc += 2;
            },
            // Fx33 - LD B, Vx: The interpreter takes the decimal value of Vx,
            // and places the hundreds digit in memory at location in I, the
            // tens digit at location I+1, and the ones digit at location I+2.
            0x0033 => {
                ram[i] = v[x] / 100;
                ram[i + 1] = (v[x] / 10) % 10;
                ram[i + 2] = (v[x] % 100) % 10;
                pc += 2;
            },
            // Fx55 - LD [I], Vx: The interpreter copies the values of registers
            // V0 through Vx into memory, starting at the address in I. I is set
            // to I + X + 1 after operation.
            0x0055 => {
                var index: u8 = 0;
                while (index <= x) : (index += 1)
                    ram[i + index] = v[index];
                // i += x + 1;
                pc += 2;
            },
            // Fx65 - LD Vx, [I]: The interpreter reads values from memory
            // starting at location I into registers V0 through Vx. I is set to
            // I + X + 1 after operation.
            0x0065 => {
                var index: u8 = 0;
                while (index <= x) : (index += 1)
                    v[index] = ram[i + index];
                // i += x + 1;
                pc += 2;
            },
            else => @panic("Invalid opcode in 0xF000 branch"),
        },
        else => @panic("Invalid opcode in main branch"),
    }
}
