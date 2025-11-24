extends Node

var scene_stack: Array = []  # 场景栈，存储场景路径

# 打开新场景
func push_scene(scene_path: String):
	# 保存当前场景
	var current_scene = get_tree().current_scene
	if current_scene:
		scene_stack.append(current_scene.scene_file_path)
	
	# 加载新场景
	get_tree().change_scene_to_file(scene_path)

# 返回上一个场景
func pop_scene():
	if scene_stack.size() > 0:
		var previous_scene_path = scene_stack.pop_back()
		get_tree().change_scene_to_file(previous_scene_path)
	else:
		print("已经是最后一个场景了")

# 获取栈深度（用于调试）
func get_stack_size() -> int:
	return scene_stack.size()
