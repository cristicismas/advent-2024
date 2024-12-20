package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:unicode/utf8"

MAX_ARRAY_SIZE :: 140

Vector2 :: [2]int

main :: proc() {
	runes_array := read_runes("./input.txt")

	sum: uint = 0

	for row, row_index in runes_array {
		for col, col_index in row {
			is_occurance := is_x_occurence(runes_array, Vector2{row_index, col_index})
			if is_occurance {
				sum += 1
			}
		}
	}

	// FIXME: 5638 and 2819 and 2816 too high
	fmt.println("Sum: ", sum)
}


read_runes :: proc(path: string) -> [MAX_ARRAY_SIZE][MAX_ARRAY_SIZE]rune {
	output := [MAX_ARRAY_SIZE][MAX_ARRAY_SIZE]rune{}

	data, ok := os.read_entire_file(path, context.allocator)

	if !ok {
		return output
	}

	defer delete(data, context.allocator)

	buf := string(data)

	index := 0
	for line in strings.split_lines_iterator(&buf) {
		line_clone := strings.clone(line, context.allocator)

		runes := utf8.string_to_runes(line_clone)

		for rune, rune_index in runes {
			output[index][rune_index] = rune
		}

		index += 1
		assert(index <= MAX_ARRAY_SIZE)
	}

	return output
}

is_x_occurence :: proc(array: [MAX_ARRAY_SIZE][MAX_ARRAY_SIZE]rune, position: Vector2) -> bool {
	row := position.x
	col := position.y

	if row - 1 >= 0 && row + 1 < MAX_ARRAY_SIZE && col - 1 >= 0 && col + 1 < MAX_ARRAY_SIZE {
		center := array[row][col]
		up_left := array[row - 1][col - 1]
		up_right := array[row - 1][col + 1]
		down_right := array[row + 1][col + 1]
		down_left := array[row + 1][col - 1]

		if center != 'A' {
			return false
		}

		up_left_down_right := false

		// Up left - Down right direction
		if (up_left == 'S' && down_right == 'M') || (up_left == 'M' && down_right == 'S') {
			up_left_down_right = true
		}

		down_left_up_right := false

		// Down left - Up right direction
		if (down_left == 'S' && up_right == 'M') || (down_left == 'M' && up_right == 'S') {
			down_left_up_right = true
		}

		return up_left_down_right && down_left_up_right

		// if row == 3 && col == 8 {
		// 	fmt.println(position)
		// 	fmt.println("center: ", center)
		// 	fmt.println("up_left: ", up_left)
		// 	fmt.println("up_right: ", up_right)
		// 	fmt.println("down_right: ", down_right)
		// 	fmt.println("down_left: ", down_left)
		// }

	}

	return false
}
