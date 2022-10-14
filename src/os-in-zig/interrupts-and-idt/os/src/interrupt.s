// Idt
.type loadIdt, @function
.global loadIdt
    
loadIdt:
    mov +4(%esp), %eax // Fetch the IdtRegister
    lidt (%eax)        // Load the new Idt
    ret                // Return from function

// Exceptions
.macro isrGenerate n
    .type isr\n, @function
    .global isr\n

    isr\n:
        .if (\n != 8 && !(\n >= 10 && \n <= 14))
            push $0    // Push a dummy error code for interrupts that don't have one
        .endif
        push $\n       // Push the interrupt number
        jmp isrCommon  // Jump to the common handler
.endmacro

.extern isrHandler

.type isrCommon, @function

isrCommon:
    pusha            // Pushes edi, esi, ebp, esp, ebx, edx, ecx, eax

    mov %ds, %ax     // Lower 16-bits of eax = ds
    push %eax        // Save the data segment descriptor

    mov $0x10, %ax   // Load the kernel data segment descriptor
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs

    call isrHandler

    pop %eax         // Reload the original data segment descriptor
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs

    popa             // Pops edi, esi, ebp, esp, ebx, edx, ecx, eax
    add 0x8, %esp    // Cleans up the pushed error code and pushed ISR number
    sti
    iret             // Pops cs, eip, eflags, ss, and esp

isrGenerate 0
isrGenerate 1
isrGenerate 2
isrGenerate 3
isrGenerate 4
isrGenerate 5
isrGenerate 6
isrGenerate 7
isrGenerate 8
isrGenerate 9
isrGenerate 10
isrGenerate 11
isrGenerate 12
isrGenerate 13
isrGenerate 14
isrGenerate 15
isrGenerate 16
isrGenerate 17
isrGenerate 18
isrGenerate 19
isrGenerate 20
isrGenerate 21
isrGenerate 22
isrGenerate 23
isrGenerate 24
isrGenerate 25
isrGenerate 26
isrGenerate 27
isrGenerate 28
isrGenerate 29
isrGenerate 30
isrGenerate 31    
