const std = @import("std");
const Io = std.Io;

pub fn method1(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    var item: [8]u8 = undefined;

    while (true) {
        const line = reader.*.takeDelimiter('\n') catch null orelse break;

        if (line[0] == '?') {
            @branchHint(.unlikely);
            return;
        }

        if (line.len == 0) {
            @branchHint(.unlikely);
            continue;
        }

        if (line.len > 8) {
            @branchHint(.unlikely);
            continue;
        }

        char_count.* += line.len;

        @memset(&item, '0');
        @memcpy(item[8 - line.len .. 8], line);

        data.append(gpa, item) catch {};
    }
}

pub fn method2(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    while (true) {
        const line = reader.*.takeDelimiter('\n') catch null orelse break;

        const item_ptr = data.addOne(gpa) catch break;

        if (line.len == 0) {
            @branchHint(.unlikely);
            continue;
        }

        if (line[0] == '?') {
            @branchHint(.unlikely);
            return;
        }

        if (line.len > 8) {
            @branchHint(.unlikely);
            continue;
        }

        char_count.* += line.len;

        @memset(item_ptr, '0');
        @memcpy(item_ptr[8 - line.len .. 8], line);
    }
}

const m3_base = 0x30_30_30_30_30_30_30_30;

pub fn method3(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    var int_rep: u64 = 0;

    var internal_count: u6 = 0;

    while (true) {
        const byte: u64 = reader.*.takeByte() catch null orelse {
            @branchHint(.unlikely);

            if (internal_count != 0) {
                int_rep = int_rep << (8 - internal_count) * 8;

                const bytes = @as([8]u8, @bitCast(int_rep | m3_base));

                data.append(gpa, bytes) catch {};
            }

            break;
        };

        if ('0' <= byte and byte <= '9') {
            int_rep += (byte << (internal_count * 8));

            char_count.* += 1;

            internal_count += 1;
        }

        if (byte == '\n') {
            int_rep = int_rep << (8 - internal_count) * 8;

            const bytes = @as([8]u8, @bitCast(int_rep | m3_base));

            data.append(gpa, bytes) catch {};

            int_rep = 0;
            internal_count = 0;
        }
    }
}

pub fn method4(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    var int_rep: u64 = 0;

    var internal_count: u6 = 0;

    var buffer: [16384]u8 = undefined;

    while (true) {
        const read_bytes = reader.*.readSliceShort(buffer[0..]) catch null orelse break;

        if (read_bytes == 0) break;

        for (buffer[0..read_bytes]) |byte| {
            const large_byte: u64 = byte;

            if ('0' <= large_byte and large_byte <= '9') {
                int_rep += (large_byte << (internal_count * 8));

                char_count.* += 1;

                internal_count += 1;
            }

            if (large_byte == '\n') {
                if (internal_count > 0) {
                    int_rep = int_rep << (8 - internal_count) * 8;

                    const bytes = @as([8]u8, @bitCast(int_rep | m3_base));

                    data.append(gpa, bytes) catch {};

                    int_rep = 0;
                    internal_count = 0;
                }
            }
        }
    }

    if (internal_count > 0) {
        int_rep = int_rep << (8 - internal_count) * 8;

        const bytes = @as([8]u8, @bitCast(int_rep | m3_base));

        data.append(gpa, bytes) catch {};

        int_rep = 0;
        internal_count = 0;
    }
}

