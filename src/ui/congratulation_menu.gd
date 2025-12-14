extends Control


func _on_main_pressed() -> void:
	SceneManager.push_scene("res://src/ui/main_menu.tscn")


func _on_credits_pressed() -> void:
	SceneManager.push_scene("res://src/ui/credits_menu.tscn")


func _on_exit_button_pressed() -> void:
	print("pressed exit")
	get_tree().quit()
