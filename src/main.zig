const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const shader = @import("rendering/shader.zig");
const img = @import("util/image.zig");

const glfw_log = std.log.scoped(.glfw);
const gl_log = std.log.scoped(.gl);

const c = @cImport({
    @cInclude("stb_image.h");
});

fn logGLFWError(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    glfw_log.err("{}: {s}\n", .{ error_code, description });
}

/// Procedure table that will hold loaded OpenGL functions.
var gl_procs: gl.ProcTable = undefined;

const square = struct {
    const vertices = [_]Vertex{
        .{ .position = .{ 0.5, 0.5, 0 }, .uv = .{ 1, 1 } },
        .{ .position = .{ 0.5, -0.5, 0 }, .uv = .{ 1, 0 } },
        .{ .position = .{ -0.5, -0.5, 0 }, .uv = .{ 0, 0 } },
        .{ .position = .{ -0.5, 0.5, 0 }, .uv = .{ 0, 1 } },
    };

    const indices = [_]u8{
        0, 1, 3,
        1, 2, 3,
    };

    const Vertex = extern struct {
        position: Position,
        uv: Uv,

        const Position = [3]f32;
        const Uv = [2]f32;
    };
};

const vertex_shader_source: [:0]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\
    \\void main()
    \\{
    \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
    \\
;

const fragment_shader_source: [:0]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
    \\
;

pub fn main() !void {
    glfw.setErrorCallback(logGLFWError);

    if (!glfw.init(.{})) {
        glfw_log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        return error.GLFWInitFailed;
    }
    defer glfw.terminate();

    // Create our window, specifying that we want to use OpenGL.
    const window = glfw.Window.create(640, 480, "mach-glfw + OpenGL", null, null, .{
        .context_version_major = gl.info.version_major,
        .context_version_minor = gl.info.version_minor,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
    }) orelse {
        glfw_log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        return error.CreateWindowFailed;
    };
    defer window.destroy();

    // Make the window's OpenGL context current.
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    // Enable VSync to avoid drawing more often than necessary.
    glfw.swapInterval(1);

    // Initialize the OpenGL procedure table.
    if (!gl_procs.init(glfw.getProcAddress)) {
        gl_log.err("failed to load OpenGL functions", .{});
        return error.GLInitFailed;
    }

    // Make the OpenGL procedure table current.
    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    //Finished Window initialization

    const program = create_program: {
        var success: c_int = undefined;
        var info_log_buf: [512:0]u8 = undefined;

        //shader compilation and program creation
        const vertex_shader = try shader.compile_shader(
            std.heap.page_allocator,
            "src/shader/vertex_shader.glsl",
            gl.VERTEX_SHADER,
        );
        defer gl.DeleteShader(vertex_shader);

        const fragment_shader = try shader.compile_shader(
            std.heap.page_allocator,
            "src/shader/fragment_shader.glsl",
            gl.FRAGMENT_SHADER,
        );
        defer gl.DeleteShader(fragment_shader);

        const program = gl.CreateProgram();
        if (program == 0) return error.CreateProgramFailed;
        errdefer gl.DeleteProgram(program);

        gl.AttachShader(program, vertex_shader);
        gl.AttachShader(program, fragment_shader);
        gl.LinkProgram(program);
        gl.GetProgramiv(program, gl.LINK_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetProgramInfoLog(program, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.LinkProgramFailed;
        }

        break :create_program program;
    };
    defer gl.DeleteProgram(program);

    //VAO init
    var vao: c_uint = undefined;
    gl.GenVertexArrays(1, (&vao)[0..1]);
    defer gl.DeleteVertexArrays(1, (&vao)[0..1]);

    //VBO init and buffer transfer
    var vbo: c_uint = undefined;
    gl.GenBuffers(1, (&vbo)[0..1]);
    defer gl.DeleteBuffers(1, (&vbo)[0..1]);

    //Index buffer object (IBO)
    var ibo: c_uint = undefined;
    gl.GenBuffers(1, (&ibo)[0..1]);
    defer gl.DeleteBuffers(1, (&ibo)[0..1]);

    {
        gl.BindVertexArray(vao);
        defer gl.BindVertexArray(0);

        {
            gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
            gl.BufferData(
                gl.ARRAY_BUFFER,
                @sizeOf(@TypeOf(square.vertices)),
                &square.vertices,
                gl.STATIC_DRAW,
            );

            // const position_attrib: c_uint = @intCast(gl.GetAttribLocation(program, "a_Position"));

            gl.VertexAttribPointer(
                0,
                @typeInfo(square.Vertex.Position).array.len,
                gl.FLOAT,
                gl.FALSE,
                @sizeOf(square.Vertex),
                @offsetOf(square.Vertex, "position"),
            );
            gl.EnableVertexAttribArray(0);

            gl.VertexAttribPointer(
                1,
                @typeInfo(square.Vertex.Uv).array.len,
                gl.FLOAT,
                gl.FALSE,
                @sizeOf(square.Vertex),
                @offsetOf(square.Vertex, "uv"),
            );
            gl.EnableVertexAttribArray(1);

            // Instruct the VAO to use our IBO, then upload index data to the IBO.
            gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo);
            gl.BufferData(
                gl.ELEMENT_ARRAY_BUFFER,
                @sizeOf(@TypeOf(square.indices)),
                &square.indices,
                gl.STATIC_DRAW,
            );
        }
    }

    var image = try img.load_image("src/data/wall.jpg");
    var texture = try img.tex_from_image(image);
    defer gl.DeleteTextures(1, (&texture)[0..1]);
    defer texture = 0;
    image.deinit();

    main_loop: while (true) {
        glfw.pollEvents();

        // Exit the main loop if the user is trying to close the window.
        if (window.shouldClose()) break :main_loop;

        {
            gl.ClearColor(0, 0, 0, 0);
            gl.Clear(gl.COLOR_BUFFER_BIT);

            gl.UseProgram(program);
            defer gl.UseProgram(0);

            gl.ActiveTexture(gl.TEXTURE0);
            gl.BindTexture(gl.TEXTURE_2D, texture);

            gl.BindVertexArray(vao);
            defer gl.BindVertexArray(0);

            gl.DrawElements(gl.TRIANGLES, square.indices.len, gl.UNSIGNED_BYTE, 0);
        }

        window.swapBuffers();
    }
}
