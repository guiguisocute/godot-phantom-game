extends Node

const MENU_SCENE_PATH  := "res://scenes/main_menu.tscn"
const LEVEL_SCENE_PATH := "res://scenes/Level.tscn"  # 注意大小写要与文件一致

var levels: Array = []          # Array[LevelDef]（如果 LevelDef 没 class_name 就先用 Array）
var current_index: int = 0
# test for commit
func _ready() -> void:
	levels = [
		load("res://data/levels/level_01.tres"),
		load("res://data/levels/level_02.tres"),
	]
	# 想开场直进第一关可在这里：start_level(0)

# ---------- 公共 API ----------
func goto_main_menu() -> void:
	_swap_to_scene_path(MENU_SCENE_PATH)

func start_level(idx: int = 0) -> void:
	if levels.is_empty(): return
	current_index = clamp(idx, 0, levels.size() - 1)

	var packed := load(LEVEL_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Cannot load Level scene: %s" % LEVEL_SCENE_PATH); return

	# 关键：先实例化 -> 先注入关卡数据 -> 再替换当前场景（这样 _ready 时就有数据）
	var inst := packed.instantiate()
	if inst.has_method("set_level_data"):
		inst.call("set_level_data", levels[current_index])
	else:
		push_warning("Level scene has no set_level_data().")

	_swap_current_scene(inst)

func restart_level() -> void:
	start_level(current_index)

func next_level() -> void:
	# 想“循环到第一关”，用这行：
	# start_level( (current_index + 1) % levels.size() )
	# 想“到最后一关就停住”，用 clamp（保持你的语义）：
	start_level(current_index + 1)

# ---------- 内部工具 ----------
func _swap_to_scene_path(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Cannot load scene: %s" % path); return
	var inst := packed.instantiate()
	_swap_current_scene(inst)

func _swap_current_scene(new_scene: Node) -> void:
	var tree := get_tree()
	var old := tree.current_scene
	tree.root.add_child(new_scene)
	tree.set_current_scene(new_scene)
	if old:
		old.queue_free()
