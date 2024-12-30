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

VisitedPosition :: struct {
	position:    Vector2,
	orientation: Direction,
}

main :: proc() {
	world := read_world("./input.txt")
	world_copy := copy_world(world)

	visited_positions, _ := traverse_world(&world)
	fmt.println("visited positions: ", len(visited_positions))

	possible_obstructions := get_possible_obstructions(&world_copy, visited_positions)
	fmt.println("possible obstructions: ", possible_obstructions)
}

copy_world :: proc(world: World) -> World {
	world_copy := world

	grid_copy := [dynamic][dynamic]Symbol{}
	for row in world.grid {
		new_row := [dynamic]Symbol{}
		for symbol in row {
			append(&new_row, symbol)
		}
		append(&grid_copy, new_row)
	}

	world_copy.grid = grid_copy

	return world_copy
}

get_possible_obstructions :: proc(
	world: ^World,
	visited_positions: [dynamic]VisitedPosition,
) -> int {
	obstructions := make(map[Vector2]struct {})
	original_guard_position := world.guard_position

	for visited in visited_positions {
		obstruction_position := Vector2{visited.position.x, visited.position.y}
		obstruction_already_handled := obstruction_position in obstructions

		if obstruction_already_handled || obstruction_position == original_guard_position {
			continue
		}

		world_copy := copy_world(world^)
		defer delete(world_copy.grid)

		// Add obstruction at position
		world_copy.grid[obstruction_position.y][obstruction_position.x] = Symbol.OBSTACLE

		_, is_loop := traverse_world(&world_copy)

		if is_loop {
			// Add the obstruction to the map
			obstructions[obstruction_position] = {}

			fmt.println("obstructions: ", len(obstructions))
		}
	}

	return len(obstructions)
}

traverse_world :: proc(
	world: ^World,
) -> (
	visited_positions: [dynamic]VisitedPosition,
	is_infinite: bool = false,
) {
	has_exited_grid := false

	for !has_exited_grid {
		new_position: VisitedPosition
		has_exited_grid, new_position = traverse_next_square(world)

		if array_contains(visited_positions[:], new_position) {
			return visited_positions, true
		}

		append(&visited_positions, new_position)
	}

	return visited_positions, is_infinite
}

array_contains :: proc(array: []$T, target: $G) -> bool {
	for item in array {
		if item == target {
			return true
		}
	}

	return false
}

has_visited_position :: proc(
	visited_positions: []VisitedPosition,
	position: VisitedPosition,
) -> bool {
	for visited in visited_positions {
		if position.position == visited.position {
			return true
		}
	}

	return false
}

traverse_next_square :: proc(world: ^World) -> (has_exited: bool, new_position: VisitedPosition) {
	guard_position := world.guard_position

	next_position := get_new_position(guard_position, world.guard_orientation)

	if is_out_of_bounds(world.grid, next_position) {
		return true, new_position
	}

	for world.grid[next_position.y][next_position.x] == Symbol.OBSTACLE {
		world.guard_orientation = get_new_orientation(world.guard_orientation)
		next_position = get_new_position(guard_position, world.guard_orientation)
		if is_out_of_bounds(world.grid, next_position) {
			return true, new_position
		}
	}

	if world.grid[guard_position.y][guard_position.x] != Symbol.VISITED {
		world.grid[guard_position.y][guard_position.x] = Symbol.VISITED
	}


	world.guard_position = next_position
	new_position = VisitedPosition{world.guard_position, world.guard_orientation}

	out_of_bounds := is_out_of_bounds(world.grid, next_position)

	return out_of_bounds, new_position
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
