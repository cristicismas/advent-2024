const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    const allocator = std.heap.page_allocator;

    var safe_reports: u32 = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split_line = std.mem.tokenizeSequence(u8, line, " ");

        var reactor_levels = try std.ArrayList(u16).initCapacity(allocator, 10);
        defer reactor_levels.deinit();

        while (split_line.next()) |level| {
            const int_level: u16 = try std.fmt.parseInt(u16, level, 10);
            try reactor_levels.append(int_level);
        }

        const is_safe = is_list_safe(reactor_levels);
        if (is_safe) {
            safe_reports += 1;
        }
        std.debug.print("new report\n", .{});
    }

    std.debug.print("safe reports: {}\n", .{safe_reports});
}

fn is_list_safe(list: std.ArrayList(u16)) bool {
    var last_item: ?u16 = null;
    var is_safe = true;
    var is_increasing: ?bool = null;

    for (list.items) |current_item| {
        std.debug.print("current item: {}\n", .{current_item});

        if (last_item == null) {
            last_item = current_item;
            continue;
        }

        if (last_item) |li| {
            const li_i32: i32 = @intCast(li);
            const current_item_i32: i32 = @intCast(current_item);

            const difference: u32 = @abs(li_i32 - current_item_i32);

            if (is_increasing) |is_increasing_val| {
                if (is_increasing_val and li_i32 > current_item_i32) {
                    is_safe = false;
                    break;
                } else if (!is_increasing_val and li_i32 < current_item_i32) {
                    is_safe = false;
                    break;
                }
            } else {
                if (li_i32 < current_item_i32) {
                    is_increasing = true;
                } else {
                    is_increasing = false;
                }
            }

            const too_small: bool = difference < 1;
            const too_big: bool = difference > 3;

            const is_unsafe: bool = too_small or too_big;

            if (is_unsafe) {
                is_safe = false;
                break;
            }
        }

        last_item = current_item;
    }

    std.debug.print("is_safe: {}\n", .{is_safe});

    return is_safe;
}
