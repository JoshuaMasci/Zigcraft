pub const BlockId = u16;

pub const Block = struct {
    const Self = @This();

    id: BlockId,
    texture_index: i16,

    pub fn new( id: BlockId, texture_index: i16) Self {
        return Self { .id = id, .texture_index = texture_index };
    }
};

pub const BlockList = [_]Block{
    Block.new(0, -1),//Air
    Block.new(1,  0),//Stone?
    Block.new(2,  1),//Dirt?
    Block.new(3,  2),//Grass?
    Block.new(4,  22),//Grass?
};