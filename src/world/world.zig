const std = @import("std");
const panic = std.debug.panic;

usingnamespace @import("zalgebra");
usingnamespace @import("../transform.zig");
const opengl = @import("../opengl_renderer.zig");
usingnamespace @import("../chunk/chunk.zig");

//TODO 3D chunk
pub const ChunkPos = Vec2(i32);

const ChunkInfo = struct {
    coord: ChunkPos,
    data: ChunkData32,
    mesh: opengl.Mesh,
    transform: Transform,
};

pub const World = struct {
    const Self = @This();

    allocator: std.heap.GeneralPurposeAllocator(.{}),
    chunk_map: std.AutoHashMap(ChunkPos, ChunkInfo),

    pub fn init() Self {
        var allocator = std.heap.GeneralPurposeAllocator(.{}){};
        var chunk_map = std.AutoHashMap(ChunkPos, ChunkInfo).init(&allocator.allocator);

        var new_chunk = ChunkInfo {
            .coord = ChunkPos.zero(),
            .data = ChunkData32.init(),
            .mesh = undefined,
            .transform = Transform.zero(),
        };

        chunk_map.put(new_chunk.coord, new_chunk) catch panic("Failed to put", .{});

        return Self {
            .allocator = allocator,
            .chunk_map = chunk_map,
        };
    }

    pub fn deinit(self: *Self) void {
        var iterator = self.chunk_map.iterator();
        while (iterator.next()) |entry| {
            entry.value.mesh.deinit();
        }

        self.chunk_map.deinit();

        const leaked = self.allocator.deinit();
        if (leaked) panic("Error: memory leaked from World", .{});
    }

    pub fn update(self: *Self, camera_pos: *vec3) void {
        const stdout = std.io.getStdOut().writer();
        //stdout.print("Loaded Chunks {}!\n", .{ self.chunk_map.count() }) catch {};

        var iterator = self.chunk_map.iterator();
        while (iterator.next()) |entry| {
            if (entry.value.data.isDirty()) {
                stdout.print("Rebuilding Chunk!\n", .{}) catch {};
                entry.value.mesh.deinit();
                entry.value.mesh = CreateChunkMesh(ChunkData32, &self.allocator.allocator, &entry.value.data);
                entry.value.data.dirty = false;
            }
        }
    }

    pub fn render(self: *Self) void {
        
    }
};