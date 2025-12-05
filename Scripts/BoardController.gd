class_name BoardController extends Control

enum DIFFICULTY {EASY, MEDIUM, HARD} # Must match LevelSelect.gd DIFFICULTY enum exactly to function properly...
# And yes I know its bad programming to have the same thing in two places, I just dont care.

@onready var turn_controller: TurnController = $TurnController
@onready var score_label: RichTextLabel = $ScoreBox/ScoreLabel
@onready var turn_label: RichTextLabel = $TurnBox/TurnLabel
@onready var hint_label: RichTextLabel = $HintBox/HintLabel
@onready var level_generator: LevelGenerator = $LevelGenerator

## Total score for this game
var score : int = 0

var grid_width: int = 6
var grid_height: int = 6
 



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
					var match_size = check_swap(first_item, new_item)
					if match_size >= 3:
						
						## Specific swaping mehcanism
						var temp: BoardItem.ITEM_TYPE = first_item.item_type
						first_item.item_type = new_item.item_type
						new_item.item_type = temp
						
						## get points based on the size
						var full_points = get_score(match_size)
						score += full_points
						
						## we then decrease the specific turn after
						turn_controller.finish_turn()
						
						## We then update the display
						score_label.text = " SCORE:\n%d" % score
						turn_label.text = " TURNS REMAINING:\n%d" % turn_controller.turns_remaining #th
						
						print("Match %d! Score: +%d (Total: %d)" % [match_size, full_points, score])
					else:
						print(" No match")
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

func count_match(item: BoardItem) -> int:
	## Count how many tiles match at this poistions, and it will return the size
	if item == null:
		return 0
	
	##we will use row and 
	var item_type = item.item_type
	var row = int(item.pos.y)
	var col = int(item.pos.x)
	
	
	## Count the horizontol matchs
	var horzi = 1
	## we first count the left 
	var check1 = col - 1
	while check1 >= 0:	
		var check_item = get_at_pos(row, check1)
		if check_item != null and check_item.item_type == item_type:
			horzi += 1
			check1 -= 1
		else:
			break
	## we then count the right	
	check1 = col + 1
	while check1 < grid_width:
		var check_item = get_at_pos(row, check1)
		if check_item != null and check_item.item_type == item_type:
			horzi += 1
			check1 += 1
		else:
			break
			
		
	
	
	## Count the horizontol matchs
	var vert = 1
	##  count the the top
	var check2 = row - 1
	while check2 >= 0:
		var check_item = get_at_pos(check2, col)
		if check_item != null and check_item.item_type == item_type:
			vert += 1
			check2 -= 1
		else:
			break
	## count the matches down
	check2 = row + 1 
	while check2 < grid_height:
		var check_item = get_at_pos(check2, col)
		if check_item != null and check_item.item_type == item_type:
			vert += 1
			check2 += 1
		else:
			break
		  
			
	 ## Returns the larger one		
	return max(horzi, vert)
	
			
func get_at_pos(row: int, col: int) -> BoardItem:
	#Search through all direct children of BoardController
	if level_generator.board.size() == 0:
		return null
	
	var grid_height = level_generator.board.size()
	var grid_width = level_generator.board[0].size()
	
	if row < 0 or row >= grid_height or col < 0 or col >= grid_width:
		return null
	
	# Access the LevelGenerator's board array
	return level_generator.board[row][col]

func check_swap(item1: BoardItem, item2: BoardItem) -> int:
	## Checks if swapping creates a match and returns the size 
	## Returns 0 iff there isnt a match
	if item1 == null or item2 == null:
		return 0
	
	## temp swaps
	var temp = item1.item_type
	item1.item_type = item2.item_type
	item2.item_type = temp
	
	## Check both positions
	var match1 = count_match(item1)
	var match2 = count_match(item2)
	var largest = max(match1, match2)
	
	## this will Swap them back
	temp = item1.item_type
	item1.item_type = item2.item_type
	item2.item_type = temp
	
	# Only return if >= 3
	return largest if largest >= 3 else 0
	
	
	
	
	
	
	
