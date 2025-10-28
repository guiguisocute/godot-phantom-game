extends Sprite2D
class_name Spike

# 定义信号：当玩家碰到尖刺时发出
signal character_hit


func _on_area_2d_body_entered(body: Node2D) -> void:
	# 修正：应该用 OR 而不是 AND
	if body is Player or body is Phantom or body is Phantom_dev or body is Player_dev:
		print_rich("[b][color=red]💡 %s 触碰到了尖刺！[/color][/b]" % body.name)
		character_hit.emit()
	return
