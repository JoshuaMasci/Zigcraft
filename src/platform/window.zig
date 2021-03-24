const glfw = @import("glfw.zig");
const opengl = @import("opengl.zig");
const std = @import("std");
const panic = std.debug.panic;

pub const Window = struct {
    const Self = @This();

    handle: *glfw.GLFWwindow,

    pub fn init(width: i32, height: i32, title: [:0]const u8) Self {
        glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 4);
        glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 6);
        glfw.glfwWindowHint(glfw.GLFW_OPENGL_FORWARD_COMPAT, glfw.GL_TRUE);
        glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);
        glfw.glfwWindowHint(glfw.GLFW_DEPTH_BITS, 0);
        glfw.glfwWindowHint(glfw.GLFW_STENCIL_BITS, 8);
        //glfw.glfwWindowHint(glfw.GLFW_OPENGL_DEBUG_CONTEXT, debug_gl.is_on);
        glfw.glfwWindowHint(glfw.GLFW_RESIZABLE, glfw.GL_TRUE);

        var handle = glfw.glfwCreateWindow(width, height, title, null, null) orelse {
            panic("Failed to create window\n", .{});
        };

        glfw.glfwMakeContextCurrent(handle);

        if (opengl.gladLoadGLLoader(@ptrCast(opengl.GLADloadproc, glfw.glfwGetProcAddress)) == 0) {
            panic("Failed to initialise GLAD\n", .{});
        }

        opengl.glClearColor(0.7, 0.1, 0.85, 1.0);
        glfw.glfwSwapInterval(1);

        return Self{ .handle = handle };
    }

    pub fn deinit(self: *Self) void {
        defer glfw.glfwDestroyWindow(self.handle);
    }

    pub fn refresh(self: *Self) void {

        opengl.glClear(opengl.GL_COLOR_BUFFER_BIT | opengl.GL_DEPTH_BUFFER_BIT | opengl.GL_STENCIL_BUFFER_BIT);
        glfw.glfwSwapBuffers(self.handle);
        glfw.glfwPollEvents();
    }

    pub fn shouldClose(self: *Self) bool {
        return glfw.glfwWindowShouldClose(self.handle) == 0;
    }
};