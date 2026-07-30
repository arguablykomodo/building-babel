const std = @import("std");

pub const Tetromino = enum {
    i,
    o,
    t,
    s,
    z,
    j,
    l,

    pub fn blocks(self: Tetromino, x: i16, y: i16, rotation: u2) [4][2]i16 {
        var block_shape: [4][2]i16 = switch (self) {
            .i => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 3, 0 } },
            .o => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 0, 1 }, .{ 1, 1 } },
            .t => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 1, 1 } },
            .s => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 2, 1 } },
            .z => .{ .{ 1, 0 }, .{ 2, 0 }, .{ 0, 1 }, .{ 1, 1 } },
            .j => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 0, 1 } },
            .l => .{ .{ 0, 0 }, .{ 1, 0 }, .{ 2, 0 }, .{ 2, 1 } },
        };
        const c: [2]f32 = switch (self) {
            .o => .{ 0.5, 0.5 },
            else => .{ 1.5, 0.5 },
        };
        for (&block_shape) |*bi| {
            const bf: [2]f32 = .{ bi[0] - c[0], bi[1] - c[1] };
            const bf2 = switch (rotation) {
                0 => bf,
                1 => .{ bf[1], -bf[0] - 1.0 },
                2 => .{ -bf[0] - 1.0, -bf[1] - 1.0 },
                3 => .{ -bf[1] - 1.0, bf[0] },
            };
            const bf3 = .{ bf2[0] + c[0], bf2[1] + c[1] };
            bi.* = .{ @intFromFloat(bf3[0] + x), @intFromFloat(bf3[1] + y) };
        }
        return block_shape;
    }

    pub const Bag = struct {
        rng: std.Random,
        shapes: [7]Tetromino = .{ .i, .o, .t, .s, .z, .j, .l },
        taken: u8 = 0,

        pub fn init(rng: std.Random) Bag {
            var bag = Bag{ .rng = rng };
            bag.rng.shuffle(Tetromino, &bag.shapes);
            return bag;
        }

        pub fn grab(self: *Bag) Tetromino {
            const grabbed = self.shapes[self.taken];
            self.taken += 1;
            if (self.taken >= 7) {
                self.rng.shuffle(Tetromino, &self.shapes);
                self.taken = 0;
            }
            return grabbed;
        }
    };
};
