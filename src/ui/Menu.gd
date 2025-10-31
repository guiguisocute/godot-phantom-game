extends Control



func _on_next_pressed() -> void:
	print("press start")
	get_tree().change_scene_to_file("res://src/level/level1.tscn")


func _on_setting_pressed() -> void:
	print("pressed setting")


func _on_exit_pressed() -> void:
	print("pressed exit")
	get_tree().quit()


func _on_back_mainmenu_pressed() -> void:
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
