extends AnimatedSprite2D
signal Charactor_pass_elect






func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player or body is Phantom or body is Phantom_dev or body is Player_dev:
		print_rich("[color=blue]💡 %s 正在通过水平电流！[/color]" % body.name)
		Charactor_pass_elect.emit()


func _on_button_blue_charactor_pess_button_blue() -> void:
	pass # Replace with function body.
