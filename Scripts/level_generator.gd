class_name LevelGenerator extends Node

@export var desired_columns : int = 5

@onready var item_grid : GridContainer = %ItemGrid
@onready var item_blueprint : PackedScene = preload("res://Scenes/board_item.tscn")

func _ready() -> void:
	item_grid.columns = desired_columns
	
	for row : int in range(0, desired_columns):
		for column : int in range(0, desired_columns):
			var new_item : BoardItem = item_blueprint.instantiate()
			new_item.item_type = randi_range(0,3) as BoardItem.ITEM_TYPE
			new_item.pos = Vector2i(column, row)
			item_grid.add_child(new_item, true)
