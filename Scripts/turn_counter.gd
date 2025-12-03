class_name TurnController extends Node

@export var turns_remaining : int = 10

## Emits when final turn is complete.
signal save_score

func finish_turn() -> void:
	turns_remaining -= 1
	if turns_remaining == 0:
		save_score.emit()
		
		#get_tree().root.add_child(game_scene)
		#get_tree().current_scene.queue_free()
		#get_tree().current_scene = game_scene
		get_tree().change_scene_to_file("res://Scenes/MainMenuScene.tscn") ## TODO: Game over -> show highscore
