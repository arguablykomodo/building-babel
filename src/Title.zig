const std = @import("std");
const w4 = @import("wasm4.zig");

const lines: [3][4][]const u8 = .{
    .{ "Building", "Babel", "Press \x80", "to start" },
    .{ "Erigiendo", "Babel", "Presiona \x80", "para\nempezar" },
    .{ "Construire", "Babel", "Appuyez \x80", "pour\nd\xE9marrer" },
};

rng: std.Random,
timers: [4]u8 = .{ 0, 0, 0, 0 },
versions: [4]u8 = .{ 0, 0, 0, 0 },

pub fn init(rng: std.Random) @This() {
    var title = @This(){ .rng = rng };
    for (&title.timers, &title.versions) |*timer, *version| {
        version.* = title.rng.uintLessThan(u8, lines.len);
        timer.* = title.rng.intRangeAtMost(u8, 30, 60);
    }
    return title;
}

pub fn update(self: *@This()) void {
    for (&self.timers, &self.versions) |*timer, *version| {
        timer.* -|= 1;
        if (timer.* == 0) {
            var new_version = version.*;
            while (new_version == version.*) new_version = self.rng.uintLessThan(u8, lines.len);
            version.* = new_version;
            timer.* = self.rng.intRangeAtMost(u8, 60, 120);
        }
    }
}

pub fn draw(self: *const @This()) void {
    w4.DRAW_COLORS.* = 0x04;
    w4.text(lines[self.versions[0]][0], 72, 16);
    w4.text(lines[self.versions[1]][1], 72, 24);
    w4.DRAW_COLORS.* = 0x03;
    w4.text(lines[self.versions[2]][2], 72, 40);
    w4.text(lines[self.versions[3]][3], 72, 48);
}
