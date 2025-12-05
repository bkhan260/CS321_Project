extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LevelSelectScreen.tscn") 
	# This is the simple way to change screens... but we cant pass arguments (See LevelSelectScreen.tscn for why this is important to note)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _ready() -> void:
	get_highscore()


func get_highscore() -> void:
	if not FileAccess.file_exists("user://highscore.save"): return
	
	var file : FileAccess = FileAccess.open("user://highscore.save", FileAccess.READ)
	var score = file.get_64()
	file.close()
	$HighScoreLabel.text = "Current High Score: [rainbow][wave]%d[/wave][/rainbow]" % score
