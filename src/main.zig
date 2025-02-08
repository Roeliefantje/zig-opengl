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

pub fn main() !void {
    glfw.setErrorCallback(logGLFWError);

    const width: u32 = 1024;
    const height: u32 = 1024;
    var frame: u32 = 0;

    if (!glfw.init(.{})) {
        glfw_log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        return error.GLFWInitFailed;
    }
    defer glfw.terminate();

    // Create our window, specifying that we want to use OpenGL.
    const window = glfw.Window.create(width, height, "mach-glfw + OpenGL", null, null, .{
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

    const tex_out = img.empty_tex(width, height, gl.RGBA32F, gl.RGBA, gl.FLOAT);
    const tex_mask = img.empty_tex(width, height, gl.R32F, gl.RED, gl.FLOAT);
    const tex_sort_help = img.empty_tex(width, height, gl.R32F, gl.RED, gl.FLOAT);

    const mask_program = try shader.create_compute_program(std.heap.page_allocator, "src/shader/compute/threshold.glsl");
    const filter_program = try shader.create_compute_program(std.heap.page_allocator, "src/shader/compute/create_pre_filter.glsl");
    const sort_program = try shader.create_compute_program(std.heap.page_allocator, "src/shader/compute/bitonic_sort.glsl");
    defer gl.DeleteProgram(mask_program);
    defer gl.DeleteProgram(filter_program);
    defer gl.DeleteProgram(sort_program);

    //Setup stuffs for mask program

    gl.UseProgram(mask_program);

    var mainTexUniform = gl.GetUniformLocation(mask_program, "mainTex");
    if (mainTexUniform != -1) {
        gl.Uniform1i(mainTexUniform, 0); // tell the shader to use texture unit 0 for mainTex
    }

    gl.BindImageTexture(
        0,
        tex_mask,
        0,
        gl.FALSE,
        0,
        gl.READ_WRITE,
        gl.R32F,
    );

    var resolution_uniform = gl.GetUniformLocation(mask_program, "iResolution");
    gl.Uniform2i(resolution_uniform, @intCast(width), @intCast(height));

    // const frame_uniform = gl.GetUniformLocation(mask_program, "frame");
    // gl.Uniform1i(frame_uniform, @intCast(frame));

    //Setup stuffs for filter program

    gl.UseProgram(filter_program);

    resolution_uniform = gl.GetUniformLocation(filter_program, "iResolution");
    gl.Uniform2i(resolution_uniform, @intCast(width), @intCast(height));

    //Setup stuffs for sort program

    gl.UseProgram(sort_program);

    mainTexUniform = gl.GetUniformLocation(mask_program, "mainTex");
    if (mainTexUniform != -1) {
        gl.Uniform1i(mainTexUniform, 0); // tell the shader to use texture unit 0 for mainTex
    }

    resolution_uniform = gl.GetUniformLocation(sort_program, "iResolution");
    gl.Uniform2i(resolution_uniform, @intCast(width), @intCast(height));

    //SETUP TEXTURE FOR EVERYONE THAT NEEDS IT

    gl.ActiveTexture(gl.TEXTURE0);
    // gl.BindTexture(gl.TEXTURE_2D, mask_program);
    // gl.BindTexture(gl.TEXTURE_2D, sort_program);
    var image = try img.load_image("src/data/lena-sample.png");
    var texture = try img.tex_from_image(image);
    // gl.Bindtexture(gl.TEXTURE_2D, texture);
    defer gl.DeleteTextures(1, (&texture)[0..1]);
    defer texture = 0;
    image.deinit();

    var fbo: c_uint = undefined;
    gl.GenFramebuffers(1, (&fbo)[0..1]);
    gl.BindFramebuffer(gl.FRAMEBUFFER, fbo);
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex_out, 0);
    gl.BindFramebuffer(gl.READ_FRAMEBUFFER, fbo);
    gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, 0);

    main_loop: while (true) {
        glfw.pollEvents();

        // Exit the main loop if the user is trying to close the window.
        if (window.shouldClose()) break :main_loop;

        {
            frame += 1;
            gl.ClearColor(0, 0, 0, 0);
            gl.Clear(gl.COLOR_BUFFER_BIT);

            gl.UseProgram(mask_program);
            defer gl.UseProgram(0);
            // gl.Uniform1i(frame_uniform, @intCast(frame));
            // std.debug.print("The number is: {}\n", .{frame});

            gl.BindImageTexture(
                0,
                tex_mask,
                0,
                gl.FALSE,
                0,
                gl.READ_WRITE,
                gl.R32F,
            );

            gl.DispatchCompute(1, height, 1);
            gl.MemoryBarrier(gl.SHADER_IMAGE_ACCESS_BARRIER_BIT);

            gl.BindImageTexture(0, 0, 0, gl.FALSE, 0, gl.READ_WRITE, gl.R32F);

            gl.UseProgram(filter_program);
            // gl.Uniform1i(frame_uniform, @intCast(frame));
            // std.debug.print("The number is: {}\n", .{frame});

            gl.BindImageTexture(
                0,
                tex_sort_help,
                0,
                gl.FALSE,
                0,
                gl.WRITE_ONLY,
                gl.R32F,
            );

            gl.BindImageTexture(
                1,
                tex_mask,
                0,
                gl.FALSE,
                0,
                gl.READ_ONLY,
                gl.R32F,
            );

            gl.DispatchCompute(1, height, 1);
            gl.MemoryBarrier(gl.SHADER_IMAGE_ACCESS_BARRIER_BIT);

            gl.BindImageTexture(0, 0, 0, gl.FALSE, 0, gl.WRITE_ONLY, gl.R32F);

            gl.UseProgram(sort_program);

            gl.BindImageTexture(
                0,
                tex_out,
                0,
                gl.FALSE,
                0,
                gl.READ_WRITE,
                gl.RGBA32F,
            );

            gl.BindImageTexture(
                1,
                tex_sort_help,
                0,
                gl.FALSE,
                0,
                gl.READ_WRITE,
                gl.R32F,
            );

            gl.DispatchCompute(1, height, 1);
            gl.MemoryBarrier(gl.SHADER_IMAGE_ACCESS_BARRIER_BIT);

            // // update texture to proper size and update uniform if the height and width changes.
            // const framebuffer_size = window.getFramebufferSize();
            // if (framebuffer_size.height != height or framebuffer_size.width != width) {
            //     height = framebuffer_size.height;
            //     width = framebuffer_size.width;
            //     gl.ActiveTexture(gl.TEXTURE1);
            //     gl.BindTexture(gl.TEXTURE_2D, tex_out);
            //     gl.TexImage2D(
            //         gl.TEXTURE_2D,
            //         0,
            //         gl.RGBA32F,
            //         @as(c_int, @intCast(width)),
            //         @as(c_int, @intCast(height)),
            //         0,
            //         gl.RGBA,
            //         gl.FLOAT,
            //         null,
            //     );
            //     gl.Uniform2i(resolution_uniform, @intCast(width), @intCast(height));
            // }

            // //Bind again after potentially modifying other texture.
            // gl.ActiveTexture(gl.TEXTURE0);
            // gl.BindTexture(mask_program, texture);
            // gl.ActiveTexture(gl.TEXTURE0);
            // gl.BindTexture(gl.TEXTURE_2D, texture);

            // gl.BindVertexArray(vao);
            // defer gl.BindVertexArray(0);
            gl.BlitFramebuffer(
                0,
                0,
                @intCast(width),
                @intCast(height),
                0,
                0,
                @intCast(width),
                @intCast(height),
                gl.COLOR_BUFFER_BIT,
                gl.LINEAR,
            );
            // gl.FrameBufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex_out, 0);
            // gl.DrawElements(gl.TRIANGLES, square.indices.len, gl.UNSIGNED_BYTE, 0);
        }

        window.swapBuffers();
    }
}
