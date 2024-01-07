const std = @import("std");

pub const Error = error{ invalid_command, invalid_option };

pub const Cmd = enum { inc, dec, ls, c };
pub const ReadOption = enum { day, month, year };
pub const WriteOption = enum { date };
const Option = union(enum) { read: ReadOption, write: WriteOption };

pub const Instruction = struct { cmd: Cmd, option: ?Option, optval: ?[]const u8 };

pub fn parseInput(args: [][:0]u8) Error!Instruction {
    const cmd = std.meta.stringToEnum(Cmd, args[1]) orelse return Error.invalid_command;

    if (args.len < 4) {
        return Instruction{ .cmd = cmd, .option = null, .optval = null };
    }

    return parseOption(args[3], cmd);
}

fn parseOption(arg: [:0]u8, cmd: Cmd) Error!Instruction {
    if (arg[0] != '-') return Error.invalid_option;
    if (arg[1] != '-') return Error.invalid_option;

    var parts = std.mem.splitScalar(u8, arg, '=');

    const opt = parts.first();
    const option: Option = switch (cmd) {
        .ls, .c => .{ .read = std.meta.stringToEnum(ReadOption, opt[2..]) orelse return Error.invalid_option },
        .dec => return Error.invalid_option,
        else => .{ .write = std.meta.stringToEnum(WriteOption, opt[2..]) orelse return Error.invalid_option },
    };
    const val = parts.next();

    if (val == null or val.?.len > 20) return Error.invalid_option;

    return Instruction{ .cmd = cmd, .option = option, .optval = val };
}
