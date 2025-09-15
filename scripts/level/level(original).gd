extends Node2D
# 整体说明：
# 这是一个纯绘制/纯逻辑驱动的关卡脚本，不依赖外部场景节点（玩家、幻影、按钮等都用 draw_* 手绘）。
# 玩法核心：玩家先“录制”若干步（record_n），之后生成一个“过去的自己”（幻影）回放这些步。
# 关卡中有：普通可站立平台格（cells）、按钮（button）、可切换的“桥”（bridge）、梯子（ladders_pairs），以及出生（spawn）/祭坛（altar）。
# 关键难点：
# 1）桥在“当回合结束后的激活状态”对“踏入桥”的人物是否掉落有影响（需要预测：玩家这步之后幻影是否会踩在按钮上）
# 2）掉落采用“两段式”：先水平运动到目标格的 x，再竖直掉落到下层/深渊，使动画自然
# 3）胜负判定顺序严格：移动一步后 → 更新按钮/桥持续效果 → 先判胜利，再判与幻影的碰撞失败
# 4）玩家与幻影的移动过渡计时器完全独立，互不干扰

# =========（新增）日志开关与工具 =========
const LOG_PREFIX := "[PhantomGame] "
var DEBUG_LOG := true
func _log(msg: String) -> void:
	if DEBUG_LOG:
		print(LOG_PREFIX + msg)
func _logf(fmt: String, args: Array) -> void:
	if DEBUG_LOG:
		print(LOG_PREFIX + fmt.format(args))

# ========= 通用常量 =========
const CELL_SIZE: float = 96.0
const ORIGIN: Vector2 = Vector2(120, 360)
const MOVE_DUR: float = 0.16
const FAIL_ANIM_DUR: float = 0.8
const WIN_ANIM_DUR: float = 0.8
const DROP_HORIZ_DUR: float = 0.10
const DROP_VERT_DUR: float = 0.18

# 时间轴UI（上面一行：录制；下面一行：回放）
const TIMELINE_TOP_Y: float = 80.0
const TIMELINE_BOX_W: float = 40.0
const TIMELINE_BOX_H: float = 40.0
const TIMELINE_GAP:   float = 8.0

# ========= 关卡数据结构（内部类） =========
class LevelData:
	# 逻辑格坐标采用 Vector2i（x 水平，y 层；y=0 上层，y=-1 下层）
	# cells/ladders_pairs 用 Dictionary 充当 Set，仅需判是否存在键
	var cells : Dictionary[Vector2i, bool] = {}                # Set<Vector2i>
	var ladders_pairs : Dictionary[Vector2i, bool] = {}        # Set<Vector2i>，键为 (x, lower_y)：表示连接 lower_y ↔ lower_y+1
	var spawn: Vector2i
	var altar: Vector2i
	var button: Vector2i
	var bridge: Vector2i
	var record_n: int = 4
	var name: String = "Level"

	func has_cell(p: Vector2i) -> bool:
		return p in cells

	func has_ladder_between(x: int, y_from: int, y_to: int) -> bool:
		if abs(y_from - y_to) != 1:
			return false
		var lower_y: int = int(min(y_from, y_to))
		return Vector2i(x, lower_y) in ladders_pairs

# ========= 关卡配置 =========
var LEVELS: Array[LevelData] = []

func _make_levels() -> void:
	LEVELS.clear()

	# --- Level 1（线性教学：只有一层，无梯子，包含按钮-桥基础）---
	var L1 := LevelData.new()
	L1.name = "Tutorial-1D"
	L1.record_n = 4
	for x in range(1, 8): L1.cells[Vector2i(x, 0)] = true  # x=1..7
	L1.spawn = Vector2i(1, 0)
	L1.altar = Vector2i(7, 0)
	L1.button = Vector2i(3, 0)
	L1.bridge = Vector2i(6, 0)
	L1.ladders_pairs = {}         # 无梯子
	LEVELS.append(L1)
	# honkai starrail

	# --- Level 2（二维：上下两层 + 梯子 + 桥在上层）---
	var L2 := LevelData.new()
	L2.name = "Tutorial-2D"
	L2.record_n = 5
	# 上层 y=0: x=0..5
	for x in range(0, 6): L2.cells[Vector2i(x, 0)] = true
	# 下层 y=-1: x=1..4
	for x in range(1, 5): L2.cells[Vector2i(x, -1)] = true
	L2.spawn = Vector2i(0, 0)
	L2.altar = Vector2i(5, 0)
	L2.button = Vector2i(4, -1)
	L2.bridge = Vector2i(4, 0)
	# 原先 ladders_x={1,2}（0↔-1），现在精确成段：
	L2.ladders_pairs = {
		Vector2i(1, -1): true,   # 1: -1↔0
		Vector2i(2, -1): true    # 2: -1↔0
	}
	LEVELS.append(L2)

	# --- Level 3（三层挑战，精确梯子段）---
	var L3 := LevelData.new()
	L3.name = "Challenge-3D"
	L3.record_n = 8
	# 平台
	for x in range(0, 7): L3.cells[Vector2i(x, 1)] = true   # y=1: x=0..6
	for x in range(0, 5): L3.cells[Vector2i(x, 0)] = true   # y=0: x=0..4
	for x in range(0, 5): L3.cells[Vector2i(x, -1)] = true  # y=-1: x=0..4
	# 关键点
	L3.spawn  = Vector2i(2, 1)
	L3.altar  = Vector2i(6, 1)
	L3.button = Vector2i(1, -1)
	L3.bridge = Vector2i(5, 1)
	# 精确梯子段
	L3.ladders_pairs = {
		Vector2i(1, 0): true,   # 1: 0↔1
		Vector2i(3, 0): true,   # 3: 0↔1
		Vector2i(0, -1): true,  # 0: -1↔0
		Vector2i(2, -1): true,  # 2: -1↔0
		Vector2i(4, -1): true   # 4: -1↔0
	}
	LEVELS.append(L3)

