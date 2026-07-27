const std = @import("std");
const w4 = @import("wasm4.zig");
const Tetromino = @import("tetromino.zig").Tetromino;
const drawing = @import("drawing.zig");

pub const WIDTH = 20;
pub const HEIGHT = 15;

var grid = [_][WIDTH]bool{[_]bool{false} ** WIDTH} ** HEIGHT;

var player_x: u8 = 0;
var player_y: u8 = 0;

var bag: Tetromino.Bag = .init();
var shape: Tetromino = undefined;
var rotation: u8 = 0;

var prev_input: u8 = 0;

fn clear_lines() void {
    var y: u8 = HEIGHT - 1;
    while (y > 0) {
        var full = true;
        for (grid[y]) |cell| {
            if (!cell) full = false;
        }
        if (full) {
            drawing.y_offset += 1.0;
            var y2 = y;
            while (y2 > 0) {
                @memcpy(&grid[y2], &grid[y2 - 1]);
                y2 -= 1;
            }
            grid[0] = [_]bool{false} ** WIDTH;
        }
        y -= 1;
    }
}

export fn start() void {
    shape = bag.grab();
}

export fn update() void {
    drawing.x_offset += 0.02;

    const input = w4.GAMEPAD1.*;
    const new_input = input & (input ^ prev_input);
    prev_input = input;

    if (new_input & w4.BUTTON_RIGHT != 0 and player_x < WIDTH) player_x += 1;
    if (player_x == WIDTH) player_x = 0;

    if (new_input & w4.BUTTON_LEFT != 0 and player_x >= 0) player_x -%= 1;
    if (player_x == std.math.maxInt(u8)) player_x = WIDTH - 1;

    if (new_input & w4.BUTTON_DOWN != 0 and player_y < (HEIGHT - 1)) player_y += 1;
    if (new_input & w4.BUTTON_UP != 0) {
        rotation += 1;
        if (rotation == 4) rotation = 0;
    }

    if (new_input & w4.BUTTON_1 != 0) {
        while (player_y < (HEIGHT - 1) and !grid[player_y + 1][player_x]) player_y += 1;
        grid[player_y][player_x] = true;
        player_y = 0;
        clear_lines();
        shape = bag.grab();
        rotation = 0;
    }

    for (shape.blocks(rotation)) |block| {
        drawing.draw_block(player_x + block[0], player_y + block[1], true);
    }
    drawing.y_offset *= 0.9;
    drawing.draw_grid(grid, true);
    drawing.draw_grid(grid, false);
    for (shape.blocks(rotation)) |block| {
        drawing.draw_block(player_x + block[0], player_y + block[1], false);
    }
}
