extends Node2D

# ========= 通用常量 =========
const CELL_SIZE: float = 96.0
const ORIGIN: Vector2 = Vector2(120, 360) # (0,0)绘制基准（越右x越大，y=0上层，y=-1下层）
const MOVE_DUR: float = 0.16              # 单步移动过渡时长
const FAIL_ANIM_DUR: float = 0.8
const WIN_ANIM_DUR: float = 0.8
# 掉落分段时长（先短水平，再稍长竖直）
const DROP_HORIZ_DUR: float = 0.10
const DROP_VERT_DUR: float = 0.18

# 时间轴UI
const TIMELINE_TOP_Y: float = 80.0
const TIMELINE_BOX_W: float = 40.0
const TIMELINE_BOX_H: float = 40.0
const TIMELINE_GAP:   float = 8.0

# ========= 关卡数据结构（内部类） =========
class LevelData:
	var cells := {}                # Set<Vector2i> 可站立格（用字典当Set）
	var ladders_x := {}            # Set<int> 在这些 x 上连接相邻 y 层
	var spawn: Vector2i
	var altar: Vector2i
	var button: Vector2i
	var bridge: Vector2i           # 隐形格（需按钮踩住才可站/通过）
	var record_n: int = 4          # 幻影生成步数
	var name: String = "Level"
	func has_cell(p: Vector2i) -> bool:
		return p in cells

# ========= 两个关卡配置 =========
var LEVELS: Array = []

func _make_levels() -> void:
	LEVELS.clear()

	# --- Level 1（横向7格）---
	var L1 := LevelData.new()
	L1.name = "Tutorial-1D"
	L1.record_n = 4
	for x in range(1, 8): L1.cells[Vector2i(x, 0)] = true
	L1.spawn = Vector2i(1, 0)
	L1.altar = Vector2i(7, 0)
	L1.button = Vector2i(3, 0)
	L1.bridge = Vector2i(6, 0)
	L1.ladders_x = {}   # 无梯子
	LEVELS.append(L1)

	# --- Level 2（二维与梯子）---
	var L2 := LevelData.new()
	L2.name = "Tutorial-2D"
	L2.record_n = 5
	# 上层 y=0: (0..5,0)
	for x in range(0, 6): L2.cells[Vector2i(x, 0)] = true
	# 下层 y=-1: (1..4, -1)
	for x in range(1, 5): L2.cells[Vector2i(x, -1)] = true
	L2.spawn = Vector2i(0, 0)
	L2.altar = Vector2i(5, 0)
	L2.button = Vector2i(4, -1)
	L2.bridge = Vector2i(4, 0)            # 未激活从水平进入会掉到(4,-1)
	L2.ladders_x = {1: true, 2: true}     # x=1、2处上下相连
	LEVELS.append(L2)

# ========= 运行时状态 =========
enum GameState { PLAYING, FAIL, WIN }
enum FailCause { FALL_PLAYER, FALL_PHANTOM, CONTACT }

var cur: LevelData
var level_index: int = 0

var player_cell: Vector2i
var phantom_cell: Vector2i = Vector2i(-999, -999)
var phantom_exists: bool = false
var is_button_pressed: bool = false

# 录制命令：-1/ +1 = 左右；-2/ +2 = 下/上；0 保留不用
var record_moves: Array[int] = []
var phantom_play_idx: int = 0
var total_player_steps: int = 0

var game_state: int = GameState.PLAYING
var fail_cause: int = FailCause.FALL_PLAYER
var win_state: bool = false
var anim_time: float = 0.0

# 幻影生成提示
var just_spawned_this_step: bool = false
var show_spawn_hint_timer: float = 0.0
const SPAWN_HINT_DUR: float = 1.2

# 移动过渡（渲染位置，玩家与幻影各自独立的计时器）
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

# 两段式掉落控制：玩家
var player_pending_drop: bool = false
var player_drop_to_px: Vector2
var player_fail_after_drop: bool = false
var player_fail_cause_after: int = FailCause.FALL_PLAYER
# 两段式掉落控制：幻影
var phantom_pending_drop: bool = false
var phantom_drop_to_px: Vector2
var phantom_fail_after_drop: bool = false
var phantom_fail_cause_after: int = FailCause.FALL_PHANTOM