# ========= 运行时状态 =========
enum GameState { PLAYING, FAIL, WIN }
enum FailCause { FALL_PLAYER, FALL_PHANTOM, CONTACT }

var steps_until_enemy: int = 0

var cur: LevelData
var level_index: int = 0

var player_cell: Vector2i
var phantom_cell: Vector2i = Vector2i(-999, -999)
var phantom_exists: bool = false
var is_button_pressed: bool = false

var record_moves: Array[int] = []
var phantom_play_idx: int = 0
var total_player_steps: int = 0

var game_state: int = GameState.PLAYING
var fail_cause: int = FailCause.FALL_PLAYER
var win_state: bool = false
var anim_time: float = 0.0

var just_spawned_this_step: bool = false
var show_spawn_hint_timer: float = 0.0
const SPAWN_HINT_DUR: float = 1.2

# ========== 渲染/过渡状态 ==========
var player_draw_pos: Vector2
var player_from_px: Vector2
var player_to_px: Vector2
var player_move_t: float = 1.0
var player_is_moving: bool = false
var player_move_dur: float = MOVE_DUR

var phantom_draw_pos: Vector2
var phantom_from_px: Vector2
var phantom_to_px: Vector2
var phantom_move_t: float = 1.0
var phantom_is_moving: bool = false
var phantom_freeze_after_move: bool = false
var phantom_move_dur: float = MOVE_DUR

var player_pending_drop: bool = false
var player_drop_to_px: Vector2
var player_fail_after_drop: bool = false
var player_fail_cause_after: int = FailCause.FALL_PLAYER

var phantom_pending_drop: bool = false
var phantom_drop_to_px: Vector2
var phantom_fail_after_drop: bool = false
var phantom_fail_cause_after: int = FailCause.FALL_PHANTOM

# ========= 生命周期 =========
# 玩家开始两段坠落（真深渊）后的公共收尾：让幻影同步执行一条，并刷新按钮/桥外观


func _ready() -> void:
	print("genshin start!")
	_log("Engine ready, building levels…")
	_make_levels()
	_load_level(0)
	set_process(true)
	_log("Processing enabled.")

func _load_level(idx: int) -> void:
	level_index = clamp(idx, 0, LEVELS.size() - 1)
	cur = LEVELS[level_index]
	_logf("Load level [{0}] name={1} record_n={2}", [str(level_index), cur.name, str(cur.record_n)])
	reset_level()

func next_level() -> void:
	_log("Next level requested.")
	_load_level((level_index + 1) % LEVELS.size())

func reset_level() -> void:
	_log("Reset level state.")
	player_cell = cur.spawn
	phantom_cell = Vector2i(-999, -999)
	phantom_exists = false
	is_button_pressed = false
	record_moves.clear()
	phantom_play_idx = 0
	total_player_steps = 0
	game_state = GameState.PLAYING
	win_state = false
	fail_cause = FailCause.FALL_PLAYER
	anim_time = 0.0
	just_spawned_this_step = false
	show_spawn_hint_timer = 0.0
	steps_until_enemy = cur.record_n

	player_draw_pos = _cell_to_px(player_cell)
	player_from_px = player_draw_pos
	player_to_px = player_draw_pos
	player_move_t = 1.0
	player_is_moving = false
	player_move_dur = MOVE_DUR

	phantom_draw_pos = _cell_to_px(phantom_cell)
	phantom_from_px = phantom_draw_pos
	phantom_to_px = phantom_draw_pos
	phantom_move_t = 1.0
	phantom_is_moving = false
	phantom_move_dur = MOVE_DUR

	player_pending_drop = false
	player_fail_after_drop = false
	phantom_pending_drop = false
	phantom_fail_after_drop = false

	queue_redraw()
	_logf("Spawn at {0}, Altar at {1}, Button at {2}, Bridge at {3}", [str(cur.spawn), str(cur.altar), str(cur.button), str(cur.bridge)])

# ========= 输入 =========
func _unhandled_input(event: InputEvent) -> void:
	if game_state != GameState.PLAYING:
		if event.is_action_pressed("reset_level"):
			_log("Input: reset while not playing.")
			reset_level()
		if event.is_action_pressed("ui_right") and game_state == GameState.WIN:
			_log("Input: proceed to next level after win.")
			next_level()
		return

	if player_is_moving or phantom_is_moving:
		return

	var dir_h: int = 0
	var do_move: bool = false
	if event.is_action_pressed("ui_left"):
		dir_h = -1; do_move = true
	elif event.is_action_pressed("ui_right"):
		dir_h = +1; do_move = true
	elif event.is_action_pressed("ui_up"):
		_log("Input: try climb up.")
		_try_vertical(+1)
	elif event.is_action_pressed("ui_down"):
		_log("Input: try climb down.")
		_try_vertical(-1)

	if do_move:
		_logf("Input: try step dir_x={0}", [str(dir_h)])
		_try_step(dir_h)

	if event.is_action_pressed("reset_level"):
		_log("Input: reset level.")
		reset_level()

