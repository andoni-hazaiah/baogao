const std = @import("std");
const testing = std.testing;
const logger = @import("logger.zig");
const ArrayList = std.ArrayList;
const allocator = std.testing.allocator;

// A writer that captures log messages for testing
const TestWriter = struct {
    base: logger.Logger.Writer,
    messages: ArrayList([]const u8),

    fn init() !TestWriter {
        return TestWriter{
            .base = logger.Logger.Writer{
                .writerFn = writeFn,
            },
            .messages = ArrayList([]const u8).init(allocator),
        };
    }

    fn deinit(self: *TestWriter) void {
        for (self.messages.items) |msg| {
            allocator.free(msg);
        }
        self.messages.deinit();
    }

    fn writeFn(base_writer: *const logger.Logger.Writer, message: []const u8) void {
        // Convert from base Writer to TestWriter
        const self: *TestWriter = @fieldParentPtr("base", @constCast(base_writer));

        // Make a copy of the message
        const msg_copy = allocator.dupe(u8, message) catch unreachable;

        // Store the message
        self.messages.append(msg_copy) catch |err| {
            std.debug.print("\n\n\nAn Error has occurred: {}\n\n", .{err});
            return;
        };
    }

    fn getLastMessage(self: *const TestWriter) ?[]const u8 {
        const len = self.messages.items.len;
        if (len == 0) {
            return null;
        }
        return self.messages.items[len - 1];
    }

    fn containsMessage(self: *const TestWriter, substring: []const u8) bool {
        for (self.messages.items) |msg| {
            if (std.mem.indexOf(u8, msg, substring) != null) {
                return true;
            }
        }
        return false;
    }
};

test "Logger initialization" {
    const log = logger.Logger.init("TestLogger", logger.Level.INFO);
    try testing.expectEqual(logger.Level.INFO, log.level);
    try testing.expectEqualStrings("TestLogger", log.name);
}

test "Logging level filtering" {
    const log = logger.Logger.init("TestLogger", logger.Level.WARNING);

    // These should be fitered out
    log.debug("This debug message should not be logged.");
    log.info("This info message should not be logged.");

    // These should be logged
    log.warning("This warning message should be logged.");
    log.err("This err message should be logged.");
    log.fatal("This fatal message should be logged.");
}

// Test using TestWriter
test "Logging level filtering with TestWriter" {
    var test_writer = try TestWriter.init();
    defer test_writer.deinit();

    // Pass a POINTER to the base writer
    var log = logger.Logger.initWithWriter("TestLogger", logger.Level.WARNING, &test_writer.base);

    // This hsould be filtered out
    log.info("This message should not be logged.");

    // No messages should be captured
    try testing.expectEqual(@as(usize, 0), test_writer.messages.items.len);

    // This should be logged
    log.warning("This warning message should be logged.");

    // One message should be captured
    try testing.expectEqual(@as(usize, 1), test_writer.messages.items.len);

    // The message should contain our warning text
    try testing.expect(test_writer.containsMessage("This warning message should be logged."));

    // The message should contain the WARNING level
    try testing.expect(test_writer.containsMessage("[WARNING]"));
}

test "String interpolation" {
    var test_writer = try TestWriter.init();
    defer test_writer.deinit();

    var log = logger.Logger.initWithWriter("TestLogger", logger.Level.INFO, &test_writer.base);

    const user_id = 12345;
    const action = "login";

    log.infof("User {d} performed action: {s}", .{ user_id, action });

    // Verify the formatted message was logged
    try testing.expect(test_writer.containsMessage("User 12345 performed action: login"));
}

// edge cases
test "Empty log message" {
    var test_writer = try TestWriter.init();
    defer test_writer.deinit();

    var log = logger.Logger.initWithWriter("TestLogger", logger.Level.INFO, &test_writer.base);

    // Log an empty message
    log.info("");

    try testing.expectEqual(@as(usize, 1), test_writer.messages.items.len);
}

test "Very long message" {
    var test_writer = try TestWriter.init();
    defer test_writer.deinit();

    var log = logger.Logger.initWithWriter("TestLogger", logger.Level.INFO, &test_writer.base);

    // Create a very long message that might exceed our buffer
    var long_message: [2000]u8 = undefined;
    @memset(&long_message, 'A');

    // This might fail if our buffer is too small
    log.info(long_message[0..]);

    // If it didn't crash, that's at least something!
    // (We'd need to modify our Logger to handle this case properly)
}

test "Log message with special characters" {
    var test_writer = try TestWriter.init();
    defer test_writer.deinit();

    var log = logger.Logger.initWithWriter("TestLogger", logger.Level.INFO, &test_writer.base);

    // Log a message with newlines, tabs, quotes, etc.
    log.info("Special chars: \n\t\r\"'\\");

    try testing.expectEqual(@as(usize, 1), test_writer.messages.items.len);
}
