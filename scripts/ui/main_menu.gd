extends Control

func _on_start_button_pressed() -> void:
	# 进入第一关（Game 是 autoload 的单例）
	Game.start_level(0)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
