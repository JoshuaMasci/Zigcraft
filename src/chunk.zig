usingnamespace @import("zalgebra");

pub const BlockId = u16;
pub const ChunkData32 = ChunkData(32, 32, 32);

const CubeFace = enum {
    x_pos,
    x_neg,
    y_pos,
    y_neg,
    z_pos,
    z_neg,
};

pub fn ChunkData(comptime X: u16, comptime Y: u16, comptime Z: u16) type {
    return struct {
        const Self = @This();
        pub const size_x: u16 = X;
        pub const size_y: u16 = Y;
        pub const size_z: u16 = Z;

        data: [size_x][size_y][size_z]BlockId,
        dirty: bool,

        pub fn init() Self {
            var data: [size_x][size_y][size_z]BlockId = undefined;

            var x: u16 = 0;
            while (x < Self.size_x) : (x += 1) {
                var y: u16 = 0;
                while (y < Self.size_y) : (y += 1) {
                    var z: u16 = 0;
                    while (z < Self.size_x) : (z += 1) {
                        data[x][y][z] = 0;
                    }
                }
            }

            return .{ .data = data, .dirty = true };
        }

        pub fn getBlock(self: *Self, x: u16, y: u16, z: u16) BlockId {
            return self.data[x][y][z];
        }

        pub fn setBlock(self: *Self, x: u16, y: u16, z: u16, id: BlockId) void {
            self.data[x][y][z] = id;
            self.dirty = true;
        }

        pub fn isDirty(self: *Self) bool {
            return self.dirty;
        }
    };
}


const std = @import("std");
const vertex = @import("vertex.zig");
const opengl = @import("opengl_renderer.zig");
pub fn CreateChunkMesh(comptime Chunk: type, allocator: *std.mem.Allocator, chunk: *Chunk) opengl.Mesh {
    var vertices = std.ArrayList(vertex.ColoredVertex).init(allocator);
    defer vertices.deinit();

    var indices = std.ArrayList(u32).init(allocator);
    defer indices.deinit();
    
    var x: u16 = 0;
    while (x < Chunk.size_x) : (x += 1) {
        var y: u16 = 0;
        while (y < Chunk.size_y) : (y += 1) {
            var z: u16 = 0;
            while (z < Chunk.size_x) : (z += 1) {
                var blockId = chunk.getBlock(x, y, z);
                var posVec = vec3.new(
                    @intToFloat(f32, x),
                    @intToFloat(f32, y),
                    @intToFloat(f32, z),
                    );
                var color = vec3.right();

                if (blockId != 0) {
                    appendCubeFace(CubeFace.x_pos, &vertices, &indices, posVec, color);
                    appendCubeFace(CubeFace.x_neg, &vertices, &indices, posVec, color);
                    appendCubeFace(CubeFace.y_pos, &vertices, &indices, posVec, color);
                    appendCubeFace(CubeFace.y_neg, &vertices, &indices, posVec, color);
                    appendCubeFace(CubeFace.z_pos, &vertices, &indices, posVec, color);
                    appendCubeFace(CubeFace.z_neg, &vertices, &indices, posVec, color);
                }
            }
        }
    }

    return opengl.Mesh.init(vertex.ColoredVertex, u32, vertices.items, indices.items);
}

fn appendCubeFace(face: CubeFace, vertices: *std.ArrayList(vertex.ColoredVertex), indices: *std.ArrayList(u32), position: vec3, color: vec3) void {
    const cube_positions = [_]vec3{
        vec3.new(0.5,  0.5,  0.5),
        vec3.new(0.5,  0.5, -0.5),
        vec3.new(0.5, -0.5,  0.5),
        vec3.new(0.5, -0.5, -0.5),
        vec3.new(-0.5,  0.5,  0.5),
        vec3.new(-0.5,  0.5, -0.5),
        vec3.new(-0.5, -0.5,  0.5),
        vec3.new(-0.5, -0.5, -0.5),
    };

    //uvs being used as colors for now
    var color_indexes: [4]usize = undefined;
    const cube_uvs = [_]vec3{
        vec3.new(0.0, 0.0, 1.0),
        vec3.new(0.0, 1.0, 1.0),
        vec3.new(1.0, 0.0, 1.0),
        vec3.new(1.0, 1.0, 1.0),
    };

    var position_indexes: [4]usize = undefined;
    switch (face) {
        CubeFace.x_pos => {
            position_indexes = [4]usize{ 0, 2, 3, 1 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.x_neg => {
            position_indexes = [4]usize{ 4, 5, 7, 6 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.y_pos => {
            position_indexes = [4]usize{ 0, 1, 5, 4 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.y_neg => {
            position_indexes = [4]usize{ 2, 6, 7, 3 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.z_pos => {
            position_indexes = [4]usize{ 0, 4, 6, 2 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.z_neg => {
            position_indexes = [4]usize{ 1, 3, 7, 5 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
    }

    var index_offset = @intCast(u32, vertices.items.len);

    vertices.appendSlice(&[_]vertex.ColoredVertex{
        vertex.ColoredVertex.new(cube_positions[position_indexes[0]].add(position), cube_uvs[color_indexes[0]]),
        vertex.ColoredVertex.new(cube_positions[position_indexes[1]].add(position), cube_uvs[color_indexes[1]]),
        vertex.ColoredVertex.new(cube_positions[position_indexes[2]].add(position), cube_uvs[color_indexes[2]]),
        vertex.ColoredVertex.new(cube_positions[position_indexes[3]].add(position), cube_uvs[color_indexes[3]]),
    }) catch std.debug.panic("Failed to append", .{});

    indices.appendSlice(&[_]u32{ 
        index_offset + 0, 
        index_offset + 1, 
        index_offset + 2, 
        index_offset + 0, 
        index_offset + 2, 
        index_offset + 3, 
        }) catch std.debug.panic("Failed to append", .{});
}