pub fn method5(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    var buffer: [16384]u8 = undefined;

    var start_index: usize = 0;

    var read_start: usize = 0;

    var item_ptr: *[8]u8 = data.addOne(gpa) catch return;

    @memset(item_ptr, '0');

    while (true) {
        const bytes_read = reader.*.readSliceShort(buffer[start_index..]) catch null orelse break;

        if (bytes_read == 0) break;

        const end_index = start_index + bytes_read;
        var i: usize = start_index;

        var current_len: usize = read_start;

        while (i < end_index) : (i += 1) {
            const char = buffer[i];

            if (char == '\n') {
                if (current_len > 0) {
                    const copy_len = if (current_len > 8) 8 else current_len;

                    @memcpy(item_ptr[8 - copy_len .. 8], buffer[i - current_len .. i - current_len + copy_len]);
                    char_count.* += copy_len;
                }

                current_len = 0;

                if (!(end_index != 16384 and i == end_index - 1)) {
                    item_ptr = data.addOne(gpa) catch break;
                    @memset(item_ptr, '0');
                }
            } else {
                current_len += 1;
            }
        }

        if (current_len > 0) {
            const remainder_start = end_index - current_len;
            @memcpy(buffer[0..current_len], buffer[remainder_start..end_index]);

            start_index = current_len;

            read_start = current_len;
        } else {
            start_index = 0;
            read_start = 0;
        }
    }
}

pub fn method6(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    var int_rep: u64 = 0;

    var internal_count: u6 = 0;

    const buffer_size = 1 << 17;
    const buffer_size_f: comptime_float = buffer_size;
    const maximum_count: comptime_int = @trunc(buffer_size_f / 8.8);

    var buffer: [buffer_size]u8 = undefined;

    while (true) {
        const read_bytes = reader.*.readSliceShort(buffer[0..]) catch null orelse break;

        if (read_bytes == 0) break;

        data.ensureUnusedCapacity(gpa, maximum_count) catch {};

        for (buffer[0..read_bytes]) |byte| {
            const large_byte: u64 = byte;

            if ('0' <= large_byte and large_byte <= '9') {
                int_rep += (large_byte << (internal_count * 8));

                char_count.* += 1;
                internal_count += 1;
            }

            if (large_byte == '\n' and internal_count > 0) {
                int_rep = int_rep << (8 - internal_count) * 8;

                const bytes = @as([8]u8, @bitCast(int_rep | m3_base));

                data.appendAssumeCapacity(bytes);

                int_rep = 0;
                internal_count = 0;
            }
        }
    }

    if (internal_count > 0) {
        int_rep = int_rep << (8 - internal_count) * 8;

        const bytes = @as([8]u8, @bitCast(int_rep | m3_base));

        data.appendAssumeCapacity(bytes);

        int_rep = 0;
        internal_count = 0;
    }
}

pub fn method7(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    const buffer_size = 1 << 17;
    const buffer_size_f: comptime_float = buffer_size;
    const maximum_count: comptime_int = @trunc(buffer_size_f / 8.8);

    var dest_ptr: *[8]u8 = undefined;

    var buffer: [buffer_size]u8 = undefined;

    var read_start: usize = 0;

    while (true) {
        const read_bytes = reader.*.readSliceShort(buffer[read_start..]) catch null orelse break;

        if (read_bytes == 0) break;

        const valid_len = read_start + read_bytes;

        const last_n = std.mem.findScalarLast(u8, buffer[0..valid_len], '\n') orelse {
            read_start = valid_len;
            continue;
        };

        data.ensureUnusedCapacity(gpa, maximum_count) catch {};

        var split = std.mem.splitScalar(u8, buffer[0..last_n], '\n');

        while (true) {
            const item = split.next() orelse break;

            char_count.* += item.len;

            dest_ptr = data.addOneAssumeCapacity();

            @memset(dest_ptr[0 .. 8 - item.len], '0');

            @memcpy(dest_ptr[8 - item.len .. 8], item);
        }

        read_start = valid_len - last_n - 1;
        @memcpy(buffer[0..read_start], buffer[last_n + 1 .. valid_len]);
    }

    if (read_start > 0) {
        const item = buffer[0..read_start];

        char_count.* += item.len;

        dest_ptr = data.addOne(gpa) catch return;

        @memset(dest_ptr[0 .. 8 - item.len], '0');
        @memcpy(dest_ptr[8 - item.len .. 8], item);
    }
}

