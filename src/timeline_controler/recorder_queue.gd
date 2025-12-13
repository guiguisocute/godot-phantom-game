# recoder_queue.gd - 录制玩家从 Idle 状态跳出时的输入操作
extends Node
class_name Recorder

# =====================================================
# === 配置（由父节点 TimelineControler 设置） ===
# =====================================================
var state_machine_path: NodePath	# 由父节点传入
var max_steps := 5					# 由父节点传入

# =====================================================
# === 输入映射字典（用于将输入事件转为字符串） ===
# =====================================================
const INPUT_MAP := {
	"goat_up": "up",
	"goat_down": "down",
	"goat_left": "left",
	"goat_right": "right",
	"attack_test": "attack"
}

# =====================================================
# === 信号定义 ===
# =====================================================
signal recording_started()						# 开始录制
signal step_recorded(step_name: String)			# 记录了一步
signal recording_completed(steps: Array)		# 录制完成（返回完整步骤数组）
signal recording_cancelled()					# 录制被取消

# =====================================================
# === 内部变量 ===
# =====================================================
var _state_machine: Node				# 状态机引用
var _recorded_steps: Array[String] = []	# 已记录的步骤数组
var _is_recording := true				# 是否正在录制
var _pending_input: String = ""			# 待记录的输入（idle 检测）

# =====================================================
# === 初始化 ===
# =====================================================
## 由父节点调用，初始化状态机连接
func initialize() -> void:
	
	if state_machine_path == NodePath():
		push_error("[Recorder] state_machine_path 未设置！")
		return
	
	# 从父节点获取状态机（因为路径是从父节点计算的）
	var parent = get_parent()
	if not parent:
		push_error("[Recorder] 没有父节点！")
		return
	
	_state_machine = parent.get_node_or_null(state_machine_path)
	
	if not _state_machine:
		push_error("[Recorder] 找不到状态机节点：", state_machine_path)
		print("[Recorder] 尝试从父节点路径：", parent.get_path())
		return
	
	print("[Recorder] ✅ 找到状态机：", _state_machine.name)
	
	if _state_machine.has_signal("state_changed"):
		_state_machine.state_changed.connect(_on_state_changed)
		print("[Recorder] ✅ 已连接到状态机信号")
	else:
		push_error("[Recorder] ❌ 状态机没有 state_changed 信号！")
		print("[Recorder] 状态机的所有信号：")
		for sig in _state_machine.get_signal_list():
			print("  - ", sig.name)

# =====================================================
# === 每物理帧检测输入（仅在 idle 状态下） ===
# =====================================================
func _physics_process(_delta: float) -> void:
	if not _is_recording or not _state_machine:
		return
	
	# 只在 idle 状态下检测输入
	if _state_machine.current_state.name != "idle":
		return
	
	# 🔥 持续检测按键（而不是 just_pressed）
	for action in INPUT_MAP.keys():
		if Input.is_action_just_pressed(action):  # 改为 is_action_pressed
			_pending_input = INPUT_MAP[action]
			# 不打印，避免刷屏
			break
	
	# 如果没有按键，清空 pending
	if not Input.is_anything_pressed():
		_pending_input = ""

# =====================================================
# === 状态切换回调 ===
# =====================================================
func _on_state_changed(previous: State, current: State) -> void:
	if previous == null or current == null:
		return
	
	# 适配状态名
	var prev_name = previous.name
	var curr_name = current.name
	
	print("[Recorder] 状态切换：", prev_name, " → ", curr_name)
	
	# 从 idle 切换到其他状态 → 记录导致切换的输入
	if prev_name == "idle" and curr_name == "move":
		print("[Recorder] 从 idle 跳出")
		_record_step()
	# 切换回 idle → 检查是否达到步数限制
	elif curr_name == "idle" and _is_recording:
		print("[Recorder] 回到 idle，步数：%d/%d" % [_recorded_steps.size(), max_steps])
		if _recorded_steps.size() >= max_steps:
			_complete_recording()

# =====================================================
# === 开始录制 ===
# =====================================================
func start_recording() -> void:
	print("[Recorder] start_recording() 被调用")
	
	if _is_recording:
		push_warning("[Recorder] 已经在录制中，忽略重复调用")
		return
	
	if not _state_machine:
		push_error("[Recorder] 状态机未初始化，请先调用 initialize()")
		return
	
	_is_recording = true
	_recorded_steps.clear()
	_pending_input = ""
	recording_started.emit()
	print("[Recorder] ✅ 录制开始，最大步数：", max_steps)

# =====================================================
# === 停止录制 ===
# =====================================================
func stop_recording() -> void:
	if not _is_recording:
		return
	
	_is_recording = false
	_pending_input = ""
	
	# 🔥 断开状态机信号
	if _state_machine and _state_machine.has_signal("state_changed"):
		if _state_machine.state_changed.is_connected(_on_state_changed):
			_state_machine.state_changed.disconnect(_on_state_changed)
			print("[Recorder] 🔇 已断开状态机信号连接（取消录制）")
	
	recording_cancelled.emit()
	print("[Recorder] 录制已取消")

# =====================================================
# === 记录一步 ===
# =====================================================
## 记录一步
func _record_step() -> void:
	if not _is_recording:
		print("[Recorder] 未在录制中，跳过")
		return
	
	# *如果 _pending_input 为空，检测当前按下的键
	if _pending_input == "":
		print("[Recorder] _pending_input 为空,开始检测按键")
		for action in INPUT_MAP.keys():
			if Input.is_action_just_pressed(action):
				_pending_input = INPUT_MAP[action]
				print("[Recorder] 即时检测到：", _pending_input)
				break
	
	# 如果还是没有输入，跳过
	if _pending_input == "":
		push_warning("[Recorder] 没有检测到有效输入，跳过记录")
		return
	
	# 记录这一步
	_recorded_steps.append(_pending_input)
	step_recorded.emit(_pending_input)
	print("[Recorder] ✅ 记录第 %d 步：%s" % [_recorded_steps.size(), _pending_input])
	
	# 清空待记录输入
	_pending_input = ""
	
	# 检查是否达到步数限制
	if _recorded_steps.size() >= max_steps:
		_complete_recording()

# =====================================================
# === 完成录制 ===
# =====================================================
func _complete_recording() -> void:
	if not _is_recording:
		return
	
	_is_recording = false
	
	# 🔥 断开状态机信号，防止继续监听
	if _state_machine and _state_machine.has_signal("state_changed"):
		if _state_machine.state_changed.is_connected(_on_state_changed):
			_state_machine.state_changed.disconnect(_on_state_changed)
			print("[Recorder] 🔇 已断开状态机信号连接")
	
	recording_completed.emit(_recorded_steps.duplicate())
	
	print("[Recorder] 🎉 录制完成！")
	print("[Recorder] 步骤列表：", _recorded_steps)
	print("[Recorder] 总步数：", _recorded_steps.size())

# =====================================================
# === 获取录制结果 ===
# =====================================================
func get_recorded_steps() -> Array[String]:
	return _recorded_steps.duplicate()

func get_step_count() -> int:
	return _recorded_steps.size()

func is_recording() -> bool:
	return _is_recording

# =====================================================
# === 清空录制 ===
# =====================================================
func clear_recording() -> void:
	_recorded_steps.clear()
	_pending_input = ""
	_is_recording = false
	print("[Recorder] 录制数据已清空")
