const std = @import("std");
const panic = std.debug.panic;

pub usingnamespace @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn init(errorCallback: GLFWerrorfun) void {
    _ = glfwSetErrorCallback(errorCallback);
    if (glfwInit() == GL_FALSE) {
        panic("Failed to initialise glfw\n", .{});
    }
}

pub fn deinit() void {
    glfwTerminate();
}