# ========= 生命周期 =========
func _ready() -> void:
	_make_levels()
	_load_level(0)
	set_process(true)

func _load_level(idx: int) -> void:
	level_index = clamp(idx, 0, LEVELS.size() - 1)
	cur = LEVELS[level_index]
	reset_level()

func next_level() -> void:
	_load_level((level_index + 1) % LEVELS.size())

func reset_level() -> void:
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

	# 初始化渲染位置 & 独立计时器
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

	# 清空两段掉落挂起
	player_pending_drop = false
	player_fail_after_drop = false
	phantom_pending_drop = false
	phantom_fail_after_drop = false

	queue_redraw()

# ========= 输入 =========
func _unhandled_input(event: InputEvent) -> void:
	if game_state != GameState.PLAYING:
		if event.is_action_pressed("reset_level"):
			reset_level()
		if event.is_action_pressed("ui_right") and game_state == GameState.WIN:
			next_level()
		return

	if player_is_moving or phantom_is_moving:
		return # 过渡中不接新步

	var dir_h: int = 0
	var do_move: bool = false
	if event.is_action_pressed("ui_left"):
		dir_h = -1; do_move = true
	elif event.is_action_pressed("ui_right"):
		dir_h = +1; do_move = true
	elif event.is_action_pressed("ui_up"):
		_try_vertical(+1)
	elif event.is_action_pressed("ui_down"):
		_try_vertical(-1)

	if do_move:
		_try_step(dir_h)

	if event.is_action_pressed("reset_level"):
		reset_level()

# ========= 规则推进 =========
func _try_step(dir_x: int) -> void:
	if game_state != GameState.PLAYING: return

	var prev_player: Vector2i = player_cell
	var prev_phantom: Vector2i = phantom_cell

	var next_player: Vector2i = player_cell + Vector2i(dir_x, 0)

	# 目标不存在 → 掉落或坠落（两段式：先水平到目标x，再竖直）
	if not cur.has_cell(next_player):
		if next_player == cur.bridge and not _bridge_active_for_player_entry(next_player):
			var below: Vector2i = next_player + Vector2i(0, -1)
			if cur.has_cell(below):
				# 先水平到桥格，再垂直掉到下层
				_start_player_move_then_drop(prev_player, next_player, _cell_to_px(below), false, FailCause.FALL_PLAYER)
				player_cell = below
				total_player_steps += 1
				_after_player_moved_from_bridge_drop(prev_player)
				return
			else:
				# 真·深渊：先到目标x，再坠入屏外；失败延迟到坠落结束
				var abyss_px := _cell_to_px(next_player) + Vector2(0, 260)
				_start_player_move_then_drop(prev_player, next_player, abyss_px, true, FailCause.FALL_PLAYER)
				return
		else:
			# 非桥直接深渊：两段式
			var abyss_px2 := _cell_to_px(next_player) + Vector2(0, 260)
			_start_player_move_then_drop(prev_player, next_player, abyss_px2, true, FailCause.FALL_PLAYER)
			return

	# 踏入桥时的再次校验（仍以本回合结束后的激活状态）
	if next_player == cur.bridge and not _bridge_active_for_player_entry(next_player):
		var below2: Vector2i = next_player + Vector2i(0, -1)
		if cur.has_cell(below2):
			_start_player_move_then_drop(prev_player, next_player, _cell_to_px(below2), false, FailCause.FALL_PLAYER)
			player_cell = below2
			total_player_steps += 1
			_after_player_moved_from_bridge_drop(prev_player)
			return
		else:
			var abyss_px3 := _cell_to_px(next_player) + Vector2(0, 260)
			_start_player_move_then_drop(prev_player, next_player, abyss_px3, true, FailCause.FALL_PLAYER)
			return

	# --- 正常水平移动 ---
	_start_player_move(prev_player, next_player)
	player_cell = next_player
	total_player_steps += 1

	# 录制（水平：±1）
	if record_moves.size() < cur.record_n:
		record_moves.append(_signi(dir_x))
		if record_moves.size() == cur.record_n and not phantom_exists:
			# 幻影出生：瞬间到出生点（无漂移）
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

	# --- 幻影行动（当玩家步数 > record_n 且非出生当帧） ---
	if phantom_exists and phantom_play_idx < cur.record_n and (total_player_steps > cur.record_n) and not just_spawned_this_step:
		_phantom_replay_step(prev_player)

	just_spawned_this_step = false

	# 更新按钮状态 & 持续性掉落
	_update_button_state()
	_bridge_persistence_check()

	# ✅ 先判胜利优先
	if player_cell == cur.altar:
		_win(); return

	# 再判碰撞（同格或交错）
	if phantom_exists:
		if player_cell == phantom_cell:
			_fail(FailCause.CONTACT, "你被过去的自己消灭。"); return
		if (player_cell == prev_phantom) and (phantom_cell == prev_player) and prev_phantom != Vector2i(-999,-999):
			_fail(FailCause.CONTACT, "你被过去的自己消灭。"); return

	queue_redraw()

