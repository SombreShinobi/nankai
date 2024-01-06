const std = @import("std");
const types = @import("types.zig");

const Error = types.Error;
const Cmd = types.Cmd;
const Instruction = types.Instruction;
const Option = types.Option;
const ReadOption = types.ReadOption;
const WriteOption = types.WriteOption;

pub fn parseInput(args: [][:0]u8) Error!Instruction {
    const cmd = std.meta.stringToEnum(Cmd, args[1]) orelse return Error.invalid_command;

    return switch (cmd) {
        .ls => Instruction{ .cmd = cmd, .option = .{ .read = std.meta.stringToEnum(ReadOption, args[3]) orelse return Error.invalid_option } },
        else => Instruction{ .cmd = cmd, .option = .{ .write = std.meta.stringToEnum(WriteOption, args[3]) orelse return Error.invalid_option } },
    };
}
