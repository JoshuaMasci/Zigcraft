usingnamespace @import("zalgebra");

pub const BlockPos = [3]isize;

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

const CubeFaceCheck = struct {
    face: CubeFace,
    x: i32,
    y: i32,
    z: i32,
};

const CubeFaceChecks = [_]CubeFaceCheck{
    CubeFaceCheck{.face = CubeFace.x_pos, .x = 1,  .y = 0,  .z = 0},
    CubeFaceCheck{.face = CubeFace.x_neg, .x = -1, .y = 0,  .z = 0},
    CubeFaceCheck{.face = CubeFace.y_pos, .x = 0,  .y = 1,  .z = 0},
    CubeFaceCheck{.face = CubeFace.y_neg, .x = 0,  .y = -1, .z = 0},
    CubeFaceCheck{.face = CubeFace.z_pos, .x = 0,  .y = 0,  .z = 1},
    CubeFaceCheck{.face = CubeFace.z_neg, .x = 0,  .y = 0,  .z = -1},
};

pub fn ChunkData(comptime X: usize, comptime Y: usize, comptime Z: usize) type {
    return struct {
        const Self = @This();
        pub const size_x: usize = X;
        pub const size_y: usize = Y;
        pub const size_z: usize = Z;

        data: [size_x][size_y][size_z]BlockId,
        dirty: bool,

        pub fn init() Self {
            var data: [size_x][size_y][size_z]BlockId = undefined;

            var x: usize = 0;
            while (x < Self.size_x) : (x += 1) {
                var y: usize = 0;
                while (y < Self.size_y) : (y += 1) {
                    var z: usize = 0;
                    while (z < Self.size_x) : (z += 1) {
                        data[x][y][z] = 0;
                    }
                }
            }

            return .{ .data = data, .dirty = true };
        }

        pub fn getBlock(self: *Self, x: i32, y: i32, z: i32) BlockId {
            return self.data[@intCast(usize, x)][@intCast(usize, y)][@intCast(usize, z)];
        }

        pub fn getBlockSafe(self: *Self, x: i32, y: i32, z: i32) BlockId {
            if(x >= Self.size_x or x < 0 or y >= Self.size_y or y < 0 or z >= Self.size_z or z < 0) {
                return 0;
            }
            return self.data[@intCast(usize, x)][@intCast(usize, y)][@intCast(usize, z)];
        }

        pub fn setBlock(self: *Self, x: i32, y: i32, z: i32, id: BlockId) void {
            self.data[@intCast(usize, x)][@intCast(usize, y)][@intCast(usize, z)] = id;
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
    var vertices = std.ArrayList(vertex.TexturedVertex).init(allocator);
    defer vertices.deinit();

    var indices = std.ArrayList(u32).init(allocator);
    defer indices.deinit();
    
    var x: i32 = 0;
    while (x < Chunk.size_x) : (x += 1) {
        var y: i32 = 0;
        while (y < Chunk.size_y) : (y += 1) {
            var z: i32 = 0;
            while (z < Chunk.size_x) : (z += 1) {
                var blockId = chunk.getBlock(x, y, z);
                var posVec = vec3.new(
                    @intToFloat(f32, x),
                    @intToFloat(f32, y),
                    @intToFloat(f32, z),
                    );
                var color = vec3.right();

                if (blockId != 0) {

                    for (CubeFaceChecks) |faceCheck| {
                        var checkId = chunk.getBlockSafe(
                            x + faceCheck.x,
                            y + faceCheck.y,
                            z + faceCheck.z,
                            );

                        if (checkId == 0) {
                            appendCubeFace(faceCheck.face, &vertices, &indices, posVec, color);
                        }
                    }
                }
            }
        }
    }

    return opengl.Mesh.init(vertex.TexturedVertex, u32, vertices.items, indices.items);
}

fn appendCubeFace(face: CubeFace, vertices: *std.ArrayList(vertex.TexturedVertex), indices: *std.ArrayList(u32), position: vec3, color: vec3) void {
    const cube_positions = [_]vec3{
        vec3.new(0.5,  0.5,  0.5), // 0
        vec3.new(0.5,  0.5, -0.5), // 1
        vec3.new(0.5, -0.5,  0.5), // 2
        vec3.new(0.5, -0.5, -0.5), // 3
        vec3.new(-0.5,  0.5,  0.5),// 4
        vec3.new(-0.5,  0.5, -0.5),// 5
        vec3.new(-0.5, -0.5,  0.5),// 6
        vec3.new(-0.5, -0.5, -0.5),// 7
    };

    //uvs being used as colors for now
    var uv_indexes: [4]usize = undefined;
    const cube_uvs = [_]vec2{
        vec2.new(0.0, 0.0), // 0
        vec2.new(0.0, 1.0), // 1
        vec2.new(1.0, 0.0), // 2
        vec2.new(1.0, 1.0), // 3
    };

    var position_indexes: [4]usize = undefined;
    switch (face) {
        CubeFace.x_pos => {
            position_indexes = [4]usize{ 0, 2, 3, 1 };
            uv_indexes =       [4]usize{ 0, 1, 3, 2 };
        },
        CubeFace.x_neg => {
            position_indexes = [4]usize{ 4, 5, 7, 6 };
            uv_indexes =       [4]usize{ 2, 0, 1, 3 };
        },
        CubeFace.y_pos => {
            position_indexes = [4]usize{ 0, 1, 5, 4 };
            uv_indexes =       [4]usize{ 0, 1, 3, 2 };
        },
        CubeFace.y_neg => {
            position_indexes = [4]usize{ 2, 6, 7, 3 };
            uv_indexes =       [4]usize{ 2, 0, 1, 3 };
        },
        CubeFace.z_pos => {
            position_indexes = [4]usize{ 0, 4, 6, 2 };
            uv_indexes =       [4]usize{ 2, 0, 1, 3 };
        },
        CubeFace.z_neg => {
            position_indexes = [4]usize{ 1, 3, 7, 5 };
            uv_indexes =       [4]usize{ 0, 1, 3, 2 };
        },
    }

    var index_offset = @intCast(u32, vertices.items.len);

    vertices.appendSlice(&[_]vertex.TexturedVertex{
        vertex.TexturedVertex.new(cube_positions[position_indexes[0]].add(position), cube_uvs[uv_indexes[0]]),
        vertex.TexturedVertex.new(cube_positions[position_indexes[1]].add(position), cube_uvs[uv_indexes[1]]),
        vertex.TexturedVertex.new(cube_positions[position_indexes[2]].add(position), cube_uvs[uv_indexes[2]]),
        vertex.TexturedVertex.new(cube_positions[position_indexes[3]].add(position), cube_uvs[uv_indexes[3]]),
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