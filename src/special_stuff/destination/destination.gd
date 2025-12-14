extends AnimatedSprite2D
signal Player_touch_destination

func _ready() -> void:
	self.play("default")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player  or body is Player_dev:
		print_rich("[color=yellow]💡 %s 通过了终点！[/color]" % body.name)
		await get_tree().create_timer(0.3).timeout
		if SceneManager.current_level==3:
			get_tree().change_scene_to_file("res://src/ui/congratulation_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://src/ui/Menu.tscn")
		Player_touch_destination.emit()