func _try_vertical(dy: int) -> void:
	# dy: +1=上（y: -1->0），-1=下（y: 0->-1）
	if game_state != GameState.PLAYING: return
	if player_is_moving or phantom_is_moving: return
	if not (player_cell.x in cur.ladders_x): return

	var target: Vector2i = player_cell + Vector2i(0, dy)
	if not cur.has_cell(target): return

	var prev: Vector2i = player_cell
	_start_player_move(prev, target)
	player_cell = target
	total_player_steps += 1

	# 纵向也计入录制：+2=上，-2=下
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

	# 幻影行动
	if phantom_exists and phantom_play_idx < cur.record_n and (total_player_steps > cur.record_n) and not just_spawned_this_step:
		_phantom_replay_step(prev)

	just_spawned_this_step = false
	_update_button_state()
	_bridge_persistence_check()

	# ✅ 先胜利，再碰撞
	if player_cell == cur.altar:
		_win(); return
	if phantom_exists and player_cell == phantom_cell:
		_fail(FailCause.CONTACT, "你被过去的自己消灭。"); return

	queue_redraw()

# 幻影执行一条录制命令（±1=左右；±2=上下）
func _phantom_replay_step(_prev_player_before: Vector2i) -> void:
	var cmd: int = record_moves[phantom_play_idx]
	var ph_next: Vector2i = phantom_cell

	if abs(cmd) == 1:
		# 水平
		ph_next += Vector2i(cmd, 0)

		# 目标不存在 → 掉落或坠落（两段式）
		if not cur.has_cell(ph_next):
			if ph_next == cur.bridge:
				# 幻影踏桥的激活由“另一方=玩家”的落位决定
				var active_after_for_ph: bool = (player_cell == cur.button) or (ph_next == cur.button)
				if not active_after_for_ph:
					var p_below: Vector2i = ph_next + Vector2i(0, -1)
					if cur.has_cell(p_below):
						# 先水平到桥格，再垂直掉到下层
						_start_phantom_move_then_drop(phantom_cell, ph_next, _cell_to_px(p_below), false, FailCause.FALL_PHANTOM)
						phantom_cell = p_below
						phantom_play_idx += 1
						return
					else:
						# 深渊：先到目标x，再坠入屏外；失败延迟到坠落结束
						var abyss_px := _cell_to_px(ph_next) + Vector2(0, 260)
						_start_phantom_move_then_drop(phantom_cell, ph_next, abyss_px, true, FailCause.FALL_PHANTOM)
						return
			else:
				# 非桥，直接深渊：两段式
				var abyss_px2 := _cell_to_px(ph_next) + Vector2(0, 260)
				_start_phantom_move_then_drop(phantom_cell, ph_next, abyss_px2, true, FailCause.FALL_PHANTOM)
				return

		# 踏桥再次校验（仍以玩家已落位为准）
		if ph_next == cur.bridge:
			var active_after_for_ph2: bool = (player_cell == cur.button) or (ph_next == cur.button)
			if not active_after_for_ph2:
				var p_below2: Vector2i = ph_next + Vector2i(0, -1)
				if cur.has_cell(p_below2):
					_start_phantom_move_then_drop(phantom_cell, ph_next, _cell_to_px(p_below2), false, FailCause.FALL_PHANTOM)
					phantom_cell = p_below2
					phantom_play_idx += 1
					return
				else:
					var abyss_px3 := _cell_to_px(ph_next) + Vector2(0, 260)
					_start_phantom_move_then_drop(phantom_cell, ph_next, abyss_px3, true, FailCause.FALL_PHANTOM)
					return

		_start_phantom_move(phantom_cell, ph_next)
		phantom_cell = ph_next

	elif abs(cmd) == 2:
		# 纵向：仅在有梯子的 x 允许
		if not (phantom_cell.x in cur.ladders_x):
			# 无梯子→视为尝试离开平台，深渊（竖直到屏外）
			var fall_px := _cell_to_px(phantom_cell) + Vector2(0, 260)
			_start_phantom_move_then_drop(phantom_cell, phantom_cell, fall_px, true, FailCause.FALL_PHANTOM)
			return
		var dy: int = (1 if cmd > 0 else -1)
		ph_next += Vector2i(0, dy)

		if not cur.has_cell(ph_next):
			# 纵向目标不存在：深渊（基本只有竖直段）
			var abyss_px4 := _cell_to_px(ph_next) + Vector2(0, 260)
			_start_phantom_move_then_drop(phantom_cell, ph_next, abyss_px4, true, FailCause.FALL_PHANTOM)
			return

		_start_phantom_move(phantom_cell, ph_next)
		phantom_cell = ph_next
	else:
		# 0：原地（当前未使用）
		pass

	phantom_play_idx += 1

	# 回放完毕：等这一步动画播完，再冻结
	if phantom_play_idx >= cur.record_n:
		phantom_freeze_after_move = true

