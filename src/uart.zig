const std = @import("std");

extern var UART_START: u8;

const Registers = packed struct {
    thr: u8,
    ier: u8,
    fcr: u8,
    lcr: u8,
    mcr: u8,
    lsr: u8,
    msr: u8,
    scr: u8,
};
var reg: *Registers = undefined;

pub fn init() void {
    reg = @ptrCast(*Registers, &UART_START);
    reg.lcr = 0b11;
    reg.fcr = 0b1;
    reg.ier = 0b1;
}

pub fn putc(c: u8) void {
    const p: *volatile u8 = &reg.thr;
    p.* = c;
}

const WriteError = error {
    GenericWriteError,
};

pub fn write(_: void, bytes: []const u8) WriteError!usize {
    for (bytes) |c| {
        putc(c);
    }
    return bytes.len;
}

const writer: std.io.Writer(void, WriteError, write) = .{ .context = {} };
pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.fmt.format(writer, fmt, args) catch unreachable;
}
