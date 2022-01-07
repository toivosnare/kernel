const uart = @import("uart.zig");

const SSI: usize = 1 << 1;
const STI: usize = 1 << 5;
const SEI: usize = 1 << 9;

pub fn timerTrap() align(4) callconv(.Naked) void {
    uart.print("BING\n", .{});
    timerSetup();
    asm volatile (
        \\csrsi sip, %[mask]
        \\mret
        ::
        [mask] "I" (SSI)
    );
}

extern var CLINT_START: u8;
const INTERVAL: u64 = 10_000_000;

pub fn timerSetup() void {
    const clint_start = @ptrToInt(&CLINT_START);
    const clint_mtimecmp = @intToPtr(*u64, clint_start + 0x4000);
    const clint_mtime = @intToPtr(*u64, clint_start + 0xBFF8);
    clint_mtimecmp.* = clint_mtime.* + INTERVAL;
}

const STATUS_SIE: usize = 1 << 1;

pub fn init() void {
    // Setup supervisor mode traps.
    asm volatile (
        \\csrw stvec, %[vec]
        \\csrw sie, %[mask]
        \\csrsi sstatus, %[status]
        ::
        [vec] "r" (@ptrToInt(supervisorTrap)),
        [mask] "r" (SSI | STI | SEI),
        [status] "I" (STATUS_SIE)
    );
}

fn supervisorTrap() align(4) callconv(.Naked) void {
    uart.print("BONG\n", .{});
    asm volatile (
        \\csrci sip, %[mask]
        \\sret
        ::
        [mask] "I" (SSI)
    );
}
