const std = @import("std");
const Shijian = @import("shijian.zig").Shijian;

pub const Logger = struct {
    level: Level,
    name: []const u8, // Add a name field to identify the logger
    writer: *Writer,

    pub const Writer = struct {
        writerFn: *const fn (self: *const Writer, message: []const u8) void,

        pub fn write(self: *const Writer, message: []const u8) void {
            self.writerFn(self, message);
        }
    };

    // Standard writer that outputs to stdout
    pub const StdoutWriter = Writer{
        .writerFn = struct {
            fn write(self: *const Writer, message: []const u8) void {
                _ = self; // Unused
                std.debug.print("{s}\n", .{message});
            }
        }.write,
    };

    pub fn init(name: []const u8, level: Level) Logger {
        return Logger{
            .level = level,
            .name = name,
            .writer = @constCast(&StdoutWriter), // Degault to stdout
        };
    }

    // New init function that allows specifying a custom writer
    pub fn initWithWriter(name: []const u8, level: Level, writer: *Writer) Logger {
        return Logger{
            .level = level,
            .name = name,
            .writer = writer,
        };
    }

    fn log(self: *const Logger, level: Level, message: []const u8) void {
        if (self.level.toInt() <= level.toInt()) {
            // Create a timestamp using Shijian
            const shijian = Shijian.init(null); // null gets current timestamp

            var time_buf: [100]u8 = undefined;
            const time_fmt = "{d}-{d}-{d} {d}:{d}:{d}";
            const timestamp = std.fmt.bufPrint(&time_buf, time_fmt, .{
                shijian.getYear(),
                shijian.getMonth(),
                shijian.getDayOfMonth(),
                shijian.getHour(),
                shijian.getMinute(),
                shijian.getSecond(),
            }) catch "time_err";

            // Get thread ID for additional context
            const thread_id = std.Thread.getCurrentId();

            // Format the log message
            var msg_buf: [1024]u8 = undefined;
            const msg_fmt = "{s} [{s}] [{s}] (Thread: {d}) {s}";
            const full_message = std.fmt.bufPrint(&msg_buf, msg_fmt, .{
                timestamp,
                level.toString(),
                self.name,
                thread_id,
                message,
            }) catch return;

            // Use the writer to output the message
            self.writer.write(full_message);
        }
    }

    pub fn debug(self: *const Logger, message: []const u8) void {
        if (self.level.toInt() <= Level.DEBUG.toInt()) {
            self.log(Level.DEBUG, message);
        }
    }

    pub fn info(self: *const Logger, message: []const u8) void {
        if (self.level.toInt() <= Level.INFO.toInt()) {
            self.log(Level.INFO, message);
        }
    }

    pub fn warning(self: *const Logger, message: []const u8) void {
        if (self.level.toInt() <= Level.WARNING.toInt()) {
            self.log(Level.WARNING, message);
        }
    }

    pub fn err(self: *const Logger, message: []const u8) void {
        if (self.level.toInt() <= Level.ERROR.toInt()) {
            self.log(Level.ERROR, message);
        }
    }

    pub fn fatal(self: *const Logger, message: []const u8) void {
        if (self.level.toInt() <= Level.FATAL.toInt()) {
            self.log(Level.FATAL, message);
        }
    }

    // Supporting string interpolation

    pub fn debugf(self: *const Logger, comptime fmt: []const u8, args: anytype) void {
        if (self.level.toInt() <= Level.DEBUG.toInt()) {
            var buf: [1024]u8 = undefined;
            const message = std.fmt.bufPrint(&buf, fmt, args) catch return;
            self.log(Level.DEBUG, message);
        }
    }

    pub fn infof(self: *const Logger, comptime fmt: []const u8, args: anytype) void {
        if (self.level.toInt() <= Level.INFO.toInt()) {
            var buf: [1024]u8 = undefined;
            const message = std.fmt.bufPrint(&buf, fmt, args) catch return;
            self.log(Level.INFO, message);
        }
    }
    pub fn warningf(self: *const Logger, comptime fmt: []const u8, args: anytype) void {
        if (self.level.toInt() <= Level.WARNING.toInt()) {
            var buf: [1024]u8 = undefined;
            const message = std.fmt.bufPrint(&buf, fmt, args) catch return;
            self.log(Level.WARNING, message);
        }
    }
    pub fn errf(self: *const Logger, comptime fmt: []const u8, args: anytype) void {
        if (self.level.toInt() <= Level.ERROR.toInt()) {
            var buf: [1024]u8 = undefined;
            const message = std.fmt.bufPrint(&buf, fmt, args) catch return;
            self.log(Level.ERROR, message);
        }
    }
    pub fn fatalf(self: *const Logger, comptime fmt: []const u8, args: anytype) void {
        if (self.level.toInt() <= Level.FATAL.toInt()) {
            var buf: [1024]u8 = undefined;
            const message = std.fmt.bufPrint(&buf, fmt, args) catch return;
            self.log(Level.FATAL, message);
        }
    }
};

pub const Level = enum(u8) {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    FATAL = 4,

    pub fn toInt(self: Level) u8 {
        return @intFromEnum(self);
    }

    pub fn toString(self: Level) []const u8 {
        return switch (self) {
            .DEBUG => "DEBUG",
            .INFO => "INFO",
            .WARNING => "WARNING",
            .ERROR => "ERROR",
            .FATAL => "FATAL",
        };
    }
};
