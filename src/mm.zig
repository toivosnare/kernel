const std = @import("std");
const assert = std.debug.assert;
const kalloc = @import("kalloc.zig");
const uart = @import("uart.zig");

const VirtualAddress = usize;
const PhysicalAddress = usize;

// Maybe use packed struct here when those are usable.
const PageTableEntry = usize;
const PTE_V: usize = 1 << 0;
const PTE_R: usize = 1 << 1;
const PTE_W: usize = 1 << 2;
const PTE_X: usize = 1 << 3;
const PTE_U: usize = 1 << 4;
const PTE_G: usize = 1 << 5;
const PTE_A: usize = 1 << 6;
const PTE_D: usize = 1 << 7;

const PageTable = *align(std.mem.page_size) [std.mem.page_size / @sizeOf(PageTableEntry)]PageTableEntry;

extern var UART_START: u8;
extern var RAM_START: u8;
extern var RAM_END: u8;

pub fn init() void {
    // Create identity mapping.
    const kernel_page_table: PageTable = allocatePageTable();

    const uart_start: PhysicalAddress = @ptrToInt(&UART_START);
    map(kernel_page_table, uart_start, uart_start, std.mem.page_size, PTE_R | PTE_W);

    const ram_start: PhysicalAddress = @ptrToInt(&RAM_START);
    const ram_end: PhysicalAddress = @ptrToInt(&RAM_END);
    map(kernel_page_table, ram_start, ram_start, ram_end - ram_start, PTE_R | PTE_W | PTE_X);

    // Turn paging on.
    var satp: usize = (1 << 31) | (@ptrToInt(kernel_page_table) >> 12);
    asm volatile (
        \\csrw satp, %[in]
        \\sfence.vma zero, zero
        ::
        [in] "r" (satp)
    );
}

fn allocatePageTable() PageTable {
    const page = kalloc.alloc() catch @panic("Page Table allocation failed");
    return @ptrCast(PageTable, page);
} 

fn map(level_1: PageTable, virtual: VirtualAddress, physical: PhysicalAddress, length: usize, permissions: usize) void {
    var current_virtual = std.mem.alignBackward(virtual, std.mem.page_size);
    const last_virtual = std.mem.alignForward(virtual + length, std.mem.page_size);
    var current_physical = physical;

    while (current_virtual < last_virtual) {
        var pte: *PageTableEntry = &level_1[current_virtual >> 22];
        var level_0: PageTable = undefined;
        if (pte.* & PTE_V == PTE_V) {
            level_0 = @intToPtr(PageTable, (pte.* >> 10) << 12);
        } else {
            level_0 = allocatePageTable();
            pte.* = ((@ptrToInt(level_0) >> 12) << 10) | PTE_V;
        }
        pte = &level_0[(current_virtual >> 12) & 0x3FF];
        pte.* = ((current_physical >> 12) << 10) | permissions | PTE_V;

        current_virtual += std.mem.page_size;
        current_physical += std.mem.page_size;
    }
}
