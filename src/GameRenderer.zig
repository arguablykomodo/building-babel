const std = @import("std");
const w4 = @import("wasm4.zig");
const Game = @import("Game.zig");

const BLOCK_SIZE = 9;
const H_RADIUS = BLOCK_SIZE * Game.WIDTH / 6;
const V_RADIUS = BLOCK_SIZE;

game: *const Game,
x_offset: f32 = 0,
y_offset: f32 = 0,

pub fn draw_block(self: @This(), x: f32, y: f32, back: bool) void {
    const circ_x = @cos((x - self.x_offset) / Game.WIDTH * std.math.tau);
    const circ_x2 = @cos((x + 1 - self.x_offset) / Game.WIDTH * std.math.tau);
    const circ_y = @sin((x - self.x_offset) / Game.WIDTH * std.math.tau);

    if (back and circ_y >= 0) return;
    if (!back and circ_y < 0) return;

    var screen_x: i32 = @intFromFloat(circ_x * H_RADIUS + 80);
    var screen_x2: i32 = @intFromFloat(circ_x2 * H_RADIUS + 80);
    if (screen_x > screen_x2) std.mem.swap(i32, &screen_x, &screen_x2);
    const screen_y: i32 = @intFromFloat(circ_y * V_RADIUS + y * BLOCK_SIZE + BLOCK_SIZE);
    w4.rect(screen_x - 40, screen_y, @intCast(screen_x2 - screen_x), BLOCK_SIZE);
}

pub fn draw_grid(self: @This(), back: bool) void {
    for (self.game.grid, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell) self.draw_block(@floatFromInt(x), @as(f32, @floatFromInt(y)) - self.y_offset, back);
        }
    }
    for (0..4) |y| {
        for (0..Game.WIDTH) |x| {
            self.draw_block(@floatFromInt(x), Game.HEIGHT + @as(f32, @floatFromInt(y)) - self.y_offset, back);
        }
    }
}

pub fn draw_shadow(self: @This()) void {
    var shadow_y: i16 = 0;
    while (!self.game.collides(0, shadow_y + 1, 0)) shadow_y += 1;
    const blocks = self.game.tetromino.blocks(
        self.game.player_x,
        self.game.player_y + shadow_y,
        self.game.rotation,
    );
    for (blocks) |block| {
        const x_wrapped = @mod(block[0], Game.WIDTH);
        self.draw_block(x_wrapped, block[1], false);
    }
}

pub fn draw(self: *@This()) void {
    self.x_offset = std.math.lerp(self.x_offset, self.game.player_x - Game.WIDTH / 4 + 1, 0.1);
    self.y_offset *= 0.9;

    w4.DRAW_COLORS.* = 0x43;
    for (self.game.tetromino.blocks(
        self.game.player_x,
        self.game.player_y,
        self.game.rotation,
    )) |block| self.draw_block(block[0], block[1], true);
    self.draw_grid(true);

    w4.DRAW_COLORS.* = 0x20;
    self.draw_shadow();

    w4.DRAW_COLORS.* = 0x32;
    self.draw_grid(false);
    for (self.game.tetromino.blocks(
        self.game.player_x,
        self.game.player_y,
        self.game.rotation,
    )) |block| self.draw_block(block[0], block[1], false);
}
