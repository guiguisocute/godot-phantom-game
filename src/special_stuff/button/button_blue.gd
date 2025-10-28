extends AnimatedSprite2D
signal Charactor_pess_button_blue
signal Charactor_pop_button_blue

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player or body is Phantom or body is Phantom_dev or body is Player_dev:
		print_rich("[color=blue]💡 %s 触发了蓝色按钮！[/color]" % body.name)
		self.play("press")
		Charactor_pess_button_blue.emit()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player or body is Phantom or body is Phantom_dev or body is Player_dev:
		print_rich("[color=blue]💡 %s 离开了了蓝色按钮！[/color]" % body.name)
		self.play("popup")
		Charactor_pop_button_blue.emit()
