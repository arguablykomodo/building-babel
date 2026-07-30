const std = @import("std");
const w4 = @import("wasm4.zig");
const Board = @import("Board.zig");
const sprites = @import("sprites");

const day_colors: [4]u32 = .{
    0xe0f8cf,
    0x86c06c,
    0x306850,
    0x071821,
};

const night_colors: [4]u32 = .{
    0x9775a6,
    0x683a68,
    0x412752,
    0x2d162c,
};

var game: Board = .{};
var input: InputManager = .{};

var cloud_timer: u32 = 1000;

const InputManager = struct {
    timer: [8]u8 = [_]u8{0} ** 8,

    fn poll(self: *InputManager) u8 {
        var output: u8 = 0;
        const inputs = w4.GAMEPAD1.*;
        for (0..8) |i| {
            if (((inputs >> @intCast(i)) & 1) == 1) {
                if (@mod(self.timer[i], 12) == 0) output += @as(u8, 1) << @intCast(i);
                self.timer[i] +%= 1;
            } else self.timer[i] = 0;
        }
        return output;
    }
};

export fn start() void {
    game.init(0);
}

pub fn lerpColor(c0: u32, c1: u32, t: f32) u32 {
    const r = lerp(c0 & 0xFF0000, c1 & 0xFF0000, t);
    const g = lerp(c0 & 0x00FF00, c1 & 0x00FF00, t);
    const b = lerp(c0 & 0x0000FF, c1 & 0x0000FF, t);
    return (r & 0xFF0000) + (g & 0x00FF00) + (b & 0x0000FF);
}

fn lerp(a: u32, b: u32, t: f32) u32 {
    return @intFromFloat((1 - t) * @as(f32, @floatFromInt(a)) + t * @as(f32, @floatFromInt(b)));
}

export fn update() void {
    const inputs = input.poll();
    game.update(inputs);

    const time_of_day = @min(1.0, @as(f32, @floatFromInt(game.lines_cleared)) / 54.0);
    w4.PALETTE.* = .{
        lerpColor(day_colors[0], night_colors[0], time_of_day),
        lerpColor(day_colors[1], night_colors[1], time_of_day),
        lerpColor(day_colors[2], night_colors[2], time_of_day),
        lerpColor(day_colors[3], night_colors[3], time_of_day),
    };

    cloud_timer +%= 1;
    inline for (0..5) |i| {
        const sprite = @field(sprites, std.fmt.comptimePrint("cloud_{}", .{i}));
        const width = @field(sprites, std.fmt.comptimePrint("cloud_{}_width", .{i}));
        const height = @field(sprites, std.fmt.comptimePrint("cloud_{}_height", .{i}));
        const flags = @field(sprites, std.fmt.comptimePrint("cloud_{}_flags", .{i}));
        w4.DRAW_COLORS.* = 0x0020;
        const x: i32 = @intCast(@mod(cloud_timer / (i + 3), 160 + width));
        w4.blit(&sprite, x - width, (4 - i) * 25 + 8, width, height, flags);
    }

    game.draw();
}
