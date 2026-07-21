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

    var carried_over_len: usize = 0;

    var item_ptr: *[8]u8 = data.addOne(gpa) catch return;
    @memset(item_ptr, '0');

    while (true) {
        const bytes_read = reader.*.readSliceShort(buffer[start_index..]) catch null orelse break;

        if (bytes_read == 0) break;

        const end_index = start_index + bytes_read;
        var i: usize = start_index;

        var current_len: usize = carried_over_len;

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

            carried_over_len = current_len;
        } else {
            start_index = 0;
            carried_over_len = 0;
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

        const last_n = std.mem.findScalarLast(u8, &buffer, '\n') orelse break;

        data.ensureUnusedCapacity(gpa, maximum_count) catch {};

        var split = std.mem.splitScalar(u8, buffer[0..last_n], '\n');

        while (true) {
            const item = split.next() orelse break;
            // std.debug.print("{s}", .{item});

            char_count.* += item.len;

            dest_ptr = data.addOneAssumeCapacity();

            @memset(dest_ptr[0 .. 8 - item.len], '0');

            @memcpy(dest_ptr[8 - item.len .. 8], item);
        }

        read_start = buffer_size - last_n - 1;

        @memcpy(buffer[0..read_start], buffer[last_n + 1 .. buffer_size]);
    }
}

pub fn method8(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    const buffer_size = 1 << 17;
    const buffer_size_f: comptime_float = buffer_size;
    const maximum_count: comptime_int = @trunc(buffer_size_f / 8.8);

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
            const remainder = pending_line.items[start..];
            pending_line.clearRetainingCapacity();
            pending_line.appendSlice(gpa, remainder) catch {};
        }
    }

    if (pending_line.items.len > 0) {
        const line = pending_line.items;
        char_count.* += line.len;

        data.ensureUnusedCapacity(gpa, maximum_count) catch {};

        const dest_index = data.items.len;
        _ = data.addOneAssumeCapacity();
        const dest_ptr = &data.items[dest_index];

        const copy_len = @min(line.len, 8);
        @memset(dest_ptr[0 .. 8 - copy_len], '0');
        @memcpy(dest_ptr[8 - copy_len .. 8], line[0..copy_len]);
    }
}

pub fn method9(gpa: std.mem.Allocator, reader: *std.Io.Reader, data: *std.ArrayList([8]u8), char_count: *u64) void {
    const buffer_size = 1 << 17;
    var buffer: [buffer_size]u8 = undefined;

    // Track how many bytes from the previous chunk are still pending
    var pending_len: usize = 0;

    while (true) {
        // Read into the buffer after any pending data
        const read_bytes = reader.*.readSliceShort(buffer[pending_len..]) catch null orelse break;

        if (read_bytes == 0) break;

        const total_len = pending_len + read_bytes;
        var i: usize = 0;

        // Pre-allocate an item to write into
        var dest_ptr = data.addOne(gpa) catch break;
        @memset(dest_ptr, '0');

        var current_line_len: usize = 0;
        var line_start: usize = 0;

        while (i < total_len) : (i += 1) {
            const byte = buffer[i];

            if (byte == '\n') {
                // Process the line from line_start to i
                const len = i - line_start;
                if (len > 0) {
                    char_count.* += len;
                    const copy_len = if (len > 8) 8 else len;
                    @memcpy(dest_ptr[8 - copy_len .. 8], buffer[line_start .. line_start + copy_len]);
                }

                // Reset for next line
                current_line_len = 0;
                line_start = i + 1;

                // Allocate next item
                dest_ptr = data.addOne(gpa) catch break;
                @memset(dest_ptr, '0');
            }
        }

        // Handle remainder
        if (line_start < total_len) {
            // Move the incomplete line to the start of the buffer
            const remainder = total_len - line_start;
            @memcpy(buffer[0..remainder], buffer[line_start..total_len]);
            pending_len = remainder;
        } else {
            pending_len = 0;
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

    var read_buf: [4096]u8 = undefined;

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
            const path = args[1];

            var arr1: std.ArrayListAligned([8]u8, null) = .empty;
            defer arr1.deinit(gpa);
            var arr2: std.ArrayListAligned([8]u8, null) = .empty;
            defer arr2.deinit(gpa);
            var arr3: std.ArrayListAligned([8]u8, null) = .empty;
            defer arr3.deinit(gpa);

            var cc1: u64 = 0;
            var cc2: u64 = 0;
            var cc3: u64 = 0;

            {
                const file1 = try cwd.openFile(io, path, .{});
                defer file1.close(io);
                var buf1: [4096]u8 = undefined;
                var r1 = file1.reader(io, &buf1);
                method1(gpa, &r1.interface, &arr1, &cc1);
            }

            {
                const file2 = try cwd.openFile(io, path, .{});
                defer file2.close(io);
                var buf2: [4096]u8 = undefined;
                var r2 = file2.reader(io, &buf2);
                method6(gpa, &r2.interface, &arr2, &cc2);
            }

            {
                const file3 = try cwd.openFile(io, path, .{});
                defer file3.close(io);
                var buf3: [4096]u8 = undefined;
                var r3 = file3.reader(io, &buf3);
                method7(gpa, &r3.interface, &arr3, &cc3);
            }

            var wrong: usize = 0;
            const max_len = @max(arr1.items.len, @max(arr2.items.len, arr3.items.len));
            var i: usize = 0;
            while (i < max_len and wrong < 10) : (i += 1) {
                const a_ok = i < arr1.items.len;
                const b_ok = i < arr2.items.len;
                const c_ok = i < arr3.items.len;

                const same = a_ok and b_ok and c_ok and std.mem.eql(u8, &arr1.items[i], &arr2.items[i]) and std.mem.eql(u8, &arr1.items[i], &arr3.items[i]);
                if (!same) {
                    wrong += 1;
                    std.debug.print("diff {d}: ", .{i});
                    std.debug.print("{s} vs ", .{arr1.items[i]});
                    std.debug.print("{s} vs ", .{arr2.items[i]});
                    std.debug.print("{s}\n", .{arr3.items[i]});
                }
            }

            if (wrong == 0 and arr1.items.len == arr2.items.len and arr1.items.len == arr3.items.len and cc1 == cc2 and cc1 == cc3) {
                std.debug.print("success: all methods match\n", .{});
            } else if (wrong >= 10) {
                std.debug.print("stopped after 10 differences\n", .{});
            }

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
