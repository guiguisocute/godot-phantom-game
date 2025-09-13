extends Node2D
class_name LevelController

# 引入常量
const Consts = preload("res://scripts/consts.gd")

# ========= 枚举 =========
enum GameState { PLAYING, FAIL, WIN }
enum FailCause { FALL_PLAYER, FALL_PHANTOM, CONTACT }

# ========= 关卡数据 =========
var level_data: Resource = null

# ========= 状态 =========
var player_cell: Vector2i
var phantom_cell: Vector2i = Vector2i(-999, -999)
var phantom_exists := false
var phantom_play_idx := 0
var record_moves: Array[int] = []
var total_player_steps := 0
var is_button_pressed := false

var game_state: int = GameState.PLAYING
var fail_cause: int = FailCause.FALL_PLAYER
var anim_time: float = 0.0
var just_spawned_this_step := false
var show_spawn_hint_timer := 0.0
const SPAWN_HINT_DUR: float = 1.2

# ========= 引用子节点 =========
@onready var player: Node2D = $Player
@onready var phantom: Node2D = $Phantom
@onready var hud: CanvasLayer = $Hud

# ========= 初始化 =========
func set_level_data(data: Resource) -> void:
	level_data = data
	_reset_level()

func _reset_level() -> void:
	if not level_data: return
	player_cell = level_data.spawn
	phantom_cell = Vector2i(-999, -999)
	phantom_exists = false
	record_moves.clear()
	phantom_play_idx = 0
	total_player_steps = 0
	game_state = GameState.PLAYING
	fail_cause = FailCause.FALL_PLAYER
	anim_time = 0.0
	just_spawned_this_step = false
	show_spawn_hint_timer = 0.0

	player.position = Consts.cell_to_px(player_cell)
	phantom.visible = false

	hud.call("reset_hud", level_data.record_n)

# ========= 输入处理 =========
func _unhandled_input(event: InputEvent) -> void:
	if game_state != GameState.PLAYING:
		if event.is_action_pressed("reset_level"):
			_reset_level()
		if event.is_action_pressed("ui_right") and game_state == GameState.WIN:
			Game.next_level()
		return

	if event.is_action_pressed("ui_left"):
		_try_step(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		_try_step(Vector2i(1, 0))
	elif event.is_action_pressed("ui_up"):
		_try_step(Vector2i(0, 1))
	elif event.is_action_pressed("ui_down"):
		_try_step(Vector2i(0, -1))
	elif event.is_action_pressed("reset_level"):
		_reset_level()

# ========= 游戏规则 =========
func _try_step(delta: Vector2i) -> void:
	if game_state != GameState.PLAYING: return

	var prev_player := player_cell
	var next_player := player_cell + delta

	# 检查边界
	if not level_data.cells.has(next_player):
		_fail(FailCause.FALL_PLAYER, "你落入无尽的深渊。")
		return

	# 桥检测（按钮没踩时第6格无效）
	if next_player == level_data.bridge and not _bridge_active(next_player):
		var below := next_player + Vector2i(0, -1)
		if level_data.cells.has(below):
			player_cell = below
		else:
			_fail(FailCause.FALL_PLAYER, "桥消失，你掉下去了。")
			return
	else:
		player_cell = next_player

	player.position = Consts.cell_to_px(player_cell)
	total_player_steps += 1

	# 录制玩家动作
	if record_moves.size() < level_data.record_n:
		record_moves.append(delta.x if delta.x != 0 else (2 if delta.y > 0 else -2))
		if record_moves.size() == level_data.record_n and not phantom_exists:
			phantom_exists = true
			phantom_cell = level_data.spawn
			phantom.position = Consts.cell_to_px(phantom_cell)
			phantom.visible = true
			just_spawned_this_step = true
			show_spawn_hint_timer = SPAWN_HINT_DUR
			hud.call("show_spawn_hint")

	# 幻影行动
	if phantom_exists and phantom_play_idx < level_data.record_n and (total_player_steps > level_data.record_n) and not just_spawned_this_step:
		_phantom_replay_step(prev_player)

	just_spawned_this_step = false
	_update_button_state()

	# 碰撞检测
	if phantom_exists and player_cell == phantom_cell:
		_fail(FailCause.CONTACT, "你被过去的自己消灭。")
		return

	# 胜利检测
	if player_cell == level_data.altar:
		_win()
		return

	hud.call("update_timeline", record_moves, phantom_play_idx)

# ========= 幻影 =========
func _phantom_replay_step(_prev_player: Vector2i) -> void:
	var cmd := record_moves[phantom_play_idx]
	var next_phantom := phantom_cell

	if abs(cmd) == 1: # 左右
		next_phantom += Vector2i(cmd, 0)
	elif abs(cmd) == 2: # 上下
		next_phantom += Vector2i(0, (1 if cmd > 0 else -1))

	if not level_data.cells.has(next_phantom):
		_fail(FailCause.FALL_PHANTOM, "幻影落入无尽的深渊。")
		return

	phantom_cell = next_phantom
	phantom.position = Consts.cell_to_px(phantom_cell)
	phantom_play_idx += 1

# ========= 辅助函数 =========
func _bridge_active(next_player: Vector2i) -> bool:
	return (next_player == level_data.button) or (phantom_exists and phantom_cell == level_data.button)

func _update_button_state() -> void:
	is_button_pressed = (player_cell == level_data.button) or (phantom_exists and phantom_cell == level_data.button)

# ========= 结局 =========
func _fail(cause: int, msg: String) -> void:
	game_state = GameState.FAIL
	fail_cause = cause
	anim_time = 0.0
	hud.call("show_fail", msg)

func _win() -> void:
	game_state = GameState.WIN
	anim_time = 0.0
	hud.call("show_win")
