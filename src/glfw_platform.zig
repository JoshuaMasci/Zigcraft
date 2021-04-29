const c = @import("c.zig");

const std = @import("std");
const panic = std.debug.panic;

const ArrayList = std.ArrayList;

const GeneralPurposeAllocator: type = std.heap.GeneralPurposeAllocator(.{});

fn glfwErrorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    panic("Error: {}\n", .{@as([*:0]const u8, description)});
}

fn glfwKeyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    if (action == c.GLFW_PRESS) {
        input.setKeyState(@intCast(usize, key), true);
    }
    else if (action == c.GLFW_RELEASE) {
        input.setKeyState(@intCast(usize, key), false);
    }
}

//Global Variables/Functions
var globalAllocator: GeneralPurposeAllocator = undefined;

pub fn init() void {
    globalAllocator = GeneralPurposeAllocator{};
    windowMap = WindowHashMap.init(&globalAllocator.allocator);

    _ = c.glfwSetErrorCallback(glfwErrorCallback);
    if (c.glfwInit() == c.GL_FALSE) {
        panic("Failed to initialise glfw\n", .{});
    }

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_DEPTH_BITS, 24);
    c.glfwWindowHint(c.GLFW_STENCIL_BITS, 8);
    //c.glfwWindowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, debug_gl.is_on);
    c.glfwWindowHint(c.GLFW_RESIZABLE, c.GL_TRUE);
}

pub fn deinit() void {
    c.glfwTerminate();
    windowMap.deinit();
    const leaked = globalAllocator.deinit();
    if (leaked) panic("Error: memory leaked", .{});
}

pub fn update() void {
    input.update();
    c.glfwPollEvents();
}

pub fn getTime() f64 {
    return c.glfwGetTime();
}

//Window Variables/Functions
pub const WindowId = usize;
const WindowHashMap = std.AutoHashMap(WindowId, *c.GLFWwindow);
var nextWindowId: WindowId = 0;
var windowMap: WindowHashMap = undefined;
pub fn createWindow(width: i32, height: i32, title: [:0]const u8) WindowId {
    var handle = c.glfwCreateWindow(width, height, title, null, null) orelse {
        panic("Failed to create window", .{});
    };
    c.glfwMakeContextCurrent(handle);
    _ = c.glfwSetKeyCallback(handle, glfwKeyCallback);

    c.glfwMaximizeWindow(handle);

    if (nextWindowId == 0) {
        //Load Glad if this is the first window
        if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress)) == 0) {
            panic("Failed to initialise GLAD", .{});
        }

        var major_ver: c.GLint = undefined;
        var minor_ver: c.GLint = undefined;
        c.glGetIntegerv(c.GL_MAJOR_VERSION, &major_ver);
        c.glGetIntegerv(c.GL_MINOR_VERSION, &minor_ver);
        var vendor_name = c.glGetString(c.GL_VENDOR);
        var device_name = c.glGetString(c.GL_RENDERER);
        const stdout = std.io.getStdOut().writer();
        stdout.print("Opengl Initialized\n", .{}) catch {};
        stdout.print("Opengl Version: {}.{}\n", .{major_ver, minor_ver}) catch {};
        stdout.print("Devcie Vendor: {s}\n", .{vendor_name}) catch {};
        stdout.print("Device Name: {s}\n", .{device_name}) catch {};
        stdout.print("\n", .{}) catch {};
    }

    windowMap.put(nextWindowId, handle) catch panic("Failed to add window Id", .{});
    var windowId = nextWindowId;
    nextWindowId += 1;
    return windowId;
}

pub fn destoryWindow(windowId: WindowId) void {
    if (windowMap.contains(windowId)) {
        var handle = windowMap.remove(windowId).?.value;
        c.glfwDestroyWindow(handle);
    }
}

pub fn refreshWindow(windowId: WindowId) void {
    if (windowMap.contains(windowId)) {
        c.glfwSwapBuffers(windowMap.get(windowId).?);
    }
}

pub fn shouldCloseWindow(windowId: WindowId) bool {
    if (windowMap.contains(windowId)) {
        return c.glfwWindowShouldClose(windowMap.get(windowId).?) == 0;
    }
    return false;
}

pub fn getWindowSize(windowId: WindowId) [2]i32 {
    var size: [2]i32 = undefined;
    if (windowMap.contains(windowId)) {
        var cSize: [2]c_int = undefined;
        c.glfwGetFramebufferSize(windowMap.get(windowId).?, &cSize[0], &cSize[1]);
        size[0] = @intCast(i32, cSize[0]);
        size[1] = @intCast(i32, cSize[1]);
    }
    return size;
}

pub fn getWindowHandle(self: *Self) *c.GLFWwindow {
    if (windowMap.contains(windowId)) {
        return windowMap.get(windowId).?;
    }
    panic("Tried to get handle for invalid window");
}

//Input Variables/Functions
const KeyboardButtonCount: usize = c.GLFW_KEY_LAST;
const ButtonInput = struct {
    current_state: bool = false,
    prev_state: bool = false,
};
pub var input = struct {
    const Self = @This();

    keyboard_buttons: [KeyboardButtonCount]ButtonInput,

    pub fn init() Self {
        return Self {
            .keyboard_buttons = [_]ButtonInput{.{}} ** KeyboardButtonCount,
        };
    }

    pub fn update(self: *Self) void {
        for (self.keyboard_buttons) |*button| {
            button.prev_state = button.current_state;
        }
    }

    pub fn setKeyState(self: *Self, key: usize, state: bool) void {
        self.keyboard_buttons[key].current_state = state;
    }

    pub fn getKeyDown(self: *Self, key: usize) bool {
        return self.keyboard_buttons[key].current_state == true;
    }

    pub fn getKeyPressed(self: *Self, key: usize) bool {
        var button = self.keyboard_buttons[key];
        return button.current_state == true and button.prev_state == false;
    }
}.init();