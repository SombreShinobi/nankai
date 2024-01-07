const std = @import("std");

pub const Error = error{ invalid_command, invalid_option };

pub const Cmd = enum { inc, dec, ls, c };
pub const ReadOption = enum { day, month, year };
pub const WriteOption = enum { date };

pub const Instruction = struct { cmd: Cmd, option: ?union(enum) { read: ReadOption, write: WriteOption } };

pub fn parseInput(args: [][:0]u8) Error!Instruction {
    const cmd = std.meta.stringToEnum(Cmd, args[1]) orelse return Error.invalid_command;

    if (args.len < 4) {
        return Instruction{ .cmd = cmd, .option = null };
    }

    return switch (cmd) {
        .ls, .c => Instruction{ .cmd = cmd, .option = .{ .read = std.meta.stringToEnum(ReadOption, args[3]) orelse return Error.invalid_option } },
        else => Instruction{ .cmd = cmd, .option = .{ .write = std.meta.stringToEnum(WriteOption, args[3]) orelse return Error.invalid_option } },
    };
}
