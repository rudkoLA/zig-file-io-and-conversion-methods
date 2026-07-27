const std = @import("std");
const Io = std.Io;

const perf_io = @import("perf_io.zig");

pub fn method1(data: *std.ArrayList([8]u8), results: *std.ArrayList(u64)) !void {
    for (data.items) |item| {
        results.addOneAssumeCapacity().* += try std.fmt.parseInt(u64, &item, 10);
    }
}

pub fn method2(data: *std.ArrayList([8]u8), results: *std.ArrayList(u64)) !void {
    for (data.items) |item| {
        results.addOneAssumeCapacity().* += try std.fmt.parseUnsigned(u64, &item, 10);
    }
}

pub fn method3(data: *std.ArrayList([8]u8), results: *std.ArrayList(u64)) !void {
    for (data.items) |item| {
        results.addOneAssumeCapacity().* += @trunc(try std.fmt.parseFloat(f64, &item));
    }
}

pub fn method4(data: *std.ArrayList([8]u8), results: *std.ArrayList(u64)) !void {
    for (data.items) |item| {
        var num: u64 = 0;

        for (item) |byte| {
            num += (byte - '0');

            num *= 10;
        }

        results.addOneAssumeCapacity().* += num;
    }
}

pub fn method5(data: *std.ArrayList([8]u8), results: *std.ArrayList(u64)) !void {
    const weights_array = comptime weights_calc: {
        var weights: [8]u64 = undefined;
        var power: u64 = 10000000;

        for (0..8) |i| {
            weights[i] = power;
            power /= 10;
        }

        break :weights_calc weights;
    };

    const weights: @Vector(8, u64) = weights_array;

    for (data.items) |item| {
        const item_vector: @Vector(8, u64) = item;

        const digits: @Vector(8, u64) = item_vector - @as(@Vector(8, u64), @splat('0'));

        const product = digits * weights;
        results.addOneAssumeCapacity().* += @reduce(.Add, product);
    }
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const gpa = init.gpa;

    const args = try init.minimal.args.toSlice(arena);

    if (args.len != 3) return error.ArgumentError;

    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    const file = try cwd.openFile(io, args[1], .{});
    defer file.close(io);

    var read_buf: [1 << 12]u8 = undefined;

    var file_reader = file.reader(io, &read_buf);
    const reader = &file_reader.interface;

    var arr: std.ArrayListAligned([8]u8, null) = .empty;
    defer arr.deinit(gpa);

    var results: std.ArrayListAligned(u64, null) = .empty;
    defer results.deinit(gpa);

    try perf_io.method6(gpa, reader, &arr);

    try results.ensureUnusedCapacity(gpa, arr.items.len);

    const method = try std.fmt.parseInt(u8, args[2], 10);

    const start = std.Io.Timestamp.now(io, .real);

    switch (method) {
        1 => {
            try method1(&arr, &results);
        },
        2 => {
            try method2(&arr, &results);
        },
        3 => {
            try method3(&arr, &results);
        },
        4 => {
            try method4(&arr, &results);
        },
        5 => {
            try method5(&arr, &results);
        },
        else => {
            std.debug.print("wrong method\n", .{});
            return;
        },
    }

    const end = std.Io.Timestamp.now(io, .real);

    const time = start.durationTo(end);

    var number_sum: u64 = 0;

    for (results.items) |value| {
        number_sum += value;
    }

    std.debug.print("sum = {d}\n", .{number_sum & 63});
    std.debug.print("time = {d}\n", .{time.toMilliseconds()});
}
