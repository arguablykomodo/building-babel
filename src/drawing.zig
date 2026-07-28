const std = @import("std");
const w4 = @import("wasm4.zig");

const WIDTH = @import("main.zig").WIDTH;
const HEIGHT = @import("main.zig").HEIGHT;

const BLOCK_SIZE = 9;
const H_RADIUS = BLOCK_SIZE * WIDTH / 6;
const V_RADIUS = BLOCK_SIZE;

pub var x_offset: f32 = 0;
pub var y_offset: f32 = 0;

pub fn draw_block(x: f32, y: f32, back: bool) void {
    const circ_x = @cos((x - x_offset) / WIDTH * std.math.tau);
    const circ_x2 = @cos((x + 1 - x_offset) / WIDTH * std.math.tau);
    const circ_y = @sin((x - x_offset) / WIDTH * std.math.tau);

    if (back and circ_y >= 0) return;
    if (!back and circ_y < 0) return;

    var screen_x: i32 = @intFromFloat(circ_x * H_RADIUS + 80);
    var screen_x2: i32 = @intFromFloat(circ_x2 * H_RADIUS + 80);
    if (screen_x > screen_x2) std.mem.swap(i32, &screen_x, &screen_x2);
    const screen_y: i32 = @intFromFloat(circ_y * V_RADIUS + y * BLOCK_SIZE + BLOCK_SIZE);
    w4.rect(screen_x - 40, screen_y, @intCast(screen_x2 - screen_x), BLOCK_SIZE);
}

pub fn draw_grid(grid: [HEIGHT][WIDTH]bool, back: bool) void {
    for (grid, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell) draw_block(@floatFromInt(x), @as(f32, @floatFromInt(y)) - y_offset, back);
        }
    }
    for (0..4) |y| {
        for (0..WIDTH) |x| {
            draw_block(@floatFromInt(x), HEIGHT + @as(f32, @floatFromInt(y)) - y_offset, back);
        }
    }
}
