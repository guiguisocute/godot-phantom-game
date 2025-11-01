extends  Node

const DEFAULT_LEVEL_PATH := "res://src/level/level1_old.tscn"

func _process(delta):
	if Input.is_action_just_pressed("reset_level"):
		var current_scene = get_tree().current_scene
		var scene_name = current_scene.name
		
		# 判断当前是不是 UI 场景
		if scene_name == "LevelFailedUI" or scene_name == "death_interface":
			# 从UI返回关卡
			print("no")
			get_tree().change_scene_to_file(DEFAULT_LEVEL_PATH)
		else:
			# 普通游戏场景就重载自己
			get_tree().reload_current_scene()
			
#func _process(delta):
	#if Input.is_action_just_pressed("reset_level"):
		#get_tree().reload_current_scene()
		
