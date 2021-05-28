const c = @import("../c.zig");
const std = @import("std");
const vertex = @import("../vertex.zig");
const opengl = @import("../opengl_renderer.zig");

usingnamespace @import("zalgebra");
usingnamespace @import("block.zig");

pub const vec3i = Vec3(i64);
pub const vec3u = Vec3(u64);

pub const TestChunk = struct {
    const Self = @This();
    pub const Size = vec3u.new(32, 32, 32);
    const DataSize: u64 = Size.x * Size.y * Size.z;

    dirty: bool,
    data: [DataSize]BlockId,
    mesh: ?opengl.Mesh,

    coord: vec3i,
    matrix: mat4,

    pub fn init(coord: vec3i) Self {
        return Self {
            .dirty = true,
            .coord = coord,
            .data = [_]BlockId{0} ** DataSize,
            .mesh = null,
            .matrix = mat4.from_translate(vec3.new(@intToFloat(f32, @intCast(u64, coord.x) * ChunkData32.size_x), @intToFloat(f32, @intCast(u64, coord.y) * ChunkData32.size_y), @intToFloat(f32, @intCast(u64, coord.z) * ChunkData32.size_z))),
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.mesh) |chunk_mesh| {
            chunk_mesh.deinit();
        }
    }

    pub fn getBlockIndex(pos: *vec3i) ?usize {
        if (pos.x >= 0 and pos.y >= 0 and pos.z >= 0) {
            var index: usize = (@intCast(usize, pos.x)) + (@intCast(usize, pos.y) * Size.y) + (@intCast(usize, pos.z) * Size.y * Size.z);
            if (index >= 0 and index < DataSize) {
                return index;
            }
        }

        return null;
    }

    fn getBlockPos(index: u64) vec3i {
        const SliceSize: u64 = (Size.x * Size.y);
        var z = index / SliceSize;
        var z_rem = @mod(index, SliceSize);
        var y = z_rem / Size.x;
        var y_rem = @mod(z_rem, Size.x);
        return vec3i.new(y_rem, y, z);
    }

    pub fn getBlock(self: *Self, pos: *vec3i) BlockId {
        if (getBlockIndex(pos)) |index| {
            return self.data[index]; 
        }
        else {
            return 0;
        }
    }

    pub fn setBlock(self: *Self, pos: *vec3i, id: BlockId) void {
        if (getBlockIndex(pos)) |index| {
            self.data[index] = id;
            self.dirty = true;
        }
    }

    pub fn render(self: *Self, matrix_uniform_index: c.GLint) void {
        if (self.mesh) |mesh| {
            c.glUniformMatrix4fv(matrix_uniform_index, 1, c.GL_FALSE, self.matrix.get_data());
            mesh.draw();
        }
    }
    
    pub fn generateChunkMesh(self: *Self, allocator: *std.mem.Allocator) void {
        if (self.dirty == false) {
            return;
        }

        if (self.mesh) |mesh| {
            mesh.deinit();
        }

        var vertices = std.ArrayList(vertex.TexturedVertex).init(allocator);
        defer vertices.deinit();

        var indices = std.ArrayList(u32).init(allocator);
        defer indices.deinit();
        
        var index: vec3i = vec3i.zero();
        while (index.x < Size.x) : (index.x += 1) {
            index.y = 0;
            while (index.y < Size.y) : (index.y += 1) {
                index.z = 0;
                while (index.z < Size.x) : (index.z += 1) {
                    var blockId = self.getBlock(&index);
                    var posVec = index.cast(f32);
                    if (blockId != 0) {
                        for (CubeFaceChecks) |faceCheck| {
                            var checkId = self.getBlock(&index.add(faceCheck.offset));
                            if (checkId == 0) {
                                var texture_index = BlockList[blockId].texture_index;
                                var x_offset = @intToFloat(f32, @rem(texture_index, 8));
                                var y_offset = @intToFloat(f32,  @divTrunc(texture_index, 8));
                                var texture_offset = vec2.new(x_offset, y_offset).scale(1.0 / 8.0);
                                appendCubeFace(faceCheck.face, &vertices, &indices, posVec, texture_offset);
                            }
                        }
                    }
                }
            }
        }
        self.mesh = opengl.Mesh.init(vertex.TexturedVertex, u32, vertices.items, indices.items);
    }
};

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
    offset: vec3i,
};

const CubeFaceChecks = [_]CubeFaceCheck{
    CubeFaceCheck{.face = CubeFace.x_pos, .offset = vec3i.new( 1,  0,  0)},
    CubeFaceCheck{.face = CubeFace.x_neg, .offset = vec3i.new(-1,  0,  0)},
    CubeFaceCheck{.face = CubeFace.y_pos, .offset = vec3i.new( 0,  1,  0)},
    CubeFaceCheck{.face = CubeFace.y_neg, .offset = vec3i.new( 0, -1,  0)},
    CubeFaceCheck{.face = CubeFace.z_pos, .offset = vec3i.new( 0,  0,  1)},
    CubeFaceCheck{.face = CubeFace.z_neg, .offset = vec3i.new( 0,  0, -1)},
};

