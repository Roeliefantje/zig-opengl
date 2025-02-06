pub const packages = struct {
    pub const @"122022ea6df16700e521078c20d7d01f894c6f967e6c6ce1ea166426b4fc61667de3" = struct {
        pub const build_root = "C:\\Users\\roeld\\AppData\\Local\\zig\\p\\122022ea6df16700e521078c20d7d01f894c6f967e6c6ce1ea166426b4fc61667de3";
        pub const build_zig = @import("122022ea6df16700e521078c20d7d01f894c6f967e6c6ce1ea166426b4fc61667de3");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "glfw", "12207be469bad84baed2ede75cf89ede37e1ed5ee8be62a54d2b2112c5f56a44cc89" },
        };
    };
    pub const @"1220563c3d5603a02e61293c2c0223e01a3f298fb606bf0d108293b925434970a207" = struct {
        pub const available = false;
    };
    pub const @"12207be469bad84baed2ede75cf89ede37e1ed5ee8be62a54d2b2112c5f56a44cc89" = struct {
        pub const build_root = "C:\\Users\\roeld\\AppData\\Local\\zig\\p\\12207be469bad84baed2ede75cf89ede37e1ed5ee8be62a54d2b2112c5f56a44cc89";
        pub const build_zig = @import("12207be469bad84baed2ede75cf89ede37e1ed5ee8be62a54d2b2112c5f56a44cc89");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "xcode_frameworks", "122098b9174895f9708bc824b0f9e550c401892c40a900006459acf2cbf78acd99bb" },
            .{ "vulkan_headers", "1220e3bb588011412a21b05e2372b8261434bc174dce61139c8450e05bc8f0609735" },
            .{ "wayland_headers", "1220563c3d5603a02e61293c2c0223e01a3f298fb606bf0d108293b925434970a207" },
            .{ "x11_headers", "1220e79da2d5efd5e9dd8b6453f83a9ec79534e2e203b3331766b81e49171f3db474" },
        };
    };
    pub const @"122098b9174895f9708bc824b0f9e550c401892c40a900006459acf2cbf78acd99bb" = struct {
        pub const available = false;
    };
    pub const @"12209d8a018832bee15d9da29a12fa753d89b56cd843cdf1f39501546c6467e38ba1" = struct {
        pub const build_root = "C:\\Users\\roeld\\AppData\\Local\\zig\\p\\12209d8a018832bee15d9da29a12fa753d89b56cd843cdf1f39501546c6467e38ba1";
        pub const build_zig = @import("12209d8a018832bee15d9da29a12fa753d89b56cd843cdf1f39501546c6467e38ba1");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"1220e3bb588011412a21b05e2372b8261434bc174dce61139c8450e05bc8f0609735" = struct {
        pub const available = true;
        pub const build_root = "C:\\Users\\roeld\\AppData\\Local\\zig\\p\\1220e3bb588011412a21b05e2372b8261434bc174dce61139c8450e05bc8f0609735";
        pub const build_zig = @import("1220e3bb588011412a21b05e2372b8261434bc174dce61139c8450e05bc8f0609735");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"1220e79da2d5efd5e9dd8b6453f83a9ec79534e2e203b3331766b81e49171f3db474" = struct {
        pub const available = false;
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "zigglgen", "12209d8a018832bee15d9da29a12fa753d89b56cd843cdf1f39501546c6467e38ba1" },
    .{ "mach-glfw", "122022ea6df16700e521078c20d7d01f894c6f967e6c6ce1ea166426b4fc61667de3" },
};
