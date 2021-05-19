const std = @import("std");
usingnamespace @import("zalgebra");

pub const Aabb = struct {
    const Self = @This();

    position: vec3,
    half_extent: vec3,

    pub fn init(pos: vec3, extent: vec3) Self {
        return Self {
            .position = pos,
            .half_extent = extent,
        };
    }

    pub fn testPoint(self: *const Self, point: *const vec3) bool {
       return (point.x >= (self.position.x - self.half_extent.x) and point.x <= (self.position.x + self.half_extent.x))
       and (point.y >= (self.position.y - self.half_extent.y) and point.y <= (self.position.y + self.half_extent.y))
       and (point.z >= (self.position.z - self.half_extent.z) and point.z <= (self.position.z + self.half_extent.z));
    }

    pub fn testAabb(self: *const Self, other: *const Self) bool {
        const a_min = self.position.sub(self.half_extent);
        const a_max = self.position.add(self.half_extent);
        const b_min = other.position.sub(other.half_extent);
        const b_max = other.position.add(other.half_extent);

        return (a_min.x <= b_max.x and a_max.x >= b_min.x)
        and (a_min.y <= b_max.y and a_max.y >= b_min.y)
        and (a_min.z <= b_max.z and a_max.z >= b_min.z);
    }

    fn calcOffset(a_min: f32, a_max: f32, b_min: f32, b_max: f32) f32 {
        if (a_min < b_max and a_max > b_min) {

            var offset1 = b_max - a_min;
            var offset2 = b_min - a_max;

            if (offset1 < -offset2) {
                return offset1;
            }
            else {
                return offset2;
            }
        }
        return 0.0;
    }

    pub fn calcPenetration(self: *const Self, other: *const Self) vec3 {
        const a_min = self.position.sub(self.half_extent);
        const a_max = self.position.add(self.half_extent);
        const b_min = other.position.sub(other.half_extent);
        const b_max = other.position.add(other.half_extent);

        var offset = vec3.new(
            calcOffset(a_min.x, a_max.x, b_min.x, b_max.x),
            calcOffset(a_min.y, a_max.y, b_min.y, b_max.y),
            calcOffset(a_min.z, a_max.z, b_min.z, b_max.z),
        );

        var abs_x = @fabs(offset.x);
        var abs_y = @fabs(offset.y);
        var abs_z = @fabs(offset.z);

        if(abs_x < abs_y and abs_x < abs_z and abs_x != 0.0) {
            return vec3.right().scale(offset.x);
        }
        else if(abs_y < abs_x and abs_y < abs_z and abs_y != 0.0) {
            return vec3.up().scale(offset.y);
        }
        else if(abs_z < abs_x and abs_z < abs_y and abs_z != 0.0) {
            return vec3.forward().scale(offset.z);
        }

        //Shouldn't be called not really sure what todo here
        return offset;
    }

    pub fn testRay(self: *const Self, start: *const vec3, end: *const vec3) bool {
        return false;
    }
};
