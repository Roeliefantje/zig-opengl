const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const glfw_log = std.log.scoped(.glfw);
const gl_log = std.log.scoped(.gl);

fn logGLFWError(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    glfw_log.err("{}: {s}\n", .{ error_code, description });
}

/// Procedure table that will hold loaded OpenGL functions.
var gl_procs: gl.ProcTable = undefined;

const triangle = struct {
    const vertices = [_]Vertex{
        .{ .position = .{ -0.5, -0.5, 0 } },
        .{ .position = .{ 0.5, -0.5, 0 } },
        .{ .position = .{ 0, 0.5, 0 } },
    };

    const Vertex = extern struct {
        position: Position,

        const Position = [3]f32;
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
        const vertex_shader: c_uint = gl.CreateShader(gl.VERTEX_SHADER);
        if (vertex_shader == 0) return error.CreateVertexShaderFailed;
        defer gl.DeleteShader(vertex_shader);

        gl.ShaderSource(
            vertex_shader,
            1,
            (&vertex_shader_source.ptr)[0..1],
            (&@as(c_int, @intCast(vertex_shader_source.len)))[0..1],
        );

        gl.CompileShader(vertex_shader);

        gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetShaderInfoLog(vertex_shader, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.CompileVertexShaderFailed;
        }

        const fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER);
        if (fragment_shader == 0) return error.CreateFragmentShaderFailed;
        defer gl.DeleteShader(fragment_shader);

        gl.ShaderSource(
            fragment_shader,
            1,
            (&fragment_shader_source.ptr)[0..1],
            (&@as(c_int, @intCast(fragment_shader_source.len)))[0..1],
        );
        gl.CompileShader(fragment_shader);
        gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetShaderInfoLog(fragment_shader, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.CompileFragmentShaderFailed;
        }

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

    {
        gl.BindVertexArray(vao);
        defer gl.BindVertexArray(0);

        {
            gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
            gl.BufferData(
                gl.ARRAY_BUFFER,
                @sizeOf(@TypeOf(triangle.vertices)),
                &triangle.vertices,
                gl.STATIC_DRAW,
            );

            // const position_attrib: c_uint = @intCast(gl.GetAttribLocation(program, "a_Position"));

            gl.VertexAttribPointer(
                0,
                @typeInfo(triangle.Vertex.Position).array.len,
                gl.FLOAT,
                gl.FALSE,
                @sizeOf(triangle.Vertex),
                @offsetOf(triangle.Vertex, "position"),
            );
            gl.EnableVertexAttribArray(0);
        }
    }

    main_loop: while (true) {
        glfw.pollEvents();

        // Exit the main loop if the user is trying to close the window.
        if (window.shouldClose()) break :main_loop;

        {
            gl.ClearColor(1, 1, 1, 1);
            gl.Clear(gl.COLOR_BUFFER_BIT);

            gl.UseProgram(program);
            defer gl.UseProgram(0);

            gl.BindVertexArray(vao);
            defer gl.BindVertexArray(0);

            gl.DrawArrays(gl.TRIANGLES, 0, 3);
            //             glUseProgram(shaderProgram);
            // glBindVertexArray(VAO);
            // glDrawArrays(GL_TRIANGLES, 0, 3);
        }

        window.swapBuffers();
    }
}
