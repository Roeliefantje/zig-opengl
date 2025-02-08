const std = @import("std");
const c = @cImport({
    @cInclude("stb_image.h");
});
const gl = @import("gl");

const log = std.log.scoped(.stb_image);

/// Basic representation of an image
pub const Image = struct {
    width: i32 = 0,
    height: i32 = 0,
    nchan: i32 = 0,
    data: [*]u8 = undefined,

    pub fn deinit(self: *Image) void {
        c.stbi_image_free(self.data);
        self.width = 0;
        self.height = 0;
        self.nchan = 0;
        self.data = undefined;
        self.* = undefined;
    }
};

/// Load an image from a file
pub fn load_image(filename: []const u8) !Image {
    c.stbi_set_flip_vertically_on_load(1);
    var img = Image{};

    const filename_c = @as([*c]const u8, &filename[0]);
    const iptr: usize = @intFromPtr(c.stbi_load(filename_c, @as([*c]i32, &img.width), @as([*c]i32, &img.height), @as([*c]i32, &img.nchan), 0));
    if (iptr == 0) {
        log.err("Error loading image {s} - check that the file exists at the given path", .{filename});
        return error.LoadError;
    }

    img.data = @ptrFromInt(iptr);
    return img;
}

/// Load an image from raw bytes in memory
pub fn load_image_from_memory(buf: []const u8) !Image {
    var img = Image{};
    const iptr: usize = @intFromPtr(c.stbi_load_from_memory(@as([*c]const u8, &buf[0]), @intCast(buf.len), @as([*c]i32, &img.width), @as([*c]i32, &img.height), @as([*c]i32, &img.nchan), 0));

    if (iptr == 0) {
        log.err("Error loading image from memory - unsupported format or corrupted data?", .{});
        return error.LoadError;
    }

    img.data = @ptrFromInt(iptr);
    return img;
}

pub fn tex_from_image(img: Image) !c_uint {
    var texture: c_uint = undefined;
    gl.GenTextures(1, (&texture)[0..1]);
    gl.BindTexture(gl.TEXTURE_2D, texture);

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    std.debug.print("Image loaded: width={}, height={}, nchan={}, data_ptr={*}\n", .{ img.width, img.height, img.nchan, img.data });

    const internal_format: c_int = if (img.nchan == 3) gl.RGB else gl.RGBA;
    const format: c_uint = if (img.nchan == 3) gl.RGB else gl.RGBA;
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1);
    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        internal_format,
        @as(c_int, @intCast(@divTrunc(img.width, 1))),
        @as(c_int, @intCast(@divTrunc(img.height, 1))),
        0,
        format,
        gl.UNSIGNED_BYTE,
        @as([*c]const u8, img.data),
    );

    gl.GenerateMipmap(gl.TEXTURE_2D);

    return texture;
}

pub fn empty_tex(
    width: u32,
    height: u32,
    internal_format: c_int,
    format: c_uint,
    data_type: c_uint,
) c_uint {
    var tex: c_uint = undefined;
    gl.GenTextures(1, (&tex)[0..1]);
    gl.ActiveTexture(gl.TEXTURE31);
    gl.BindTexture(gl.TEXTURE_2D, tex);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        internal_format,
        @as(c_int, @intCast(width)),
        @as(c_int, @intCast(height)),
        0,
        format,
        data_type,
        null,
    );

    return tex;
}

/// Free the data associated with an Image
pub fn free_image(image: *Image) void {
    image.deinit();
}
