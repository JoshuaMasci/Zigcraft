const c = @import("c.zig");

const std = @import("std");
const panic = std.debug.panic;

pub const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
};

pub const Mesh = struct {
    const Self = @This();

    vertex_buffer: c.GLuint,
    index_buffer: c.GLuint,

    //TODO: compiletime types for vertex and index(index may not need to be compiletime since it is u16 or u32)
    pub fn init(vertices: []const Vertex, indices: []const u32) Self {
        var buffers: [2]c.GLuint = undefined;
        c.glGenBuffers(buffers.len, &buffers);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, buffers[0]);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(c_longlong, @sizeOf(Vertex) * vertices.len), @ptrCast(*const c_void, vertices.ptr), c.GL_STATIC_DRAW);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, buffers[1]);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(c_longlong, @sizeOf(u32) * indices.len), @ptrCast(*const c_void, indices.ptr), c.GL_STATIC_DRAW);

        return Self {
            .vertex_buffer = buffers[0],
            .index_buffer = buffers[1],
        };
    }

    pub fn deinit(self: *Self) void {
        c.glDeleteBuffers(1, &self.vertex_buffer);
        c.glDeleteBuffers(1, &self.index_buffer);
    }
};