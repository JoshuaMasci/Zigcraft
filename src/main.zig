const std = @import("std");
const panic = std.debug.panic;

const c = @import("c.zig");
const glfw = @import("glfw_platform.zig");
const opengl = @import("opengl_renderer.zig");

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    panic("Error: {}\n", .{@as([*:0]const u8, description)});
}

pub const Vertex = struct {
    const Self = @This();

    position: [3]f32,
    color: [3]f32,

    fn new( position: [3]f32, color: [3]f32)Self {
        return Self {
            .position = position,
            .color = color,
        };
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    glfw.init(errorCallback);
    defer glfw.deinit();

    var window = glfw.Window.init(1920, 1080, "ZigCraft V0.1");
    defer window.deinit();

    var vertex_code = @embedFile("vert.glsl");
    var fragment_code =  @embedFile("frag.glsl");
    var shader = opengl.Shader.init(vertex_code, fragment_code);
    defer shader.deinit();

    var vertices = [_]Vertex {
        Vertex.new([_]f32{-1.0, -1.0, 0.0}, [_]f32{1.0, 0.0, 0.0}),
        Vertex.new([_]f32{1.0, -1.0, 0.0},  [_]f32{0.0, 1.0, 0.0}),
        Vertex.new([_]f32{0.0, 1.0, 0.0},   [_]f32{0.0, 0.0, 1.0}),
    };
    var indices = [_]u32{0, 1, 2};

    var mesh = opengl.Mesh.init(Vertex, &vertices, &indices);
    defer mesh.deinit();

    var frameCount: u32 = 0;
    var lastTime = glfw.getTime();
    while (window.shouldClose()) {
        glfw.update();

        c.glUseProgram(shader.shader_program);

        c.glBindVertexArray(mesh.vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, mesh.vertex_buffer);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, mesh.index_buffer);

        c.glEnableVertexAttribArray(0);
        c.glEnableVertexAttribArray(1);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), null);
        c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @intToPtr(*const c_void, @byteOffsetOf(Vertex, "color")));

        c.glDrawElements(c.GL_TRIANGLES, 3, c.GL_UNSIGNED_INT, null);

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