# ========= 规则推进：水平 =========
func _try_step(dir_x: int) -> void:
	if game_state != GameState.PLAYING: return

	var prev_player: Vector2i = player_cell
	var prev_phantom: Vector2i = phantom_cell

	var next_player: Vector2i = player_cell + Vector2i(dir_x, 0)
	_logf("TryStep from {0} -> {1}", [str(prev_player), str(next_player)])

	# 情况 A：目标格不是平台
	if not cur.has_cell(next_player):
		if next_player == cur.bridge and not _bridge_active_for_player_entry(next_player):
			var below: Vector2i = next_player + Vector2i(0, -1)
			if cur.has_cell(below):
				_logf("Bridge inactive, safe below at {0}. Player will drop.", [str(below)])
				_start_player_move_then_drop(prev_player, next_player, _cell_to_px(below), false, FailCause.FALL_PLAYER)
				player_cell = below
				total_player_steps += 1
				_dec_spawn_counter()

			if record_moves.size() < cur.record_n:
				record_moves.append(_signi(dir_x))
			if record_moves.size() == cur.record_n and not phantom_exists:
				phantom_exists = true
				phantom_cell = cur.spawn
				var spawn_px: Vector2 = _cell_to_px(phantom_cell)
				phantom_draw_pos = spawn_px
				phantom_from_px = spawn_px
				phantom_to_px = spawn_px
				phantom_move_t = 1.0
				phantom_is_moving = false
				just_spawned_this_step = true
				show_spawn_hint_timer = SPAWN_HINT_DUR
				_log("Phantom spawned (record complete).")

				_after_player_moved_from_bridge_drop(prev_player)
				return
			else:
				var abyss_px := _cell_to_px(next_player) + Vector2(0, 260)
				_log("Bridge inactive, no floor below. Player falls into abyss.")
				_start_player_move_then_drop(prev_player, next_player, abyss_px, true, FailCause.FALL_PLAYER)
				_after_player_started_abyss(prev_player)
				return
		else:
			var abyss_px2 := _cell_to_px(next_player) + Vector2(0, 260)
			_log("Target is not a cell; player falls into abyss.")
			_start_player_move_then_drop(prev_player, next_player, abyss_px2, true, FailCause.FALL_PLAYER)
			_after_player_started_abyss(prev_player)
			return

	# 情况 B：目标格是“桥格”，但根据“本回合的落位”仍未激活
	if next_player == cur.bridge and not _bridge_active_for_player_entry(next_player):
		var below2: Vector2i = next_player + Vector2i(0, -1)
		if cur.has_cell(below2):
			_logf("Step onto inactive bridge; drop to {0}.", [str(below2)])
			_start_player_move_then_drop(prev_player, next_player, _cell_to_px(below2), false, FailCause.FALL_PLAYER)
			player_cell = below2
			total_player_steps += 1
			_dec_spawn_counter()

			if record_moves.size() < cur.record_n:
				record_moves.append(_signi(dir_x))
			if record_moves.size() == cur.record_n and not phantom_exists:
				phantom_exists = true
				phantom_cell = cur.spawn
				var spawn_px2: Vector2 = _cell_to_px(phantom_cell)
				phantom_draw_pos = spawn_px2
				phantom_from_px = spawn_px2
				phantom_to_px = spawn_px2
				phantom_move_t = 1.0
				phantom_is_moving = false
				just_spawned_this_step = true
				show_spawn_hint_timer = SPAWN_HINT_DUR
				_log("Phantom spawned (record complete).")
			_after_player_moved_from_bridge_drop(prev_player)
			return
		else:
			var abyss_px3 := _cell_to_px(next_player) + Vector2(0, 260)
			_log("Inactive bridge with abyss below; player falls.")
			_start_player_move_then_drop(prev_player, next_player, abyss_px3, true, FailCause.FALL_PLAYER)
			_after_player_started_abyss(prev_player)
			return

	# 情况 C：正常水平移动
	_start_player_move(prev_player, next_player)
	player_cell = next_player
	total_player_steps += 1
	_dec_spawn_counter()
	_logf("Player moved to {0}. total_player_steps={1}", [str(player_cell), str(total_player_steps)])

	if record_moves.size() < cur.record_n:
		record_moves.append(_signi(dir_x))
		if record_moves.size() == cur.record_n and not phantom_exists:
			phantom_exists = true
			phantom_cell = cur.spawn
			var spawn_px3: Vector2 = _cell_to_px(phantom_cell)
			phantom_draw_pos = spawn_px3
			phantom_from_px = spawn_px3
			phantom_to_px = spawn_px3
			phantom_move_t = 1.0
			phantom_is_moving = false
			just_spawned_this_step = true
			show_spawn_hint_timer = SPAWN_HINT_DUR
			_log("Phantom spawned (record complete).")

	if phantom_exists and phantom_play_idx < cur.record_n and (total_player_steps > cur.record_n) and not just_spawned_this_step:
		_phantom_replay_step(prev_player)

	just_spawned_this_step = false

	_update_button_state()
	_bridge_persistence_check()

	if player_cell == cur.altar:
		_win(); return

	if phantom_exists:
		if player_cell == phantom_cell:
			_fail(FailCause.CONTACT, "你被过去的自己消灭。"); return
		if (player_cell == prev_phantom) and (phantom_cell == prev_player) and prev_phantom != Vector2i(-999,-999):
			_fail(FailCause.CONTACT, "你被过去的自己消灭。"); return

	queue_redraw()