# =========== “本回合结束后桥是否激活（玩家尝试踏入时）” =============
func _bridge_active_for_player_entry(player_next: Vector2i) -> bool:
	var phantom_on_button_after := false

	# 幻影是否会在“这一回合”移动？（玩家这步计入 total_player_steps + 1）
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
			# 纵向动作需要有梯子且目标存在
			if (phantom_cell.x in cur.ladders_x):
				var dy := (1 if cmd > 0 else -1)
				var cand2 := cand + Vector2i(0, dy)
				if cur.has_cell(cand2):
					cand = cand2
		phantom_on_button_after = (cand == cur.button)
	else:
		phantom_on_button_after = (phantom_exists and phantom_cell == cur.button)

	return (player_next == cur.button) or phantom_on_button_after

# 移动后是否有人踩按钮（旧函数；现在玩家踏桥不再使用）
func _bridge_active_after(_player_cur: Vector2i, player_next: Vector2i, phantom_cur: Vector2i) -> bool:
	return (player_next == cur.button) or (phantom_cur == cur.button)

func _update_button_state() -> void:
	is_button_pressed = (player_cell == cur.button) or (phantom_exists and phantom_cell == cur.button)

func _bridge_persistence_check() -> void:
	# 按钮松开时桥上的人/幻影掉落或坠落（纯垂直）
	if not is_button_pressed:
		if player_cell == cur.bridge:
			var pb: Vector2i = player_cell + Vector2i(0, -1)
			if cur.has_cell(pb):
				_start_player_move_direct(player_cell, pb)
				player_cell = pb
			else:
				_fail(FailCause.FALL_PLAYER, "你落入无尽的深渊。"); return
		if phantom_exists and phantom_cell == cur.bridge:
			var phb: Vector2i = phantom_cell + Vector2i(0, -1)
			if cur.has_cell(phb):
				_start_phantom_move_direct(phantom_cell, phb)
				phantom_cell = phb
			else:
				_fail(FailCause.FALL_PHANTOM, "过去的幻影落入无尽的深渊。"); return

# ========= 过渡动画 =========
func _start_player_move(from_c: Vector2i, to_c: Vector2i) -> void:
	player_from_px = _cell_to_px(from_c)
	player_to_px = _cell_to_px(to_c)
	player_move_t = 0.0
	player_move_dur = MOVE_DUR
	player_is_moving = true