pub fn method8(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    const buffer_size = 1 << 17;
    const maximum_count: comptime_int = buffer_size / 8;

    var pending_line: std.ArrayList(u8) = .empty;
    defer pending_line.deinit(gpa);

    var buffer: [buffer_size]u8 = undefined;

    while (true) {
        const read_bytes = reader.*.readSliceShort(buffer[0..]) catch null orelse break;
        if (read_bytes == 0) break;

        pending_line.appendSlice(gpa, buffer[0..read_bytes]) catch {};

        var start: usize = 0;
        while (true) {
            const newline_index = std.mem.indexOfScalarPos(u8, pending_line.items, start, '\n');
            if (newline_index == null) break;

            const line = pending_line.items[start..newline_index.?];
            char_count.* += line.len;

            data.ensureUnusedCapacity(gpa, maximum_count) catch {};

            const dest_index = data.items.len;
            _ = data.addOneAssumeCapacity();
            const dest_ptr = &data.items[dest_index];

            const copy_len = @min(line.len, 8);
            @memset(dest_ptr[0 .. 8 - copy_len], '0');
            @memcpy(dest_ptr[8 - copy_len .. 8], line[0..copy_len]);

            start = newline_index.? + 1;
        }

        if (start > 0) {
            const remainder_len = pending_line.items.len - start;
            var remainder_buf: [256]u8 = undefined;
            @memcpy(remainder_buf[0..remainder_len], pending_line.items[start..]);

            pending_line.clearRetainingCapacity();
            pending_line.appendSlice(gpa, remainder_buf[0..remainder_len]) catch {};
        }
    }

    if (pending_line.items.len > 0) {
        const line = pending_line.items;
        char_count.* += line.len;

        data.ensureUnusedCapacity(gpa, 1) catch {};
        const dest_ptr = data.addOneAssumeCapacity();

        const copy_len = @min(line.len, 8);
        @memset(dest_ptr[0 .. 8 - copy_len], '0');
        @memcpy(dest_ptr[8 - copy_len .. 8], line[0..copy_len]);
    }
}

