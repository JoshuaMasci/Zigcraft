const std = @import("std");
const panic = std.debug.panic;

usingnamespace @import("zalgebra");
usingnamespace @import("../transform.zig");
usingnamespace @import("../chunk/chunk.zig");
const c = @import("../c.zig");
const opengl = @import("../opengl_renderer.zig");

//TODO 3D chunk
pub const ChunkPos = Vec2(i32);

const ChunkInfo = struct {
    const Self = @This();

    coord: ChunkPos,
    data: ChunkData32,
    mesh: opengl.Mesh,
    transform: Transform,

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

        var new_chunk_data = ChunkData32.init();
        generateChunk(&new_chunk_data);

        var new_chunk = ChunkInfo {
            .coord = ChunkPos.zero(),
            .data = new_chunk_data,
            .mesh = CreateChunkMesh(ChunkData32, allocator, &new_chunk_data),
            .transform = Transform.zero(),
        };
        new_chunk.data.dirty = false;

        chunk_map.put(new_chunk.coord, new_chunk) catch panic("Failed to put", .{});

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

        // var new_chunk_data = ChunkData32.init();
        // var new_chunk = ChunkInfo {
        //     .coord = ChunkPos.zero(),
        //     .data = new_chunk_data,
        //     .mesh = CreateChunkMesh(ChunkData32, self.allocator, &new_chunk_data),
        //     .transform = Transform.zero(),
        // };

        //self.chunk_map.put(ChunkPos.new(@intCast(i32, self.chunk_map.count()), 0), new_chunk) catch panic("Failed to put", .{});
    }

    pub fn render(self: *Self, matrix_uniform_index: c.GLint) void {
        var iterator = self.chunk_map.iterator();
        while (iterator.next()) |entry| {
            //Model Matrix
            var model_matrix = entry.value.transform.getModelMatrix();
            c.glUniformMatrix4fv(matrix_uniform_index, 1, c.GL_FALSE, model_matrix.get_data());
            entry.value.mesh.draw();
        }
    }
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