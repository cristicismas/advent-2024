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

    var difference_ranges = try std.ArrayList(u32).initCapacity(allocator, 1000);

    while (difference_ranges.items.len < 1000) {
        const smallest_left_number = remove_smallest_number(&left_side_numbers);

        if (smallest_left_number) |left| {
            const smallest_right_number = remove_smallest_number(&right_side_numbers);

            if (smallest_right_number) |right| {
                try difference_ranges.append(@abs(left - right));
            }
        }
    }

    const sum = get_array_sum(&difference_ranges);

    std.debug.print("sum: {}\n", .{sum});
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

fn get_array_sum(list: *std.ArrayList(u32)) u32 {
    var sum: u32 = 0;
    for (list.items) |item| {
        sum += item;
    }

    return sum;
}