func _start_player_move_direct(from_c: Vector2i, to_c: Vector2i) -> void:
	# 专用于“桥掉落”等需要从桥格直落到下格的情况（纯竖直）
	player_from_px = _cell_to_px(from_c)
	player_to_px = _cell_to_px(to_c)
	player_move_t = 0.0
	player_move_dur = DROP_VERT_DUR
	player_is_moving = true

func _start_phantom_move(from_c: Vector2i, to_c: Vector2i) -> void:
	phantom_from_px = _cell_to_px(from_c)
	phantom_to_px = _cell_to_px(to_c)
	phantom_move_t = 0.0
	phantom_move_dur = MOVE_DUR
	phantom_is_moving = true

func _start_phantom_move_direct(from_c: Vector2i, to_c: Vector2i) -> void:
	# 幻影纯垂直掉落
	phantom_from_px = _cell_to_px(from_c)
	phantom_to_px = _cell_to_px(to_c)
	phantom_move_t = 0.0
	phantom_move_dur = DROP_VERT_DUR
	phantom_is_moving = true

# 两段式：先水平 from->to，结束后再竖直掉到 drop_to_px；will_fail 表示二段结束即失败
func _start_player_move_then_drop(from_c: Vector2i, to_c: Vector2i, drop_to_px: Vector2, will_fail: bool, fail_cause: int) -> void:
	_start_player_move(from_c, to_c)
	player_move_dur = DROP_HORIZ_DUR
	player_pending_drop = true
	player_drop_to_px = drop_to_px
	player_fail_after_drop = will_fail
	player_fail_cause_after = fail_cause

func _start_phantom_move_then_drop(from_c: Vector2i, to_c: Vector2i, drop_to_px: Vector2, will_fail: bool, fail_cause: int) -> void:
	_start_phantom_move(from_c, to_c)
	phantom_move_dur = DROP_HORIZ_DUR
	phantom_pending_drop = true
	phantom_drop_to_px = drop_to_px
	phantom_fail_after_drop = will_fail
	phantom_fail_cause_after = fail_cause

func _process(delta: float) -> void:
	# 玩家过渡
	if player_is_moving:
		player_move_t = min(1.0, player_move_t + delta / player_move_dur)
		var ep: float = ease_out_quad(player_move_t)
		player_draw_pos = player_from_px.lerp(player_to_px, ep)
		if player_move_t >= 1.0:
			player_is_moving = false
			if player_pending_drop:
				# 水平段结束，衔接竖直段（不瞬移回 cell）
				player_draw_pos = player_to_px
				player_pending_drop = false
				player_from_px = player_to_px
				player_to_px = player_drop_to_px
				player_move_t = 0.0
				player_move_dur = DROP_VERT_DUR
				player_is_moving = true
			elif player_fail_after_drop:
				player_fail_after_drop = false
				_fail(player_fail_cause_after, "你落入无尽的深渊。")
			else:
				player_draw_pos = _cell_to_px(player_cell)
		queue_redraw()

	# 幻影过渡
	if phantom_is_moving:
		phantom_move_t = min(1.0, phantom_move_t + delta / phantom_move_dur)
		var eh: float = ease_out_quad(phantom_move_t)
		phantom_draw_pos = phantom_from_px.lerp(phantom_to_px, eh)
		if phantom_move_t >= 1.0:
			phantom_is_moving = false
			# 延迟冻结：最后一步动画播完后静止
			if phantom_freeze_after_move:
				phantom_freeze_after_move = false
			if phantom_pending_drop:
				phantom_draw_pos = phantom_to_px
				phantom_pending_drop = false
				phantom_from_px = phantom_to_px
				phantom_to_px = phantom_drop_to_px
				phantom_move_t = 0.0
				phantom_move_dur = DROP_VERT_DUR
				phantom_is_moving = true
			elif phantom_fail_after_drop:
				phantom_fail_after_drop = false
				_fail(phantom_fail_cause_after, "过去的幻影落入无尽的深渊。")
			else:
				phantom_draw_pos = _cell_to_px(phantom_cell)
		queue_redraw()

	# 失败/胜利动画
	if game_state != GameState.PLAYING:
		anim_time += delta
		queue_redraw()

	# 出生提示计时
	if show_spawn_hint_timer > 0.0:
		show_spawn_hint_timer = max(0.0, show_spawn_hint_timer - delta)
		queue_redraw()

