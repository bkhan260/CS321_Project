class_name LevelGenerator extends Node

@export var desired_columns : Array[int] = [5, 10, 20]

## The number of different types of items that should be on the board
@export var num_items : int = 3

@onready var item_grid : GridContainer = %ItemGrid
@onready var item_blueprint : PackedScene = preload("res://Scenes/board_item.tscn")

func generate_level(difficulty : BoardController.DIFFICULTY = BoardController.DIFFICULTY.EASY) -> void:
	var num_columns : int = desired_columns[difficulty as int]
	item_grid.columns = num_columns
	
	for row : int in range(0, num_columns):
		for column : int in range(0, num_columns):
			var new_item : BoardItem = item_blueprint.instantiate()# this is test
			new_item.item_type = randi_range(0, num_items) as BoardItem.ITEM_TYPE
			new_item.pos = Vector2i(column, row)
			item_grid.add_child(new_item, true)
