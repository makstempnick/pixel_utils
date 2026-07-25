const std = @import("std");
const utils = @import("utils");
const sdl = @import("sdl3");

test "test1" {
    var allocator = std.heap.DebugAllocator(.{}).init;
    const gpa = allocator.allocator();

    defer sdl.shutdown();

    const flags = sdl.InitFlags{ .video = true };
    try sdl.init(flags);
    defer sdl.quit(flags);

    const window = try sdl.video.Window.init("tests", 400, 400, .{});
    defer window.deinit();

    const surface = try window.getSurface();
    const pixels = surface.getPixels().?;

    const buffer = try utils.Buffer.init(gpa, 400, 400);
    defer buffer.deinit(gpa);

    buffer.fill(.{ 255, 0, 0, 255 });

    const image = try utils.Buffer.init(gpa, 100, 100);
    defer image.deinit(gpa);

    image.fill(.{ 0, 255, 0, 255 });

    image.drawOnOther(&buffer, 200, 200, 100, 100);

    var running = true;
    while (running) {
        for (0..buffer.colors.len / 4) |i| {
            const index = i * 4;

            pixels[index] = buffer.colors[index + 2];
            pixels[index + 1] = buffer.colors[index + 1];
            pixels[index + 2] = buffer.colors[index];
            pixels[index + 3] = buffer.colors[index + 3];
        }

        try window.updateSurface();

        while (sdl.events.poll()) |event| {
            switch (event) {
                .quit => running = false,
                .terminating => running = false,
                else => {},
            }
        }
    }
}
