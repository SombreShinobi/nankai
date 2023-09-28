const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const Cmd = enum { inc, dec, ls, invalid };
const Error = error{ InvalidCommand, CounterNameTooLong };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    const stdErr = std.io.getStdErr().writer();
    const stdOut = std.io.getStdOut().writer();

    const cmd = parseCommand(args[1]) catch .invalid;

    switch (cmd) {
        .inc => {
            try appendToFile(args[2], try now(allocator));
            stdOut.print("Imma {s} that for ya!\n", .{"inc"}) catch return;
        },
        .dec => {
            stdOut.print("Imma {s} that for ya!\n", .{"dec"}) catch return;
        },
        .ls => {
            stdOut.print("Imma {s} that for ya!\n", .{"ls"}) catch return;
        },
        .invalid => {
            stdErr.print("Invalid command!\n", .{}) catch return;
            return;
        },
    }

    std.debug.print("Arguments: {s}\n", .{args});
}

fn parseCommand(command: [:0]u8) Error!Cmd {
    return std.meta.stringToEnum(Cmd, command) orelse return Error.InvalidCommand;
}

fn appendToFile(name: []const u8, content: []const u8) !void {
    // TODO: Add propper error handling
    const file = try createFile(name);
    defer file.close();

    const stat = try file.stat();
    try file.seekTo(stat.size);

    const fileContent = try appendNewLn(content);
    try file.writeAll(fileContent);
}

fn createFile(name: []const u8) !File {
    if (name.len > 124) return Error.CounterNameTooLong;

    var buffer: [128]u8 = undefined;
    const fileName = try std.fmt.bufPrint(&buffer, "{s}.txt", .{name});

    const file = try std.fs.cwd().createFile(fileName, .{ .truncate = false });
    return file;
}

fn appendNewLn(content: []const u8) ![]u8 {
    var fileContent: [512]u8 = undefined;
    return try std.fmt.bufPrint(&fileContent, "{s}\n", .{content});
}

fn now(alloc: Allocator) ![]const u8 {
    const time = std.time.timestamp();
    return try std.fmt.allocPrint(alloc, "{d}", .{time});
}
