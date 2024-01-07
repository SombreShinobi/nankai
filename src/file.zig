const std = @import("std");

const File = std.fs.File;
const Allocator = std.mem.Allocator;

const Error = error{ counter_name_too_long, file_not_found };

pub const ENTRY_LEN = 20;

pub fn appendToFile(name: []const u8, content: []const u8) !void {
    const file = try createFile(name);
    defer file.close();

    const stat = try file.stat();
    try file.seekTo(stat.size);

    const fileContent = try appendLn(content);
    try file.writeAll(fileContent);
}

pub fn removeLn(name: []const u8, alloc: Allocator) ![]u8 {
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

pub fn read(name: []const u8, alloc: Allocator) ![]u8 {
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
