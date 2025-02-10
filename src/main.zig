const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const shader = @import("rendering/shader.zig");
const img = @import("util/image.zig");

const glfw_log = std.log.scoped(.glfw);
const gl_log = std.log.scoped(.gl);

const zgui = @import("zgui");

const c = @cImport({
    @cInclude("stb_image.h");
});

fn logGLFWError(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    glfw_log.err("{}: {s}\n", .{ error_code, description });
}

/// Procedure table that will hold loaded OpenGL functions.
var gl_procs: gl.ProcTable = undefined;

pub fn main() !void {
    glfw.setErrorCallback(logGLFWError);

    const width: u32 = 1920;
    const height: u32 = 1080;
    var frame: u32 = 0;
    // pretty cool lena: 0.201, Upper threshold: 0.594
    var lower_threshold: f32 = 0.011;
    var higher_threshold: f32 = 0.594;

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

    //Texture inits

    const tex_out = img.empty_tex(width, height, gl.RGBA32F, gl.RGBA, gl.FLOAT);
    const tex_mask = img.empty_tex(width, height, gl.R32F, gl.RED, gl.FLOAT);
    const tex_sort_help = img.empty_tex(width, height, gl.R32F, gl.RED, gl.FLOAT);

    const mask_program = try shader.create_compute_program(std.heap.page_allocator, "src/shader/compute/edge.glsl");
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

    const threshold_uniform = gl.GetUniformLocation(mask_program, "thresholds");
    gl.Uniform2f(threshold_uniform, lower_threshold, higher_threshold);

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

    var changeUpper = false;

    var last_time: f64 = @as(f64, @floatFromInt(std.time.milliTimestamp()));

    main_loop: while (true) {
        glfw.pollEvents();

        // Exit the main loop if the user is trying to close the window.
        if (window.shouldClose()) break :main_loop;
        {
            const curr_time: f64 = @as(f64, @floatFromInt(std.time.milliTimestamp())) / 1000.0;
            const delta_time: f64 = curr_time - last_time;
            last_time = curr_time;
            frame += 1;

            // std.debug.print("curr  time: {d:.3}\n", .{curr_time});
            // std.debug.print("delta time: {d:.3}\n", .{curr_time});

            // Process keypresses
            if (window.getKey(glfw.Key.h) == glfw.Action.press) {
                changeUpper = true;
            }

            if (window.getKey(glfw.Key.l) == glfw.Action.press) {
                changeUpper = false;
            }

            if (window.getKey(glfw.Key.right) == glfw.Action.press) {
                if (changeUpper) {
                    // std.debug.print("Increasing upper_threshold by {d:.3}\n", .{@as(f32, @floatCast(delta_time)) * 10});
                    higher_threshold = @min(1.0, higher_threshold + @as(f32, @floatCast(delta_time)) * 0.1);
                    std.debug.print("Increased upper_threshold to {d:.3}\n", .{higher_threshold});
                    std.debug.print("Lower Threshold: {d:.3}, Upper threshold: {d:.3}\n", .{ lower_threshold, higher_threshold });
                } else {
                    // std.debug.print("Increasing lower_threshold by {d:.3}\n", .{@as(f32, @floatCast(delta_time)) * 10});
                    lower_threshold = @min(1.0, lower_threshold + @as(f32, @floatCast(delta_time)) * 0.1);
                    std.debug.print("Increased lower_threshold to {d:.3}\n", .{lower_threshold});
                    std.debug.print("Lower Threshold: {d:.3}, Upper threshold: {d:.3}\n", .{ lower_threshold, higher_threshold });
                }
            }

            if (window.getKey(glfw.Key.left) == glfw.Action.press) {
                if (changeUpper) {
                    higher_threshold = @max(0.0, higher_threshold - @as(f32, @floatCast(delta_time)) * 0.1);
                    std.debug.print("Decreased upper_threshold to {d:.3}\n", .{higher_threshold});
                    std.debug.print("Lower Threshold: {d:.3}, Upper threshold: {d:.3}\n", .{ lower_threshold, higher_threshold });
                } else {
                    lower_threshold = @max(0.0, lower_threshold - @as(f32, @floatCast(delta_time)) * 0.1);
                    std.debug.print("Decreased lower_threshold to {d:.3}\n", .{lower_threshold});
                    std.debug.print("Lower Threshold: {d:.3}, Upper threshold: {d:.3}\n", .{ lower_threshold, higher_threshold });
                }
            }

            gl.ClearColor(0, 0, 0, 0);
            gl.Clear(gl.COLOR_BUFFER_BIT);

            gl.UseProgram(mask_program);
            defer gl.UseProgram(0);

            gl.Uniform2f(threshold_uniform, lower_threshold, higher_threshold);
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

            gl.DispatchCompute(@divFloor(width + 127, 128), height, 1);
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
