class_name BoardController extends Control

enum DIFFICULTY {EASY, MEDIUM, HARD} # Must match LevelSelect.gd DIFFICULTY enum exactly to function properly...
# And yes I know its bad programming to have the same thing in two places, I just dont care.

@onready var turn_controller: TurnController = $TurnController
@onready var score_label: RichTextLabel = $ScoreBox/ScoreLabel
@onready var turn_label: RichTextLabel = $TurnBox/TurnLabel
@onready var hint_label: RichTextLabel = $HintBox/HintLabel

## Total score for this game
var score : int = 0

## rest of system variables
var combo_multiplier: int = 1 
var max_combo: int = 0

## The first item on the board that is selected when M1 is pressed down.
var first_item : BoardItem = null


#<<<<<<< HEAD
#var turn = 0
#=======


var grid_cols : int = 8
var grid_rows : int = 8



const GRID_COLS = 8
const GRID_ROWS = 8


# Score values for diffrent matches
const SCORE_3_MATCH = 30
const SCORE_4_MATCH = 60
const SCORE_5_MATCH = 100
const SCORE_6_PLUS_MATCH = 150

# Bonus points
const COMBO_BONUS = 10  # Per combo level
const CASCADE_BONUS = 20  # For chain reactions



#>>>>>>> 1357db25246501c7e3b6e21c41c105d386e7cb5a


## Generates a level based on the passed difficulty
## Should be called by the LevelSelectScreen when a difficulty is selected
## Must await BoardController.ready or else all instances will be null
func set_difficulty(diff : DIFFICULTY) -> void:
	await self.ready
	$LevelGenerator.generate_level(diff)




func _ready() -> void:
	turn_controller.save_score.connect(save_score) ## Connect save score signal to function.

	
	score = 0 
	combo_multiplier = 1
	max_combo = 0
	
	update_score_display()
	update_turn_display()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var item = get_viewport().gui_get_hovered_control()
			if item is BoardItem:
				first_item = item
		else:
			if first_item != null: ## IF ITEM is next to tile were releasing on, then swap() else: dont swap
				var new_item = get_viewport().gui_get_hovered_control()
				if new_item is BoardItem and first_item.pos.distance_to(new_item.pos) == 1.0: ## The distance should only be 1. if > 1 it was too far.
					
					## TODO: IF swap is possible, check its validity, then swap & clear valid matches.
					
					#var temp : BoardItem.ITEM_TYPE = first_item.item_type ## Swap the two items.
					#first_item.item_type = new_item.item_type
					#new_item.item_type = temp
					
					# Store positions
					var a : BoardItem = first_item
					var b : BoardItem = new_item
					var a_pos : Vector2i = a.pos
					var b_pos : Vector2i = b.pos

# Swap in board array
					var board :Array = $LevelGenerator.board
					board[a_pos.y][a_pos.x] = b
					board[b_pos.y][b_pos.x] = a

# Swap pos variables
					a.pos = b_pos
					b.pos = a_pos

# Swap visuals (either rect_position or position)
					if "rect_position" in a:
						a.rect_position = Vector2(b_pos.x, b_pos.y)
						b.rect_position = Vector2(a_pos.x, a_pos.y)
					else:
						a.position = Vector2(b_pos.x, b_pos.y)
						b.position = Vector2(a_pos.x, a_pos.y)
				
					## TODO ASSUMING Swap was VALID, then take a turn away + Increase score
					score += 10
					turn_controller.finish_turn()
					
					
					
					score_label.text = "SCORE:\n%d" % score
					turn_label.text = "TURNS REMAINING:\n%d" % turn_controller.turns_remaining
					await $LevelGenerator.safe_wait_frame()
					$LevelGenerator.resolve_board()
					
					# COUNT THE ACTUAL MATCH SIZE (NO MORE HARDCODING!)
					var first_match = count_matched_tiles(first_item)
					var second_match = count_matched_tiles(new_item)
					var best_match = max(first_match, second_match)

					if best_match >= 3:
						add_points(best_match)
						turn_controller.finish_turn()
						update_turn_display()
						print("Match of %d tiles scored!" % best_match)
						# TODO: Clear matched tiles here
					else:
						# Swap back
						var temp = first_item.item_type
						first_item.item_type = new_item.item_type
						new_item.item_type = temp
			
			first_item = null
		

