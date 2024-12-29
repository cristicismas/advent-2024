package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Vector2 :: [2]int

Symbol :: enum {
	OBSTACLE,
	GUARD,
	EMPTY,
	VISITED,
}

Direction :: enum {
	UP,
	RIGHT,
	DOWN,
	LEFT,
}

World :: struct {
	grid:              [dynamic][dynamic]Symbol,
	guard_position:    Vector2,
	guard_orientation: Direction,
}


main :: proc() {
	world := read_world("./input.txt")

	has_exited_grid := false
	positions_visited := 1

	for !has_exited_grid {
		fmt.println("pos: ", world.guard_position, " orientation: ", world.guard_orientation)
		has_already_visited := false

		has_exited_grid, has_already_visited = traverse_world(&world)

		if !has_exited_grid && !has_already_visited {
			positions_visited += 1
		}
	}

	fmt.println("positions visited: ", positions_visited)
}

traverse_world :: proc(world: ^World) -> (has_exited: bool, already_visited: bool) {
	guard_position := world.guard_position

	has_already_visited := false

	next_position := get_new_position(guard_position, world.guard_orientation)

	if is_out_of_bounds(world.grid, next_position) {
		return true, has_already_visited
	}

	for world.grid[next_position.y][next_position.x] == Symbol.OBSTACLE {
		fmt.println("ROTATE")
		world.guard_orientation = get_new_orientation(world.guard_orientation)
		next_position = get_new_position(guard_position, world.guard_orientation)
		if is_out_of_bounds(world.grid, next_position) {
			return true, has_already_visited
		}
	}

	if world.grid[guard_position.y][guard_position.x] == Symbol.VISITED {
		has_already_visited = true
	} else {
		world.grid[guard_position.y][guard_position.x] = Symbol.VISITED
	}

	world.guard_position = next_position

	out_of_bounds := is_out_of_bounds(world.grid, next_position)

	return out_of_bounds, has_already_visited
}

is_out_of_bounds :: proc(grid: [dynamic][dynamic]Symbol, position: Vector2) -> bool {
	if position.x < 0 || position.y < 0 || position.x >= len(grid[0]) || position.y >= len(grid) {
		return true
	}

	return false
}

get_new_position :: proc(position: Vector2, orientation: Direction) -> Vector2 {
	next_position: Vector2
	switch orientation {
	case Direction.UP:
		next_position = Vector2{position.x, position.y - 1}
	case Direction.RIGHT:
		next_position = Vector2{position.x + 1, position.y}
	case Direction.DOWN:
		next_position = Vector2{position.x, position.y + 1}
	case Direction.LEFT:
		next_position = Vector2{position.x - 1, position.y}
	}

	return next_position
}

get_new_orientation :: proc(current_orientation: Direction) -> Direction {
	switch current_orientation {
	case Direction.UP:
		return Direction.RIGHT
	case Direction.RIGHT:
		return Direction.DOWN
	case Direction.DOWN:
		return Direction.LEFT
	case Direction.LEFT:
		return Direction.UP
	}

	return current_orientation
}

read_world :: proc(path: string) -> (world: World) {
	file_data, ok := os.read_entire_file(path, context.allocator)

	if !ok {
		return
	}

	defer delete(file_data)

	buffer := string(file_data)

	has_reached_pages := false

	line_index := 0
	for line in strings.split_lines_iterator(&buffer) {
		// Need to clone the line, otherwise it just points to the original buffer, which gets deleted
		line_clone := strings.clone(line)

		row := [dynamic]Symbol{}

		for rune, rune_index in line_clone {
			symbol: Symbol

			switch rune {
			case '#':
				symbol = Symbol.OBSTACLE
			case '.':
				symbol = Symbol.EMPTY
			case:
				symbol = Symbol.GUARD

				world.guard_position = Vector2{rune_index, line_index}

				switch rune {
				case '^':
					world.guard_orientation = Direction.UP
				case '>':
					world.guard_orientation = Direction.RIGHT
				case 'V':
					world.guard_orientation = Direction.DOWN
				case '<':
					world.guard_orientation = Direction.LEFT
				}
			}

			append(&row, symbol)
		}

		append(&world.grid, row)
		line_index += 1
	}

	return
}
