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
    const opt: Option = switch (cmd) {
        .ls => std.meta.stringToEnum(ReadOption, args[3]) orelse return Error.invalid_option,
        else => std.meta.stringToEnum(WriteOption, args[3]) orelse return Error.invalid_option,
    };

    const inst = Instruction{
        .cmd = cmd,
        .option = opt,
    };

    return inst;
}

// pub fn parseCmd(command: [:0]u8) Error!Cmd {
//     return std.meta.stringToEnum(Cmd, command) orelse return Error.InvalidCommand;
// }
