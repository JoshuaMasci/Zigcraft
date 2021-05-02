const std = @import("std");
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;

//Core types
usingnamespace @import("zalgebra");
usingnamespace @import("camera.zig");
usingnamespace @import("transform.zig");
usingnamespace @import("chunk/chunk.zig");
usingnamespace @import("world/world.zig");

const c = @import("c.zig");
const glfw = @import("glfw_platform.zig");
const opengl = @import("opengl_renderer.zig");
const png = @import("png.zig");

fn createChunkMesh(allocator: *Allocator) opengl.Mesh {
    var chunk = ChunkData32.init();
    generateChunk(&chunk);
    return CreateChunkMesh(ChunkData32, allocator, &chunk);
}

fn generateChunk(chunk: *ChunkData32) void {
    var index: vec3i = vec3i.zero();
    while (index.x < ChunkData32.size_x) : (index.x += 1) {
        index.y = 0;
        while (index.y < ChunkData32.size_y) : (index.y += 1) {
            index.z = 0;
            while (index.z < ChunkData32.size_x) : (index.z += 1) {
                if (index.y  == 24) {
                    chunk.setBlock(&index, 3);
                }
                else if (index.y  < 24 and index.y  > 18) {
                    chunk.setBlock(&index, 2);
                }
                else if (index.y  <= 18) {
                    chunk.setBlock(&index, 1);
                }
            }
        }
    }
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

    var world = World.init();
    defer world.deinit();

    var png_file = @embedFile("spritesheet.png");
    var png_image = try png.Png.initMemory(png_file);
    defer png_image.deinit();
    var png_texture = opengl.Texture.init(png_image.size, png_image.data);
    defer png_texture.deinit();

    var camera = Camera.new(64.0, 0.1, 1000.0);
    var camera_transform = Transform.zero();

    var vertex_code = @embedFile("texture.vert.glsl");
    var fragment_code = @embedFile("texture.frag.glsl");
    var shader = opengl.Shader.init(vertex_code, fragment_code);
    defer shader.deinit();

    var mesh_transform = Transform.zero(); mesh_transform.move(vec3.new(0.0, 0.0, 3.0));
    var mesh = createChunkMesh(&gpa.allocator);
    defer mesh.deinit();

    //Uniform Indexes
    var view_projection_matrix_index = c.glGetUniformLocation(shader.shader_program, "view_projection_matrix");
    var model_matrix_index = c.glGetUniformLocation(shader.shader_program, "model_matrix");
    var texture_index = c.glGetUniformLocation(shader.shader_program, "block_texture");

    var frameCount: u32 = 0;
    var lastTime = glfw.getTime();
    while (glfw.shouldCloseWindow(window)) {
        glfw.update();
        var windowSize = glfw.getWindowSize(window);
        opengl.setViewport(windowSize);
        opengl.init3dRendering();
        opengl.clearFramebuffer();

        world.update(&camera_transform.position);
        moveCamera(1.0/60.0, &camera_transform);

        c.glUseProgram(shader.shader_program);

        //View Projection Matrix
        var projection_matrix = camera.getPerspective(@intToFloat(f32, windowSize[0]) / @intToFloat(f32, windowSize[1]));
        var view_matrix = camera_transform.getViewMatrix();
        var view_projection_matrix = mat4.mult(projection_matrix, view_matrix);
        c.glUniformMatrix4fv(view_projection_matrix_index, 1, c.GL_FALSE, view_projection_matrix.get_data());

        //Model Matrix
        var model_matrix = mesh_transform.getModelMatrix();
        c.glUniformMatrix4fv(model_matrix_index, 1, c.GL_FALSE, model_matrix.get_data());
        
        //Texture
        const bind_point = 0;
        png_texture.bind(bind_point);
        c.glUniform1i(texture_index, bind_point);

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

fn moveCamera(timeStep: f32, transform: *Transform) void {
        const moveSpeed: f32 = 3.0; //Meters
        const rotateSpeed: f32 = 45.0; //Degrees

        const left = transform.getLeft();
        const up = transform.getUp();
        const forward = transform.getForward();

        {
            var leftMove: f32 = 0.0;
            if(glfw.input.getKeyDown(c.GLFW_KEY_A)) {
                leftMove += 1.0;
            }
            if(glfw.input.getKeyDown(c.GLFW_KEY_D)) {
                leftMove -= 1.0;
            }
            transform.move(left.scale(leftMove * moveSpeed * timeStep));
        }

        {
            var upMove: f32 = 0.0;
            if(glfw.input.getKeyDown(c.GLFW_KEY_SPACE)) {
                upMove += 1.0;
            }
            if(glfw.input.getKeyDown(c.GLFW_KEY_LEFT_SHIFT)) {
                upMove -= 1.0;
            }
            transform.move(up.scale(upMove * moveSpeed * timeStep));
        }

        {
            var forwardMove: f32 = 0.0;
            if(glfw.input.getKeyDown(c.GLFW_KEY_W)) {
                forwardMove += 1.0;
            }
            if(glfw.input.getKeyDown(c.GLFW_KEY_S)) {
                forwardMove -= 1.0;
            }
            transform.move(forward.scale(forwardMove * moveSpeed * timeStep));
        }

        {
            var pitchRotate: f32 = 0.0;
            if(glfw.input.getKeyDown(c.GLFW_KEY_UP)) {
                pitchRotate += 1.0;
            }
            if(glfw.input.getKeyDown(c.GLFW_KEY_DOWN)) {
                pitchRotate -= 1.0;
            }
            transform.rotate(quat.from_axis(pitchRotate * rotateSpeed * timeStep, transform.getLeft()));
        }

        {
            var yawRotate: f32 = 0.0;
            if(glfw.input.getKeyDown(c.GLFW_KEY_LEFT)) {
                yawRotate += 1.0;
            }
            if(glfw.input.getKeyDown(c.GLFW_KEY_RIGHT)) {
                yawRotate -= 1.0;
            }
            transform.rotate(quat.from_axis(yawRotate * rotateSpeed * timeStep, vec3.up()));
        }
}