package main

import "core:fmt"
import "core:log"
import "core:os"
import "core:strconv"
import "core:strings"

Operator :: enum {
	ADD,
	MULTIPLY,
}

main :: proc() {
	lines := read_lines("./input.txt")

	sum := 0

	for line in lines {
		cache: map[string]struct {}

		split, _err := strings.split(line, ": ")
		result := split[0]
		values := strings.split(split[1], " ")

		result_int, ok := strconv.parse_int(result, 10)

		if !ok {
			fmt.println("ERROR on converting result to int.")
			continue
		}

		int_values := str_array_to_int(values)

		if is_result_correct(result_int, int_values, &cache) {
			sum += result_int
		}
	}

	fmt.println("sum: ", sum)
}

str_array_to_int :: proc(array: []string) -> []int {
	int_arr := make([dynamic]int, len(array), len(array))

	for elem, index in array {
		elem_int, ok := strconv.parse_int(elem, 10)

		if !ok {
			fmt.println("ERROR on converting array element to int.")
			continue
		}

		int_arr[index] = elem_int
	}

	return int_arr[:]
}

is_result_correct :: proc(result: int, values: []int, cache: ^map[string]struct {}) -> bool {
	operators := get_operator_permutations(len(values), cache)
	defer delete(operators)

	for operator_permutation in operators {
		permutation_result := values[0]

		for value, value_index in values {
			if value_index == 0 {
				continue
			}

			operator := operator_permutation[value_index - 1]

			switch operator {
			case Operator.ADD:
				permutation_result += value
			case Operator.MULTIPLY:
				permutation_result *= value
			}
		}

		if permutation_result == result {
			return true
		}
	}

	return false
}

get_operator_permutations :: proc(values: int, cache: ^map[string]struct {}) -> [][]Operator {
	// Populate array with ADD initially
	initial_permutation := make([dynamic]Operator, values - 1)
	populate_array(initial_permutation[:], Operator.ADD)

	variant_permutations := get_variant_permutations(initial_permutation[:], cache)

	permutations := make([dynamic][]Operator, 0, len(variant_permutations) + 1)

	append(&permutations, initial_permutation[:])
	append(&permutations, ..variant_permutations)

	return permutations[:]
}

get_variant_permutations :: proc(
	variant: []Operator,
	cache: ^map[string]struct {},
) -> [][]Operator {
	permutations := make([dynamic][]Operator, 0, len(variant))

	for operator, index in variant {
		current_permutation := make([dynamic]Operator, len(variant))
		copy_variant(&current_permutation, variant)

		current_permutation[index] = Operator.MULTIPLY

		operators_string := get_operators_string(current_permutation[:])
		_cache_elem, in_cache := cache[operators_string]

		if !in_cache {
			append(&permutations, current_permutation[:])
			cache[operators_string] = {}

			if only_has_multiply(current_permutation[:]) {
				// End recursion
				return permutations[:]
			}
		}
	}

	for permutation in permutations {
		new_variants := get_variant_permutations(permutation, cache)
		append(&permutations, ..new_variants)
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

	for operator in operators {
		switch operator {
		case Operator.ADD:
			append(&string_operators, "+")
		case Operator.MULTIPLY:
			append(&string_operators, "*")
		}
	}

	joined_string := strings.join(string_operators[:], "")

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
