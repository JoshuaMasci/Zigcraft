usingnamespace @import("zalgebra");
const c = @import("c.zig");

pub const ColoredVertex = struct {
    const Self = @This();

    position: vec3,
    color: vec3,

    pub fn new(position: vec3, color: vec3) Self {
        return Self{
            .position = position,
            .color = color,
        };
    }

    pub fn genVao() void {
        c.glEnableVertexAttribArray(0);
        c.glEnableVertexAttribArray(1);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Self), null); // Position is at zero
        c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Self), @intToPtr(*const c_void, @byteOffsetOf(Self, "color")));
    }
};

pub const TexturedVertex = struct {
    const Self = @This();

    position: vec3,
    uv: vec2,

    pub fn new(position: vec3, uv: vec2) Self {
        return Self{
            .position = position,
            .uv = uv,
        };
    }

    pub fn genVao() void {
        c.glEnableVertexAttribArray(0);
        c.glEnableVertexAttribArray(1);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Self), null); // Position is at zero
        c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Self), @intToPtr(*const c_void, @byteOffsetOf(Self, "uv")));
    }
};