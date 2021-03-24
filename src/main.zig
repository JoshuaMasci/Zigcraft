const std = @import("std");
const panic = std.debug.panic;

const glfw = @import("platform/glfw.zig");
const platform = @import("platform/window.zig");

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    panic("Error: {}\n", .{@as([*:0]const u8, description)});
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    glfw.init(errorCallback);
    defer glfw.deinit();

    var window = platform.Window.init(1920, 1080, "ZigCraft");
    defer window.deinit();

    var frameCount: u32 = 0;
    var lastTime = glfw.glfwGetTime();
    while (window.shouldClose()) {
        window.refresh();

        frameCount += 1;
        var currentTime = glfw.glfwGetTime();
        if ((currentTime - 1.0) > lastTime) {
            try stdout.print("FPS: {}\n", .{frameCount});
            frameCount = 0;
            lastTime = currentTime;
        }
    }

    //Alloc testing
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) panic("Error: memory leaked", .{});
    }
    const bytes = try gpa.allocator.alloc(u8, 100);
    gpa.allocator.free(bytes);

    try stdout.print("Hello, {s}!\n", .{"world"});
}

