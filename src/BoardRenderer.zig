const std = @import("std");
const w4 = @import("wasm4.zig");
const Board = @import("Board.zig");

pub const BLOCK_SIZE = 9;
const H_RADIUS = BLOCK_SIZE * Board.WIDTH / 6;
const V_RADIUS = BLOCK_SIZE;

game: *const Board,
x_offset: f32 = Board.WIDTH,
y_offset: f32 = 200,

fn draw_block(self: @This(), x: f32, y: f32, back: bool) void {
    const circ_x = @cos((x - (self.x_offset - Board.WIDTH / 4 + 1)) / Board.WIDTH * std.math.tau);
    const circ_x2 = @cos((x + 1 - (self.x_offset - Board.WIDTH / 4 + 1)) / Board.WIDTH * std.math.tau);
    const circ_y = @sin((x - (self.x_offset - Board.WIDTH / 4 + 1)) / Board.WIDTH * std.math.tau);

    if (back and circ_y >= 0) return;
    if (!back and circ_y < 0) return;

    var screen_x: i32 = @intFromFloat(circ_x * H_RADIUS + 80);
    var screen_x2: i32 = @intFromFloat(circ_x2 * H_RADIUS + 80);
    if (screen_x > screen_x2) std.mem.swap(i32, &screen_x, &screen_x2);
    const screen_y: i32 = @intFromFloat(circ_y * V_RADIUS + y * BLOCK_SIZE + BLOCK_SIZE);
    w4.rect(screen_x - 40, screen_y - @as(i32, @intFromFloat(self.y_offset)), @intCast(screen_x2 - screen_x), BLOCK_SIZE);
}

fn draw_grid(self: @This(), back: bool) void {
    for (self.game.grid, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell) self.draw_block(@floatFromInt(x), @as(f32, @floatFromInt(y)), back);
        }
    }
    for (0..3 + @as(usize, @intFromFloat(self.y_offset))) |y| {
        for (0..Board.WIDTH) |x| {
            self.draw_block(@floatFromInt(x), Board.HEIGHT + @as(f32, @floatFromInt(y)), back);
        }
    }
}

fn draw_shadow(self: @This()) void {
    var shadow_y: i16 = 0;
    while (!self.game.collides(0, shadow_y + 1, 0)) shadow_y += 1;
    const blocks = self.game.tetromino.blocks(
        self.game.player_x,
        self.game.player_y + shadow_y,
        self.game.rotation,
    );
    for (blocks) |block| {
        const x_wrapped = @mod(block[0], Board.WIDTH);
        self.draw_block(x_wrapped, block[1], false);
    }
}

pub fn update(self: *@This()) void {
    if (self.y_offset < 10) self.y_offset *= 0.9 else self.y_offset -= 1;
    self.x_offset = if (@abs(self.x_offset - self.game.player_x) < 1.0)
        std.math.lerp(self.x_offset, self.game.player_x, 0.1)
    else
        self.x_offset - @as(f32, @floatFromInt(std.math.sign(self.x_offset - self.game.player_x))) * 0.1;
}

pub fn draw(self: @This()) void {
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

pub fn set_time_of_day(self: *const @This()) void {
    const time_of_day = @min(1.0, @as(f32, @floatFromInt(self.game.lines_cleared)) / 54.0);
    w4.PALETTE.* = .{
        lerpColor(day_colors[0], night_colors[0], time_of_day),
        lerpColor(day_colors[1], night_colors[1], time_of_day),
        lerpColor(day_colors[2], night_colors[2], time_of_day),
        lerpColor(day_colors[3], night_colors[3], time_of_day),
    };
}

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

pub fn lerpColor(c0: u32, c1: u32, t: f32) u32 {
    const r = lerp(c0 & 0xFF0000, c1 & 0xFF0000, t);
    const g = lerp(c0 & 0x00FF00, c1 & 0x00FF00, t);
    const b = lerp(c0 & 0x0000FF, c1 & 0x0000FF, t);
    return (r & 0xFF0000) + (g & 0x00FF00) + (b & 0x0000FF);
}

fn lerp(a: u32, b: u32, t: f32) u32 {
    return @intFromFloat((1 - t) * @as(f32, @floatFromInt(a)) + t * @as(f32, @floatFromInt(b)));
}
