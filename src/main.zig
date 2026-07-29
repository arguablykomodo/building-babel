const std = @import("std");
const w4 = @import("wasm4.zig");
const Game = @import("Game.zig");
const sprites = @import("sprites");

var game: Game = undefined;
var input: InputManager = .{};

var drop_timer: u8 = 0;
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
    game = Game.init(0);
    game.renderer = Game.Renderer{ .game = &game };
}

export fn update() void {
    cloud_timer +%= 1;
    drop_timer +%= 1;
    if (drop_timer > 60 - game.lines_cleared) {
        drop_timer = 0;
        game.soft_drop();
    }
    const inputs = input.poll();

    if (inputs & w4.BUTTON_RIGHT != 0) game.move(-1);
    if (inputs & w4.BUTTON_LEFT != 0) game.move(1);
    if (inputs & w4.BUTTON_UP != 0) game.rotate();
    if (inputs & w4.BUTTON_DOWN != 0) game.soft_drop();
    if (inputs & w4.BUTTON_1 != 0) game.hard_drop();

    inline for (0..5) |i| {
        const sprite = @field(sprites, std.fmt.comptimePrint("cloud_{}", .{i}));
        const width = @field(sprites, std.fmt.comptimePrint("cloud_{}_width", .{i}));
        const height = @field(sprites, std.fmt.comptimePrint("cloud_{}_height", .{i}));
        const flags = @field(sprites, std.fmt.comptimePrint("cloud_{}_flags", .{i}));
        w4.DRAW_COLORS.* = 0x0020;
        const x: i32 = @intCast(@mod(cloud_timer / (i + 3), 160 + width));
        w4.blit(&sprite, x - width, (4 - i) * 25 + 8, width, height, flags);
    }

    game.renderer.draw();
}
