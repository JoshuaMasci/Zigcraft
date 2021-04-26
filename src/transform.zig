usingnamespace @import("zalgebra");

pub const Transform = struct {
    const Self = @This();

    position: vec3,
    rotation: quat,

    pub fn zero() Self {
        return .{
            .position = vec3.zero(),
            .rotation = quat.zero(),
        };
    }

    pub fn move(self: *Self, offset: vec3) void {
        self.position = self.position.add(offset);
    }

    pub fn rotate(self: *Self, offset: quat) void {
        self.rotation = offset.mult(self.rotation);
    }

    pub fn getLeft(self: *Self) vec3 {
        //zalgebra uses a left handed system, I use right
        return self.rotation.rotate_vec(vec3.right());
    }

    pub fn getUp(self: *Self) vec3 {
        return self.rotation.rotate_vec(vec3.up());
    }

    pub fn getForward(self: *Self) vec3 {
        return self.rotation.rotate_vec(vec3.forward());
    }

    pub fn getModelMatrix(self: *Self) mat4 {
        var translate = mat4.from_translate(self.position);
        var rotation = self.rotation.to_mat4();
        return mat4.mult(translate, rotation);
    }

    pub fn getViewMatrix(self: *Self) mat4 {
        var eye = self.position;
        var forward = self.getForward();
        var up = self.getUp();
        return mat4.look_at(eye, eye.add(forward), up);
    }
};