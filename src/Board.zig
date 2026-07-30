const w4 = @import("wasm4.zig");
const Tetromino = @import("tetromino.zig").Tetromino;
const Renderer = @import("BoardRenderer.zig");

pub const WIDTH = 20;
pub const HEIGHT = 15;
pub const Grid = [HEIGHT][WIDTH]bool;

grid: Grid = [_][WIDTH]bool{[_]bool{false} ** WIDTH} ** HEIGHT,
bag: Tetromino.Bag = undefined,
tetromino: Tetromino = undefined,
player_x: i16 = 0,
player_y: i16 = 0,
rotation: u2 = 0,
lines_cleared: usize = 0,
game_over: bool = false,
drop_timer: u8 = 0,

renderer: Renderer = undefined,

pub fn init(self: *@This(), seed: u64) void {
    self.bag = Tetromino.Bag.init(seed);
    self.tetromino = self.bag.grab();
    self.renderer = Renderer{ .game = self };
}

pub fn update(self: *@This(), inputs: u8) void {
    self.renderer.update();
    if (self.game_over) return;
    self.drop_timer +%= 1;
    if (self.drop_timer > 60 - self.lines_cleared) {
        self.drop_timer = 0;
        self.soft_drop();
    }
    if (inputs & w4.BUTTON_RIGHT != 0) self.move(-1);
    if (inputs & w4.BUTTON_LEFT != 0) self.move(1);
    if (inputs & w4.BUTTON_UP != 0) self.rotate();
    if (inputs & w4.BUTTON_DOWN != 0) self.soft_drop();
    if (inputs & w4.BUTTON_1 != 0) self.hard_drop();
}

pub fn draw(self: *const @This()) void {
    self.renderer.draw();
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

fn move(self: *@This(), direction: i2) void {
    if (!self.collides(direction, 0, 0)) self.player_x += direction;
}

fn rotate(self: *@This()) void {
    if (!self.collides(0, 0, 1)) self.rotation +%= 1;
}

fn soft_drop(self: *@This()) void {
    if (self.collides(0, 1, 0)) self.place_tetromino() else self.player_y += 1;
}

fn hard_drop(self: *@This()) void {
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
    if (self.collides(0, 0, 0)) self.game_over = true;
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
            self.renderer.y_offset += Renderer.BLOCK_SIZE;
            w4.tone(880, 1 | (5 << 8), 50, w4.TONE_TRIANGLE);
        }
        y -= 1;
    }
}
