extends Control


func _on_start_pressed() -> void:
	print("press start")
	get_tree().change_scene_to_file("res://scenes/level1.tscn")
	

func _on_setting_button_pressed() -> void:
	print("pressed setting")


func _on_exit_button_pressed() -> void:
	print("pressed exit")
	get_tree().quit()
