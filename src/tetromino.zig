pub const Tetromino = enum {
    i,
    o,
    t,
    s,
    z,
    j,
    l,

    pub fn shape(self: Tetromino) [4][2]i16 {
        return switch (self) {
            .i => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 3, 0 } },
            .o => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 0, 1 }, .{ 1, 1 } },
            .t => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 1, 1 } },
            .s => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 2, 1 } },
            .z => .{ .{ 1, 0 }, .{ 2, 0 }, .{ 0, 1 }, .{ 1, 1 } },
            .j => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 0, 1 } },
            .l => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 2, 1 } },
        };
    }

    pub fn center(self: Tetromino) [2]f32 {
        return switch (self) {
            .o => .{ 0.5, 0.5 },
            else => .{ 1.5, 0.5 },
        };
    }

    pub fn blocks(self: Tetromino, rotation: u8) [4][2]i16 {
        var block_shape = self.shape();
        const c = self.center();
        for (&block_shape) |*bi| {
            const bf: [2]f32 = .{ bi[0] - c[0], bi[1] - c[1] };
            const bf2 = switch (@mod(rotation, 4)) {
                0 => bf,
                1 => .{ bf[1], -bf[0] - 1.0 },
                2 => .{ -bf[0] - 1.0, -bf[1] - 1.0 },
                3 => .{ -bf[1] - 1.0, bf[0] },
                else => bf,
            };
            const bf3 = .{ bf2[0] + c[0], bf2[1] + c[1] };
            bi.* = .{ @intFromFloat(bf3[0]), @intFromFloat(bf3[1]) };
        }
        return block_shape;
    }
};
