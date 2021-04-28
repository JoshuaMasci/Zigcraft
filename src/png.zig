const c = @import("c.zig");

pub const Format = enum {
    R8,
    RG8,
    RGB8,
    RGBA8,
    R16,
    RG16,
    RGB16,
    RGBA16,
};

pub const Png = struct {
    const Self = @This();

    size: [2]u32,
    format: Format,
    data: []u8,

    pub fn initMemory(data: []const u8) !Self {
        var c_width: c_int = 0;
        var c_height: c_int = 0;
        var channels: c_int = 0;

        if (c.stbi_info_from_memory(data.ptr, @intCast(c_int, data.len), &c_width, &c_height, &channels) == 0) {
            return error.PngLoadFailed;
        }

        if(c_width <= 0 or c_height <= 0) {
            return error.PngLoadFailed;
        }

        var is_16bits: bool = c.stbi_is_hdr_from_memory(data.ptr, @intCast(c_int, data.len)) != 0;
        if (is_16bits) {
            //For now
            return error.PngLoadFailed;
        }

        //Force format
        const bytes_per_channel: u32 = 1;
        var format = Format.RGBA8;
        channels = 4;

        const image_data = c.stbi_load_from_memory(data.ptr, @intCast(c_int, data.len), &c_width, &c_height, null, channels);

        if (image_data == null) {
            return error.PngLoadFailed; 
        }


        var width = @intCast(u32, c_width);
        var height = @intCast(u32, c_height);
        var date_size: usize = width * height * @intCast(u32, channels) * bytes_per_channel;

        return Self{
            .size = [2]u32{width, height},
            .format = format,
            .data = image_data[0 .. date_size],
        };
    }

    //pub fn initFile(filename: []const u8) Self {};

    pub fn deinit(self: *Self) void {
        c.stbi_image_free(self.data.ptr);
    }
};