const std = @import("std");
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;

//Core types
usingnamespace @import("zalgebra");
usingnamespace @import("camera.zig");
usingnamespace @import("transform.zig");

const c = @import("c.zig");
const glfw = @import("glfw_platform.zig");
const opengl = @import("opengl_renderer.zig");

const world_chunks = @import("chunk_data.zig");

pub const Vertex = struct {
    const Self = @This();

    position: vec3,
    color: vec3,

    pub fn new(position: vec3, color: vec3) Self {
        return Self{
            .position = position,
            .color = color,
        };
    }

    pub fn genVao() void {
        c.glEnableVertexAttribArray(0);
        c.glEnableVertexAttribArray(1);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Self), null); // Position is at zero
        c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Self), @intToPtr(*const c_void, @byteOffsetOf(Self, "color")));
    }
};

const CubeFace = enum {
    x_pos,
    x_neg,
    y_pos,
    y_neg,
    z_pos,
    z_neg,
};

const VertexList = std.ArrayList(Vertex);
const IndexList = std.ArrayList(u32);

fn appendCubeFace(face: CubeFace, vertices: *VertexList, indices: *IndexList) void {
    const cube_positions = [_]vec3{
        vec3.new(0.5,  0.5,  0.5),
        vec3.new(0.5,  0.5, -0.5),
        vec3.new(0.5, -0.5,  0.5),
        vec3.new(0.5, -0.5, -0.5),
        vec3.new(-0.5,  0.5,  0.5),
        vec3.new(-0.5,  0.5, -0.5),
        vec3.new(-0.5, -0.5,  0.5),
        vec3.new(-0.5, -0.5, -0.5),
    };

    //uvs being used as colors for now
    const cube_uvs = [_]vec3{
        vec3.new(0.0, 0.0, 1.0),
        vec3.new(0.0, 1.0, 1.0),
        vec3.new(1.0, 0.0, 1.0),
        vec3.new(1.0, 1.0, 1.0),
    };

    var position_indexes: [4]usize = undefined;
    var color_indexes: [4]usize = undefined;
    switch (face) {
        CubeFace.x_pos => {
            position_indexes = [4]usize{ 0, 2, 3, 1 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.x_neg => {
            position_indexes = [4]usize{ 4, 5, 7, 6 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.y_pos => {
            position_indexes = [4]usize{ 0, 1, 5, 4 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.y_neg => {
            position_indexes = [4]usize{ 2, 6, 7, 3 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.z_pos => {
            position_indexes = [4]usize{ 0, 4, 6, 2 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
        CubeFace.z_neg => {
            position_indexes = [4]usize{ 1, 3, 7, 5 };
            color_indexes = [4]usize{ 0, 1, 2, 3 };
        },
    }

    var index_offset = @intCast(u32, vertices.items.len);

    vertices.appendSlice(&[_]Vertex{
        Vertex.new(cube_positions[position_indexes[0]], cube_uvs[color_indexes[0]]),
        Vertex.new(cube_positions[position_indexes[1]], cube_uvs[color_indexes[1]]),
        Vertex.new(cube_positions[position_indexes[2]], cube_uvs[color_indexes[2]]),
        Vertex.new(cube_positions[position_indexes[3]], cube_uvs[color_indexes[3]]),
    }) catch panic("Failed to append", .{});

    indices.appendSlice(&[_]u32{ 
        index_offset + 0, 
        index_offset + 1, 
        index_offset + 2, 
        index_offset + 0, 
        index_offset + 2, 
        index_offset + 3 }) catch panic("Failed to append", .{});
}

fn createCubeMesh(allocator: *Allocator) opengl.Mesh {
    var vertices = VertexList.init(allocator);
    defer vertices.deinit();

    var indices = IndexList.init(allocator);
    defer indices.deinit();

    appendCubeFace(CubeFace.x_pos, &vertices, &indices);
    appendCubeFace(CubeFace.x_neg, &vertices, &indices);
    appendCubeFace(CubeFace.y_pos, &vertices, &indices);
    appendCubeFace(CubeFace.y_neg, &vertices, &indices);
    appendCubeFace(CubeFace.z_pos, &vertices, &indices);
    appendCubeFace(CubeFace.z_neg, &vertices, &indices);

    std.io.getStdOut().writer().print("Mesh size: {}\n", .{vertices.items.len}) catch {};

    return opengl.Mesh.init(Vertex, u32, vertices.items, indices.items);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) panic("Error: memory leaked", .{});
    }

    glfw.init();
    defer glfw.deinit();

    var window = glfw.createWindow(1600, 900, "ZigCraft V0.1");
    defer glfw.destoryWindow(window);

    var camera = Camera.new(64.0, 0.1, 1000.0);
    var camera_transform = Transform.zero();

    var vertex_code = @embedFile("vert.glsl");
    var fragment_code = @embedFile("frag.glsl");
    var shader = opengl.Shader.init(vertex_code, fragment_code);
    defer shader.deinit();

    var mesh_transform = Transform.zero(); mesh_transform.move(vec3.new(0.0, 0.0, 3.0));
    var mesh = createCubeMesh(&gpa.allocator);
    defer mesh.deinit();

    //Uniform Indexes
    var view_projection_matrix_index = c.glGetUniformLocation(shader.shader_program, "view_projection_matrix");
    var model_matrix_index = c.glGetUniformLocation(shader.shader_program, "model_matrix");

    var frameCount: u32 = 0;
    var lastTime = glfw.getTime();
    while (glfw.shouldCloseWindow(window)) {
        glfw.update();
        opengl.setViewport(glfw.getWindowSize(window));
        opengl.init3dRendering();
        opengl.clearFramebuffer();

        if(glfw.input.getKeyDown(c.GLFW_KEY_W)) {
            camera_transform.move(vec3.new(0.0, 0.01, 0.0));
        }
        if(glfw.input.getKeyDown(c.GLFW_KEY_S)) {
            camera_transform.move(vec3.new(0.0, -0.01, 0.0));
        }

        if(glfw.input.getKeyDown(c.GLFW_KEY_A)) {
            camera_transform.move(vec3.new(0.01, 0.0, 0.0));
        }
        if(glfw.input.getKeyDown(c.GLFW_KEY_D)) {
            camera_transform.move(vec3.new(-0.01, 0.0, 0.0));
        }

        c.glUseProgram(shader.shader_program);

        //View Projection Matrix
        var projection_matrix = camera.getPerspective(1920.0 / 1080.0);
        var view_matrix = camera_transform.getViewMatrix();
        var view_projection_matrix = mat4.mult(projection_matrix, view_matrix);
        c.glUniformMatrix4fv(view_projection_matrix_index, 1, c.GL_FALSE, view_projection_matrix.get_data());

        //Model Matrix
        var model_matrix = mesh_transform.getModelMatrix();
        c.glUniformMatrix4fv(model_matrix_index, 1, c.GL_FALSE, model_matrix.get_data());

        mesh.draw();

        glfw.refreshWindow(window);

        frameCount += 1;
        var currentTime = glfw.getTime();
        if ((currentTime - 1.0) > lastTime) {
            try stdout.print("FPS: {}\n", .{frameCount});
            frameCount = 0;
            lastTime = currentTime;
        }
    }

    try stdout.print("Hello, {s}!\n", .{"world"});
}
