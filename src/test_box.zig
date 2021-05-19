const std = @import("std");

usingnamespace @import("zalgebra");
usingnamespace @import("collision/aabb.zig");

const c = @import("c.zig");
const opengl = @import("opengl_renderer.zig");

const vertex = @import("vertex.zig");

fn genBoxMesh(half_size: vec3) opengl.Mesh {
    var vertices = [_]vertex.TexturedVertex {
        vertex.TexturedVertex.new(half_size.mul(vec3.new( 1,  1,  1)), vec2.zero()),
        vertex.TexturedVertex.new(half_size.mul(vec3.new( 1,  1, -1)), vec2.zero()),
        vertex.TexturedVertex.new(half_size.mul(vec3.new( 1, -1,  1)), vec2.zero()),
        vertex.TexturedVertex.new(half_size.mul(vec3.new( 1, -1, -1)), vec2.zero()),
        vertex.TexturedVertex.new(half_size.mul(vec3.new(-1,  1,  1)), vec2.zero()),
        vertex.TexturedVertex.new(half_size.mul(vec3.new(-1,  1, -1)), vec2.zero()),
        vertex.TexturedVertex.new(half_size.mul(vec3.new(-1, -1,  1)), vec2.zero()),
        vertex.TexturedVertex.new(half_size.mul(vec3.new(-1, -1, -1)), vec2.zero())
    };

    var indices = [_]u32 {
        0, 2, 3, 0, 3, 1,
        5, 7, 6, 5, 6, 4,
        0, 1, 5, 0, 5, 4,
        6, 7, 3, 6, 3, 2,
        4, 6, 2, 4, 2, 0,
        1, 3, 7, 1, 7, 5,
    };

    return opengl.Mesh.init(vertex.TexturedVertex, u32, &vertices, &indices);
}

pub const TestBox = struct {
    const Self = @This();

    aabb: Aabb,
    color: vec3,
    mesh: opengl.Mesh,

    pub fn init(pos: vec3, size: vec3, color: vec3) Self {
        var half_size = size.scale(1);
        return Self {
            .aabb = Aabb.init(pos, half_size),
            .color = color,
            .mesh = genBoxMesh(half_size),
        };
    }

    pub fn deinit(self: *Self) void {
        self.mesh.deinit();
    }

    pub fn render(self: *Self, matrix_uniform_index: c.GLint, color_uniform_index: c.GLint) void {
        c.glUniformMatrix4fv(matrix_uniform_index, 1, c.GL_FALSE, mat4.from_translate(self.aabb.position).get_data());
        c.glUniform3f(color_uniform_index, @floatCast(c.GLfloat, self.color.x), @floatCast(c.GLfloat, self.color.y), @floatCast(c.GLfloat, self.color.z));
        self.mesh.draw();
    }

    pub fn update(self: *Self, ground: *Self) void {
        if (self.aabb.testAabb(&ground.aabb)) {
            var offset = self.aabb.calcPenetration(&ground.aabb);
            //std.log.info("Offset: ({d}, {d}, {d})", .{offset.x, offset.y, offset.z});
            //Correct the collision kinda
            self.aabb.position = self.aabb.position.add(offset);

            self.color = vec3.new(0.0, 0.0, 1.0);
        }
        else {
            self.color = vec3.new(1.0, 0.0, 0.0);
        }
    }
};

