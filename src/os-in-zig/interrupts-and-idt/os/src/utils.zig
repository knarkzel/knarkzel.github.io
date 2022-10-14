pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [port] "N{dx}" (port),
          [value] "{al}" (value),
    );
}

pub const Registers = extern struct {
    ds: u32, // Data segment selector
    edi: u32, // Pushed by pusha
    esi: u32,
    ebp: u32,
    esp: u32,
    ebx: u32,
    edx: u32,
    ecx: u32,
    eax: u32,
    int_no: u32, // Interrupt number and error code (if applicable)
    err_no: u32,
    eip: u32, // Pushed by the processor automatically
    cs: u32,
    eflags: u32,
    useresp: u32,
    ss: u32,
};
