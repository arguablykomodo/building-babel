const std = @import("std");
const w4 = @import("wasm4.zig");

const LEFT = 72;
const MAX_WIDTH = 88;
const SPACE_WIDTH = 4;
const CHAR_WIDTH = 8;
const REVEAL_TIME = 4;
const LANG_TIME = 120;
const LANGUAGES = 3;
const PARAGRAPHS = 18;

paragraphs: [PARAGRAPHS]Paragraph = blk: {
    const scripts: [LANGUAGES][]const u8 = .{
        @embedFile("script/es.ascii"),
        @embedFile("script/en.ascii"),
        @embedFile("script/fr.ascii"),
    };
    var paragraphs: [PARAGRAPHS]Paragraph = undefined;
    var iters: [LANGUAGES]std.mem.SplitIterator(u8, .scalar) = undefined;
    for (scripts, 0..) |script, i| iters[i] = std.mem.splitScalar(u8, script, '\n');
    for (&paragraphs) |*paragraph| {
        paragraph.* = Paragraph.init(&iters);
    }
    break :blk paragraphs;
},
revealed: usize = 0,
offset_y: f32 = 0,

pub fn update(self: *@This()) void {
    var height: i32 = 1;
    for (self.paragraphs[0..self.revealed]) |*paragraph| {
        paragraph.update();
        height += paragraph.height * CHAR_WIDTH + SPACE_WIDTH;
    }
    const target_y: f32 = @floatFromInt(@max(height - 160, 0));
    self.offset_y = std.math.lerp(self.offset_y, target_y, 0.02);
}

pub fn draw(self: *const @This()) void {
    var height: i32 = 1;
    for (self.paragraphs[0..self.revealed]) |paragraph| {
        paragraph.draw(height - @as(i32, @intFromFloat(self.offset_y)));
        height += paragraph.height * CHAR_WIDTH + SPACE_WIDTH;
    }
}

const Paragraph = struct {
    versions: [LANGUAGES]Wrapped = undefined,
    version_timer: usize = LANG_TIME,
    version: usize = 0,
    right: bool = false,
    height: i32 = 0,

    reveal_timer: usize = REVEAL_TIME,
    chars: usize = 0,
    sound: bool = true,

    pub fn init(iters: *[LANGUAGES]std.mem.SplitIterator(u8, .scalar)) Paragraph {
        var paragraph = Paragraph{};
        for (iters, 0..) |*iter, i| {
            const line = iter.next().?;
            paragraph.right = line[0] != '>';
            paragraph.versions[i] = Wrapped.init(if (paragraph.right) line else line[1..]);
            paragraph.height = @max(paragraph.versions[i].height, paragraph.height);
        }
        return paragraph;
    }

    pub fn update(self: *Paragraph) void {
        self.version_timer -= 1;
        if (self.version_timer == 0) {
            self.version = @mod(self.version + 1, LANGUAGES);
            self.version_timer = LANG_TIME;
        }
        self.reveal_timer -= 1;
        if (self.reveal_timer == 0) {
            self.chars +|= 1;
            self.reveal_timer = REVEAL_TIME;
            if (self.sound and self.chars < self.versions[self.version].len) {
                if (self.right) {
                    w4.tone(207, 2, 30, w4.TONE_TRIANGLE);
                } else w4.tone(196, 2, 30, w4.TONE_TRIANGLE);
            } else self.sound = true;
        }
    }

    pub fn draw(self: *const Paragraph, y: i32) void {
        self.versions[self.version].draw(y, self.right, self.chars);
    }
};

const Wrapped = struct {
    height: usize = 0,
    lines: [12][]const u8 = undefined,
    widths: [12]i32 = undefined,
    len: usize = 0,

    pub fn init(comptime paragraph: []const u8) Wrapped {
        @setEvalBranchQuota(20000);
        var wrapped = Wrapped{};
        var words = std.mem.splitScalar(u8, paragraph, ' ');
        var width: usize = 0;
        var start_index: usize = 0;
        var end_index: usize = 0;
        const first_word = words.first();
        wrapped.len += first_word.len;
        width += first_word.len * CHAR_WIDTH + SPACE_WIDTH;
        end_index += first_word.len + 1;
        while (words.next()) |word| {
            wrapped.len += word.len;
            if (width + word.len * CHAR_WIDTH > MAX_WIDTH) {
                width -|= SPACE_WIDTH;
                end_index -|= 1;
                wrapped.lines[wrapped.height] = paragraph[start_index..end_index];
                wrapped.widths[wrapped.height] = width;
                wrapped.height += 1;
                width = 0;
                start_index = end_index + 1;
                end_index = start_index;
            }
            width += word.len * CHAR_WIDTH + SPACE_WIDTH;
            end_index += word.len + 1;
        }
        if (width > 0) {
            width -|= SPACE_WIDTH;
            end_index -|= 1;
            wrapped.lines[wrapped.height] = paragraph[start_index..@min(end_index, paragraph.len)];
            wrapped.widths[wrapped.height] = width;
            wrapped.height += 1;
        }
        return wrapped;
    }

    pub fn draw(self: *const Wrapped, y: i32, right: bool, chars: usize) void {
        w4.DRAW_COLORS.* = if (right) 0x04 else 0x03;
        var chars_drawn: usize = 0;
        for (self.lines[0..self.height], self.widths[0..self.height], 0..) |line, width, i| {
            var x: i32 = if (right) LEFT + MAX_WIDTH - width else LEFT - @max(0, width - MAX_WIDTH);
            var words = std.mem.splitScalar(u8, line, ' ');
            while (words.next()) |word| {
                const chars_to_draw = @min(chars - chars_drawn, word.len);
                w4.text(word[0..chars_to_draw], x, y + @as(i32, @intCast(i)) * CHAR_WIDTH);
                x += @intCast(word.len * CHAR_WIDTH + SPACE_WIDTH);
                chars_drawn += chars_to_draw;
                if (chars_drawn >= chars) return;
            }
        }
    }
};
