const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

const MultiBoot = packed struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};

export var multiboot align(4) linksection(".multiboot") = MultiBoot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

export fn _start() callconv(.Naked) noreturn {
    init();
    @call(.{ .stack = &stack_bytes }, main, .{});
    while (true) asm volatile ("hlt");
}

const idt = @import("idt.zig");
const utils = @import("utils.zig");
const Console = @import("Console.zig");

export fn isrHandler(registers: utils.Registers) void {
    Console.write("\nunhandled interrupt occurred: ");
    Console.write(&.{@intCast(u8, registers.int_no) + '0'});
}

fn init() void {
    idt.init();
    Console.init();
}

fn main() void {
    Console.setColor(.green, .black);
    Console.write("kernel ");
    Console.setColor(.light_blue, .black);
    Console.write("> ");
    asm volatile ("int $0x4");
}
