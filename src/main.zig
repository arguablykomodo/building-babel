const std = @import("std");
const w4 = @import("wasm4.zig");

const BLOCK_SIZE = 8;
const WIDTH = 20;
const HEIGHT = 16;

var grid = [_][WIDTH]bool{[_]bool{false} ** WIDTH} ** HEIGHT;
var player_x: u8 = 0;
var player_y: u8 = 0;
var prev_input: u8 = 0;

fn draw_block(x: u8, y: u8) void {
    const H_RADIUS = 40;
    const V_RADIUS = BLOCK_SIZE;

    const circ_x = @cos(@as(f32, @floatFromInt(x)) / WIDTH * std.math.tau);
    const circ_x2 = @cos(@as(f32, @floatFromInt(x + 1)) / WIDTH * std.math.tau);
    const circ_y = @sin(@as(f32, @floatFromInt(x)) / WIDTH * std.math.tau);

    var screen_x: i32 = @intFromFloat(circ_x * H_RADIUS + 80);
    var screen_x2: i32 = @intFromFloat(circ_x2 * H_RADIUS + 80);
    if (screen_x > screen_x2) {
        const tmp = screen_x;
        screen_x = screen_x2;
        screen_x2 = tmp;
    }
    const screen_y: i32 = @intFromFloat(circ_y * V_RADIUS + y * BLOCK_SIZE + BLOCK_SIZE);
    if (circ_y > 0.0) {
        w4.DRAW_COLORS.* = 2;
    } else {
        w4.DRAW_COLORS.* = 3;
    }
    w4.rect(screen_x, screen_y, @intCast(screen_x2 - screen_x), BLOCK_SIZE);
}

export fn start() void {}

export fn update() void {
    w4.DRAW_COLORS.* = 2;

    const input = w4.GAMEPAD1.*;
    const new_input = input & (input ^ prev_input);
    prev_input = input;

    if (new_input & w4.BUTTON_RIGHT != 0 and player_x < WIDTH) player_x += 1;
    if (player_x == WIDTH) player_x = 0;

    if (new_input & w4.BUTTON_LEFT != 0 and player_x >= 0) player_x -%= 1;
    if (player_x == std.math.maxInt(u8)) player_x = WIDTH - 1;

    if (new_input & w4.BUTTON_DOWN != 0 and player_y < (HEIGHT - 1)) player_y += 1;
    draw_block(player_x, player_y);

    if (new_input & w4.BUTTON_1 != 0) {
        while (player_y < (HEIGHT - 1) and !grid[player_y + 1][player_x]) player_y += 1;
        grid[player_y][player_x] = true;
        player_y = 0;
    }

    var grid_y: u8 = 0;
    for (grid) |row| {
        var grid_x: u8 = 0;
        for (row) |cell| {
            if (cell) draw_block(grid_x, grid_y);
            grid_x += 1;
        }
        grid_y += 1;
    }
}
