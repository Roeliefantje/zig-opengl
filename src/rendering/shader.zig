const std = @import("std");
const gl = @import("gl");
const gl_log = std.log.scoped(.gl);

pub fn compile_shader(allocator: std.mem.Allocator, path: [:0]const u8, shader_type: comptime_int) !c_uint {
    var success: c_int = undefined;
    var info_log_buf: [512:0]u8 = undefined;

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const shader_source = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(shader_source);

    const shader = gl.CreateShader(shader_type);
    if (shader == 0) return error.CreateShaderFailed;

    gl.ShaderSource(
        shader,
        1,
        (&shader_source.ptr)[0..1],
        (&@as(c_int, @intCast(shader_source.len)))[0..1],
    );
    gl.CompileShader(shader);
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(shader, info_log_buf.len, null, &info_log_buf);
        gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.CompileShaderFailed;
    }

    return shader;
}

pub fn create_compute_program(allocator: std.mem.Allocator, path: [:0]const u8) !c_uint {
    var success: c_int = undefined;
    var info_log_buf: [512:0]u8 = undefined;

    //shader compilation and program creation
    const compute_shader = try compile_shader(
        allocator,
        path,
        gl.COMPUTE_SHADER,
    );
    defer gl.DeleteShader(compute_shader);

    const program = gl.CreateProgram();
    if (program == 0) return error.CreateProgramFailed;
    errdefer gl.DeleteProgram(program);

    gl.AttachShader(program, compute_shader);
    gl.LinkProgram(program);
    gl.GetProgramiv(program, gl.LINK_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetProgramInfoLog(program, info_log_buf.len, null, &info_log_buf);
        gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.LinkProgramFailed;
    }

    return program;
}
