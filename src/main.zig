const uart = @import("uart.zig");
const kalloc = @import("kalloc.zig");
const mm = @import("mm.zig");
const trap = @import("trap.zig");

var stack: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

export fn main() linksection(".text.main") callconv(.Naked) noreturn {
    @call(.{ .stack = stack[0..] }, mainM, .{});
    @panic("main exited\n");
}
const STATUS_MPP_S: usize = 1 << 11;
// const STATUS_MIE: usize = 3;
const MTI: usize = 1 << 7;

fn mainM() noreturn {
    // Who needs memory protection anyways?
    asm volatile (
        \\csrwi satp, 0
        \\csrwi pmpcfg0, 0xf
    );

    // Setup Machine mode timer interupt and trap delegation.
    asm volatile (
        \\csrw mtvec, %[vec]
        \\csrw mie, %[mask]
        \\csrw medeleg, %[deleg]
        \\csrw mideleg, %[deleg]
        ::
        [vec] "r" (@ptrToInt(trap.timerTrap)),
        [mask] "r" (MTI),
        [deleg] "r" (@as(usize, 0xff))
    );
    trap.timerSetup();

    // Jump to mainS in supervisor mode.
    asm volatile(
        \\csrw mstatus, %[status]
        \\csrw mepc, %[address]
        \\mret
        ::
        [status] "r" (STATUS_MPP_S),
        [address] "r" (@ptrToInt(mainS))
    );
    @panic("mainM exited\n");
}

fn mainS() noreturn {
    uart.init();
    uart.print("Hello world!\n", .{});
    kalloc.init();
    mm.init();
    trap.init();
    while (true) {}
}

pub fn panic(msg: []const u8, _: ?*(@import("std").builtin.StackTrace)) noreturn {
    uart.print("panic: {s}", .{msg});
    while (true) {}
}
