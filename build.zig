const std = @import("std");

const QEMU_BIN = "qemu-system-riscv32";
const QEMU_OPTS = [_][]const u8 {QEMU_BIN, "-machine", "virt", "-bios", "none", "-serial", "mon:stdio", "-nographic", "-kernel", "zig-out/bin/kernel"};
const QEMU_DEBUG_OPTS = [_][]const u8 {"-S", "-s"};

pub fn build(b: *std.build.Builder) void {
    const kernel = b.addExecutable("kernel", "src/main.zig");
    kernel.setBuildMode(b.standardReleaseOptions());
    kernel.setTarget(.{
        .cpu_arch = std.Target.Cpu.Arch.riscv32,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.baseline_rv32 },
        .os_tag = std.Target.Os.Tag.freestanding,
    });
    kernel.setLinkerScriptPath(.{.path = "src/kernel.ld"});
    kernel.code_model = .medium;
    kernel.install();

    const run_cmd = b.addSystemCommand(&QEMU_OPTS);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run with QEMU");
    run_step.dependOn(&run_cmd.step);

    const debug_cmd = b.addSystemCommand(&(QEMU_OPTS ++ QEMU_DEBUG_OPTS));
    debug_cmd.step.dependOn(b.getInstallStep());
    const debug_step = b.step("debug", "Run with QEMU waiting for gdb remote connection");
    debug_step.dependOn(&debug_cmd.step);
}
