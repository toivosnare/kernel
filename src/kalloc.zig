const std = @import("std");
const assert = std.debug.assert;
const page_size = std.mem.page_size;
const uart = @import("uart.zig");

const Page = [page_size]u8;
const PagePtr = *align(page_size)Page;
var heap: [1024]Page align(page_size) linksection(".bss") = undefined;
const Node = struct {
    next: ?*Node = null,
};
const NodePtr = *align(page_size)Node;
var freelist: ?NodePtr = null;

pub fn init() void {
    for (heap) |*page|
        free(@alignCast(page_size, page));
}

const Error = error{OutOfMemory};
pub fn alloc() Error!PagePtr {
    var node = freelist;
    if (node) |n| {
        freelist = @alignCast(page_size, n.next);
        return @ptrCast(PagePtr, n);
    } else {
        return Error.OutOfMemory;
    }
}

pub fn free(page: PagePtr) void {
    @memset(page, 0, page.len);
    var node = @ptrCast(NodePtr, page);
    node.next = freelist;
    freelist = node;
}