# ========= 规则推进：垂直（爬梯） =========
func _try_vertical(dy: int) -> void:
	if game_state != GameState.PLAYING: return
	if player_is_moving or phantom_is_moving: return

	# 精确检查：当前列在 y→y+dy 之间是否真的有梯子段
	if not cur.has_ladder_between(player_cell.x, player_cell.y, player_cell.y + dy): 
		_logf("No ladder segment between y={0} and y={1} at x={2}", [str(player_cell.y), str(player_cell.y + dy), str(player_cell.x)])
		return

	var target: Vector2i = player_cell + Vector2i(0, dy)
	if not cur.has_cell(target): 
		_logf("Vertical target {0} is not a cell.", [str(target)])
		return

	var prev: Vector2i = player_cell
	_start_player_move(prev, target)
	player_cell = target
	total_player_steps += 1
	_dec_spawn_counter()
	_logf("Player climbed to {0}. steps={1}", [str(player_cell), str(total_player_steps)])

	if record_moves.size() < cur.record_n:
		record_moves.append(2 if dy > 0 else -2)
		if record_moves.size() == cur.record_n and not phantom_exists:
			phantom_exists = true
			phantom_cell = cur.spawn
			var spawn_px: Vector2 = _cell_to_px(phantom_cell)
			phantom_draw_pos = spawn_px
			phantom_from_px = spawn_px
			phantom_to_px = spawn_px
			phantom_move_t = 1.0
			phantom_is_moving = false
			just_spawned_this_step = true
			show_spawn_hint_timer = SPAWN_HINT_DUR
			_log("Phantom spawned (record complete).")

	if phantom_exists and phantom_play_idx < cur.record_n and (total_player_steps > cur.record_n) and not just_spawned_this_step:
		_phantom_replay_step(prev)

	just_spawned_this_step = false
	_update_button_state()
	_bridge_persistence_check()

	if player_cell == cur.altar:
		_win(); return
	if phantom_exists and player_cell == phantom_cell:
		_fail(FailCause.CONTACT, "你被过去的自己消灭。"); return

	queue_redraw()

# ========= 幻影执行一条录制命令 =========
func _phantom_replay_step(_prev_player_before: Vector2i) -> void:
	var cmd: int = record_moves[phantom_play_idx]
	var ph_next: Vector2i = phantom_cell
	_logf("Phantom step idx={0} cmd={1} from {2}", [str(phantom_play_idx), str(cmd), str(phantom_cell)])

	if abs(cmd) == 1:
		ph_next += Vector2i(cmd, 0)

		if not cur.has_cell(ph_next):
			if ph_next == cur.bridge:
				var active_after_for_ph: bool = (player_cell == cur.button) or (ph_next == cur.button)
				if not active_after_for_ph:
					var p_below: Vector2i = ph_next + Vector2i(0, -1)
					if cur.has_cell(p_below):
						_logf("Phantom: inactive bridge, drop to {0}", [str(p_below)])
						_start_phantom_move_then_drop(phantom_cell, ph_next, _cell_to_px(p_below), false, FailCause.FALL_PHANTOM)
						phantom_cell = p_below
						phantom_play_idx += 1
						return
					else:
						var abyss_px := _cell_to_px(ph_next) + Vector2(0, 260)
						_log("Phantom: inactive bridge & abyss, fall.")
						_start_phantom_move_then_drop(phantom_cell, ph_next, abyss_px, true, FailCause.FALL_PHANTOM)
						return
			else:
				var abyss_px2 := _cell_to_px(ph_next) + Vector2(0, 260)
				_log("Phantom: target not cell, fall into abyss.")
				_start_phantom_move_then_drop(phantom_cell, ph_next, abyss_px2, true, FailCause.FALL_PHANTOM)
				return

		if ph_next == cur.bridge:
			var active_after_for_ph2: bool = (player_cell == cur.button) or (ph_next == cur.button)
			if not active_after_for_ph2:
				var p_below2: Vector2i = ph_next + Vector2i(0, -1)
				if cur.has_cell(p_below2):
					_logf("Phantom: step onto inactive bridge, drop to {0}", [str(p_below2)])
					_start_phantom_move_then_drop(phantom_cell, ph_next, _cell_to_px(p_below2), false, FailCause.FALL_PHANTOM)
					phantom_cell = p_below2
					phantom_play_idx += 1
					return
				else:
					var abyss_px3 := _cell_to_px(ph_next) + Vector2(0, 260)
					_log("Phantom: inactive bridge & abyss, fall.")
					_start_phantom_move_then_drop(phantom_cell, ph_next, abyss_px3, true, FailCause.FALL_PHANTOM)
					return

		_start_phantom_move(phantom_cell, ph_next)
		phantom_cell = ph_next
		_logf("Phantom moved to {0}", [str(phantom_cell)])

	elif abs(cmd) == 2:
		# 精确检查：该段是否有梯子
		var dy: int = (1 if cmd > 0 else -1)
		if not cur.has_ladder_between(phantom_cell.x, phantom_cell.y, phantom_cell.y + dy):
			var fall_px := _cell_to_px(phantom_cell) + Vector2(0, 260)
			_log("Phantom tried climb without ladder; fall.")
			_start_phantom_move_then_drop(phantom_cell, phantom_cell, fall_px, true, FailCause.FALL_PHANTOM)
			return

		ph_next += Vector2i(0, dy)

		if not cur.has_cell(ph_next):
			var abyss_px4 := _cell_to_px(ph_next) + Vector2(0, 260)
			_log("Phantom climbed into non-cell; fall.")
			_start_phantom_move_then_drop(phantom_cell, ph_next, abyss_px4, true, FailCause.FALL_PHANTOM)
			return

		_start_phantom_move(phantom_cell, ph_next)
		phantom_cell = ph_next
		_logf("Phantom climbed to {0}", [str(phantom_cell)])
	else:
		pass

	phantom_play_idx += 1

	if phantom_play_idx >= cur.record_n:
		phantom_freeze_after_move = true
		_log("Phantom finished all recorded steps; freeze.")

