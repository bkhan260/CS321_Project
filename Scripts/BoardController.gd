class_name BoardController extends Control

enum DIFFICULTY {EASY, MEDIUM, HARD} # Must match LevelSelect.gd DIFFICULTY enum exactly to function properly...
# And yes I know its bad programming to have the same thing in two places, I just dont care.

@onready var turn_controller: TurnController = $TurnController
@onready var score_label: RichTextLabel = $ScoreBox/ScoreLabel
@onready var turn_label: RichTextLabel = $TurnBox/TurnLabel
@onready var hint_label: RichTextLabel = $HintBox/HintLabel

## Total score for this game
var score : int = 0

## The first item on the board that is selected when M1 is pressed down.
var first_item : BoardItem = null

## Generates a level based on the passed difficulty
## Should be called by the LevelSelectScreen when a difficulty is selected
## Must await BoardController.ready or else all instances will be null
func set_difficulty(diff : DIFFICULTY) -> void:
	await self.ready
	$LevelGenerator.generate_level(diff)
	$LevelGenerator.resolve_board()

func _ready() -> void:
	turn_controller.save_score.connect(save_score) ## Connect save score signal to function.
	

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
					
					$LevelGenerator._rebuild_grid_children()
					await $LevelGenerator.safe_wait_frame()
					
					var matches = $LevelGenerator.find_matches()
					
					if matches.size() > 0:
						await $LevelGenerator.resolve_board()
						score += 10

					#else:
						#board[b_pos.y][b_pos.x] = b
						#board[a_pos.y][a_pos.x] = a
						#
						#a.pos = a_pos
						#b.pos = b_pos
					$LevelGenerator._rebuild_grid_children()
					await $LevelGenerator.safe_wait_frame()
					turn_controller.finish_turn()
						
# Swap visuals (either rect_position or position)
					#if "rect_position" in a:
						#a.rect_position = Vector2(b_pos.x, b_pos.y)
						#b.rect_position = Vector2(a_pos.x, a_pos.y)
					#else:
						#a.position = Vector2(b_pos.x, b_pos.y)
						#b.position = Vector2(a_pos.x, a_pos.y)
				

					
					#var temp : BoardItem.ITEM_TYPE = first_item.item_type ## Swap the two items.
					#first_item.item_type = new_item.item_type
					#new_item.item_type = temp
					

					## TODO ASSUMING Swap was VALID, then take a turn away + Increase score
					#score += 10
					#turn_controller.finish_turn()
					
					
					score_label.text = "SCORE:\n%d" % score
					turn_label.text = "TURNS REMAINING:\n%d" % turn_controller.turns_remaining

					
					await $LevelGenerator.safe_wait_frame()
					$LevelGenerator.resolve_board()
					
					
					# COUNT THE ACTUAL MATCH SIZE (NO MORE HARDCODING!)
					#var first_match = count_matched_tiles(first_item)
					#var second_match = count_matched_tiles(new_item)
					#var best_match = max(first_match, second_match)
#
					#if best_match >= 3:
						#add_points(best_match)
						#turn_controller.finish_turn()
						#update_turn_display()
						#print("Match of %d tiles scored!" % best_match)
						## TODO: Clear matched tiles here
					#else:
						## Swap back
						#var temp = first_item.item_type
						#first_item.item_type = new_item.item_type
						#new_item.item_type = temp

			
			first_item = null

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
