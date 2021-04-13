usingnamespace @import("zalgebra");

pub const Camera = struct {
    const Self = @This();

    fov: f32,
    zNear: f32,
    zFar: f32,

    pub fn init(
        fov: f32,
        zNear: f32,
        zFar: f32,
    ) Self {
        return .{ .fov = fov, .zNear = zNear, .zFar = zFar };
    }

    pub fn getPerspective(self: *Self, aspectRatio: f32) mat4 {
        return perspective(self.fov, aspectRatio, self.zNear, self.zFar);
    }
};
