const std = @import("std");
const parser = @import("parser.zig");

const Allocator = std.mem.Allocator;
const SplitIterator = std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar);

pub fn list(content: []u8, opt: ?parser.Option, optVal: ?[]const u8, alloc: Allocator) ![]u8 {
    if (optVal == null) {
        return content;
    }

    var rows = std.mem.splitScalar(u8, content, '\n');
    var result = std.ArrayList(u8).init(alloc);

    switch (opt.?.read) {
        .day => try filter(&result, &rows, optVal.?, 8, 10),
        .month => try filter(&result, &rows, optVal.?, 5, 7),
        .year => try filter(&result, &rows, optVal.?, 0, 4),
    }

    return try result.toOwnedSlice();
}

fn filter(arrList: *std.ArrayList(u8), rows: *SplitIterator, optVal: []const u8, start: u8, end: u8) !void {
    while (rows.next()) |row| {
        if (row.len > 0 and std.mem.eql(u8, row[start..end], optVal)) {
            try arrList.appendSlice(row);
            try arrList.append('\n');
        }
    }
}

pub fn count(content: []u8, opt: ?parser.Option, optVal: ?[]const u8) !usize {
    if (optVal == null) {
        return content.len;
    }

    var rows = std.mem.splitScalar(u8, content, '\n');

    return switch (opt.?.read) {
        .day => try countFilter(&rows, optVal.?, 8, 10),
        .month => try countFilter(&rows, optVal.?, 5, 7),
        .year => try countFilter(&rows, optVal.?, 0, 4),
    };
}

fn countFilter(rows: *SplitIterator, optVal: []const u8, start: u8, end: u8) !usize {
    var curr: usize = 0;

    while (rows.next()) |row| {
        if (row.len > 0 and std.mem.eql(u8, row[start..end], optVal)) {
            curr += 1;
        }
    }

    return curr;
}
