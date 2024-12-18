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

        const is_safe = try are_permutations_safe(reactor_levels);
        if (is_safe) {
            safe_reports += 1;
        }
        std.debug.print("\n--new report--\n\n", .{});
    }

    std.debug.print("safe reports: {}\n", .{safe_reports});
}

fn are_permutations_safe(original_list: std.ArrayList(u16)) !bool {
    var are_safe = false;

    const permutation_lists = try get_list_permutations(original_list);
    std.debug.print("Permutation lists: {any}", .{permutation_lists.items});

    for (permutation_lists.items) |list| {
        const is_safe = is_list_safe(list);

        if (is_safe) {
            are_safe = true;
            break;
        }
    }

    return are_safe;
}

fn is_list_safe(list: std.ArrayList(u16)) bool {
    var last_item: ?u16 = null;
    var is_safe = false;
    var is_increasing: ?bool = null;

    std.debug.print("is computing list of size: {}\n", .{list.items.len});

    for (list.items) |current_item| {
        if (last_item == null) {
            last_item = current_item;
            continue;
        }

        std.debug.print("last item: {?}\n", .{last_item});
        std.debug.print("current item: {}\n", .{current_item});

        if (last_item) |li| {
            if (is_increasing == null) {
                if (li < current_item) {
                    is_increasing = true;
                } else {
                    is_increasing = false;
                }
            }

            is_safe = is_item_safe(li, current_item, is_increasing);
            if (!is_safe) {
                break;
            }
        }

        last_item = current_item;
    }

    std.debug.print("is_list_safe: {}\n", .{is_safe});

    return is_safe;
}

fn is_item_safe(last_item: i32, item: i32, is_increasing: ?bool) bool {
    var is_safe = true;

    const li_i32: i32 = @intCast(last_item);
    const current_item_i32: i32 = @intCast(item);

    const difference: u32 = @abs(li_i32 - current_item_i32);

    if (is_increasing) |is_increasing_val| {
        if (is_increasing_val and li_i32 > current_item_i32) {
            is_safe = false;
        } else if (!is_increasing_val and li_i32 < current_item_i32) {
            is_safe = false;
        }
    }

    const too_small: bool = difference < 1;
    const too_big: bool = difference > 3;

    const is_unsafe: bool = too_small or too_big;

    if (is_unsafe) {
        is_safe = false;
    }

    return is_safe;
}

fn get_list_permutations(original_list: std.ArrayList(u16)) !std.ArrayList(std.ArrayList(u16)) {
    var ignore_index: usize = 0;

    var permutation_lists = try std.ArrayList(std.ArrayList(u16)).initCapacity(std.heap.page_allocator, original_list.items.len);

    while (ignore_index < original_list.items.len) {
        var curr_index: usize = 0;

        var list = try std.ArrayList(u16).initCapacity(std.heap.page_allocator, original_list.items.len - 1);

        for (original_list.items) |item| {
            if (ignore_index != curr_index) {
                try list.append(item);
            }

            curr_index += 1;
        }

        try permutation_lists.append(list);

        ignore_index += 1;
    }

    return permutation_lists;
}
