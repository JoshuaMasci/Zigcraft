const std = @import("std");
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;

//Core types
usingnamespace @import("zalgebra");
usingnamespace @import("camera.zig");
usingnamespace @import("transform.zig");
usingnamespace @import("chunk/chunk.zig");
usingnamespace @import("world/world.zig");

usingnamespace @import("collision/aabb.zig");
usingnamespace @import("test_box.zig");

const c = @import("c.zig");
const glfw = @import("glfw_platform.zig");
const opengl = @import("opengl_renderer.zig");
const png = @import("png.zig");

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
    //glfw.setMouseCaptured(window, true);
    glfw.maximizeWindow(window);

    var png_file = @embedFile("spritesheet.png");
    var png_image = try png.Png.initMemory(png_file);
    defer png_image.deinit();
    var png_texture = opengl.Texture.init(png_image.size, png_image.data);
    defer png_texture.deinit();

    var camera = Camera.new(64.0, 0.1, 1000.0);
    var camera_transform = Transform.zero();
    camera_transform.move(vec3.new(0.0, 1.0, -5.0));

    var texture_vertex_code = @embedFile("texture.vert.glsl");
    var texture_fragment_code = @embedFile("texture.frag.glsl");
    var texture_shader = opengl.Shader.init(texture_vertex_code, texture_fragment_code);
    defer texture_shader.deinit();

    var color_vertex_code = @embedFile("color.vert.glsl");
    var color_fragment_code = @embedFile("color.frag.glsl");
    var color_shader = opengl.Shader.init(color_vertex_code, color_fragment_code);
    defer color_shader.deinit();

    //Uniform Indexes
    var view_projection_matrix_index = c.glGetUniformLocation(texture_shader.shader_program, "view_projection_matrix");
    var model_matrix_index = c.glGetUniformLocation(texture_shader.shader_program, "model_matrix");
    var texture_index = c.glGetUniformLocation(texture_shader.shader_program, "block_texture");

    //World stuff
    var world = World.init(&gpa.allocator);
    defer world.deinit();

    var test_box1 = TestBox.init(vec3.new(0.0, 3.0, 0.0), vec3.one(), vec3.new(1.0, 0.0, 0.0));
    defer test_box1.deinit();

    var test_box2 = TestBox.init(vec3.zero(), vec3.one().scale(1.2), vec3.one());
    defer test_box2.deinit();

    var frameCount: u32 = 0;
    var lastTime = glfw.getTime();
    while (glfw.shouldCloseWindow(window)) {
        glfw.update();

        if (glfw.getMouseCaptured(window)) {
            //Free mouse if escape is at all pressed
            if (glfw.input.getKeyDown(c.GLFW_KEY_ESCAPE)) {
                glfw.setMouseCaptured(window, false);
            }
        }
        else {
            if (glfw.input.getMousePressed(c.GLFW_MOUSE_BUTTON_LEFT)) {
                glfw.setMouseCaptured(window, true);
            }
        }

        var windowSize = glfw.getWindowSize(window);
        opengl.setViewport(windowSize);
        opengl.init3dRendering();
        opengl.clearFramebuffer();

        //world.update(&camera_transform.position);
        moveCamera(1.0/60.0, &camera_transform);

        test_box1.aabb.position = test_box1.aabb.position.add(vec3.new(0.0, -0.1 / 60.0, 0.0));
        test_box1.update(&test_box2);

        c.glUseProgram(texture_shader.shader_program);

        //View Projection Matrix
        var projection_matrix = camera.getPerspective(@intToFloat(f32, windowSize[0]) / @intToFloat(f32, windowSize[1]));
        var view_matrix = camera_transform.getViewMatrix();
        var view_projection_matrix = mat4.mult(projection_matrix, view_matrix);

        //World render
        {
            c.glUniformMatrix4fv(view_projection_matrix_index, 1, c.GL_FALSE, view_projection_matrix.get_data());

            //Texture
            const bind_point = 0;
            png_texture.bind(bind_point);
            c.glUniform1i(texture_index, bind_point);

            //world.render(model_matrix_index);
        }


        //TestBox Renders
        {
            var box_model_index = c.glGetUniformLocation(color_shader.shader_program, "model_matrix");
            var box_color_index = c.glGetUniformLocation(color_shader.shader_program, "color");

            c.glUseProgram(color_shader.shader_program);
            c.glUniformMatrix4fv( c.glGetUniformLocation(color_shader.shader_program, "view_projection_matrix"), 1, c.GL_FALSE, view_projection_matrix.get_data());
            test_box1.render(box_model_index, box_color_index);
            test_box2.render(box_model_index, box_color_index);
        }

        glfw.refreshWindow(window);

        frameCount += 1;
        var currentTime = glfw.getTime();
        if ((currentTime - 1.0) > lastTime) {
            //try stdout.print("FPS: {}\n", .{frameCount});
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

        var mouse_axes = glfw.input.getMouseAxes();
        const mouse_sensitivity: f32 = 25.0;

        {
            var pitchRotate: f32 = mouse_axes[1] / mouse_sensitivity;
            if(glfw.input.getKeyDown(c.GLFW_KEY_UP)) {
                pitchRotate += 1.0;
            }
            if(glfw.input.getKeyDown(c.GLFW_KEY_DOWN)) {
                pitchRotate -= 1.0;
            }
            transform.rotate(quat.from_axis(pitchRotate * rotateSpeed * timeStep, transform.getLeft()));
        }

        {
            var yawRotate: f32 = -mouse_axes[0] / mouse_sensitivity;
            if(glfw.input.getKeyDown(c.GLFW_KEY_LEFT)) {
                yawRotate += 1.0;
            }
            if(glfw.input.getKeyDown(c.GLFW_KEY_RIGHT)) {
                yawRotate -= 1.0;
            }
            transform.rotate(quat.from_axis(yawRotate * rotateSpeed * timeStep, vec3.up()));
        }
}