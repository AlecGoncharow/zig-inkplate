const std = @import("std");
const zig_serial = @import("serial");

const ECHO = "#?*\n\r";
const OK = "OK";

pub fn main() !u8 {
    const port_name = "/dev/ttyUSB0";
    var echo_buffer: [2]u8 = undefined;

    var serial = std.fs.cwd().openFile(port_name, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            try std.io.getStdOut().writer().print("The serial port {s} does not exist.\n", .{port_name});
            return 1;
        },
        else => return err,
    };
    defer serial.close();

    try zig_serial.configureSerialPort(serial, zig_serial.SerialConfig{
        .baud_rate = 115200,
        .word_size = 8,
        .parity = .none,
        .stop_bits = .one,
        .handshake = .none,
    });

    try serial.writer().writeAll(ECHO);

    var read = try serial.reader().read(&echo_buffer);
    if (read != 2) {
        return 1;
    }
    std.debug.print("{s}", .{echo_buffer});
    if (!std.mem.eql(u8, OK, &echo_buffer)) {
        return 1;
    }

    return 0;
}
