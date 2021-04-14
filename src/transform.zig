usingnamespace @import("zalgebra");

pub const Transform = struct {
    position: vec3,
    rotation: quat,

    pub fn getModelMatrix(self: *Self) mat4 {
        var translate = mat4.from_translation(self.position);
        var rotation = self.rotation.to_mat4();
        return mat4.mult(translate, rotation);
    }
};