const Terminal = @import("Terminal.zig");
const Emulator = @import("Emulator.zig");

pub fn main() !void {
    // Initialize emulator
    const rom = @embedFile("../roms/chip8-test-suite.ch8");
    Emulator.init(rom);

    // Initialize terminal
    try Terminal.init();
    try Terminal.hideCursor();
    try Terminal.clear();

    // Main loop
    while (true) {
        // Emulate current opcode
        Emulator.cycle();

        if (Emulator.update) {
            // Update terminal
            try Terminal.clear();
            for (Emulator.screen) |bit, i| {
                if (bit == 1) try Terminal.write("█") else try Terminal.write(" ");
                if ((i + 1) % 64 == 0) try Terminal.write("\n");
            }
            Emulator.update = false;
        }
    }
}
