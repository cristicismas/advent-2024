package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

TOKENS: []string : {"mul", "(", ",", ")"}

main :: proc() {
	lines := read_lines("./input.txt")
	defer delete(lines)

	sum := 0

	for line in lines {
		sum += parse_line(line)
	}
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
	sum := 0

	in_parenthesis := false

	tokens := tokenize(line)
	fmt.println(tokens)

	// TODO: for loop the tokens, if in a valid arrangement, add the relevant numbers

	// sum += len(tokens)

	delete(tokens)
	return sum
}

tokenize :: proc(line: string) -> [dynamic]string {
	tokens: [dynamic]string

	current_sequence: string

	for char in line {
		char_to_str := utf8.runes_to_string({char})

		// NOTE: add char to current_sequence
		current_sequence = strings.concatenate({current_sequence, char_to_str})

		// NOTE: for each potential token, compare the last characters of current_sequence[:token.length] with the token
		for token in TOKENS {
			if strings.ends_with(current_sequence, token) {
				// NOTE: if they match, add the token, reset current_sequence
				append(&tokens, current_sequence)
				current_sequence = ""
			}
		}
		// TODO: also check for numbers as tokens
	}

	return tokens
}