# ========= 桥是否激活（用于“玩家尝试踏入桥格”的即时判断） =========
func _bridge_active_for_player_entry(player_next: Vector2i) -> bool:
	var phantom_on_button_after := false

	var will_phantom_move := phantom_exists \
		and phantom_play_idx < cur.record_n \
		and (total_player_steps + 1 > cur.record_n) \
		and not just_spawned_this_step

	if will_phantom_move:
		var cmd: int = record_moves[phantom_play_idx]
		var cand: Vector2i = phantom_cell
		if abs(cmd) == 1:
			cand += Vector2i(cmd, 0)
		elif abs(cmd) == 2:
			var dy := (1 if cmd > 0 else -1)
			var cand2 := cand + Vector2i(0, dy)
			if cur.has_ladder_between(phantom_cell.x, phantom_cell.y, phantom_cell.y + dy) and cur.has_cell(cand2):
				cand = cand2
		phantom_on_button_after = (cand == cur.button)
	else:
		phantom_on_button_after = (phantom_exists and phantom_cell == cur.button)

	var active := (player_next == cur.button) or phantom_on_button_after
	_logf("Bridge active check for player_next={0} => {1}", [str(player_next), str(active)])
	return active

func _bridge_active_after(_player_cur: Vector2i, player_next: Vector2i, phantom_cur: Vector2i) -> bool:
	return (player_next == cur.button) or (phantom_cur == cur.button)

func _update_button_state() -> void:
	is_button_pressed = (player_cell == cur.button) or (phantom_exists and phantom_cell == cur.button)
	_logf("Update button state: is_button_pressed={0}", [str(is_button_pressed)])

func _bridge_persistence_check() -> void:
	if not is_button_pressed:
		if player_cell == cur.bridge:
			var pb: Vector2i = player_cell + Vector2i(0, -1)
			if cur.has_cell(pb):
				_logf("Bridge off: player standing on bridge, drop to {0}", [str(pb)])
				_start_player_move_direct(player_cell, pb)
				player_cell = pb
			else:
				_log("Bridge off: player over abyss; fail.")
				_fail(FailCause.FALL_PLAYER, "你落入无尽的深渊。"); return

		if phantom_exists and phantom_cell == cur.bridge:
			var phb: Vector2i = phantom_cell + Vector2i(0, -1)
			if cur.has_cell(phb):
				_logf("Bridge off: phantom standing on bridge, drop to {0}", [str(phb)])
				_start_phantom_move_direct(phantom_cell, phb)
				phantom_cell = phb
			else:
				_log("Bridge off: phantom over abyss; fail.")
				_fail(FailCause.FALL_PHANTOM, "过去的幻影落入无尽的深渊。"); return

# ========= 过渡动画（设置起止像素与时长） =========
func _start_player_move(from_c: Vector2i, to_c: Vector2i) -> void:
	player_from_px = _cell_to_px(from_c)
	player_to_px = _cell_to_px(to_c)
	player_move_t = 0.0
	player_move_dur = MOVE_DUR
	player_is_moving = true
	_logf("Player tween start {0} -> {1}", [str(from_c), str(to_c)])

func _start_player_move_direct(from_c: Vector2i, to_c: Vector2i) -> void:
	player_from_px = _cell_to_px(from_c)
	player_to_px = _cell_to_px(to_c)
	player_move_t = 0.0
	player_move_dur = DROP_VERT_DUR
	player_is_moving = true
	_logf("Player direct move {0} -> {1}", [str(from_c), str(to_c)])

func _start_phantom_move(from_c: Vector2i, to_c: Vector2i) -> void:
	phantom_from_px = _cell_to_px(from_c)
	phantom_to_px = _cell_to_px(to_c)
	phantom_move_t = 0.0
	phantom_move_dur = MOVE_DUR
	phantom_is_moving = true
	_logf("Phantom tween start {0} -> {1}", [str(from_c), str(to_c)])

func _start_phantom_move_direct(from_c: Vector2i, to_c: Vector2i) -> void:
	phantom_from_px = _cell_to_px(from_c)
	phantom_to_px = _cell_to_px(to_c)
	phantom_move_t = 0.0
	phantom_move_dur = DROP_VERT_DUR
	phantom_is_moving = true
	_logf("Phantom direct move {0} -> {1}", [str(from_c), str(to_c)])

func _start_player_move_then_drop(from_c: Vector2i, to_c: Vector2i, drop_to_px: Vector2, will_fail: bool, fail_cause: int) -> void:
	_start_player_move(from_c, to_c)
	player_move_dur = DROP_HORIZ_DUR
	player_pending_drop = true
	player_drop_to_px = drop_to_px
	player_fail_after_drop = will_fail
	player_fail_cause_after = fail_cause
	_logf("Player will drop after horizontal: to_px={0}, will_fail={1}", [str(drop_to_px), str(will_fail)])

func _start_phantom_move_then_drop(from_c: Vector2i, to_c: Vector2i, drop_to_px: Vector2, will_fail: bool, fail_cause: int) -> void:
	_start_phantom_move(from_c, to_c)
	phantom_move_dur = DROP_HORIZ_DUR
	phantom_pending_drop = true
	phantom_drop_to_px = drop_to_px
	phantom_fail_after_drop = will_fail
	phantom_fail_cause_after = fail_cause
	_logf("Phantom will drop after horizontal: to_px={0}, will_fail={1}", [str(drop_to_px), str(will_fail)])

