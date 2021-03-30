const std = @import("std");
const panic = std.debug.panic;

const glfw = @import("glfw_platform.zig");
const opengl = @import("opengl_renderer.zig");

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    panic("Error: {}\n", .{@as([*:0]const u8, description)});
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    glfw.init(errorCallback);
    defer glfw.deinit();

    var window = glfw.Window.init(1920, 1080, "ZigCraft V0.1");
    defer window.deinit();

    var vertices = [_]opengl.Vertex {
        opengl.Vertex {
            .position = [_]f32{0.0, 0.0, 0.0},
            .color = [_]f32{0.0, 0.0, 0.0},
        },
    };
    var indices = [_]u32{0, 0, 0, 0};

    var mesh = opengl.Mesh.init(&vertices, &indices);
    defer mesh.deinit();

    var frameCount: u32 = 0;
    var lastTime = glfw.getTime();
    while (window.shouldClose()) {
        glfw.update();
        window.refresh();

        frameCount += 1;
        var currentTime = glfw.getTime();
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

