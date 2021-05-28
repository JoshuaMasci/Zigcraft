const std = @import("std");
const panic = std.debug.panic;

usingnamespace @import("zalgebra");
usingnamespace @import("../transform.zig");
usingnamespace @import("../chunk/chunk.zig");
const c = @import("../c.zig");
const opengl = @import("../opengl_renderer.zig");
const glfw = @import("../glfw_platform.zig");
usingnamespace @import("../test_box.zig");

//TODO 3D chunk
pub const ChunkPos = Vec2(i32);

const ChunkInfo = struct {
    const Self = @This();

    coord: ChunkPos,
    data: ChunkData32,
    mesh: opengl.Mesh,
    matrix: mat4,

    pub fn deinit(self: *Self) void {
        self.mesh.deinit();
    }
};

pub const World = struct {
    const Self = @This();

    allocator: *std.mem.Allocator,
    chunk_map: std.AutoHashMap(ChunkPos, ChunkInfo),

    pub fn init(allocator: *std.mem.Allocator) Self {
        var chunk_map = std.AutoHashMap(ChunkPos, ChunkInfo).init(allocator);

        const CHUNK_SIZE = 1;
        var index = ChunkPos.zero();
        while (index.x < CHUNK_SIZE) : (index.x += 1) {
            index.y = 0;
            while (index.y < CHUNK_SIZE) : (index.y += 1) {
                var new_chunk_data = ChunkData32.init();
                generateChunk(&new_chunk_data);

                var new_chunk = ChunkInfo {
                    .coord = index,
                    .data = new_chunk_data,
                    .mesh = CreateChunkMesh(ChunkData32, allocator, &new_chunk_data),
                    .matrix = mat4.from_translate(vec3.new(@intToFloat(f32, @intCast(u64, index.x) * ChunkData32.size_x), 0.0, @intToFloat(f32, @intCast(u64, index.y) * ChunkData32.size_z))),
                };
                new_chunk.data.dirty = false;
                chunk_map.put(new_chunk.coord, new_chunk) catch panic("Failed to put", .{});
            }
        }

        return Self {
            .allocator = allocator,
            .chunk_map = chunk_map,
        };
    }

    pub fn deinit(self: *Self) void {
        var iterator = self.chunk_map.iterator();
        while (iterator.next()) |entry| {
            entry.value.deinit();
        }
        self.chunk_map.deinit();
    }

    pub fn update(self: *Self, camera_pos: *vec3) void {
        const stdout = std.io.getStdOut().writer();

        var iterator = self.chunk_map.iterator();
        while (iterator.next()) |entry| {
            if (entry.value.data.isDirty()) {
                stdout.print("Rebuilding Chunk!\n", .{}) catch {};
                entry.value.mesh.deinit();
                entry.value.mesh = CreateChunkMesh(ChunkData32, self.allocator, &entry.value.data);
                entry.value.data.dirty = false;
            }
        }
    }

    pub fn render(self: *Self, matrix_uniform_index: c.GLint) void {
        var iterator = self.chunk_map.iterator();
        while (iterator.next()) |entry| {
            //Model Matrix
            c.glUniformMatrix4fv(matrix_uniform_index, 1, c.GL_FALSE, entry.value.matrix.get_data());
            entry.value.mesh.draw();
        }
    }

    // pub fn calcCollision(self: *Self, player: *TestBox) void {
    //     var iterator = self.chunk_map.iterator();
    //     while (iterator.next()) |entry| {
    //     }
    // }
};

fn generateChunk(chunk: *ChunkData32) void {
    var index: vec3i = vec3i.zero();
    while (index.x < ChunkData32.size_x) : (index.x += 1) {
        index.y = 0;
        while (index.y < ChunkData32.size_y) : (index.y += 1) {
            index.z = 0;
            while (index.z < ChunkData32.size_x) : (index.z += 1) {
                if (index.y  == 24) {
                    chunk.setBlock(&index, 3);
                }
                else if (index.y  < 24 and index.y  > 18) {
                    chunk.setBlock(&index, 2);
                }
                else if (index.y  <= 18) {
                    chunk.setBlock(&index, 1);
                }
            }
        }
    }
}

// fn testCollision(chunk: *ChunkData32) vec3 {
//     var offset = vec3.zero();
//     var aabb = Aabb.init(vec3.zero(), vec3.one())
//     var index: vec3i = vec3i.zero();
//     while (index.x < ChunkData32.size_x) : (index.x += 1) {
//         index.y = 0;
//         while (index.y < ChunkData32.size_y) : (index.y += 1) {
//             index.z = 0;
//             while (index.z < ChunkData32.size_x) : (index.z += 1) {
//                 if (chunk.getBlock(index) != 0) {
                    
//                 }
//             }
//         }
//     }

//     return offset;
// }