pub fn method9(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    const buffer_size = 1 << 17;
    const buffer_size_f: comptime_float = buffer_size;
    const maximum_count: comptime_int = @trunc(buffer_size_f / 8.8);

    var buffer: [buffer_size]u8 = undefined;

    var read_start: usize = 0;

    while (true) {
        const read_bytes = reader.*.readSliceShort(buffer[read_start..]) catch null orelse break;

        if (read_bytes == 0) break;

        const total_len = read_start + read_bytes;

        var line_start: usize = 0;

        var i: usize = 0;

        data.ensureUnusedCapacity(gpa, maximum_count) catch break;

        while (i < total_len) : (i += 1) {
            const byte = buffer[i];

            if (byte == '\n') {
                const len = i - line_start;

                const dest_ptr = data.addOneAssumeCapacity();
                @memset(dest_ptr, '0');

                char_count.* += len;

                @memcpy(dest_ptr[8 - len .. 8], buffer[line_start .. line_start + len]);
                line_start = i + 1;
            }
        }

        if (line_start < total_len) {
            read_start = total_len - line_start;
            @memcpy(buffer[0..read_start], buffer[line_start..total_len]);
        } else {
            read_start = 0;
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const gpa = init.gpa;

    const args = try init.minimal.args.toSlice(arena);

    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    const file = try cwd.openFile(io, args[1], .{});
    defer file.close(io);

    var read_buf: [1 << 12]u8 = undefined;

    var char_count: u64 = 0;

    var file_reader = file.reader(io, &read_buf);
    const reader = &file_reader.interface;

    var arr: std.ArrayListAligned([8]u8, null) = .empty;
    defer arr.deinit(gpa);

    const method = std.fmt.parseInt(u8, args[2], 10) catch |err| switch (err) {
        error.InvalidCharacter => {
            std.debug.print("Error: The string contained non-numeric characters.\n", .{});
            return;
        },
        error.Overflow => {
            std.debug.print("Error: The number is too large for a u8.\n", .{});
            return;
        },
    };

    const start = std.Io.Timestamp.now(io, .real);

    switch (method) {
        1 => {
            method1(gpa, reader, &arr, &char_count);
        },
        2 => {
            method2(gpa, reader, &arr, &char_count);
        },
        3 => {
            method3(gpa, reader, &arr, &char_count);
        },
        4 => {
            method4(gpa, reader, &arr, &char_count);
        },
        5 => {
            method5(gpa, reader, &arr, &char_count);
        },
        6 => {
            method6(gpa, reader, &arr, &char_count);
        },
        7 => {
            method7(gpa, reader, &arr, &char_count);
        },
        8 => {
            method8(gpa, reader, &arr, &char_count);
        },
        9 => {
            method9(gpa, reader, &arr, &char_count);
        },
        100 => {
            return;
        },
        else => {
            std.debug.print("wrong method\n", .{});
            return;
        },
    }

    const end = std.Io.Timestamp.now(io, .real);

    const time = start.durationTo(end);

    // for (arr.items) |str| {
    //     std.debug.print("value successfully read: {s}\n", .{str});
    // }

    std.debug.print("char count = {d}\n", .{char_count});
    std.debug.print("time = {d}\n", .{time.toMilliseconds()});
}

test "expect all methods to match" {
    const gpa = std.testing.allocator;

    const io = std.testing.io;
    const cwd = std.Io.Dir.cwd();

    const file_path = "large.mad";
    const ref_file = try cwd.openFile(io, file_path, .{});
    defer ref_file.close(io);

    var ref_buf: [4096]u8 = undefined;
    var ref_reader = ref_file.reader(io, &ref_buf);

    var ref_arr: std.ArrayListAligned([8]u8, null) = .empty;
    defer ref_arr.deinit(gpa);

    var ref_char_count: u64 = 0;
    method1(gpa, &ref_reader.interface, &ref_arr, &ref_char_count);

    for (2..10) |method_num| {
        const test_file = try cwd.openFile(io, file_path, .{});
        defer test_file.close(io);

        var test_buf: [4096]u8 = undefined;
        var test_reader = test_file.reader(io, &test_buf);

        var test_arr: std.ArrayListAligned([8]u8, null) = .empty;
        defer test_arr.deinit(gpa);

        var test_char_count: u64 = 0;

        switch (method_num) {
            2 => method2(gpa, &test_reader.interface, &test_arr, &test_char_count),
            3 => method3(gpa, &test_reader.interface, &test_arr, &test_char_count),
            4 => method4(gpa, &test_reader.interface, &test_arr, &test_char_count),
            5 => method5(gpa, &test_reader.interface, &test_arr, &test_char_count),
            6 => method6(gpa, &test_reader.interface, &test_arr, &test_char_count),
            7 => method7(gpa, &test_reader.interface, &test_arr, &test_char_count),
            8 => method8(gpa, &test_reader.interface, &test_arr, &test_char_count),
            9 => method9(gpa, &test_reader.interface, &test_arr, &test_char_count),
            else => unreachable,
        }

        // Check length
        try std.testing.expectEqual(ref_arr.items.len, test_arr.items.len);

        // Check char_count
        try std.testing.expectEqual(ref_char_count, test_char_count);

        // Check each item
        var wrong: usize = 0;
        for (ref_arr.items, 0..) |ref_item, idx| {
            if (!std.mem.eql(u8, &ref_item, &test_arr.items[idx])) {
                wrong += 1;
                std.debug.print("method {d} diff at index {d}: expected '{s}', got '{s}'\n", .{
                    method_num, idx, ref_item, test_arr.items[idx],
                });
                if (wrong >= 10) break;
            }
        }

        try std.testing.expectEqual(@as(usize, 0), wrong);
        std.debug.print("success: method {d} matches reference (method1)\n", .{method_num});
    }
}
