extends  Node

func _process(delta):
	if Input.is_action_just_pressed("reset_level"):
		get_tree().reload_current_scene()
