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

# Score values for diffrent matches
const SCORE_3_MATCH = 30
const SCORE_4_MATCH = 60
const SCORE_5_MATCH = 100
const SCORE_6_PLUS_MATCH = 150

# Bonus points
const COMBO_BONUS = 10  # Per combo level
const CASCADE_BONUS = 20  # For chain reactions


## Generates a level based on the passed difficulty
## Should be called by the LevelSelectScreen when a difficulty is selected
## Must await BoardController.ready or else all instances will be null
func set_difficulty(diff : DIFFICULTY) -> void:
	await self.ready
	$LevelGenerator.generate_level(diff)

func _ready() -> void:
	turn_controller.save_score.connect(save_score) ## Connect save score signal to function.

    # Initialize score display
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
					
					var temp : BoardItem.ITEM_TYPE = first_item.item_type ## Swap the two items.
					first_item.item_type = new_item.item_type
					new_item.item_type = temp
					
					## NEW ADVANCED SCORING - Replace old score += 10
					# For now, assuming 3-match (you'll need to detect actual match size)
					var match_count = 3  # TODO: Implement actual match detection
					on_valid_swap_match(match_count)
			
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


func add_score_for_match(match_size: int, is_cascade: bool = false):
	var base_points = calculate_base_score(match_size)
	var combo_bonus = calculate_combo_bonus()
	var cascade_bonus_points = CASCADE_BONUS if is_cascade else 0
	
	var total_points = base_points + combo_bonus + cascade_bonus_points
	
	score += total_points
	update_score_display()
	
	# Show score popup
	show_score_popup(total_points, is_cascade)
	
	print("Match scored! Size: %d, Points: %d (Base: %d, Combo: %d, Cascade: %d)" % 
		[match_size, total_points, base_points, combo_bonus, cascade_bonus_points])


func calculate_base_score(match_size: int) -> int:
	match match_size:
		3: return SCORE_3_MATCH     # 30 points
		4: return SCORE_4_MATCH     # 60 points
		5: return SCORE_5_MATCH     # 100 points
		_: return SCORE_6_PLUS_MATCH # 150 points for 6+


func calculate_combo_bonus() -> int:
	"""Calculate bonus points from current combo multiplier"""
	return (combo_multiplier - 1) * COMBO_BONUS


func increment_combo():
	"""Increase combo counter for cascading matches"""
	combo_multiplier += 1
	if combo_multiplier > max_combo:
		max_combo = combo_multiplier
	
	print("COMBO x%d!" % combo_multiplier)
	
	# Show combo notification
	if hint_label:
		hint_label.text = "COMBO x%d!" % combo_multiplier


func reset_combo():
	"""Reset combo when player makes a new move (not cascade)"""
	if combo_multiplier > 1:
		print("Combo ended at x%d" % combo_multiplier)
	combo_multiplier = 1


func update_score_display():
	"""Update the score label on screen"""
	if score_label:
		score_label.text = "SCORE:\n%d" % score


func update_turn_display():
	"""Update the turns remaining label"""
	if turn_label:
		turn_label.text = "TURNS REMAINING:\n%d" % turn_controller.turns_remaining


func show_score_popup(points: int, is_combo: bool):
	"""Show floating score popup"""
	if hint_label:
		var text = "+%d" % points
		if is_combo:
			text = "+%d COMBO!" % points
		
		hint_label.text = text
		hint_label.modulate.a = 1.0
		
		# Fade out animation
		var tween = create_tween()
		tween.tween_property(hint_label, "modulate:a", 1.0, 0.1)
		tween.tween_property(hint_label, "modulate:a", 0.0, 1.5)


func on_valid_swap_match(matched_tiles_count: int):
	"""
	Called when player makes a valid swap that creates a match
	matched_tiles_count: How many tiles were matched
	"""
	# Reset combo since this is a new player move
	reset_combo()
	
	# Add score for the match
	add_score_for_match(matched_tiles_count, false)
	
	# Decrease turn
	turn_controller.finish_turn()
	update_turn_display()
	
	# Check for cascades after clearing tiles
	# (Your existing cascade detection code should call process_cascade)


func process_cascade(matched_tiles_count: int):
	"""
	Called when a cascade (chain reaction) creates a match
	matched_tiles_count: How many tiles matched in this cascade
	"""
	# Increment combo
	increment_combo()
	
	# Add score with cascade bonus
	add_score_for_match(matched_tiles_count, true)
	
	# Don't decrease turn for cascades!
	# Cascades are free bonus matches


func game_over():
	print("GAME OVER! Final Score: %d, Max Combo: x%d" % [score, max_combo])
	# Save high score
	save_score()
	# Return to main menu
	get_tree().change_scene_to_file("res://Scenes/MainMenuScene.tscn")
