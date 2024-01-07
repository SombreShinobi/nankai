const std = @import("std");
const parser = @import("parser.zig");

const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Error = error{ counter_name_too_long, file_not_found };
const ParseError = parser.Error;
const ENTRY_LEN = 20;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    const stdErr = std.io.getStdErr().writer();
    const stdOut = std.io.getStdOut().writer();

    const cmd = parser.parseInput(args) catch |err| {
        switch (err) {
            ParseError.invalid_command => stdErr.print("Invalid command!\n", .{}) catch return,
            ParseError.invalid_option => stdErr.print("Invalid option!\n", .{}) catch return,
        }

        return;
    };

    switch (cmd.cmd) {
        .inc => {
            try appendToFile(args[2], try now(allocator));
        },
        .dec => {
            const removedLn = removeLn(args[2], allocator) catch return stdErr.print("Error: Counter doesn't exist!\n", .{});
            stdOut.print("Removed value {s}", .{removedLn}) catch return;
        },
        .ls => {
            const content = read(args[2], allocator) catch return stdErr.print("Error: Counter doesn't exist!\n", .{});
            stdOut.print("Entries:\n{s}", .{content}) catch return;
        },
        .c => {
            const content = read(args[2], allocator) catch return stdErr.print("Error: Counter doesn't exist!\n", .{});
            stdOut.print("Count: {d}\n", .{content.len / ENTRY_LEN}) catch return;
        },
    }
}

fn appendToFile(name: []const u8, content: []const u8) !void {
    const file = try createFile(name);
    defer file.close();

    const stat = try file.stat();
    try file.seekTo(stat.size);

    const fileContent = try appendLn(content);
    try file.writeAll(fileContent);
}

fn removeLn(name: []const u8, alloc: Allocator) ![]u8 {
    const content = try read(name, alloc);
    const path = try appendFilePath(name);

    const prevEntryPos = content.len - ENTRY_LEN;

    if (prevEntryPos == 0) {
        try std.fs.cwd().deleteFile(path);
        return content[prevEntryPos..content.len];
    }

    const outFile = try std.fs.cwd().openFile(path, .{ .mode = .write_only });
    defer outFile.close();

    try outFile.setEndPos(0);
    try outFile.writeAll(content[0..prevEntryPos]);

    return content[prevEntryPos..content.len];
}

fn read(name: []const u8, alloc: Allocator) ![]u8 {
    const path = try appendFilePath(name);

    const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch return Error.file_not_found;
    defer file.close();

    return try file.readToEndAlloc(alloc, std.math.maxInt(usize));
}

fn appendFilePath(name: []const u8) ![]u8 {
    if (name.len > 124) return Error.counter_name_too_long;

    var buff: [128]u8 = undefined;
    return std.fmt.bufPrint(&buff, "{s}.txt", .{name});
}

fn createFile(name: []const u8) !File {
    const path = try appendFilePath(name);

    const file = try std.fs.cwd().createFile(path, .{ .truncate = false });
    return file;
}

fn appendLn(content: []const u8) ![]u8 {
    var fileContent: [1024]u8 = undefined;
    return try std.fmt.bufPrint(&fileContent, "{s}\n", .{content});
}

fn now(alloc: Allocator) ![]const u8 {
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
