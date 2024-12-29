package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

main :: proc() {
	rules, page_rows := read_rules_and_pages("./input.txt")


	test := [dynamic]string{"1", "2", "3", "4", "5"}
	remove_and_insert(&test, 2, 0)

	middle_numbers := [dynamic]u8{}

	for &row in page_rows {
		if is_row_valid(row, rules) {
			continue
		}

		if !is_row_valid(row, rules) {
			fix_row(&row, rules)
			append(&middle_numbers, get_middle_number(row))
		}
	}

	total := sum(middle_numbers)

	fmt.println("sum: ", total)
}

fix_row :: proc(row: ^string, rules: [dynamic]string) {
	pages := strings.split(row^, ",")
	pages_dynamic := make([dynamic]string, len(pages), len(pages))
	copy(pages_dynamic[:], pages[:])

	for page, current_page_index in pages_dynamic {
		for rule in rules {
			split_rule := strings.split(rule, "|")

			before := split_rule[0]
			after := split_rule[1]

			found_after_index := find_index(pages_dynamic, after)
			found_before_index := find_index(pages_dynamic, before)

			if found_after_index != -1 &&
			   found_before_index != -1 &&
			   found_after_index < found_before_index {

				remove_and_insert(&pages_dynamic, found_before_index, found_after_index)
				row^ = strings.join(pages_dynamic[:], ",")
			}
		}
	}
}

remove_and_insert :: proc(array: ^[dynamic]string, remove_index: int, insert_index: int) {
	removed_item := array[remove_index]
	replaced_item := array[insert_index]

	inject_at(array, insert_index, removed_item)
	ordered_remove(array, remove_index + 1)
}


find_index :: proc(arr: [dynamic]string, target: string) -> int {
	for item, index in arr {
		if item == target {
			return index
		}
	}
	return -1
}

is_row_valid :: proc(row: string, rules: [dynamic]string) -> bool {
	is_valid := true

	pages := strings.split(row, ",")

	for page in pages {
		for rule in rules {
			split_rule := strings.split(rule, "|")

			before := split_rule[0]
			after := split_rule[1]

			if before != page {
				continue
			}

			for current_page in pages {
				if current_page == before {
					break
				}

				if current_page == after {
					return false
				}
			}
		}
	}

	return is_valid
}

sum :: proc(numbers: [dynamic]u8) -> uint {
	total: uint = 0

	for number in numbers {
		total += uint(number)
	}

	return total
}

get_middle_number :: proc(row: string) -> u8 {
	pages := strings.split(row, ",")
	middle_index: uint = len(pages) / 2

	number, ok := strconv.parse_uint(pages[middle_index])
	if !ok {
		return 0
	}

	return u8(number)
}

read_rules_and_pages :: proc(
	path: string,
) -> (
	rules: [dynamic]string,
	page_rows: [dynamic]string,
) {
	file_data, ok := os.read_entire_file(path, context.allocator)

	if !ok {
		return rules, page_rows
	}

	defer delete(file_data)

	buffer := string(file_data)

	has_reached_pages := false

	for line in strings.split_lines_iterator(&buffer) {
		// Need to clone the line, otherwise it just points to the original buffer, which gets deleted
		line_clone := strings.clone(line)

		if line == "" {
			has_reached_pages = true
			continue
		}

		if has_reached_pages {
			append(&page_rows, line_clone)
		} else {
			append(&rules, line_clone)
		}
	}

	return rules, page_rows
}
