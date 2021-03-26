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

    //pub fn init(vertices: []const Vertex, indices: []const u32) Self {
    pub fn init() Self {
        var buffers: [2]c.GLuint = undefined;
        c.glGenBuffers(buffers.len, &buffers);

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