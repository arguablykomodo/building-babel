const w4 = @import("wasm4.zig");
const Tetromino = @import("tetromino.zig").Tetromino;
pub const Renderer = @import("BoardRenderer.zig");

pub const WIDTH = 20;
pub const HEIGHT = 15;
pub const Grid = [HEIGHT][WIDTH]bool;

grid: Grid = [_][WIDTH]bool{[_]bool{false} ** WIDTH} ** HEIGHT,
bag: Tetromino.Bag,
tetromino: Tetromino = undefined,
player_x: i16 = 0,
player_y: i16 = 0,
rotation: u2 = 0,
lines_cleared: usize = 0,

renderer: Renderer = undefined,

pub fn init(seed: u64) @This() {
    var game: @This() = .{ .bag = Tetromino.Bag.init(seed) };
    game.tetromino = game.bag.grab();
    return game;
}

pub fn collides(self: @This(), x: i16, y: i16, rot: u1) bool {
    const blocks = self.tetromino.blocks(
        self.player_x + x,
        self.player_y + y,
        self.rotation +% rot,
    );
    for (blocks) |block| {
        const x_wrapped = @mod(block[0], WIDTH);
        if (block[1] < 0) return false;
        if (block[1] >= HEIGHT) return true;
        if (self.grid[@intCast(block[1])][@intCast(x_wrapped)]) return true;
    }
    return false;
}

pub fn move(self: *@This(), direction: i2) void {
    if (!self.collides(direction, 0, 0)) self.player_x += direction;
}

pub fn rotate(self: *@This()) void {
    if (!self.collides(0, 0, 1)) self.rotation +%= 1;
}

pub fn soft_drop(self: *@This()) void {
    if (self.collides(0, 1, 0)) self.place_tetromino() else self.player_y += 1;
}

pub fn hard_drop(self: *@This()) void {
    while (!self.collides(0, 1, 0)) self.player_y += 1;
    self.place_tetromino();
}

fn place_tetromino(self: *@This()) void {
    const blocks = self.tetromino.blocks(self.player_x, self.player_y, self.rotation);
    for (blocks) |block| {
        const wrapped_x = @mod(block[0], WIDTH);
        if (block[1] < 0) return;
        if (block[1] >= HEIGHT) return;
        self.grid[@intCast(block[1])][@intCast(wrapped_x)] = true;
    }
    self.clear_lines();
    self.player_y = 0;
    self.rotation = 0;
    self.tetromino = self.bag.grab();
    w4.tone(110, 2 | (15 << 8), 50, w4.TONE_NOISE);
}

fn clear_lines(self: *@This()) void {
    var y: u8 = HEIGHT - 1;
    while (y > 0) {
        var full = true;
        for (self.grid[y]) |cell| {
            if (!cell) full = false;
        }
        if (full) {
            var y2 = y;
            while (y2 > 0) {
                @memcpy(&self.grid[y2], &self.grid[y2 - 1]);
                y2 -= 1;
            }
            self.grid[0] = [_]bool{false} ** WIDTH;
            self.lines_cleared +|= 1;
            self.renderer.y_offset += 1.0;
            w4.tone(880, 1 | (5 << 8), 50, w4.TONE_TRIANGLE);
        }
        y -= 1;
    }
}
