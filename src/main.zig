const std = @import("std");
const w4 = @import("wasm4.zig");
const Tetromino = @import("tetromino.zig").Tetromino;
const drawing = @import("drawing.zig");

pub const WIDTH = 20;
pub const HEIGHT = 15;

var grid = [_][WIDTH]bool{[_]bool{false} ** WIDTH} ** HEIGHT;

var player_x: i16 = 0;
var player_y: u8 = 0;

var bag: Tetromino.Bag = .init();
var shape: Tetromino = undefined;
var rotation: u2 = 0;

var input: InputManager = .{};

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

fn collides() bool {
    const blocks = shape.blocks(rotation);
    for (blocks) |block| {
        const x = @mod(block[0] + player_x, WIDTH);
        const y = block[1] + player_y;
        if (y < 0) return false;
        if (y >= HEIGHT) return true;
        if (grid[@intCast(y)][@intCast(x)]) return true;
    }
    return false;
}

fn move(direction: i2) void {
    player_x += direction;
    if (collides()) player_x -= direction;
}

fn rotate() void {
    rotation +%= 1;
    if (collides()) rotation -%= 1;
}

fn soft_drop() void {
    player_y += 1;
    if (collides()) {
        player_y -= 1;
        place_tetromino();
    }
}

fn hard_drop() void {
    while (!collides()) player_y +%= 1;
    player_y -%= 1;
    place_tetromino();
}

fn place_tetromino() void {
    const blocks = shape.blocks(rotation);
    for (blocks) |block| {
        const x = @mod(block[0] + player_x, WIDTH);
        const y = block[1] + player_y;
        if (y < 0) return;
        if (y >= HEIGHT) return;
        grid[@intCast(y)][@intCast(x)] = true;
    }
    clear_lines();
    player_y = 0;
    shape = bag.grab();
    rotation = 0;
}

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

fn draw_shadow() void {
    const original_y = player_y;
    while (!collides()) player_y +%= 1;
    player_y -%= 1;
    const blocks = shape.blocks(rotation);
    for (blocks) |block| {
        const x = @mod(block[0] + player_x, WIDTH);
        const y = block[1] + player_y;
        drawing.draw_block(x, y, false);
    }
    player_y = original_y;
}

export fn start() void {
    shape = bag.grab();
}

export fn update() void {
    const inputs = input.poll();

    if (inputs & w4.BUTTON_RIGHT != 0) move(-1);
    if (inputs & w4.BUTTON_LEFT != 0) move(1);
    if (inputs & w4.BUTTON_UP != 0) rotate();
    if (inputs & w4.BUTTON_DOWN != 0) soft_drop();
    if (inputs & w4.BUTTON_1 != 0) hard_drop();

    drawing.x_offset = std.math.lerp(drawing.x_offset, player_x - WIDTH / 4 + 1, 0.1);
    drawing.y_offset *= 0.9;

    w4.DRAW_COLORS.* = 0x43;
    for (shape.blocks(rotation)) |block| {
        drawing.draw_block(player_x + block[0], player_y + block[1], true);
    }
    drawing.draw_grid(grid, true);

    w4.DRAW_COLORS.* = 0x20;
    draw_shadow();

    w4.DRAW_COLORS.* = 0x32;
    drawing.draw_grid(grid, false);
    for (shape.blocks(rotation)) |block| {
        drawing.draw_block(player_x + block[0], player_y + block[1], false);
    }
}
