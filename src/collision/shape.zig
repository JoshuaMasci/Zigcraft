usingnamespace @import("zalgebra");

const PlaneInfo = struct {

};

const BoxInfo = struct {

};

const ShpereInfo = struct {

};

const CylinderInfo = struct {

};

const CapsuleInfo = struct {

};

const ConeInfo = struct {

};

const CollisionShape = union(enum) {
    Point: void,
    Plane: PlaneInfo,
    Box: BoxInfo,
    Sphere: ShpereShape,
    Cylinder: CylinderInfo,
    Capsule: CapsuleShape,
    Cone: ConeInfo,
};