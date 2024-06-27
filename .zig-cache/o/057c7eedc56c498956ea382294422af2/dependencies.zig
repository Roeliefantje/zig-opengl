pub const packages = struct {
    pub const @"1220e5343c2fe2a490aa90dc52d92fd34ebfd7d0ffc7d246dd4720bb5c339ead4d7b" = struct {
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
