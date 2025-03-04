/// A Very basic wrapper around `time` and `epoch` std libraries.
/// The module time provides functionality for measuring and displaying time.
const std = @import("std");

const time = std.time;
const testing = std.testing;
const expect = testing.expect;

const epoch = time.epoch;
const EpochSeconds = epoch.EpochSeconds;
const Month = epoch.Month;

// For now, only English is supported
// TODO: Internationalization
const Months = enum(u4) {
    jan = 1,
    feb,
    mar,
    apr,
    may,
    jun,
    jul,
    aug,
    sep,
    oct,
    nov,
    dec,

    /// return the numeric calendar value for the given month
    /// i.e. jan=1, feb=2, etc
    pub fn numeric(self: Months) u4 {
        return @intFromEnum(self);
    }

    // Return the textual calendar value for the given numeric month
    // i.e jan=january, feb=february, etc
    pub fn string(self: Months) []const u8 {
        // All lowercase only
        return switch (self) {
            .jan => "january",
            .feb => "february",
            .mar => "march",
            .apr => "april",
            .may => "may",
            .jun => "june",
            .jul => "july",
            .aug => "august",
            .sep => "september",
            .oct => "october",
            .nov => "November",
            .dec => "december",
        };
    }
};

pub const Shijian = struct {
    timestamp: i64,
    epoch_seconds: EpochSeconds,

    // TODO: better way to detect bad initializer values
    pub fn init(timestamp: ?i64) Shijian {
        const ts: i64 = timestamp orelse time.timestamp();
        const es: u64 = @intCast(ts);
        return Shijian{
            .timestamp = ts,
            .epoch_seconds = EpochSeconds{ .secs = es },
        };
    }

    pub fn getYear(self: *const Shijian) u16 {
        return self.epoch_seconds.getEpochDay().calculateYearDay().year;
    }
    pub fn getMonth(self: *const Shijian) u4 {
        return self.epoch_seconds.getEpochDay().calculateYearDay().calculateMonthDay().month.numeric();
    }
    pub fn getMonthName(self: *const Shijian) []const u8 {
        return self._getMonth();
    }
    pub fn getDayOfMonth(self: *const Shijian) u5 {
        return self.epoch_seconds.getEpochDay().calculateYearDay().calculateMonthDay().day_index;
    }
    pub fn getHour(self: *const Shijian) u5 {
        return self.epoch_seconds.getDaySeconds().getHoursIntoDay();
    }
    pub fn getMinute(self: *const Shijian) u6 {
        return self.epoch_seconds.getDaySeconds().getMinutesIntoHour();
    }
    pub fn getSecond(self: *const Shijian) u6 {
        return self.epoch_seconds.getDaySeconds().getSecondsIntoMinute();
    }

    pub fn now(self: Shijian) i64 {
        // Maybe: return time.timestamp();
        return self.timestamp;
    }

    fn _getMonth(self: Shijian) []const u8 {
        const numeric_month = self.epoch_seconds.getEpochDay().calculateYearDay().calculateMonthDay().month.numeric();
        const month: Months = @enumFromInt(numeric_month);
        return month.string();
    }
};

test "parsing time" {
    const timestamp = 1741039628;
    const sj = Shijian.init(timestamp);
    try testing.expect(sj.getYear() == 2025);
    try testing.expectEqual("march", sj.getMonthName());
    try testing.expect(sj.getDayOfMonth() == 2);
    try testing.expect(sj.getHour() == 22);
    try testing.expect(sj.getMinute() == 7);
    try testing.expect(sj.getSecond() == 8);
    try testing.expect(sj.now() == timestamp);
}
