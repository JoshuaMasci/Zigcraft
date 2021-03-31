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

    pub fn init(comptime T: type, vertices: []const T, indices: []const u32) Self {
        var buffers: [2]c.GLuint = undefined;
        c.glGenBuffers(buffers.len, &buffers);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, buffers[0]);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(c_longlong, @sizeOf(T) * vertices.len), @ptrCast(*const c_void, vertices.ptr), c.GL_STATIC_DRAW);

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

pub const Shader = struct {
    const Self = @This();

    shader_program: c.GLuint,

    pub fn init(vertex_shader: []const u8, fragment_shader: []const u8) Self {
        var program = c.glCreateProgram();

        var vertex_module = Self.init_shader_module(vertex_shader, c.GL_VERTEX_SHADER);
        c.glAttachShader(program, vertex_module);

        c.glLinkProgram(program);

        c.glDeleteShader(vertex_module);

        return Self {
            .shader_program = program,
        };
    }

    pub fn deinit(self: *Self) void {
        c.glDeleteProgram(&self.shader_program);
    }

    fn init_shader_module(shader_code: []const u8, stage: c.GLuint) c.GLuint {
        var shader = c.glCreateShader(stage);

        var code_ptr: *const c.GLchar = @ptrCast(*const c.GLchar, shader_code.ptr);
        c.glShaderSource(shader, 1, &shader_code.ptr, &@intCast(c.GLint, shader_code.len));
        c.glCompileShader(shader);

        return shader;
    }

};