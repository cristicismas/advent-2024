package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

TOKENS: []string : {"do", "don't", "mul", "(", ",", ")"}

main :: proc() {
	lines := read_lines("./input.txt")
	defer delete(lines)

	sum := 0

	for line in lines {
		sum += parse_line(line)
	}

	fmt.println("Final sum: ", sum)
}

read_lines :: proc(path: string) -> [dynamic]string {
	output := [dynamic]string{}

	data, ok := os.read_entire_file(path, context.allocator)

	if !ok {
		return output
	}

	defer delete(data, context.allocator)

	buf := string(data)

	for line in strings.split_lines_iterator(&buf) {
		append(&output, strings.clone(line))
	}

	return output
}

parse_line :: proc(line: string) -> int {
	in_parenthesis := false

	tokens := tokenize(line)
	defer delete(tokens)

	sum := validate_and_calculate(tokens)

	return sum
}

enable_calculation := true


validate_and_calculate :: proc(tokens: [dynamic]string) -> int {
	sum := 0

	has_printed := false

	for i := 0; i < len(tokens); i += 1 {
		found_mul := is_mul(tokens, i)

		is_condition, is_enabled := is_condition(tokens, i)

		if is_condition && is_enabled {
			enable_calculation = true
		} else if is_condition && !is_enabled {
			enable_calculation = false
		}

		if found_mul && enable_calculation {
			first_int, first_ok := strconv.parse_int(tokens[i - 3])
			second_int, second_ok := strconv.parse_int(tokens[i - 1])

			mul := first_int * second_int
			fmt.println("mul(", first_int, ",", second_int, ") = ", mul)

			sum += mul
		}
	}

	return sum
}

is_mul :: proc(tokens: [dynamic]string, index: int) -> bool {
	if index < 5 {
		return false
	}

	if tokens[index - 5] != "mul" {
		return false
	}

	if tokens[index - 4] != "(" {
		return false
	}

	if !is_number(tokens[index - 3]) {
		return false
	}

	if tokens[index - 2] != "," {
		return false
	}

	if !is_number(tokens[index - 1]) {
		return false
	}

	if tokens[index] != ")" {
		return false
	}

	return true
}

is_condition :: proc(
	tokens: [dynamic]string,
	index: int,
) -> (
	is_condition: bool,
	is_enabled: bool,
) {
	if index < 3 {
		return false, false
	}

	if tokens[index - 1] == "(" && tokens[index] == ")" {
		if tokens[index - 2] == "do" {
			return true, true
		} else if tokens[index - 3] == "do" && tokens[index - 2] == "n't" {
			return true, false
		}
	}


	return false, false
}

is_number :: proc(str: string) -> bool {
	_is_number := true
	for r in str {
		if !unicode.is_digit(r) {
			return false
		}
	}

	return _is_number
}


tokenize :: proc(line: string) -> [dynamic]string {
	tokens: [dynamic]string

	current_sequence: string
	looking_for_numbers := false

	for char in line {
		char_to_str := utf8.runes_to_string({char})
		found_number := false

		if looking_for_numbers && !unicode.is_digit(char) {
			append(&tokens, current_sequence)
			looking_for_numbers = false
			found_number = true
		}

		if unicode.is_digit(char) {
			if looking_for_numbers {
				current_sequence = strings.concatenate({current_sequence, char_to_str})
			} else {
				current_sequence = char_to_str
			}

			looking_for_numbers = true
			continue
		}

		current_sequence = strings.concatenate({current_sequence, char_to_str})

		for token in TOKENS {
			if strings.ends_with(current_sequence, token) {
				// If it's not an exact match, add an invalid token before
				if current_sequence != token && !found_number {
					append(&tokens, current_sequence[:len(current_sequence) - len(token)])
				}
				append(&tokens, current_sequence[len(current_sequence) - len(token):])
				current_sequence = ""
				continue
			}
		}

	}

	return tokens
}
