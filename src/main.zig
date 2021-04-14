const std = @import("std");
const panic = std.debug.panic;

//Core types
usingnamespace @import("zalgebra");
usingnamespace @import("camera.zig");
usingnamespace @import("transform.zig");

const c = @import("c.zig");
const glfw = @import("glfw_platform.zig");
const opengl = @import("opengl_renderer.zig");

const world_chunks = @import("chunk_data.zig");

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    panic("Error: {}\n", .{@as([*:0]const u8, description)});
}

pub const Vertex = struct {
    const Self = @This();

    position: vec3,
    color: vec3,

    fn new(position: vec3, color: vec3) Self {
        return Self{
            .position = position,
            .color = color,
        };
    }
};

fn createCubeMesh() opengl.Mesh {
    var cube_vertices = [_]vec3{
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
    var cube_uvs = [_]vec3{
        vec3.new(0.0, 0.0, 0),
        vec3.new(0.0, 1.0, 0),
        vec3.new(1.0, 0.0, 0),
        vec3.new(1.0, 1.0, 0),
    };

    var vertices = [_]Vertex{
    Vertex.new(vec3.new(-1.0, -1.0, 0.0), vec3.new(1.0, 0.0, 0.0)),
    Vertex.new(vec3.new(2.0, -1.0, 0.0), vec3.new(0.0, 1.0, 0.0)),
    Vertex.new(vec3.new(0.0, 1.0, 0.0), vec3.new(0.0, 0.0, 1.0)),
    };
    
    var indices = [_]u32{ 0, 1, 2 };

    return opengl.Mesh.init(Vertex, &vertices, &indices);
}

pub fn main() !void {
   {
        var chunk = world_chunks.ChunkData32.init();
        chunk.setBlock(0, 0, 0, 1);
        var id = chunk.getBlock(0, 0, 0);
   }

    const stdout = std.io.getStdOut().writer();

    glfw.init(errorCallback);
    defer glfw.deinit();

    var window = glfw.Window.init(1920, 1080, "ZigCraft V0.1");
    defer window.deinit();

    var camera = Camera.new(64.0, 0.1, 1000.0);
    var camera_transform = Transform.zero();

    var vertex_code = @embedFile("vert.glsl");
    var fragment_code = @embedFile("frag.glsl");
    var shader = opengl.Shader.init(vertex_code, fragment_code);
    defer shader.deinit();

    var mesh_transform = Transform.zero(); mesh_transform.move(vec3.new(0.0, 0.0, 3.0));
    var mesh = createCubeMesh();
    defer mesh.deinit();

    //Uniform Indexes
    var view_projection_matrix_index = c.glGetUniformLocation(shader.shader_program, "view_projection_matrix");
    var model_matrix_index = c.glGetUniformLocation(shader.shader_program, "model_matrix");

    var frameCount: u32 = 0;
    var lastTime = glfw.getTime();
    while (window.shouldClose()) {
        glfw.update();

        c.glUseProgram(shader.shader_program);

        //View Projection Matrix
        var projection_matrix = camera.getPerspective(1920.0 / 1080.0);
        var view_matrix = camera_transform.getViewMatrix();
        var view_projection_matrix = mat4.mult(projection_matrix, view_matrix);
        c.glUniformMatrix4fv(view_projection_matrix_index, 1, c.GL_FALSE, view_projection_matrix.get_data());

        //Model Matrix
        var model_matrix = mesh_transform.getModelMatrix();
        c.glUniformMatrix4fv(model_matrix_index, 1, c.GL_FALSE, model_matrix.get_data());

        c.glBindVertexArray(mesh.vao);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, mesh.vertex_buffer);
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, mesh.index_buffer);

        c.glEnableVertexAttribArray(0);
        c.glEnableVertexAttribArray(1);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), null);
        c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(Vertex), @intToPtr(*const c_void, @byteOffsetOf(Vertex, "color")));

        c.glDrawElements(c.GL_TRIANGLES, 3, c.GL_UNSIGNED_INT, null);

        window.refresh();

        frameCount += 1;
        var currentTime = glfw.getTime();
        if ((currentTime - 1.0) > lastTime) {
            try stdout.print("FPS: {}\n", .{frameCount});
            frameCount = 0;
            lastTime = currentTime;
        }
    }

    //Alloc testing
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) panic("Error: memory leaked", .{});
    }
    const bytes = try gpa.allocator.alloc(u8, 100);
    gpa.allocator.free(bytes);

    try stdout.print("Hello, {s}!\n", .{"world"});
}
