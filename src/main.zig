const std = @import("std");
const panic = std.debug.panic;

const c = @import("c.zig");
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

    var vertex_code = [_]u8{};
    var fragment_code = [_]u8{};
    var shader = opengl.Shader.init(&vertex_code, &fragment_code);
    defer shader.deinit();


    var vertices = [_]opengl.Vertex {
        opengl.Vertex {
            .position = [_]f32{0.0, 0.0, 0.0},
            .color = [_]f32{0.0, 0.0, 0.0},
        },
    };
    var indices = [_]u32{0, 1, 2};

    var pos_verts = [_]f32{    
    -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0,  0.5, 0.0};

    var mesh = opengl.Mesh.init(f32, &pos_verts, &indices);
    //var mesh = opengl.Mesh.init(opengl.Vertex, &vertices, &indices);
    defer mesh.deinit();

    var frameCount: u32 = 0;
    var lastTime = glfw.getTime();
    while (window.shouldClose()) {
        glfw.update();

        c.glBindBuffer(c.GL_ARRAY_BUFFER, mesh.vertex_buffer);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);  
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

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

