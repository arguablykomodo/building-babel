const std = @import("std");
const w4 = @import("wasm4.zig");

const LEFT = 72;
const MAX_WIDTH = 88;
const SPACE_WIDTH = 4;

const Paragraph = struct {
    text_es: []const u8,
    text_en: []const u8,
    right: bool,
    len: usize,
    height: i32,
    chars: usize = 0,
};

timer: usize = 0,
revealed: usize = 0,
paragraphs: [18]Paragraph = init_paragraphs(),
offset_y: f32 = 0,

fn init_paragraphs() [18]Paragraph {
    @setEvalBranchQuota(100000);
    var paragraphs: [18]Paragraph = undefined;
    inline for (0..18) |i| {
        const right = text_es[i][0] != '>';
        const es = if (right) text_es[i] else text_es[i][1..];
        const en = if (right) text_en[i] else text_en[i][1..];
        paragraphs[i] = Paragraph{
            .text_es = es,
            .text_en = en,
            .right = right,
            .len = @max(en.len, es.len),
            .height = @max(calc_height(en), calc_height(es))
        };
    }
    return paragraphs;
}

fn calc_height(paragraph: []const u8) i32 {
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
        draw_wrapped(paragraph.text_es[0..@min(paragraph.chars, paragraph.text_es.len)], height - @as(i32, @intFromFloat(self.offset_y)), paragraph.right);
        height += paragraph.height;
    }

    self.offset_y = std.math.lerp(self.offset_y, @as(f32, @floatFromInt(height - 160)), 0.02);
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

const text_es: [18][]const u8 = .{
    ">¿De verdad crees que va a funcionar?",
    "No lo se, siento que es lo unico que queda para probar.",
    "Siento que desde la confusion, ya nadie esta de acuerdo en nada.",
    "Nuestros mundos, nuestros puntos de vista, son cada vez mas distintos.",
    ">¿Es eso tan terrible?",
    "¡Lo es! Cada dia veo mas odio en los ojos de quienes consideraba mis vecinos.",
    "Si tan solo pudieramos entendernos, si tan solo les pudiera hacer entender...",
    ">Pero hay tanta riqueza, tanto valor en nuestras lenguas, nuestras diferencias.",
    ">¡Es tan hermoso el abismo entre Shakespeare y Cervantes!",
    ">¿No perderiamos algo si dejaramos de ser tan distintas?",
    "¿Acaso valen nuestras diferencias tanto dolor?",
    ">Tiene que existir un punto medio, una forma de hacer esto funcionar...",
    "No vivimos en tiempos de puntos medios. Eso tambien nos trajo la confusion.",
    ">Nuestra discusion es prueba de que es posible.",
    ">Nuestro disenso, en su desarrollo, es promesa de un mundo mejor.",
    "...Tal vez tienes razon.",
    ">Tal vez nuestras diferencias son las que van a traer una nueva solucion.",
    "Tal vez, es mejor dejar que la torre se derrumba.",
};

const text_en: [18][]const u8 = .{
    ">Do you really think this will work?",
    "I don't know, I feel like it's the only thing left to try.",
    "Ever since the confusion, no one agrees on anything anymore.",
    "Our worlds, our points of view, keep growing apart.",
    ">Is that so bad?",
    "It's awful! Every day I see the hatred grow in the eyes of those whom I considered neighbors.",
    "If only we could understand each other, if only I could make them understand...",
    ">But there is so much richness, so much value in our tongues, our differences.",
    ">The gap between Cervantes and Shakespeare is so beautiful!",
    ">Wouldn't we lose something if we stopped being so different?",
    "Are our differences worth so much pain?",
    ">There has to be a middle ground, a way to make this work...",
    "We don't live in a time for half measures. The confusion brought us that too.",
    ">Our discussion is proof that it is possible.",
    ">Our disagreement, as it unfolds, holds the promise of a better world.",
    "...Maybe you are right.",
    ">Maybe it is our differences that will bring about a new solution.",
    "Maybe, we should let the tower collapse.",
};