func _fail(cause: int, _msg: String) -> void:
	game_state = GameState.FAIL
	fail_cause = cause
	anim_time = 0.0
	queue_redraw()

func _win() -> void:
	game_state = GameState.WIN
	anim_time = 0.0
	# 保险：清掉任何等待的“二段掉落失败”
	player_fail_after_drop = false
	phantom_fail_after_drop = false
	queue_redraw()

# ========= 绘制 =========
func _draw() -> void:
	# 背景
	draw_rect(Rect2(Vector2(0,0), get_viewport_rect().size), Color(0.08,0.09,0.12))

	# 画格子
	for p in cur.cells.keys():
		var px: Vector2 = _cell_to_px_top(p)
		if p == cur.bridge and not is_button_pressed:
			draw_rect(Rect2(px, Vector2(CELL_SIZE - 8.0, 14.0)), Color(0,0,0))
		else:
			draw_rect(Rect2(px, Vector2(CELL_SIZE - 8.0, 14.0)), Color(0.25,0.28,0.34))

	# 按钮
	var btn_col: Color = (Color(0.2,0.8,0.3) if is_button_pressed else Color(0.15,0.45,0.2))
	var btn_top: Vector2 = _cell_to_px_top(cur.button) + Vector2(0, 2)
	draw_rect(Rect2(btn_top, Vector2(CELL_SIZE - 8.0, 6.0)), btn_col)

	# 梯子（竖线）
	for k in cur.ladders_x.keys():
		var top_px: Vector2 = _cell_to_px(Vector2i(k, 0))
		var bot_px: Vector2 = _cell_to_px(Vector2i(k, -1))
		draw_line(top_px + Vector2(0, 30), bot_px + Vector2(0, 30), Color(0.8,0.7,0.4), 4.0)
		draw_line(top_px + Vector2(12, 30), bot_px + Vector2(12, 30), Color(0.8,0.7,0.4), 4.0)

	# 出生点与祭坛
	_draw_spawn_marker(_cell_to_px(cur.spawn))
	_draw_altar_marker(_cell_to_px(cur.altar))

	# 角色与失败/胜利动画
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

	# 提示 & 时间轴
	var tip: String = " ←/→ 左右 | ↑/↓ 上下(梯子) | R 重开"
	if game_state == GameState.PLAYING and show_spawn_hint_timer > 0.0:
		tip += "\n【提示】过去的幻影已出生，将从下一步开始行动。"
	_draw_text_top_left(tip)
	_draw_timeline()

# ========= 绘制工具 =========
func _cell_to_px(c: Vector2i) -> Vector2:
	# 角色中心位置
	return ORIGIN + Vector2(float(c.x) * CELL_SIZE + (CELL_SIZE - 8.0) / 2.0, -28.0 + float(-c.y) * 90.0)

func _cell_to_px_top(c: Vector2i) -> Vector2:
	# 平台条顶边位置
	return ORIGIN + Vector2(float(c.x) * CELL_SIZE, float(-c.y) * 90.0)

func _draw_text_top_left(text: String) -> void:
	var font: Font = ThemeDB.fallback_font as Font
	var size: int = ThemeDB.fallback_font_size
	draw_string(font, Vector2(24, 36), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(1,1,1,0.9))

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
	# 蓝旗：杆+三角旗
	draw_line(p + Vector2(-18,-8), p + Vector2(-18,-44), Color(0.3,0.6,1.0), 3.0)
	var tri := PackedVector2Array([p + Vector2(-18,-44), p + Vector2(4,-36), p + Vector2(-18,-28)])
	draw_colored_polygon(tri, Color(0.3,0.6,1.0))

func _draw_altar_marker(p: Vector2) -> void:
	# 金柱：底座+柱体+光环
	draw_rect(Rect2(p + Vector2(-10,-30), Vector2(20,30)), Color(0.95,0.9,0.3), true)
	draw_rect(Rect2(p + Vector2(-14,0), Vector2(28,6)), Color(0.8,0.75,0.25), true)
	draw_circle(p + Vector2(0,-38), 10.0, Color(1.0,0.95,0.4,0.5))