# ========= 主循环：推进补间 & 触发收尾 =========
func _process(delta: float) -> void:
	if player_is_moving:
		player_move_t = min(1.0, player_move_t + delta / player_move_dur)
		var ep: float = ease_out_quad(player_move_t)
		player_draw_pos = player_from_px.lerp(player_to_px, ep)
		if player_move_t >= 1.0:
			player_is_moving = false
			if player_pending_drop:
				player_draw_pos = player_to_px
				player_pending_drop = false
				player_from_px = player_to_px
				player_to_px = player_drop_to_px
				player_move_t = 0.0
				player_move_dur = DROP_VERT_DUR
				player_is_moving = true
				_log("Player vertical drop phase begin.")
			elif player_fail_after_drop:
				player_fail_after_drop = false
				_log("Player drop finished with fail.")
				_fail(player_fail_cause_after, "你落入无尽的深渊。")
			else:
				player_draw_pos = _cell_to_px(player_cell)
		queue_redraw()

	if phantom_is_moving:
		phantom_move_t = min(1.0, phantom_move_t + delta / phantom_move_dur)
		var eh: float = ease_out_quad(phantom_move_t)
		phantom_draw_pos = phantom_from_px.lerp(phantom_to_px, eh)
		if phantom_move_t >= 1.0:
			phantom_is_moving = false
			if phantom_freeze_after_move:
				phantom_freeze_after_move = false
				_log("Phantom freeze after finishing playback.")
			if phantom_pending_drop:
				phantom_draw_pos = phantom_to_px
				phantom_pending_drop = false
				phantom_from_px = phantom_to_px
				phantom_to_px = phantom_drop_to_px
				phantom_move_t = 0.0
				phantom_move_dur = DROP_VERT_DUR
				phantom_is_moving = true
				_log("Phantom vertical drop phase begin.")
			elif phantom_fail_after_drop:
				phantom_fail_after_drop = false
				_log("Phantom drop finished with fail.")
				_fail(phantom_fail_cause_after, "过去的幻影落入无尽的深渊。")
			else:
				phantom_draw_pos = _cell_to_px(phantom_cell)
		queue_redraw()

	if game_state != GameState.PLAYING:
		anim_time += delta
		queue_redraw()

	if show_spawn_hint_timer > 0.0:
		show_spawn_hint_timer = max(0.0, show_spawn_hint_timer - delta)
		queue_redraw()

# ========= 状态切换：失败/胜利 =========
func _fail(cause: int, _msg: String) -> void:
	game_state = GameState.FAIL
	fail_cause = cause
	anim_time = 0.0
	queue_redraw()
	_logf("FAIL state entered. cause={0}", [str(cause)])

func _win() -> void:
	game_state = GameState.WIN
	anim_time = 0.0
	player_fail_after_drop = false
	phantom_fail_after_drop = false
	queue_redraw()
	_log("WIN state entered.")

# ========= 绘制（所有视觉元素都在此手绘） =========
func _draw() -> void:
	draw_rect(Rect2(Vector2(0,0), get_viewport_rect().size), Color(0.08,0.09,0.12))

	# 平台条（顶边）
	for p in cur.cells.keys():
		var px: Vector2 = _cell_to_px_top(p)
		if p == cur.bridge and not is_button_pressed:
			draw_rect(Rect2(px, Vector2(CELL_SIZE - 8.0, 14.0)), Color(0,0,0))
		else:
			draw_rect(Rect2(px, Vector2(CELL_SIZE - 8.0, 14.0)), Color(0.25,0.28,0.34))

	# 按钮（细条）
	var btn_col: Color = (Color(0.2,0.8,0.3) if is_button_pressed else Color(0.15,0.45,0.2))
	var btn_top: Vector2 = _cell_to_px_top(cur.button) + Vector2(0, 2)
	draw_rect(Rect2(btn_top, Vector2(CELL_SIZE - 8.0, 6.0)), btn_col)

	# 梯子：对 ladders_pairs 的每一段，若两端都有平台则画出来
	for key in cur.ladders_pairs.keys():
		var seg: Vector2i = key
		var x: int = seg.x          # 连接 lower_y ↔ lower_y+1
		var lower_y: int = seg.y
		var up_y: int = lower_y + 1
		if cur.has_cell(Vector2i(x, lower_y)) and cur.has_cell(Vector2i(x, up_y)):
			var up_px: Vector2 = _cell_to_px(Vector2i(x, up_y))
			var dn_px: Vector2 = _cell_to_px(Vector2i(x, lower_y))
			draw_line(up_px + Vector2(0, 30),  dn_px + Vector2(0, 30),  Color(0.8,0.7,0.4), 4.0)
			draw_line(up_px + Vector2(12, 30), dn_px + Vector2(12, 30), Color(0.8,0.7,0.4), 4.0)

	# 出生点 & 祭坛
	_draw_spawn_marker(_cell_to_px(cur.spawn))
	_draw_altar_marker(_cell_to_px(cur.altar))

	# 玩家/幻影主体与状态覆盖层
	var ppos: Vector2 = player_draw_pos
	var phpos: Vector2 = phantom_draw_pos

	match game_state:
		GameState.PLAYING:
			draw_circle(ppos, 12.0, Color(0.3,0.7,1.0))
			if phantom_exists:
				draw_circle(phpos, 12.0, Color(1.0,0.4,0.45))
		GameState.FAIL:
			var t: float = clamp(anim_time / FAIL_ANIM_DUR, 0.0, 1.0)
			if fail_cause == FailCause.FALL_PLAYER:
				var drop: Vector2 = Vector2(0, 220.0 * ease_out_quad(t))
				draw_circle(ppos + drop, 12.0 * (1.0 - 0.2 * t), Color(0.3,0.7,1.0, 1.0 - t))
				if phantom_exists:
					draw_circle(phpos, 12.0, Color(1.0,0.4,0.45,0.8))
			elif fail_cause == FailCause.FALL_PHANTOM:
				if phantom_exists:
					var drop2: Vector2 = Vector2(0, 220.0 * ease_out_quad(t))
					draw_circle(phpos + drop2, 12.0 * (1.0 - 0.2 * t), Color(1.0,0.4,0.45, 1.0 - t))
				draw_circle(ppos, 12.0, Color(0.3,0.7,1.0,0.8))
			else:
				var r: float = lerpf(12.0, 0.0, ease_in_quad(t))
				var flash: Color = Color(1,1,1, (1.0 - t) * 0.5)
				draw_circle(ppos, r, Color(0.3,0.7,1.0, 1.0 - t))
				if phantom_exists:
					draw_circle(phpos, r, Color(1.0,0.4,0.45, 1.0 - t))
				var mid: Vector2 = (ppos + phpos) * 0.5 if phantom_exists else ppos
				draw_circle(mid, 20.0 * (1.0 - t) + 4.0, flash)
			_draw_fail_popup()
		GameState.WIN:
			draw_circle(ppos, 12.0, Color(0.3,0.7,1.0))
			if phantom_exists:
				draw_circle(phpos, 12.0, Color(1.0,0.4,0.45))
			var vp: Vector2 = get_viewport_rect().size
			var a: float = clamp(anim_time / WIN_ANIM_DUR, 0.0, 1.0) * 0.6
			draw_rect(Rect2(Vector2(0,0), vp), Color(1.0,0.95,0.2, a))
			_draw_win_popup()

	# 顶部提示文本 & 时间轴/倒计时
	var tip: String = " ←/→ 左右 | ↑/↓ 上下(梯子) | R 重开"
	var tip2 := "【提示】过去的幻影已出生，将从下一步开始行动。"
	if game_state == GameState.PLAYING and show_spawn_hint_timer > 0.0:
		_draw_text_top_left(tip2, Vector2(510, 60))
	_draw_text_top_left(tip, Vector2(24, 36))
	_draw_timeline()
	if not phantom_exists:
		_draw_spawn_countdown()