pub fn ChunkData(comptime X: u64, comptime Y: u64, comptime Z: u64) type {
    return struct {
        const Self = @This();
        pub const size_x: u64 = X;
        pub const size_y: u64 = Y;
        pub const size_z: u64 = Z;

        const ARRAY_SIZE: u64 = size_x * size_y * size_z;
        data: [ARRAY_SIZE]BlockId,
        dirty: bool,

        pub fn init() Self {
            var data: [ARRAY_SIZE]BlockId = [_]BlockId{0} ** ARRAY_SIZE;
            return .{ .data = data, .dirty = true };
        }

        fn getBlockIndex(pos: *vec3i) u64 {
            return (@intCast(u64, pos.x)) + (@intCast(u64, pos.y) * size_y) + (@intCast(u64, pos.z) * size_y * size_z);
        }

        pub fn getBlock(self: *Self, pos: *vec3i) BlockId {
            return self.data[getBlockIndex(pos)];
        }

        pub fn getBlockSafe(self: *Self, pos: *vec3i) BlockId {
            if(pos.x >= Self.size_x or pos.x < 0 or pos.y >= Self.size_y or pos.y < 0 or pos.z >= Self.size_z or pos.z < 0) {
                return 0;
            }
            return self.data[getBlockIndex(pos)];
        }

        pub fn setBlock(self: *Self, pos: *vec3i, id: BlockId) void {
            self.data[getBlockIndex(pos)] = id;
            self.dirty = true;
        }

        pub fn isDirty(self: *Self) bool {
            return self.dirty;
        }
    };
}

pub fn CreateChunkMesh(comptime Chunk: type, allocator: *std.mem.Allocator, chunk: *Chunk) opengl.Mesh {
    var vertices = std.ArrayList(vertex.TexturedVertex).init(allocator);
    defer vertices.deinit();

    var indices = std.ArrayList(u32).init(allocator);
    defer indices.deinit();
    
    var index: vec3i = vec3i.zero();
    while (index.x < Chunk.size_x) : (index.x += 1) {
        index.y = 0;
        while (index.y < Chunk.size_y) : (index.y += 1) {
            index.z = 0;
            while (index.z < Chunk.size_x) : (index.z += 1) {
                var blockId = chunk.getBlock(&index);
                var posVec = index.cast(f32);

                if (blockId != 0) {

                    for (CubeFaceChecks) |faceCheck| {
                        var checkId = chunk.getBlockSafe(&index.add(faceCheck.offset));
                        if (checkId == 0) {

                            var texture_index = BlockList[blockId].texture_index;
                            var x_offset = @intToFloat(f32, @rem(texture_index, 8));
                            var y_offset = @intToFloat(f32,  @divTrunc(texture_index, 8));
                            var texture_offset = vec2.new(x_offset, y_offset).scale(1.0 / 8.0);
                            appendCubeFace(faceCheck.face, &vertices, &indices, posVec, texture_offset);
                        }
                    }
                }
            }
        }
    }

    return opengl.Mesh.init(vertex.TexturedVertex, u32, vertices.items, indices.items);
}

fn appendCubeFace(face: CubeFace, vertices: *std.ArrayList(vertex.TexturedVertex), indices: *std.ArrayList(u32), position: vec3, uv_offset: vec2) void {
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

    const cube_uvs = [_]vec2{
        vec2.new(0.0, 0.0).add(uv_offset),
        vec2.new(0.0, 1.0 / 8.0).add(uv_offset),
        vec2.new(1.0 / 8.0, 1.0 / 8.0).add(uv_offset),
        vec2.new(1.0 / 8.0, 0.0).add(uv_offset),
    };

    var position_indexes: [4]usize = undefined;
    switch (face) {
        CubeFace.x_pos => {
            position_indexes = [4]usize{ 0, 2, 3, 1 };
        },
        CubeFace.x_neg => {
            position_indexes = [4]usize{ 5, 7, 6, 4 };
        },
        CubeFace.y_pos => {
            position_indexes = [4]usize{ 0, 1, 5, 4 };
        },
        CubeFace.y_neg => {
            position_indexes = [4]usize{ 6, 7, 3, 2 };
        },
        CubeFace.z_pos => {
            position_indexes = [4]usize{ 4, 6, 2, 0 };
        },
        CubeFace.z_neg => {
            position_indexes = [4]usize{ 1, 3, 7, 5 };
        },
    }

    var index_offset = @intCast(u32, vertices.items.len);

    vertices.appendSlice(&[_]vertex.TexturedVertex{
        vertex.TexturedVertex.new(cube_positions[position_indexes[0]].add(position), cube_uvs[0]),
        vertex.TexturedVertex.new(cube_positions[position_indexes[1]].add(position), cube_uvs[1]),
        vertex.TexturedVertex.new(cube_positions[position_indexes[2]].add(position), cube_uvs[2]),
        vertex.TexturedVertex.new(cube_positions[position_indexes[3]].add(position), cube_uvs[3]),
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