func count_matched_tiles(item: BoardItem) -> int:
	if item == null:
		return 0
	
	var item_type = item.item_type
	var col = int(item.pos.x)
	var row = int(item.pos.y)
	
	# we start with horizontal, startinging with the tile itself
	var horizontal = 1
	
	# first we Count left side of grid
	var check_col = col - 1
	while check_col >= 0:
		var neighbor = get_item_at(check_col, row)
		if neighbor != null and neighbor.item_type == item_type:
			horizontal += 1
			check_col -= 1
		else:
			break
	
	# then we Count right side of grid
	check_col = col + 1
	while check_col < GRID_COLS:
		var neighbor = get_item_at(check_col, row)
		if neighbor != null and neighbor.item_type == item_type:
			horizontal += 1
			check_col += 1
		else:
			break
	
	# now we count go vertical, sarting with the tile itself
	var vertical = 1  
	
	# first we Count up
	var check_row = row - 1
	while check_row >= 0:
		var neighbor = get_item_at(col, check_row)
		if neighbor != null and neighbor.item_type == item_type:
			vertical += 1
			check_row -= 1
		else:
			break
	
	# then we Count down
	check_row = row + 1
	while check_row < GRID_ROWS:
		var neighbor = get_item_at(col, check_row)
		if neighbor != null and neighbor.item_type == item_type:
			vertical += 1
			check_row += 1
		else:
			break
	
	# Return the bigger count
	var best = max(horizontal, vertical)
	
	if best >= 3:
		print("  Found match at (%d,%d): H=%d, V=%d → %d tiles" % [col, row, horizontal, vertical, best])
	return best



func get_item_at(col: int, row: int) -> BoardItem:
	# Search through all direct children of BoardController
	for child in get_children():
		if child is BoardItem:
			if int(child.pos.x) == col and int(child.pos.y) == row:
				return child
	return null





 
func add_points(match_size: int):
	# this section will be used for the scoring system
	var points = get_points_for_match(match_size)
	score += points
	update_score_display()
	
	# Show feedback
	if hint_label:
		hint_label.text = "+%d" % points


func get_points_for_match(match_size: int) -> int:
	match match_size:
		3: return SCORE_3_MATCH     # 30 points
		4: return SCORE_4_MATCH     # 60 points
		5: return SCORE_5_MATCH     # 100 points
		_: return SCORE_6_PLUS_MATCH # 150 points


func update_score_display(): ##this basically updates the scores on the screen
	if score_label:
		score_label.text = "SCORE:\n%d" % score


func update_turn_display(): ##this basically updates the turns on the screen
	if turn_label:
		turn_label.text = "TURNS REMAINING:\n%d" % turn_controller.turns_remaining



func save_score() -> void:
	## This section is important for creating the files.
	if not FileAccess.file_exists("user://highscore.save"):
		var f := FileAccess.open("user://highscore.save", FileAccess.WRITE)
		f.close()
	if not FileAccess.file_exists("user://score_history.save"):
		var f := FileAccess.open("user://score_history.save", FileAccess.WRITE)
		f.close()
	
	
	var file : FileAccess = FileAccess.open("user://highscore.save", FileAccess.READ)
	var highscore : int = file.get_64() as int
	
	var score_history : FileAccess = FileAccess.open("user://score_history.save", FileAccess.READ_WRITE)
	score_history.seek_end()
	score_history.store_line("%s %s - %d" % [Time.get_date_string_from_system(), Time.get_time_string_from_system(), score])
	score_history.close()
	
	file.close()
	if score > highscore: # if new highscore, save it.
		file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
		file.store_64(score)
		file.close()
