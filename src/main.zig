const w4 = @import("wasm4.zig");

const BLOCK_SIZE = 8;
const WIDTH = 10;
const HEIGHT = 20;

var grid = [_][WIDTH]bool{[_]bool{false} ** WIDTH} ** HEIGHT;
var x: u8 = 0;
var y: u8 = 0;
var prev_input: u8 = 0;

export fn start() void {}

export fn update() void {
    w4.DRAW_COLORS.* = 2;

    const input = w4.GAMEPAD1.*;
    const new_input = input & (input ^ prev_input);
    prev_input = input;

    if (new_input & w4.BUTTON_RIGHT != 0 and x < (WIDTH - 1)) x += 1;
    if (new_input & w4.BUTTON_LEFT != 0 and x > 0) x -= 1;
    if (new_input & w4.BUTTON_DOWN != 0 and y < (HEIGHT - 1)) y += 1;
    w4.rect(x * BLOCK_SIZE, y * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE);

    if (new_input & w4.BUTTON_1 != 0) {
        while (y < (HEIGHT - 1) and !grid[y+1][x]) y += 1;
        grid[y][x] = true;
        y = 0;
    }

    var grid_y: u8 = 0;
    for (grid) |row| {
        var grid_x: u8 = 0;
        for (row) |cell| {
            if (cell) {
                w4.rect(grid_x * BLOCK_SIZE, grid_y * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE);
            }
            grid_x += 1;
        }
        grid_y += 1;
    }
}
