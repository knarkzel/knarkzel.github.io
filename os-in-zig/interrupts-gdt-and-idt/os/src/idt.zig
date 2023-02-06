const std = @import("std");

// Extern directive ASM ISR handlers
extern fn isr0() void;
extern fn isr1() void;
extern fn isr2() void;
extern fn isr3() void;
extern fn isr4() void;
extern fn isr5() void;
extern fn isr6() void;
extern fn isr7() void;
extern fn isr8() void;
extern fn isr9() void;
extern fn isr10() void;
extern fn isr11() void;
extern fn isr12() void;
extern fn isr13() void;
extern fn isr14() void;
extern fn isr15() void;
extern fn isr16() void;
extern fn isr17() void;
extern fn isr18() void;
extern fn isr19() void;
extern fn isr20() void;
extern fn isr21() void;
extern fn isr22() void;
extern fn isr23() void;
extern fn isr24() void;
extern fn isr25() void;
extern fn isr26() void;
extern fn isr27() void;
extern fn isr28() void;
extern fn isr29() void;
extern fn isr30() void;
extern fn isr31() void;

const IdtEntry = packed struct {
    offset_low: u16,
    segment_selector: u16,
    zero: u8,
    flags: u8,
    offset_high: u16,

    fn init(handler: fn () callconv(.C) void, segment_selector: u16, flags: u8) IdtEntry {
        const offset = @ptrToInt(handler);
        return .{
            .offset_low = @truncate(u16, offset & 0xFFFF),
            .offset_high = @truncate(u16, (offset >> 16) & 0xFFFF),
            .segment_selector = segment_selector,
            .zero = 0,
            .flags = flags,
        };
    }
};

const IdtRegister = packed struct {
    limit: u16,
    base: *[256]IdtEntry,

    fn init(table: *[256]IdtEntry) IdtRegister {
        return .{
            .limit = @as(u16, @sizeOf(@TypeOf(table.*))) - 1,
            .base = table,
        };
    }
};

extern fn loadIdt(register: *const IdtRegister) void;

var idt_table: [256]IdtEntry = undefined;
var idt_register: IdtRegister = undefined;

pub fn init() void {
    // Load default exceptions into idt
    idt_table[0] = IdtEntry.init(isr0, 0x08, 0x8E);
    idt_table[1] = IdtEntry.init(isr1, 0x08, 0x8E);
    idt_table[2] = IdtEntry.init(isr2, 0x08, 0x8E);
    idt_table[3] = IdtEntry.init(isr3, 0x08, 0x8E);
    idt_table[4] = IdtEntry.init(isr4, 0x08, 0x8E);
    idt_table[5] = IdtEntry.init(isr5, 0x08, 0x8E);
    idt_table[6] = IdtEntry.init(isr6, 0x08, 0x8E);
    idt_table[7] = IdtEntry.init(isr7, 0x08, 0x8E);
    idt_table[8] = IdtEntry.init(isr8, 0x08, 0x8E);
    idt_table[9] = IdtEntry.init(isr9, 0x08, 0x8E);
    idt_table[10] = IdtEntry.init(isr10, 0x08, 0x8E);
    idt_table[11] = IdtEntry.init(isr11, 0x08, 0x8E);
    idt_table[12] = IdtEntry.init(isr12, 0x08, 0x8E);
    idt_table[13] = IdtEntry.init(isr13, 0x08, 0x8E);
    idt_table[14] = IdtEntry.init(isr14, 0x08, 0x8E);
    idt_table[15] = IdtEntry.init(isr15, 0x08, 0x8E);
    idt_table[16] = IdtEntry.init(isr16, 0x08, 0x8E);
    idt_table[17] = IdtEntry.init(isr17, 0x08, 0x8E);
    idt_table[18] = IdtEntry.init(isr18, 0x08, 0x8E);
    idt_table[19] = IdtEntry.init(isr19, 0x08, 0x8E);
    idt_table[20] = IdtEntry.init(isr20, 0x08, 0x8E);
    idt_table[21] = IdtEntry.init(isr21, 0x08, 0x8E);
    idt_table[22] = IdtEntry.init(isr22, 0x08, 0x8E);
    idt_table[23] = IdtEntry.init(isr23, 0x08, 0x8E);
    idt_table[24] = IdtEntry.init(isr24, 0x08, 0x8E);
    idt_table[25] = IdtEntry.init(isr25, 0x08, 0x8E);
    idt_table[26] = IdtEntry.init(isr26, 0x08, 0x8E);
    idt_table[27] = IdtEntry.init(isr27, 0x08, 0x8E);
    idt_table[28] = IdtEntry.init(isr28, 0x08, 0x8E);
    idt_table[29] = IdtEntry.init(isr29, 0x08, 0x8E);
    idt_table[30] = IdtEntry.init(isr30, 0x08, 0x8E);
    idt_table[31] = IdtEntry.init(isr31, 0x08, 0x8E);

    // Load idt
    idt_register = IdtRegister.init(&idt_table);
    loadIdt(&idt_register);
}
