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
			occurences := get_occurences_in_8_directions(
				runes_array,
				Vector2{row_index, col_index},
			)
			sum += occurences
		}
	}

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

get_occurences_in_8_directions :: proc(
	array: [MAX_ARRAY_SIZE][MAX_ARRAY_SIZE]rune,
	position: Vector2,
) -> uint {
	sum: uint = 0

	row := position.x
	col := position.y

	// Right direction
	if col + 3 < MAX_ARRAY_SIZE &&
	   array[row][col] == 'X' &&
	   array[row][col + 1] == 'M' &&
	   array[row][col + 2] == 'A' &&
	   array[row][col + 3] == 'S' {
		sum += 1
	}

	// Left direction
	if col - 3 >= 0 &&
	   array[row][col] == 'X' &&
	   array[row][col - 1] == 'M' &&
	   array[row][col - 2] == 'A' &&
	   array[row][col - 3] == 'S' {
		sum += 1
	}

	// Up direction
	if row - 3 >= 0 &&
	   array[row][col] == 'X' &&
	   array[row - 1][col] == 'M' &&
	   array[row - 2][col] == 'A' &&
	   array[row - 3][col] == 'S' {
		sum += 1
	}

	// Down direction
	if row + 3 < MAX_ARRAY_SIZE &&
	   array[row][col] == 'X' &&
	   array[row + 1][col] == 'M' &&
	   array[row + 2][col] == 'A' &&
	   array[row + 3][col] == 'S' {
		sum += 1
	}

	// Down right direction
	if row + 3 < MAX_ARRAY_SIZE &&
	   col + 3 < MAX_ARRAY_SIZE &&
	   array[row][col] == 'X' &&
	   array[row + 1][col + 1] == 'M' &&
	   array[row + 2][col + 2] == 'A' &&
	   array[row + 3][col + 3] == 'S' {
		sum += 1
	}

	// Up right direction
	if row - 3 >= 0 &&
	   col + 3 < MAX_ARRAY_SIZE &&
	   array[row][col] == 'X' &&
	   array[row - 1][col + 1] == 'M' &&
	   array[row - 2][col + 2] == 'A' &&
	   array[row - 3][col + 3] == 'S' {
		sum += 1
	}

	// Down left direction
	if row + 3 < MAX_ARRAY_SIZE &&
	   col - 3 >= 0 &&
	   array[row][col] == 'X' &&
	   array[row + 1][col - 1] == 'M' &&
	   array[row + 2][col - 2] == 'A' &&
	   array[row + 3][col - 3] == 'S' {
		sum += 1
	}

	// Up left direction
	if row - 3 >= 0 &&
	   col - 3 >= 0 &&
	   array[row][col] == 'X' &&
	   array[row - 1][col - 1] == 'M' &&
	   array[row - 2][col - 2] == 'A' &&
	   array[row - 3][col - 3] == 'S' {
		sum += 1
	}

	return sum
}
