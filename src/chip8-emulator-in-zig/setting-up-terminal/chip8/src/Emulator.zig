var ram: [4096]u8 = .{
    0xF0, 0x90, 0x90, 0x90, 0xF0, 0x20, 0x60, 0x20, 0x20, 0x70, 0xF0, 0x10, 0xF0, 0x80, 0xF0, 0xF0,
    0x10, 0xF0, 0x10, 0xF0, 0x90, 0x90, 0xF0, 0x10, 0x10, 0xF0, 0x80, 0xF0, 0x10, 0xF0, 0xF0, 0x80,
    0xF0, 0x90, 0xF0, 0xF0, 0x10, 0x20, 0x40, 0x40, 0xF0, 0x90, 0xF0, 0x90, 0xF0, 0xF0, 0x90, 0xF0,
    0x10, 0xF0, 0xF0, 0x90, 0xF0, 0x90, 0x90, 0xE0, 0x90, 0xE0, 0x90, 0xE0, 0xF0, 0x80, 0x80, 0x80,
    0xF0, 0xE0, 0x90, 0x90, 0x90, 0xE0, 0xF0, 0x80, 0xF0, 0x80, 0xF0, 0xF0, 0x80, 0xF0, 0x80, 0x80,
} ++ .{0} ** (4096 - 80);
var stack: [16]u16 = .{0} ** 16;
var v: [u8]16 = .{0} ** 16;
var i: u8 = 0;
var dt: u8 = 0;
var st: u8 = 0;
var pc: u16 = 0;
var sp: u16 = 0;

pub fn init(bytes: []const u8) void {
    // Load bytes into memory
    for (bytes) |byte, index|
        ram[index + 0x200] = byte;
}

pub fn cycle(_: [16]bool, screen: *[64 * 32]bool) void {
    const opcode = @as(u16, ram[pc] << 8) | ram[pc + 1];
    const x = (opcode & 0x0F00) >> 8;
    const y = (opcode & 0x00F0) >> 4;
    const nnn = (opcode & 0x0FFF);
    const kk = (opcode & 0x00FF);
    switch (opcode & 0xF000) {
        0x0000 => switch (opcode & 0x0FF) {
            // 00E0 - CLS: Clear the display.
            0x00E0 => {
                for (screen) |byte|
                    byte = 0;
                pc += 2;
            },
            // 00EE - RET: The interpreter sets the program counter to the address at
            // the top of the stack, then subtracts 1 from the stack pointer.
            0x00EE => {
                pc = stack[sp];
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
            v[x] +%= kk;
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
                const overflow = @addWithOverflow(u8, v[x], v[y], &v[x]);
                if (overflow) v[0xF] = 1 else v[0xF] = 0;
                pc += 2;
            },
            // 8xy5 - SUB Vx, Vy: If Vx > Vy, then VF is set to 1, otherwise
            // 0. Then Vy is subtracted from Vx, and the results stored in Vx.
            0x0005 => {
                const overflow = @subWithOverflow(u8, v[x], v[y], &v[x]);
                if (overflow) v[0xF] = 1 else v[0xF] = 0;
                pc += 2;
            },
            // 8xy6 - SHR Vx {, Vy}: If the least-significant bit of Vx is 1,
            // then VF is set to 1, otherwise 0. Then Vx is divided by 2.
            0x0006 => {
                v[0xF] = v[x] & 1;
                v[x] /= 2;
                pc += 2;
            },
            // 8xy7 - SUBN Vx, Vy: If Vy > Vx, then VF is set to 1, otherwise
            // 0. Then Vx is subtracted from Vy, and the results stored in Vx.
            0x0007 => {
                const overflow = @subWithOverflow(u8, v[y], v[x], &v[y]);
                if (overflow) v[0xF] = 1 else v[0xF] = 0;
                pc += 2;
            },
            // 8xyE - SHL Vx {, Vy}: If the most-significant bit of Vx is 1,
            // then VF is set to 1, otherwise to 0. Then Vx is multiplied by 2.
            0x000E => {
                if (v[x] & (0b1000000) > 0)
                    v[0xF] = 1
                else
                    v[0xF] = 0;
                v[x] *= 2;
                pc += 2;
            },
            else => @panic("Invalid opcode in 0x8000 branch"),
        },
        // Annn - LD I, addr: The value of register I is set to nnn.
        0xA000 => {
            i = opcode & 0x0FFF;
            pc += 2;
        },
    }
}
