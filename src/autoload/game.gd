extends  Node

var previous_scene_path: String = ""

func _process(delta):
	if Input.is_action_just_pressed("reset_level"):
		var current_scene = get_tree().current_scene
		var scene_name = current_scene.name
		
		# 判断当前是不是 UI 场景
		if scene_name == "LevelFailedUI" or scene_name == "death_interface":
			# 从UI返回关卡
			print("返回上一个场景")
			go_back()
		else:
			# 普通游戏场景就重载自己，并记录当前场景
			get_tree().reload_current_scene()

func record_current_scene():
	# 总是记录当前场景路径
	previous_scene_path = get_tree().current_scene.scene_file_path
	print("记录场景: ", previous_scene_path)

func go_back():
	if previous_scene_path != "":
		print("返回到: ", previous_scene_path)
		get_tree().change_scene_to_file(previous_scene_path)  # 移除了引号
	else:
		print("没有上一个场景可以返回")

#func _process(delta):
	#if Input.is_action_just_pressed("reset_level"):
		#get_tree().reload_current_scene()
		
