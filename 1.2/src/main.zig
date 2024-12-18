const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    const allocator = std.heap.page_allocator;

    var left_side_numbers = try std.ArrayList(i32).initCapacity(allocator, 1001);
    var right_side_numbers = try std.ArrayList(i32).initCapacity(allocator, 1001);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split_line = std.mem.tokenizeSequence(u8, line, "   ");

        const maybeLeft = split_line.next();

        if (maybeLeft) |left| {
            const leftInt: i32 = try std.fmt.parseInt(i32, left, 10);
            try left_side_numbers.append(leftInt);
        }

        const maybeRight = split_line.next();

        if (maybeRight) |right| {
            const rightInt: i32 = try std.fmt.parseInt(i32, right, 10);
            try right_side_numbers.append(rightInt);
        }
    }

    const similarity = get_similarity(left_side_numbers, right_side_numbers);

    std.debug.print("similarity: {}\n", .{similarity});
}

fn remove_smallest_number(list: *std.ArrayList(i32)) ?i32 {
    var smallest_number_temp: i32 = list.items[0];
    var index_to_remove: usize = 0;

    for (0..list.items.len) |i| {
        if (smallest_number_temp > list.items[i]) {
            smallest_number_temp = list.items[i];
            index_to_remove = i;
        }
    }

    const smallest_number: ?i32 = list.orderedRemove(index_to_remove);

    return smallest_number;
}

fn get_array_sum(list: *std.ArrayList(i32)) i32 {
    var sum: i32 = 0;
    for (list.items) |item| {
        sum += item;
    }

    return sum;
}

fn get_occurences(list: std.ArrayList(i32), lookup: i32) u32 {
    var occurences: u32 = 0;

    for (list.items) |item| {
        if (item == lookup) {
            occurences += 1;
        }
    }

    return occurences;
}

fn get_similarity(first_list: std.ArrayList(i32), second_list: std.ArrayList(i32)) u32 {
    var total_occurences: u32 = 0;

    for (first_list.items) |first_list_item| {
        const item_occurences = get_occurences(second_list, first_list_item);
        if (item_occurences > 0) {
            const u32_first_list_item: u32 = @intCast(first_list_item);
            std.debug.print("{}*{}\n", .{ u32_first_list_item, item_occurences });
            total_occurences += u32_first_list_item * item_occurences;
        }
    }

    return total_occurences;
}
