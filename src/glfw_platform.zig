const c = @import("c.zig");

const std = @import("std");
const panic = std.debug.panic;

pub fn init(errorCallback: c.GLFWerrorfun) void {
    _ = c.glfwSetErrorCallback(errorCallback);
    if (c.glfwInit() == c.GL_FALSE) {
        panic("Failed to initialise glfw\n", .{});
    }
}

pub fn deinit() void {
    c.glfwTerminate();
}

pub fn update() void {
    c.glfwPollEvents();
}

pub fn getTime() f64 {
    return c.glfwGetTime();
}

pub const Window = struct {
    const Self = @This();

    handle: *c.GLFWwindow,

    pub fn init(width: i32, height: i32, title: [:0]const u8) Self {
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
        c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
        c.glfwWindowHint(c.GLFW_DEPTH_BITS, 0);
        c.glfwWindowHint(c.GLFW_STENCIL_BITS, 8);
        //c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, debug_gl.is_on);
        c.glfwWindowHint(c.GLFW_RESIZABLE, c.GL_TRUE);

        var handle = c.glfwCreateWindow(width, height, title, null, null) orelse {
            panic("Failed to create window\n", .{});
        };

        c.glfwMakeContextCurrent(handle);

        if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress)) == 0) {
            panic("Failed to initialise GLAD\n", .{});
        }

        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glfwSwapInterval(1);

        return Self{ .handle = handle };
    }

    pub fn deinit(self: *Self) void {
        defer c.glfwDestroyWindow(self.handle);
    }

    pub fn refresh(self: *Self) void {

        c.glfwSwapBuffers(self.handle);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT | c.GL_STENCIL_BUFFER_BIT);
    }

    pub fn shouldClose(self: *Self) bool {
        return c.glfwWindowShouldClose(self.handle) == 0;
    }
};