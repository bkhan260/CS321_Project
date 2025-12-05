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

## this scores values for diffrent match sizes 
const SCORE_3 = 30
const SCORE_4 = 60
const SCORE_5 = 100
const SCORE6PLUS = 150




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

					var a: BoardItem = first_item
					var b: BoardItem = new_item
					var a_pos: Vector2i = a.pos
					var b_pos: Vector2i = b.pos
						
					var board: Array = $LevelGenerator.board

					############################## animation for "swaps" starts here
					var tween = create_tween()
					tween.set_parallel(true)
					tween.set_trans(Tween.TRANS_CUBIC)
					tween.set_ease(Tween.EASE_OUT)
					tween.tween_property(a, "position", b.position, 0.15)
					tween.tween_property(b, "position", a.position, 0.15)
					await tween.finished
					############################## animation for "swaps" ends here

					board[a_pos.y][a_pos.x] = b
					board[b_pos.y][b_pos.x] = a
					
					# Swap pos variables
					a.pos = b_pos
					b.pos = a_pos
					
					$LevelGenerator._rebuild_grid_children()
					await $LevelGenerator.safe_wait_frame()
					
					# Find matches
					var matches = $LevelGenerator.find_matches()
					
					if matches.size() > 0:
						# Calculate score based on match sizes
						var points = count_match(matches)
						score += points
						
						
						# Resolve board
						await $LevelGenerator.resolve_board()
					else:
						print("Invalid swap - no match created")
					
					$LevelGenerator._rebuild_grid_children()
					await $LevelGenerator.safe_wait_frame()
					
					# Decrease turn
					turn_controller.finish_turn()
						
					# Update displays
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
		
func get_score(match_size: int) -> int:
	##convert match size ot points
	match match_size:
		3: return SCORE_3
		4: return SCORE_4
		5: return SCORE_5
		_: return SCORE6PLUS

func count_match(matches: Array) -> int:
	## Count how many tiles match at this poistions, and it will return the size
	var total_points = 0
	# Each match in the array represents a group of matched tiles
	for match in matches:
		var match_size = 0
		
		# Figure out the size of this match
		if match is Array:
			match_size = match.size()
		elif match is Dictionary and "tiles" in match:
			match_size = match.tiles.size()
		elif match is Dictionary and "size" in match:
			match_size = match.size
		else:
			# Default to treating it as a 3-match if we can't determine
			match_size = 3
		
		# Get points for this match size
		var points = get_score(match_size)
		total_points += points
	return total_points
