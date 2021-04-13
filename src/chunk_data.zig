pub const BlockId = u16;
pub const ChunkData32 = ChunkData(32, 32, 32);

pub fn ChunkData(comptime size_x: u16, comptime size_y: u16, comptime size_z: u16) type {
    return struct {
        const Self = @This();
        pub const size_x: u16 = size_x;
        pub const size_y: u16 = size_y;
        pub const size_z: u16 = size_z;

        data: [size_x][size_y][size_z]BlockId,
        dirty: bool,

        pub fn init() Self {
            return .{ .data = undefined, .dirty = false };
        }

        pub fn getBlock(self: *Self, x: u16, y: u16, z: u16) BlockId {
            return self.data[x][y][z];
        }

        pub fn setBlock(self: *Self, x: u16, y: u16, z: u16, id: BlockId) void {
            self.data[x][y][z] = id;
            self.dirty = true;
        }
    };
}
