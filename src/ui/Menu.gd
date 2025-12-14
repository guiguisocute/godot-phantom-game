extends Control



func _on_next_pressed() -> void:
	print("press start")
	SceneManager.go_to_next_level()


func _on_setting_pressed() -> void:
	print("pressed setting")
	SceneManager.push_scene("res://src/ui/setting_menu.tscn")


func _on_exit_pressed() -> void:
	print("pressed exit")
	get_tree().quit()


func _on_back_mainmenu_pressed() -> void:
	SceneManager.push_scene("res://src/ui/main_menu.tscn")
