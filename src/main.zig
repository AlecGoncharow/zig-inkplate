const std = @import("std");
const zig_serial = @import("serial");

const ECHO = "#?*\n\r";
const DISPLAY = "#L(1)*\n\r";
const CLEAR_DISPLAY = "#K(1)*\n\r";
const OK = "OK";
const TEXT_SIZE = "#D(04)*\n\r";
const CURSOR = "#E(150, 320)*\n\r";

fn print(allocator: std.mem.Allocator, serial: std.fs.File, text: []const u8) anyerror!void {
    const string = try std.fmt.allocPrint(allocator, "#C(\"{x}\")*\n\r", .{std.fmt.fmtSliceHexLower(text)});
    try serial.writer().writeAll(string);
}

fn send(serial: std.fs.File, bytes: []const u8) std.os.WriteError!void {
    try serial.writer().writeAll(bytes);
}

pub fn main() !u8 {
    const port_name = "/dev/ttyUSB0";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
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

    try send(serial, CLEAR_DISPLAY);
    try send(serial, DISPLAY);
    try send(serial, TEXT_SIZE);
    try send(serial, CURSOR);
    try print(allocator, serial, "Hello, world!");
    try send(serial, DISPLAY);

    return 0;
}
