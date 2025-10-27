# move.gd
extends State

# =====================================================
# === 暴露给设计师的参数（Inspector 可见） ===
# =====================================================

# 引用其他状态
@export var idle_state: State
@export var fall_state: State
@export var up_state: State

# =====================================================
# === 内部计算变量（不暴露，仅用于 Debug） ===
# =====================================================
var _calculated_initial_velocity: float = 0.0    # 计算出的初速度
var _calculated_acceleration: float = 0.0        # 计算出的加速度（用于减速）

# =====================================================
# === 运行时状态变量 ===
# =====================================================
var start_position: float = 0.0    # 开始移动时的 x 坐标
var move_direction: int = 0        # 移动方向（1=右，-1=左）
var has_reached_target: bool = false  # 是否已到达目标距离


# =====================================================
# === 进入状态时的初始化 ===
# =====================================================
func enter() -> void:
	super.enter()  # 播放移动动画
	
	# 重置状态
	start_position = parent.position.x
	has_reached_target = false
	
	# 确定移动方向
	if Input.is_action_pressed('goat_right'):
		move_direction = 1
		parent.animations.flip_h = false
	elif Input.is_action_pressed('goat_left'):
		move_direction = -1
		parent.animations.flip_h = true
	else:
		# 兜底：根据当前速度方向判断
		move_direction = 1 if parent.velocity.x >= 0 else -1
	
	# === 核心：根据 target_move_distance 和 speed_affect 计算物理参数 ===
	_calculate_movement_physics()
	
	# 设置初速度
	parent.velocity.x = _calculated_initial_velocity * move_direction


# =====================================================
# === 核心算法：根据目标距离和速度系数计算物理参数 ===
# =====================================================
func _calculate_movement_physics() -> void:
	# === 设计思路 ===
	# 1. speed_affect 控制"移动时长"
	#    - 值越大，移动时间越短（速度越快）
	#    - 值越小，移动时间越长（速度越慢）
	# 2. 使用匀减速运动公式反推初速度和加速度
	
	# 基准移动时长（秒）
	# speed_affect=0.5 时约 0.4 秒，可根据手感调整这个系数
	var base_duration: float = 0.8  # 基准时长（秒）
	var move_duration: float = base_duration * (1.0 - parent.speed_affect * 0.7)  # 0.24 ~ 0.8 秒
	
	# === 匀减速直线运动公式 ===
	# 位移 s = v0 * t - 0.5 * a * t²
	# 终速度 v = v0 - a * t = 0（停止）
	# 解得：
	#   a = v0 / t
	#   s = v0 * t - 0.5 * (v0/t) * t² = 0.5 * v0 * t
	#   => v0 = 2 * s / t
	
	_calculated_initial_velocity = (2.0 * parent.target_move_distance) / move_duration
	_calculated_acceleration = _calculated_initial_velocity / move_duration
	
	# Debug 输出（可在开发时查看）
	if OS.is_debug_build():
		print("[MoveState] 目标距离=%d, 速度系数=%.1f -> 初速度=%.1f, 加速度=%.1f, 预计时长=%.2fs" % [
			parent.target_move_distance, 
			parent.speed_affect, 
			_calculated_initial_velocity, 
			_calculated_acceleration, 
			move_duration
		])


# =====================================================
# === 处理输入事件 ===
# =====================================================
func process_input(event: InputEvent) -> State:
	return null


# =====================================================
# === 每物理帧的逻辑 ===
# =====================================================
func process_physics(delta: float) -> State:
	# 应用重力
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
	
	# === 计算移动进度 ===
	var distance_moved = abs(parent.position.x - start_position)
	var remaining_distance = parent.target_move_distance - distance_moved
	
	# === 速度控制逻辑 ===
	if not has_reached_target:
		# 还没到达目标距离
		if remaining_distance <= 0:
			# 刚到达目标，标记并开始减速
			has_reached_target = true
		# 保持初速度（也可以在这里添加加速过程，看手感需求）
	
	# 无论是否到达，都应用减速（模拟摩擦力）
	parent.velocity.x = move_toward(parent.velocity.x, 0, _calculated_acceleration * delta)
	
	# 执行移动
	parent.move_and_slide()
	
	# === 状态切换判断 ===
	
	# 1. 速度接近零 -> 回到 idle
	if abs(parent.velocity.x) < 10:
		return idle_state
	
	# 2. 离开地面 -> 进入 fall
	if not parent.is_on_floor() and abs(parent.velocity.x) < 10:
		return fall_state
	
	return null


# =====================================================
# === 退出状态时的清理 ===
# =====================================================
func exit() -> void:
	# 确保速度清零（防止状态切换时残留速度）
	parent.velocity.x = 0
