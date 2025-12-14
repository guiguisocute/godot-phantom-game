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

# 只保留一个变量：当前关卡编号
var current_level: int = 1
	# 获取下一关的路径
func get_next_level() -> String:
	# 返回下一关的场景路径，关卡文件名为：level_1.tscn, level_2.tscn...
	return "res://src/level/level_%d.tscn" % [current_level + 1]

# 切换到下一关
func go_to_next_level():
	var next_path = get_next_level()
	
	
	# 检查场景文件是否存在
	if ResourceLoader.exists(next_path):
		push_scene(next_path)
	else:
		print("没有更多关卡了！")
		# 如果没更多关卡，回到第一关或主菜单
		push_scene("res://src/ui/main_menu.tscn")



# 获取栈深度（用于调试）
func get_stack_size() -> int:
	return scene_stack.size()
