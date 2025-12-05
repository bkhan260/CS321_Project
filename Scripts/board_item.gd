class_name BoardItem extends Control

enum ITEM_TYPE {BLUEFISH, BROWNFISH, GREENFISH, ORANGEFISH}

## The type of item that this object represents.
## Setting this variable changes the objects sprite to the respective image.
@export var item_type : ITEM_TYPE = ITEM_TYPE.BLUEFISH:
	set(val):
		assert(val is ITEM_TYPE, "passed value was not an ITEM_TYPE")
		for child in self.get_children():
			if child is TextureRect: child.visible = false # Hide all sprites.
		
		# Enable relative sprite
		match val:
			ITEM_TYPE.BLUEFISH: $BlueFish.visible = true
			ITEM_TYPE.BROWNFISH: $BrownFish.visible = true
			ITEM_TYPE.GREENFISH: $GreenFish.visible = true
			ITEM_TYPE.ORANGEFISH: $OrangeFish.visible = true
			_: assert(false, "How did you even get here.")
		
		item_type = val

var pos : Vector2i = Vector2i(-1, -1)
