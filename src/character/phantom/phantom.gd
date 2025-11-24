# phantom.gd - 幻影角色（回放玩家操作）
class_name Phantom
extends CharacterBody2D
signal  crush
var Player_enter_front:bool = false
var Player_enter_back:bool = false

# =====================================================
# === 信号定义 ===
# =====================================================

# =====================================================
# === 导出变量（在 Inspector 中配置） ===
# =====================================================
@export_node_path("Node") var timeline_controler_path: NodePath  # TimelineControler 节点路径
@export_node_path("Player") var player_path: NodePath            # Player 节点路径（用于复制移动参数）

# =====================================================
# === 节点引用 ===
# =====================================================
@onready var anim = $AnimatedSprite2D
@onready var animations = $AnimatedSprite2D
@onready var state_machine = $StateMachine
@onready var attack_area_front = $Area2D
@onready var attack_area_back = $Area2D2

# =====================================================
# === 移动参数（从 Player 复制） ===
# =====================================================
var target_move_distance: float = 200.0  # 单次移动目标距离（像素）
var jump_speed: float = -300.0           # 跳跃速度
var speed_affect: float = 0.5            # 速度系数（0-1，越大越快）

# =====================================================
# === 指令系统 ===
# =====================================================
var _current_command: String = ""      # 当前接收到的指令
var _command_consumed := true          # 指令是否已被消费
var _playback_node: Node = null        # Playback 节点引用

# =====================================================
# === 初始化 ===
# =====================================================
func _ready() -> void:
	# 🔥 初始状态：禁用并隐藏

	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	print("[Phantom] 初始状态：已禁用")
	
	# 初始化状态机
	state_machine.init(self)
	print("[Phantom] ✅ 状态机已初始化")
	
	# 从 Player 复制移动参数
	_copy_player_parameters()
	
	# 连接 Playback 节点
	_connect_to_playback()

## 从 Player 复制移动参数
func _copy_player_parameters() -> void:
	if player_path.is_empty():
		push_warning("[Phantom] ⚠️ player_path 未设置，使用默认参数")
		return
	
	var player = get_node_or_null(player_path)
	
	if player == null:
		push_error("[Phantom] ❌ 无法找到 Player 节点：", player_path)
		return
	
	# 复制移动参数
	if "target_move_distance" in player:
		target_move_distance = player.target_move_distance
	
	if "jump_speed" in player:
		jump_speed = player.jump_speed
	
	if "speed_affect" in player:
		speed_affect = player.speed_affect

## 连接到 Playback 节点
func _connect_to_playback() -> void:
	if timeline_controler_path.is_empty():
		push_error("[Phantom] ❌ timeline_controler_path 未设置！请在 Inspector 中配置")
		return
	
	var timeline_controler = get_node_or_null(timeline_controler_path)
	
	if timeline_controler == null:
		push_error("[Phantom] ❌ 无法找到 TimelineControler 节点：", timeline_controler_path)
		return
	
	# 获取 Playback 子节点
	_playback_node = timeline_controler.get_node_or_null("Playback")
	
	if _playback_node == null:
		push_error("[Phantom] ❌ TimelineControler 下没有 Playback 子节点")
		return
	
	# 连接信号
	if _playback_node.has_signal("playback_command"):
		_playback_node.playback_command.connect(_on_playback_command)
		print("[Phantom] ✅ 已连接到 Playback")
	
	if _playback_node.has_signal("playback_started"):
		_playback_node.playback_started.connect(_on_playback_started)
	
	if _playback_node.has_signal("playback_completed"):
		_playback_node.playback_completed.connect(_on_playback_completed)

# =====================================================
# === Playback 信号回调 ===
# =====================================================
## 回放开始 - 启用幻影（但不发送指令，等待玩家行动）
func _on_playback_started() -> void:
	print("[Phantom] 🎬 录制完成，启用幻影")
	print("[Phantom] 🔍 DEBUG: 当前位置 = %s" % position)
	print("[Phantom] 🔍 DEBUG: is_on_floor() = %s" % is_on_floor())
	
	if state_machine and state_machine.current_state:
		print("[Phantom] 🔍 DEBUG: 当前状态 = %s" % state_machine.current_state.name)
	
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	attack_area_back.monitoring = false
	attack_area_front.monitoring = false
	set_collision_mask_value(2, false)
	var player = get_node_or_null(player_path)
	while true:
		var args = await player.state_machine.state_changed
		var new_state = args[1]
		if new_state.name == "idle":
			break;
	attack_area_back.monitoring = true
	attack_area_front.monitoring = true
	set_collision_mask_value(2, true)			# 为了那点1%的情况居然写了这么一大坨（126~138），真的服了……
	# 重置状态
	_current_command = ""
	_command_consumed = true
	
## 接收 Playback 指令
func _on_playback_command(command: String) -> void:
	print("[Phantom] 📥 收到指令：", command)
	print("[Phantom] 🔍 当前状态 = %s" % state_machine.current_state.name)
	_current_command = command
	_command_consumed = false  # 标记为未消费

## 回放完成 - 保持显示（不禁用）
func _on_playback_completed() -> void:
	print("[Phantom] 🎉 回放完成")
	
	# 重置指令状态
	_current_command = ""
	_command_consumed = true

# =====================================================
# === 指令检测接口（供状态脚本调用） ===
# =====================================================
## 检查是否有指定指令（消费型）
func has_command(action: String) -> bool:
	if _command_consumed:
		return false
	
	if _current_command == action:
		_command_consumed = true  # 消费指令
		print("[Phantom] ✅ 消费指令：", action)
		return true
	
	return false

## 检查水平移动指令（left 或 right）
func has_horizontal_command() -> bool:
	return has_command("left") or has_command("right")

## 检查跳跃指令
func has_jump_command() -> bool:
	return has_command("up")

## 检查攻击指令
func has_attack_command() -> bool:
	return has_command("attack")

## 获取当前移动方向
func get_move_direction() -> int:
	if _current_command == "right":
		return 1
	elif _current_command == "left":
		return -1
	return 0

## 检查指令是否按下
func is_command_pressed(action: String) -> bool:
	return _current_command == action

# =====================================================
# === 兼容接口（与 Player 保持一致） ===
# =====================================================
## 检查是否可以跳跃
func is_legalto_up() -> bool:
	return is_on_floor()

# =====================================================
# === 物理处理（驱动状态机） ===
# =====================================================
func _physics_process(delta: float) -> void:
	if state_machine:
		state_machine.process_physics(delta)

func _process(delta: float) -> void:
	if state_machine:
		state_machine.process_frame(delta)

# =====================================================
# === 测试接口 ===
# =====================================================

#碰撞时怎么办
func _on_area_2d_front_body_entered(body: Node2D) -> void:
	if body is Player or body is Player_dev: 
		if anim.flip_h:
			anim.set_flip_h(false)
		Player_enter_front = true
		crush.emit()

	
func _on_area_2d_back_body_entered(body: Node2D) -> void:
	if body is Player or body is Player_dev: 
		if !anim.flip_h:
			anim.set_flip_h(true)
		Player_enter_back = true
		crush.emit()
		
