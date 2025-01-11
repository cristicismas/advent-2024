package main

import sa "core:container/small_array"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

Operator :: enum {
	ADD,
	MULTIPLY,
	CONCAT,
}

main :: proc() {
	lines := read_lines("./sample_input.txt")

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				for _, entry in track.allocation_map {
					fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
				}
			}
			if len(track.bad_free_array) > 0 {
				for entry in track.bad_free_array {
					fmt.eprintf("%v bad free at %v\n", entry.location, entry.memory)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	sum := 0
	computed_lines := 0

	for line in lines {
		cache: map[string]struct {}
		defer delete(cache)

		split, _err := strings.split(line, ": ")
		defer delete(split)

		result := split[0]

		values := strings.split(split[1], " ")
		defer delete(values)

		result_int, ok := strconv.parse_int(result, 10)

		if !ok {
			fmt.eprintln("ERROR on converting result to int.")
			continue
		}

		if is_result_correct(result_int, values, &cache) {
			fmt.println("correct: ", values)
			sum += result_int
		} else {
			fmt.println("incorrect: ", values)
		}

		computed_lines += 1
		fmt.println("computed lines: ", computed_lines)
	}

	fmt.println("sum: ", sum)
}

is_result_correct :: proc(result: int, values: []string, cache: ^map[string]struct {}) -> bool {
	operators := get_operator_permutations(len(values), cache)
	fmt.println("operators: ", operators)
	fmt.println("operator permutations length: ", len(operators))

	defer delete(operators)

	int_values := str_array_to_int(values)
	defer delete(int_values)

	for operator_permutation, operator_index in operators {
		permutation_result := int_values[0]

		value_index := 1

		for value_index < len(int_values) {
			value := int_values[value_index]

			operator := operator_permutation[value_index - 1]

			switch operator {
			case Operator.ADD:
				permutation_result += value
			case Operator.MULTIPLY:
				permutation_result *= value
			case Operator.CONCAT:
				perm_result_str := int_to_str(permutation_result)
				concatenated_string := strings.concatenate({perm_result_str, values[value_index]})
				defer delete(concatenated_string)
				concat_int, _ok := strconv.parse_int(concatenated_string, 10)
				permutation_result = concat_int
			}

			value_index += 1
		}

		if permutation_result == result {
			// TODO: print the correct permutation?
			return true
		}
	}

	return false
}

int_to_str :: proc(from: int) -> string {
	result := fmt.aprintf("%d", from)

	return result
}

str_array_to_int :: proc(array: []string) -> []int {
	int_arr := make([dynamic]int, len(array), len(array))

	for elem, index in array {
		elem_int, ok := strconv.parse_int(elem, 10)

		if !ok {
			fmt.eprintln("ERROR on converting array element to int.")
			continue
		}

		int_arr[index] = elem_int
	}

	return int_arr[:]
}

clone_array_except_one :: proc(arr: []string, exception_index: int) -> []string {
	cloned_array := make([dynamic]string, 0, len(arr) - 1)

	for elem, index in arr {
		if index == exception_index {
			continue
		}

		append(&cloned_array, elem)
	}

	return cloned_array[:]
}

get_operator_permutations :: proc(values: int, cache: ^map[string]struct {}) -> [][]Operator {
	// Populate array with ADD initially
	initial_permutation := make([dynamic]Operator, values - 1)
	populate_array(initial_permutation[:], Operator.ADD)

	plus_variant_permutations := get_variant_permutations(
		initial_permutation[:],
		Operator.MULTIPLY,
		cache,
	)
	defer delete(plus_variant_permutations)

	VARIANT_TYPES :: 3
	permutations_capacity := pow(VARIANT_TYPES, values - 1)
	permutations := make([dynamic][]Operator, 0, permutations_capacity)

	append(&permutations, initial_permutation[:])
	append(&permutations, ..plus_variant_permutations)

	for permutation in permutations {
		multiply_variants := get_variant_permutations(permutation, Operator.MULTIPLY, cache)
		defer delete(multiply_variants)
		append(&permutations, ..multiply_variants)
	}

	for permutation in permutations {
		concat_variants := get_variant_permutations(permutation, Operator.CONCAT, cache)
		defer delete(concat_variants)
		append(&permutations, ..concat_variants)
	}

	clear(cache)
	free_all(context.temp_allocator)

	return permutations[:]
}

pow :: proc(initial: int, times: int) -> int {
	result := initial

	for i in 1 ..< times {
		result *= initial
	}

	return result
}

get_variant_permutations :: proc(
	variant: []Operator,
	new_operator: Operator,
	cache: ^map[string]struct {},
) -> [][]Operator {
	permutations := make([dynamic][]Operator, 0, len(variant))

	current_permutation: [dynamic]Operator

	for _operator, index in variant {
		current_permutation = make([dynamic]Operator, len(variant))
		copy_variant(&current_permutation, variant)

		current_permutation[index] = new_operator

		operators_string := get_operators_string(current_permutation[:])

		in_cache := operators_string in cache

		if !in_cache {
			append(&permutations, current_permutation[:])
			cache[operators_string] = {}
		}
	}

	return permutations[:]
}

only_has_multiply :: proc(operator_array: []Operator) -> bool {
	for elem in operator_array {
		if elem == Operator.ADD {
			return false
		}
	}

	return true
}

copy_variant :: proc(destination: ^[dynamic]Operator, source: []Operator) -> (ok: bool = true) {
	if len(destination) != len(source) {
		return false
	}

	for operator, index in source {
		destination[index] = operator
	}

	return ok
}

get_operators_string :: proc(operators: []Operator) -> string {
	string_operators := make([dynamic]string, len(operators))
	defer delete(string_operators)

	for operator in operators {
		switch operator {
		case Operator.ADD:
			append(&string_operators, "+")
		case Operator.MULTIPLY:
			append(&string_operators, "*")
		case Operator.CONCAT:
			append(&string_operators, "||")
		}
	}

	joined_string := strings.join(string_operators[:], "", context.temp_allocator)

	return joined_string
}

populate_array :: proc(array: []Operator, value: Operator) {
	i := 0
	for i < len(array) {
		array[i] = value
		i += 1
	}
}

join_with_separator_array :: proc(strings_array: []string, separators: []string) -> string {
	return ""
}

read_lines :: proc(path: string) -> [dynamic]string {
	lines := [dynamic]string{}

	file_data, ok := os.read_entire_file(path, context.allocator)

	if !ok {
		return lines
	}

	defer delete(file_data)

	buffer := string(file_data)

	has_reached_pages := false

	for line in strings.split_lines_iterator(&buffer) {
		// Need to clone the line, otherwise it just points to the original buffer, which gets deleted
		line_clone := strings.clone(line)
		append(&lines, line_clone)
	}

	return lines
}
