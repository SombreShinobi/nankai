const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Cmd = enum { inc, dec, ls, invalid };
const Error = error{ InvalidCommand, CounterNameTooLong, FileNotFound };
const FileContent = struct { content: []u8, path: []u8 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    const stdErr = std.io.getStdErr().writer();
    const stdOut = std.io.getStdOut().writer();

    const cmd = try parseCmd(args[1]);

    switch (cmd) {
        .inc => {
            try appendToFile(args[2], try now(allocator));
        },
        .dec => {
            const removedLn = removeLn(args[2], allocator) catch return stdErr.print("Error: Counter doesn't exist!\n", .{});
            stdOut.print("Removed value {s}", .{removedLn}) catch return;
        },
        .ls => {
            const file = read(args[2], allocator) catch return stdErr.print("Error: Counter doesn't exist!\n", .{});
            stdOut.print("Entries:\n{s}", .{file.content}) catch return;
        },
        .invalid => stdErr.print("Invalid command!\n", .{}) catch return,
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
    const file = try read(name, alloc);

    const prevEntryPos: u64 = file.content.len - 20;

    if (prevEntryPos == 0) {
        try std.fs.cwd().deleteFile(file.path);
        return file.content[prevEntryPos..file.content.len];
    }

    const outFile = try std.fs.cwd().openFile(file.path, .{ .mode = .write_only });
    defer outFile.close();

    try outFile.setEndPos(0);
    try outFile.writeAll(file.content[0..prevEntryPos]);

    return file.content[prevEntryPos..file.content.len];
}

fn read(name: []const u8, alloc: Allocator) !FileContent {
    const path = try appendFilePath(name);

    const readFile = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch return Error.FileNotFound;
    defer readFile.close();

    return .{ .content = try readFile.readToEndAlloc(alloc, std.math.maxInt(usize)), .path = path };
}

fn parseCmd(command: [:0]u8) Error!Cmd {
    return std.meta.stringToEnum(Cmd, command) orelse return Cmd.invalid;
}

fn appendFilePath(name: []const u8) ![]u8 {
    if (name.len > 124) return Error.CounterNameTooLong;

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

    return try std.fmt.allocPrint(alloc, "{d}-{:02}-{:02}T{:02}:{:02}:{:02}", .{ year.year, month.month.numeric(), day, hours, minutes, seconds });
}
