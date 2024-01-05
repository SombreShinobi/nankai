pub const Error = error{ invalid_command, invalid_option, counter_name_too_long, file_not_found };
pub const Cmd = enum { inc, dec, ls };

pub const ReadOption = enum { day, month, year };
pub const WriteOption = enum { date };

pub const Option = union(enum) { read: ReadOption, write: WriteOption };

pub const Instruction = struct { cmd: Cmd, option: Option };
