# timeline_controler.gd - 时间轴控制器（父节点）
extends Node
class_name TimelineControler

# =====================================================
# === 暴露给检查器的配置 ===
# =====================================================
@export var player_path: NodePath	# 玩家节点路径（如 ../Player）
@export var max_steps := 5			# 最大录制步数

# =====================================================
# === 子节点引用 ===
# =====================================================
@onready var recorder: Node = $RecorderQueue
@onready var playback: Node = $Playback

# =====================================================
# === 信号转发（方便关卡监听） ===
# =====================================================
signal recording_started()
signal step_recorded(step_name: String)
signal recording_completed(steps: Array)
signal recording_cancelled()

# =====================================================
# === 初始化 ===
# =====================================================
func _ready() -> void:
	
	# 从 Player 路径获取 StateMachine
	var state_machine_path := _get_state_machine_path()
	
	if state_machine_path == NodePath():
		push_error("[TimelineControler] 无法获取 StateMachine 路径！")
		return
	
	# 等待一帧，确保所有节点都准备好
	await get_tree().process_frame
	
	
	# 传递配置
	recorder.state_machine_path = state_machine_path
	recorder.max_steps = max_steps
	
	# 调用recoder 的 initialize
	recorder.initialize()
	print("[TimelineControler] ✅ initialize() 调用完成")
	
	# 🆕 初始化 Playback
	if playback and playback.has_method("set_state_machine"):
		var state_machine = get_node_or_null(state_machine_path)
		if state_machine:
			playback.set_state_machine(state_machine)
			print("[TimelineControler] ✅ Playback 已绑定状态机")
	
	# 转发信号
	recorder.recording_started.connect(func(): recording_started.emit())
	recorder.step_recorded.connect(func(s): step_recorded.emit(s))
	recorder.recording_completed.connect(func(s): recording_completed.emit(s))
	recorder.recording_cancelled.connect(func(): recording_cancelled.emit())
	
	print("[TimelineControler] 🎉 初始化完成")
	print("  - 最大步数：", max_steps)

# =====================================================
# === 内部辅助函数 ===
# =====================================================
## 从玩家节点路径自动获取 StateMachine 子节点路径
func _get_state_machine_path() -> NodePath:
	
	if player_path == NodePath():
		push_warning("[TimelineControler] player_path 未设置！")
		return NodePath()
	
	var player = get_node_or_null(player_path)
	
	if not player:
		push_error("[TimelineControler] 找不到玩家节点：", player_path)
		return NodePath()
	
	
	var state_machine = player.get_node_or_null("StateMachine")
	
	if not state_machine:
		push_error("[TimelineControler] 玩家节点下找不到 StateMachine 子节点！")
		return NodePath()
	
	
	return get_path_to(state_machine)

# =====================================================
# === 公共接口 ===
# =====================================================
## 开始录制
func start_recording() -> void:
	print("[TimelineControler] start_recording() 被调用")
	if recorder:
		recorder.start_recording()

## 停止录制
func stop_recording() -> void:
	if recorder:
		recorder.stop_recording()

## 获取录制结果
func get_recorded_steps() -> Array[String]:
	if recorder:
		return recorder.get_recorded_steps()
	return []

## 清空录制
func clear_recording() -> void:
	if recorder:
		recorder.clear_recording()

## 获取当前已录制步数
func get_step_count() -> int:
	if recorder:
		return recorder.get_step_count()
	return 0

## 是否正在录制
func is_recording() -> bool:
	if recorder:
		return recorder.is_recording()
	return false

## 打印当前状态（调试用）
func print_status() -> void:
	print("=== TimelineControler 状态 ===")
	print("录制中：", is_recording())
	print("已录制步数：", get_step_count(), "/", max_steps)
	print("步骤列表：", get_recorded_steps())