func _draw_spawn_countdown() -> void:
	var font: Font = ThemeDB.fallback_font as Font
	var size: int = ThemeDB.fallback_font_size
	var viewport: Vector2 = get_viewport_rect().size
	var msg := str(steps_until_enemy) + "步之后，过去的自己将化作敌人"
	var y := TIMELINE_TOP_Y + TIMELINE_BOX_H * 0.5 - 40
	draw_string(
		font,
		Vector2(0, y),
		msg,
		HORIZONTAL_ALIGNMENT_CENTER,
		viewport.x,
		size,
		Color(1,1,1,0.95)
	)

# ========= 像素换算 & 文本/弹窗绘制 =========
func _cell_to_px(c: Vector2i) -> Vector2:
	return ORIGIN + Vector2(float(c.x) * CELL_SIZE + (CELL_SIZE - 8.0) / 2.0, -28.0 + float(-c.y) * 90.0)

func _cell_to_px_top(c: Vector2i) -> Vector2:
	return ORIGIN + Vector2(float(c.x) * CELL_SIZE, float(-c.y) * 90.0)

func _draw_text_top_left(text: String, position: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font as Font
	var size: int = ThemeDB.fallback_font_size
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(1,1,1,0.9))

func _draw_center_popup(title: String, body: String, col: Color) -> void:
	var viewport: Vector2 = get_viewport_rect().size
	var font: Font = ThemeDB.fallback_font as Font
	var title_size: int = ThemeDB.fallback_font_size + 4
	var body_size: int = ThemeDB.fallback_font_size

	var box_w: float = 540.0
	var box_h: float = 190.0
	var box: Rect2 = Rect2(Vector2(viewport.x * 0.5 - box_w / 2.0, viewport.y * 0.5 - box_h / 2.0), Vector2(box_w, box_h))
	draw_rect(box, Color(0,0,0,0.75), true, -1.0)
	draw_rect(box.grow(2.0), col, false, 3.0)

	var title_pos: Vector2 = box.position + Vector2(24, 46)
	var body_pos: Vector2 = box.position + Vector2(24, 92)
	draw_string(font, title_pos, title, HORIZONTAL_ALIGNMENT_LEFT, box_w - 48.0, title_size, Color(1,1,1))
	var tail_text: String = ("\n按 → 进入下一关 或 按 R 重开" if game_state == GameState.WIN else "\n按 R 重开")
	draw_string(font, body_pos, body + tail_text, HORIZONTAL_ALIGNMENT_LEFT, box_w - 48.0, body_size, Color(1,1,1,0.9))

func _draw_fail_popup() -> void:
	if fail_cause == FailCause.CONTACT:
		_draw_center_popup("失败", "你被过去的自己消灭。", Color(1.0,0.35,0.35))
	else:
		_draw_center_popup("失败", "你落入无尽的深渊。", Color(1.0,0.35,0.35))

func _draw_win_popup() -> void:
	_draw_center_popup("恭喜通关！", "你触碰了祭坛。", Color(0.95,0.9,0.2))

func _draw_spawn_marker(p: Vector2) -> void:
	draw_line(p + Vector2(-18,-8), p + Vector2(-18,-44), Color(0.3,0.6,1.0), 3.0)
	var tri := PackedVector2Array([p + Vector2(-18,-44), p + Vector2(4,-36), p + Vector2(-18,-28)])
	draw_colored_polygon(tri, Color(0.3,0.6,1.0))

