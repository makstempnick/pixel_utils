const std = @import("std");
const Allocator = std.mem.Allocator;

/// Represents a pixel buffer where each continous 4 bytes of the `colors` slice are a single color.
pub const Buffer = struct {
    width: usize,
    height: usize,
    colors: []u8,

    /// Creates a buffer with its content filled with zeroes.
    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Buffer {
        var colors = try allocator.alloc(u8, (width * height) * 4);

        @memset(colors[0..], 0);

        return .{ .width = width, .height = height, .colors = colors };
    }
    pub fn from(width: usize, height: usize, colors: []u8) Buffer {
        return .{ .width = width, .height = height, .colors = colors };
    }
    pub fn deinit(self: *const Buffer, allocator: std.mem.Allocator) void {
        allocator.free(self.colors);
    }

    /// Returns the color on a given position on the buffer.
    /// Will return null if given position is outside the buffer.
    pub fn getColor(self: *const Buffer, x: usize, y: usize) ?[4]u8 {
        if (x < 0 or x >= self.width or y < 0 or y >= self.height) {
            return null;
        }

        const index = idx(x, y, self.width) * 4;

        var color = [_]u8{ 0, 0, 0, 0 };

        for (0..4) |i| {
            color[i] = self.colors[index + i];
        }

        return color;
    }

    /// Sets the color on a given position on the buffer.
    pub fn setColor(self: *const Buffer, x: usize, y: usize, color: [4]u8) void {
        if (x < 0 or x >= self.width or y < 0 or y >= self.height) {
            return;
        }

        const index = idx(x, y, self.width) * 4;

        for (0..4) |i| {
            self.colors[index + i] = color[i];
        }
    }

    /// Fills buffer with the given color.
    pub fn fill(self: *const Buffer, color: [4]u8) void {
        for (0..self.colors.len / 4) |i| {
            for (0..4) |j| {
                self.colors[i * 4 + j] = color[j];
            }
        }
    }

    /// Samples color from some position on the buffer given in percentages of its width and height.
    /// Will return null if given percentages are outside the buffer.
    pub fn sample(self: *const Buffer, perc_x: f32, perc_y: f32) ?[4]u8 {
        if (perc_x < 0.0 or perc_x > 1.0 or perc_y < 0.0 or perc_y > 1.0) {
            return null;
        }

        const x: usize = @trunc(@as(f32, @floatFromInt(self.width)) * perc_x);
        const y: usize = @trunc(@as(f32, @floatFromInt(self.height)) * perc_y);

        return self.getColor(x, y);
    }

    /// Returns a new version of the buffer with content scaled to given size.
    pub fn scale(self: *const Buffer, allocator: Allocator, width: usize, height: usize) !Buffer {
        var new_buffer = try Buffer.init(allocator, width, height);

        for (0..height) |y| {
            for (0..width) |x| {
                const perc_x = @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(width));
                const perc_y = @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(height));

                const color = self.sample(perc_x, perc_y).?;

                new_buffer.setColor(x, y, color);
            }
        }

        return new_buffer;
    }

    // gotta add blending...
    /// Draws the buffer onto another one, positioning and scaling it correctly.
    pub fn drawOnOther(self: *const Buffer, other: *const Buffer, x: isize, y: isize, width: usize, height: usize) void {
        for (0..height) |screen_y| {
            for (0..width) |screen_x| {
                const perc_x =
                    @as(f32, @floatFromInt(screen_x)) / @as(f32, @floatFromInt(width));
                const perc_y =
                    @as(f32, @floatFromInt(screen_y)) / @as(f32, @floatFromInt(height));

                const color = self.sample(perc_x, perc_y).?;

                const pos_x = x - @divTrunc(@as(isize, @intCast(width)), 2) + @as(isize, @intCast(screen_x));
                const pos_y = y - @divTrunc(@as(isize, @intCast(height)), 2) + @as(isize, @intCast(screen_y));

                if (pos_x >= 0 and pos_x < other.width and pos_y >= 0 and pos_y < other.height) {
                    other.setColor(@intCast(pos_x), @intCast(pos_y), color);
                }
            }
        }
    }

    /// Draws the other buffer onto self, positioning and scaling it correctly.
    pub fn drawOnSelf(self: *const Buffer, other: *const Buffer, x: isize, y: isize, width: usize, height: usize) void {
        for (0..height) |screen_y| {
            for (0..width) |screen_x| {
                const perc_x =
                    @as(f32, @floatFromInt(screen_x)) / @as(f32, @floatFromInt(width));
                const perc_y =
                    @as(f32, @floatFromInt(screen_y)) / @as(f32, @floatFromInt(height));

                const color = other.sample(perc_x, perc_y).?;

                const pos_x = x - @divTrunc(@as(isize, @intCast(width)), 2) + @as(isize, @intCast(screen_x));
                const pos_y = y - @divTrunc(@as(isize, @intCast(height)), 2) + @as(isize, @intCast(screen_y));

                if (pos_x >= 0 and pos_x < self.width and pos_y >= 0 and pos_y < self.height) {
                    self.setColor(@intCast(pos_x), @intCast(pos_y), color);
                }
            }
        }
    }
};

pub fn idx(x: usize, y: usize, width: usize) usize {
    return y * width + x;
}
pub fn xy(i: usize, width: usize) [2]usize {
    const x = i / width;
    const y = i % width;

    return [_]usize{ x, y };
}
