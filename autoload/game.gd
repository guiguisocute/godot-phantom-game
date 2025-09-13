extends Node
# 最开始运行的单例，存在于整个游戏的生命周期中
var levels: Array = []
# 初始化关卡数组
var current_index: int = 0

func _ready() -> void:
	levels = [
		load("res://data/levels/level_01.tres"),
		load("res://data/levels/level_02.tres"),
	]
	# 如果一开游戏就进第一关，那就调用 start_level(0)

func goto_main_menu() -> void:
	# 切换到主菜单场景
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	# 获得场景树的方法

func start_level(idx: int = 0) -> void:
	# 进入指定的关卡
	if levels.is_empty(): return
	current_index = clamp(idx, 0, levels.size() - 1)
	var level_packed := load("res://scenes/level.tscn")
	if level_packed:
		get_tree().change_scene_to_packed(level_packed)
		# 等一帧：当前场景切换完成，再把数据塞给关卡脚本
		await get_tree().process_frame
		var level := get_tree().current_scene
		if level and level.has_method("set_level_data"):
			level.set_level_data(levels[current_index])

func restart_level() -> void:
	# 触发重开条件后会被调用的关卡
	start_level(current_index)

func next_level() -> void:
	# 胜利后会被调用的关卡
	start_level(current_index + 1)
