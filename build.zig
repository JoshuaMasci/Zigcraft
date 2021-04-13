const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    var exe = b.addExecutable("ZigCraft", "src/main.zig");

    exe.setBuildMode(mode);
    exe.install();

    //zalgebra
    const zalgebra = Pkg {
        .name = "zalgebra",
        .path = "zalgebra/src/main.zig"
    };
    exe.addPackage(zalgebra);

    //glfw
    exe.addIncludeDir("C:/zig_glfw/include");
    exe.addLibPath("C:/zig_glfw/build/src/Release");

    //opengl
    exe.addIncludeDir("glad/include");
    exe.addCSourceFile("glad/src/glad.c", &[_][]const u8{"-std=c99"});
    exe.linkSystemLibrary("glfw3");

    exe.linkLibC();

    //OS specific libraries
    switch (builtin.os.tag) {
        .windows => {
            exe.linkSystemLibrary("kernel32");
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("shell32");
            exe.linkSystemLibrary("gdi32");
        },
        .linux => {
            //Add linux libraries if needed
        },
        else => {
            @compileError("Platform not supported, unsure of build requirements");
        },
    }

    const play = b.step("run", "Run the game");
    const run = exe.run();
    run.step.dependOn(b.getInstallStep());
    play.dependOn(&run.step);
}

