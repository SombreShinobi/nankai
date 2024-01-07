const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn now(alloc: Allocator) ![]const u8 {
    const time: u64 = @intCast(std.time.timestamp());

    const epoch = std.time.epoch;
    const epochsecs = epoch.EpochSeconds{ .secs = time };

    const year = epochsecs.getEpochDay().calculateYearDay();
    const month = year.calculateMonthDay();
    const day = month.day_index + 1;
    const dayseconds = epochsecs.getDaySeconds();
    const hours = dayseconds.getHoursIntoDay() + 1;
    const minutes = dayseconds.getMinutesIntoHour();
    const seconds = dayseconds.getSecondsIntoMinute();

    return try std.fmt.allocPrint(alloc, "{d}-{:0>2}-{:0>2}T{:0>2}:{:0>2}:{:0>2}", .{ year.year, month.month.numeric(), day, hours, minutes, seconds });
}