# ========= 时间轴 =========
func _draw_timeline() -> void:
	var font: Font = ThemeDB.fallback_font as Font
	var size: int = ThemeDB.fallback_font_size
	var viewport: Vector2 = get_viewport_rect().size

	var total_w: float = float(cur.record_n) * TIMELINE_BOX_W + float(cur.record_n - 1) * TIMELINE_GAP
	var x0: float = (viewport.x - total_w) / 2.0

	# 上：录制箭头
	for i in range(cur.record_n):
		var box: Rect2 = Rect2(Vector2(x0 + float(i) * (TIMELINE_BOX_W + TIMELINE_GAP), TIMELINE_TOP_Y), Vector2(TIMELINE_BOX_W, TIMELINE_BOX_H))
		draw_rect(box, Color(0.18,0.2,0.25,0.9))
		if i < record_moves.size():
			_draw_arrow_in_box(box, record_moves[i], Color(0.35,0.8,1.0))

	# 下：回放箭头（0..phantom_play_idx）
	var y2: float = TIMELINE_TOP_Y + TIMELINE_BOX_H + 16.0
	for i in range(min(phantom_play_idx, cur.record_n)):
		var box2: Rect2 = Rect2(Vector2(x0 + float(i) * (TIMELINE_BOX_W + TIMELINE_GAP), y2), Vector2(TIMELINE_BOX_W, TIMELINE_BOX_H))
		draw_rect(box2, Color(0.18,0.2,0.25,0.9))
		_draw_arrow_in_box(box2, record_moves[i], Color(1.0,0.5,0.55))

	var title: String = "时间轴"
	draw_string(font, Vector2(x0, TIMELINE_TOP_Y - 10.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(1,1,1,0.85))

func _draw_arrow_in_box(box: Rect2, dir: int, col: Color) -> void:
	# dir: -1/ +1 = 左/右；-2/ +2 = 下/上；0=原地
	var cx: float = box.position.x + box.size.x * 0.5
	var cy: float = box.position.y + box.size.y * 0.5
	var arm: float = min(box.size.x, box.size.y) * 0.36

	if dir == 0:
		draw_circle(Vector2(cx, cy), 6.0, col)
		return
	elif abs(dir) == 1:
		# 水平箭头
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
		# 垂直箭头（注意屏幕Y向下：+2=上箭头）
		var dy: float = (-1.0 if dir > 0 else 1.0)
		var head_v: Vector2 = Vector2(cx, cy + arm * dy)
		var tail_v: Vector2 = Vector2(cx, cy - arm * dy)
		draw_line(tail_v, head_v, col, 3.0)
		var n2: Vector2 = (head_v - tail_v).normalized()
		var left_v2: Vector2 = n2.rotated(PI/2.0) * (arm * 0.45)
		var right_v2: Vector2 = n2.rotated(-PI/2.0) * (arm * 0.45)
		draw_line(head_v, head_v - n2 * (arm * 0.4) + left_v2 * 0.4, col, 3.0)
		draw_line(head_v, head_v - n2 * (arm * 0.4) + right_v2 * 0.4, col, 3.0)

# ========= 工具 =========
func ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)
func ease_in_quad(t: float) -> float:
	return t * t
func _signi(v: int) -> int:
	return -1 if v < 0 else (1 if v > 0 else 0)

# ========= 掉桥后的公共收尾 =========
func _after_player_moved_from_bridge_drop(prev_player_before: Vector2i) -> void:
	# 幻影可能需要跟进（若已生成且步数允许）
	if phantom_exists and phantom_play_idx < cur.record_n and (total_player_steps > cur.record_n):
		_phantom_replay_step(prev_player_before)

	# 更新按钮与持续性
	_update_button_state()
	_bridge_persistence_check()

	# ✅ 先胜利，再碰撞
	if player_cell == cur.altar:
		_win(); return
	if phantom_exists and player_cell == phantom_cell:
		_fail(FailCause.CONTACT, "你被过去的自己消灭。"); return

	queue_redraw()
