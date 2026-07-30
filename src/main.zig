const std = @import("std");
const w4 = @import("wasm4.zig");
const Game = @import("Game.zig");
const Title = @import("Title.zig");
const sprites = @import("sprites");

var rng: std.Random.DefaultPrng = std.Random.DefaultPrng.init(0);
var input: InputManager = .{};
var game: Game = .{};
var cloud_timer: u32 = 1000;
var title: Title = undefined;

var game_started: bool = false;

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
    title = Title.init(rng.random());
    game.init(rng.random());
}

export fn update() void {
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

    const inputs = input.poll();
    if (game_started) {
        if (game.game_over and inputs & w4.BUTTON_2 != 0) {
            game = .{};
            game.init(rng.random());
            game_started = false;
        }
        game.update(inputs);
    } else {
        if (inputs & w4.BUTTON_1 != 0) {
            game.init(rng.random());
            game_started = true;
        }
        title.update();
        title.draw();
    }
    game.draw();
}
