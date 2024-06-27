pub const packages = struct {
    pub const @"122058b98f7d2ac86597363d0c0515c30aea392c605d5976c600196bd2c5b08b95d6" = struct {
        pub const available = false;
    };
    pub const @"12205d131983601cdb3500f38e9d8adaed5574fb0211b8b39291d2e9b90c6555ce59" = struct {
        pub const build_root = "C:\\Users\\roeld\\AppData\\Local\\zig\\p\\12205d131983601cdb3500f38e9d8adaed5574fb0211b8b39291d2e9b90c6555ce59";
        pub const build_zig = @import("12205d131983601cdb3500f38e9d8adaed5574fb0211b8b39291d2e9b90c6555ce59");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"1220c15e66c13f9633fcfd50b5ed265f74f2950c98b1f1defd66298fa027765e0190" = struct {
        pub const build_root = "C:\\Users\\roeld\\AppData\\Local\\zig\\p\\1220c15e66c13f9633fcfd50b5ed265f74f2950c98b1f1defd66298fa027765e0190";
        pub const build_zig = @import("1220c15e66c13f9633fcfd50b5ed265f74f2950c98b1f1defd66298fa027765e0190");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "xcode_frameworks", "12205d131983601cdb3500f38e9d8adaed5574fb0211b8b39291d2e9b90c6555ce59" },
            .{ "vulkan_headers", "122058b98f7d2ac86597363d0c0515c30aea392c605d5976c600196bd2c5b08b95d6" },
            .{ "wayland_headers", "1220f350a0782d20a6618ea4e2884f7d0205a4e9b02c2d65fe3bf7b8113e7860fadf" },
            .{ "x11_headers", "1220ddf168c855cf69b4f8c5284403106a3c681913e34453df10cc5a588d9bd1d005" },
        };
    };
    pub const @"1220ddf168c855cf69b4f8c5284403106a3c681913e34453df10cc5a588d9bd1d005" = struct {
        pub const available = false;
    };
    pub const @"1220e5343c2fe2a490aa90dc52d92fd34ebfd7d0ffc7d246dd4720bb5c339ead4d7b" = struct {
        pub const build_root = "C:\\Users\\roeld\\AppData\\Local\\zig\\p\\1220e5343c2fe2a490aa90dc52d92fd34ebfd7d0ffc7d246dd4720bb5c339ead4d7b";
        pub const build_zig = @import("1220e5343c2fe2a490aa90dc52d92fd34ebfd7d0ffc7d246dd4720bb5c339ead4d7b");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "glfw", "1220c15e66c13f9633fcfd50b5ed265f74f2950c98b1f1defd66298fa027765e0190" },
        };
    };
    pub const @"1220f350a0782d20a6618ea4e2884f7d0205a4e9b02c2d65fe3bf7b8113e7860fadf" = struct {
        pub const available = false;
    };
    pub const @"1220f4188a5e1bdbb15fd50e9ea322c0721384eeba9bc077e4179b0b0eeaa7fe4ad9" = struct {
        pub const build_root = "C:\\Users\\roeld\\AppData\\Local\\zig\\p\\1220f4188a5e1bdbb15fd50e9ea322c0721384eeba9bc077e4179b0b0eeaa7fe4ad9";
        pub const build_zig = @import("1220f4188a5e1bdbb15fd50e9ea322c0721384eeba9bc077e4179b0b0eeaa7fe4ad9");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "zigglgen", "1220f4188a5e1bdbb15fd50e9ea322c0721384eeba9bc077e4179b0b0eeaa7fe4ad9" },
    .{ "mach_glfw", "1220e5343c2fe2a490aa90dc52d92fd34ebfd7d0ffc7d246dd4720bb5c339ead4d7b" },
};
