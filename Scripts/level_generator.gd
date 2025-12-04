class_name LevelGenerator extends Node

@export var desired_columns : Array[int] = [5, 10, 20] # Board sizes based on difficulty level

@onready var item_grid : GridContainer = %ItemGrid # Board
@onready var item_blueprint : PackedScene = preload("res://Scenes/board_item.tscn")

var board: Array = [] #2D array of board and board objects

const TILE_SIZE := Vector2(588, 588)

# Generate board according to difficulty level
func generate_level(difficulty : BoardController.DIFFICULTY = BoardController.DIFFICULTY.EASY) -> void:
	var num_columns : int = desired_columns[difficulty as int] # determine the size of the board based on difficulty
	item_grid.columns = num_columns
	# initialize 2D array for match checking
	for row in range(num_columns):
		board.append([])
		for col in range(num_columns):
			board[row].append(null)
	# Populate board with items in randomized order on board
	for row : int in range(0, num_columns):
		for column : int in range(0, num_columns):
			var new_item : BoardItem = item_blueprint.instantiate()
			new_item.item_type = randi_range(0,3) as BoardItem.ITEM_TYPE
			new_item.pos = Vector2i(column, row)
			#var sprite = new_item.get_node("Sprite")
			#var tex_size = sprite.texture.get_size()
			#sprite.scale = TILE_SIZE/tex_size
			if new_item.has_method("set_position"):
				new_item.position = Vector2(column, row) * TILE_SIZE
			item_grid.add_child(new_item, true)
			board[row][column] = new_item


# Fucnting to check for matches on rows
func check_row():
	var matches : Array = []
	var rows = board.size()
	if rows == 0:
		return matches
	var cols = board[0].size()

	for r in range(rows):
		var run_start = 0
		var run_len = 1

		# start at col 1 and compare to prev
		for c in range(1, cols):
			var curr = board[r][c]
			var prev = board[r][c - 1]

			# if either is null, break any run
			if curr == null or prev == null:
				if run_len >= 3:
					for off in range(run_len):
						matches.append(board[r][run_start + off])
				run_start = c
				run_len = 1
				continue

			# compare types
			if curr.item_type == prev.item_type:
				run_len += 1
			else:
				if run_len >= 3:
					for off in range(run_len):
						matches.append(board[r][run_start + off])
				run_start = c
				run_len = 1

		# end-of-row check
		if run_len >= 3:
			for off in range(run_len):
				matches.append(board[r][run_start + off])

	return matches

# Function to check for matches in columns
func check_column():
	var matches : Array = []
	var rows = board.size()
	if rows == 0:
		return matches
	var cols = board[0].size()

	for c in range(cols):
		var run_start = 0
		var run_len = 1

		for r in range(1, rows):
			var curr = board[r][c]
			var prev = board[r - 1][c]

			if curr == null or prev == null:
				if run_len >= 3:
					for off in range(run_len):
						matches.append(board[run_start + off][c])
				run_start = r
				run_len = 1
				continue

			if curr.item_type == prev.item_type:
				run_len += 1
			else:
				if run_len >= 3:
					for off in range(run_len):
						matches.append(board[run_start + off][c])
				run_start = r
				run_len = 1

		# end-of-column check
		if run_len >= 3:
			for off in range(run_len):
				matches.append(board[run_start + off][c])

	return matches

func _rebuild_grid_children():
	# Remove all children but DO NOT free them
	for child in item_grid.get_children():
		item_grid.remove_child(child)

	# Re-add in row-major order
	for r in range(board.size()):
		for c in range(board[0].size()):
			var tile = board[r][c]
			if tile != null:
				item_grid.add_child(tile)



# clean up board after finiding a match
func clear_matches(matches):
	for tile in matches:
		var p = tile.pos
		board[p.y][p.x] = null
		tile.queue_free()

	_rebuild_grid_children()


func gravity():
	var rows = board.size()
	var cols = board[0].size()

	for col in range(cols):
		var stack := []
		# collect all tiles in this column (bottom-up)
		for row in range(rows):
			var tile = board[row][col]
			if tile != null:
				stack.append(tile)

		# fill bottom of column with existing tiles
		var write_row = rows - 1
		stack.reverse()
		for tile in stack:
			board[write_row][col] = tile
			tile.pos = Vector2i(col, write_row)
			write_row -= 1

		# rest become null
		for r in range(write_row, -1, -1):
			board[r][col] = null

	# After updating board[][], rebuild GridContainer children order
	_rebuild_grid_children()


func refill_board():
	var rows = board.size()
	var cols = board[0].size()

	for r in range(rows):
		for c in range(cols):
			if board[r][c] == null:
				var tile : BoardItem = item_blueprint.instantiate()
				tile.item_type = randi_range(0,3)
				tile.pos = Vector2i(c, r)
				board[r][c] = tile

	_rebuild_grid_children()




func erase_duplicates(arr: Array) -> Array:
	var seen := {}
	var result := []
	for elem in arr:
		if not seen.has(elem):
			seen[elem] = true
			result.append(elem)
	return result
	

func find_matches() -> Array:
	var matches = check_row() + check_column()
	matches = erase_duplicates(matches)
	return matches

func resolve_board(max_iterations: int = 50) -> void:
	var iter = 0
	while true:
		iter += 1
		if iter > max_iterations:
			push_error("resolve_board: reached max iterations (%d). Aborting." % max_iterations)
			break

		var matches = find_matches()
		if matches.size() == 0:
			break

		# debug
		print("resolve_board: clearing ", matches.size(), " matches (iter ", iter, ")")

		matches = erase_duplicates(matches)
		clear_matches(matches)
		gravity()
		refill_board()

		# allow a frame for visuals/tweens/engine to update (prevents perceived freezes)
		#await get_tree().process_frame
		#if get_tree():
			#await get_tree().process_frame
		#else:
		await safe_wait_frame()  # fallback safe version
			
func safe_wait_frame() -> void:
	await Engine.get_main_loop().create_timer(0.0).timeout