func _draw_altar_marker(p: Vector2) -> void:
	draw_rect(Rect2(p + Vector2(-10,-30), Vector2(20,30)), Color(0.95,0.9,0.3), true)
	draw_rect(Rect2(p + Vector2(-14,0), Vector2(28,6)), Color(0.8,0.75,0.25), true)
	draw_circle(p + Vector2(0,-38), 10.0, Color(1.0,0.95,0.4,0.5))

# ========= 时间轴（UI 展示录制/回放） =========
func _draw_timeline() -> void:
	var font: Font = ThemeDB.fallback_font as Font
	var size: int = ThemeDB.fallback_font_size
	var viewport: Vector2 = get_viewport_rect().size

	var total_w: float = float(cur.record_n) * TIMELINE_BOX_W + float(cur.record_n - 1) * TIMELINE_GAP
	var x0: float = (viewport.x - total_w) / 2.0

	# 上行：玩家录制的前 record_n 步
	for i in range(cur.record_n):
		var box: Rect2 = Rect2(Vector2(x0 + float(i) * (TIMELINE_BOX_W + TIMELINE_GAP), TIMELINE_TOP_Y), Vector2(TIMELINE_BOX_W, TIMELINE_BOX_H))
		draw_rect(box, Color(0.18,0.2,0.25,0.9))
		if i < record_moves.size():
			_draw_arrow_in_box(box, record_moves[i], Color(0.35,0.8,1.0))

	# 下行：幻影已回放的步
	var y2: float = TIMELINE_TOP_Y + TIMELINE_BOX_H + 16.0
	for i in range(min(phantom_play_idx, cur.record_n)):
		var box2: Rect2 = Rect2(Vector2(x0 + float(i) * (TIMELINE_BOX_W + TIMELINE_GAP), y2), Vector2(TIMELINE_BOX_W, TIMELINE_BOX_H))
		draw_rect(box2, Color(0.18,0.2,0.25,0.9))
		_draw_arrow_in_box(box2, record_moves[i], Color(1.0,0.5,0.55))

	var title: String = ""
	draw_string(font, Vector2(x0, TIMELINE_TOP_Y - 10.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(1,1,1,0.85))

func _draw_arrow_in_box(box: Rect2, dir: int, col: Color) -> void:
	var cx: float = box.position.x + box.size.x * 0.5
	var cy: float = box.position.y + box.size.y * 0.5
	var arm: float = min(box.size.x, box.size.y) * 0.36

	if dir == 0:
		draw_circle(Vector2(cx, cy), 6.0, col)
		return
	elif abs(dir) == 1:
		var dx: float = (1.0 if dir > 0 else -1.0)
		var head: Vector2 = Vector2(cx + arm * dx, cy)
		var tail: Vector2 = Vector2(cx - arm * dx, cy)
		draw_line(tail, head, col, 3.0)
		var n: Vector2 = (head - tail).normalized()
		var left_v: Vector2 = n.rotated(-PI/2.0) * (arm * 0.45)
		var right_v: Vector2 = n.rotated(PI/2.0) * (arm * 0.45)
		draw_line(head, head - n * (arm * 0.4) + left_v * 0.4, col, 3.0)
		draw_line(head, head - n * (arm * 0.4) + right_v * 0.4, col, 3.0)
	elif abs(dir) == 2:
		var dy: float = (-1.0 if dir > 0 else 1.0)
		var head_v: Vector2 = Vector2(cx, cy + arm * dy)
		var tail_v: Vector2 = Vector2(cx, cy - arm * dy)
		draw_line(tail_v, head_v, col, 3.0)
		var n2: Vector2 = (head_v - tail_v).normalized()
		var left_v2: Vector2 = n2.rotated(PI/2.0) * (arm * 0.45)
		var right_v2: Vector2 = n2.rotated(-PI/2.0) * (arm * 0.45)
		draw_line(head_v, head_v - n2 * (arm * 0.4) + left_v2 * 0.4, col, 3.0)

# ========= 通用工具 =========
func ease_out_quad(t: float) -> float:
	# 
	return 1.0 - (1.0 - t) * (1.0 - t)

func ease_in_quad(t: float) -> float:
	return t * t

func _signi(v: int) -> int:
	return -1 if v < 0 else (1 if v > 0 else 0)

func _dec_spawn_counter() -> void:
	if steps_until_enemy > 0:
		steps_until_enemy -= 1
		_logf("Countdown to phantom: {0}", [str(steps_until_enemy)])

# ========= 特殊情况debug函数 =========
func _after_player_moved_from_bridge_drop(prev_player_before: Vector2i) -> void:
	# 解决若玩家即将从桥上掉下去，幻影不会跟随玩家移动的问题
	if phantom_exists and phantom_play_idx < cur.record_n and (total_player_steps > cur.record_n):
		_phantom_replay_step(prev_player_before)
	_update_button_state()
	_bridge_persistence_check()
	if player_cell == cur.altar:
		_win(); return
	if phantom_exists and player_cell == phantom_cell:
		_fail(FailCause.CONTACT, "你被过去的自己消灭。"); return
	queue_redraw()
	_log("_after_player_moved_from_bridge_drop done.")

func _after_player_started_abyss(prev_player_before: Vector2i) -> void:
	# 兜底函数，把摔死的特殊动作补全为一个完整的回合，让幻影回放、按钮/桥逻辑、UI 同步都不会漏掉。
	total_player_steps += 1
	if phantom_exists and phantom_play_idx < cur.record_n and (total_player_steps > cur.record_n) and not just_spawned_this_step:
		_phantom_replay_step(prev_player_before)
	just_spawned_this_step = false
	_update_button_state()
	_bridge_persistence_check()
	queue_redraw()
	_log("_after_player_started_abyss completed a full turn.")
