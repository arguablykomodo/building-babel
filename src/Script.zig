const std = @import("std");
const w4 = @import("wasm4.zig");

const LEFT = 72;
const MAX_WIDTH = 88;
const SPACE_WIDTH = 4;

pub const LINES = 18;
const LANGUAGES = 2;

const scripts: [LANGUAGES][]const u8 = .{
    @embedFile("script/es.ascii"),
    @embedFile("script/en.ascii"),
};

const Paragraph = struct {
    version_timer: usize = 0,
    version: usize = 0,
    versions: [LANGUAGES][]const u8 = undefined,
    right: bool = false,
    len: usize = 0,
    height: i32 = 0,
    chars: usize = 0,
};

timer: usize = 0,
revealed: usize = 0,
paragraphs: [LINES]Paragraph = init_paragraphs(),
offset_y: f32 = 0,

fn init_paragraphs() [18]Paragraph {
    comptime var paragraphs: [LINES]Paragraph = undefined;
    comptime var iters: [LANGUAGES]std.mem.SplitIterator(u8, .scalar) = undefined;
    inline for (scripts, 0..) |script, i| iters[i] = std.mem.splitScalar(u8, script, '\n');
    inline for (&paragraphs) |*paragraph| {
        comptime var versions: [LANGUAGES][]const u8 = undefined;
        inline for (&iters, 0..) |*iter, j| versions[j] = iter.next().?;
        paragraph.* = Paragraph{};
        paragraph.right = versions[0][0] != '>';
        inline for (versions, 0..) |version, j| {
            paragraph.versions[j] = if (paragraph.right) version else version[1..];
            paragraph.len = @max(paragraph.versions[j].len, paragraph.len);
            paragraph.height = @max(calc_height(paragraph.versions[j]), paragraph.height);
        }
    }
    return paragraphs;
}

fn calc_height(paragraph: []const u8) i32 {
    @setEvalBranchQuota(20000);
    var words = std.mem.tokenizeScalar(u8, paragraph, ' ');
    var height: i32 = 0;
    var line_width: usize = 0;
    while (words.peek()) |word| {
        if (line_width + word.len * 8 > MAX_WIDTH) {
            height += 8;
            line_width = 0;
        }
        _ = words.next();
        line_width += word.len * 8 + SPACE_WIDTH;
    }
    return height + 16;
}

pub fn draw(self: *@This()) void {
    self.timer += 1;
    if (self.timer == 4) self.timer = 0;

    var height: i32 = 0;
    for (&self.paragraphs, 0..) |*paragraph, i| {
        if (i >= self.revealed) break;
        if (self.timer == 0) paragraph.chars +|= 1;
        paragraph.version_timer += 1;
        if (paragraph.version_timer == 120) {
            paragraph.version_timer = 0;
            paragraph.version = @mod(paragraph.version + 1, LANGUAGES);
        }
        const version = paragraph.versions[paragraph.version];
        draw_wrapped(
            version[0..@min(paragraph.chars, version.len)],
            height - @as(i32, @intFromFloat(self.offset_y)) + 1,
            paragraph.right,
        );
        height += paragraph.height;
    }

    const target_y: f32 = @floatFromInt(@max(height - 160, 0));
    self.offset_y = std.math.lerp(self.offset_y, target_y, 0.02);
}

fn draw_wrapped(paragraph: []const u8, y: i32, right: bool) void {
    w4.DRAW_COLORS.* = if (right) 0x04 else 0x03;
    var words = std.mem.tokenizeScalar(u8, paragraph, ' ');
    var height: i32 = 0;
    var line_start: usize = 0;
    var line_end: usize = 0;
    var line_width: usize = 0;
    while (words.peek()) |word| {
        if (line_width + word.len * 8 > MAX_WIDTH) {
            draw_line(paragraph[line_start..line_end], line_width, y + height, right);
            height += 8;
            line_start = line_end;
            line_width = 0;
        }
        _ = words.next();
        line_width += word.len * 8 + SPACE_WIDTH;
        line_end = words.index;
    }
    draw_line(paragraph[line_start..line_end], line_width, y + height, right);
}

fn draw_line(line: []const u8, line_width: usize, y: i32, right: bool) void {
    var draw_words = std.mem.tokenizeScalar(u8, line, ' ');
    var draw_x = if (right) LEFT + MAX_WIDTH - line_width + SPACE_WIDTH else LEFT;
    while (draw_words.next()) |draw_word| {
        w4.text(draw_word, @intCast(draw_x), y);
        draw_x += draw_word.len * 8 + SPACE_WIDTH;
    }
}
