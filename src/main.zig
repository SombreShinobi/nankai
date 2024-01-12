const std = @import("std");
const parser = @import("parser.zig");
const file = @import("file.zig");
const date = @import("date.zig");

const Allocator = std.mem.Allocator;

const ParserError = parser.Error;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    const stdErr = std.io.getStdErr().writer();
    const stdOut = std.io.getStdOut().writer();

    const input = parser.parseInput(args) catch |err| {
        switch (err) {
            ParserError.invalid_command => stdErr.print("Invalid command!\n", .{}) catch return,
            ParserError.invalid_option => stdErr.print("Invalid option!\n", .{}) catch return,
        }

        return;
    };

    switch (input.cmd) {
        .inc => {
            var value: []const u8 = undefined;
            if (input.option != null and input.option.?.write == parser.WriteOption.date) {
                value = input.optval.?;
            } else {
                value = date.now(allocator) catch return stdErr.print("Error: Cannot get current date!\n", .{});
            }

            file.appendToFile(args[2], value) catch return stdErr.print("Error: Cannot append to file!\n", .{});
        },
        .dec => {
            const removedLn = file.removeLn(args[2], allocator) catch return stdErr.print("Error: Counter doesn't exist!\n", .{});
            stdOut.print("{s}", .{removedLn}) catch return;
        },
        .ls => {
            const content = file.read(args[2], allocator) catch return stdErr.print("Error: Counter doesn't exist!\n", .{});
            try list(content, input.option, input.optval, allocator);
        },
        .c => {
            const content = file.read(args[2], allocator) catch return stdErr.print("Error: Counter doesn't exist!\n", .{});
            stdOut.print("{d}\n", .{content.len / file.ENTRY_LEN}) catch return;
        },
    }
}

fn list(content: []u8, opt: ?parser.Option, optVal: ?[]const u8, alloc: Allocator) !void {
    const stdOut = std.io.getStdOut().writer();

    if (optVal == null) {
        stdOut.print("{s}", .{content}) catch return;
        return;
    }

    var rows = std.mem.splitScalar(u8, content, '\n');
    var result = std.ArrayList(u8).init(alloc);

    if (opt.?.read == parser.ReadOption.day) {
        while (rows.next()) |row| {
            if (row.len > 0 and std.mem.eql(u8, row[8..10], optVal.?)) {
                try result.appendSlice(row);
                try result.append('\n');
            }
        }
    } else if (opt.?.read == parser.ReadOption.month) {
        while (rows.next()) |row| {
            if (row.len > 0 and std.mem.eql(u8, row[5..7], optVal.?)) {
                try result.appendSlice(row);
                try result.append('\n');
            }
        }
    } else {
        while (rows.next()) |row| {
            if (row.len > 0 and std.mem.eql(u8, row[0..4], optVal.?)) {
                try result.appendSlice(row);
                try result.append('\n');
            }
        }
    }

    stdOut.print("{s}", .{try result.toOwnedSlice()}) catch return;
}
