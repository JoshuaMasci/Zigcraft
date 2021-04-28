pub usingnamespace @cImport({
    @cInclude("glad/glad.h");

    @cDefine("STBI_ONLY_PNG", "");
    @cDefine("STBI_NO_STDIO", "");
    @cInclude("stb_image.h");
    
    @cInclude("GLFW/glfw3.h");
});