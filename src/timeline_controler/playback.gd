# playback.gd - 回放控制器
extends Node
class_name Playback

# =====================================================
# === 信号定义（幻影会监听这些信号） ===
# =====================================================
signal playback_command(command: String)  # 发送指令给幻影
signal playback_started()                 # 回放开始
signal playback_completed()               # 回放完成
signal playback_step(step_index: int, command: String)  # 当前步骤

# =====================================================
# === 内部变量 ===
# =====================================================
var _recorded_steps: Array[String] = []  # 录制的步骤数组
var _current_step_index := 0             # 当前回放到第几步
var _is_playing := false                 # 是否正在回放
var _state_machine: Node = null          # 玩家状态机引用

# =====================================================
# === 初始化 ===
# =====================================================
func _ready() -> void:
	# 连接录制完成信号（由 TimelineControler 转发）
	var parent = get_parent()
	if parent and parent.has_signal("recording_completed"):
		parent.recording_completed.connect(_on_recording_completed)
		print("[Playback] 已连接 recording_completed 信号")

## 设置玩家状态机引用（由 TimelineControler 调用）
func set_state_machine(state_machine: Node) -> void:
	_state_machine = state_machine
	
	# 🔥 只保存引用，不立即连接信号
	if _state_machine:
		print("[Playback] ✅ 已保存状态机引用")
		
		# DEBUG: 打印状态机所属的父节点
		if _state_machine.get_parent():
			print("[Playback] 🔍 DEBUG: 状态机父节点 = %s (类型: %s)" % [
				_state_machine.get_parent().name,
				_state_machine.get_parent().get_class()
			])
	else:
		push_error("[Playback] 状态机引用无效")

# =====================================================
# === 录制完成回调 ===
# =====================================================
func _on_recording_completed(steps: Array) -> void:
	## 录制完成，保存步骤数组并准备回放
	_recorded_steps = steps.duplicate()
	_current_step_index = 0
	_is_playing = true
	
	print("[Playback] 🎬 录制完成，准备回放")
	print("[Playback] 步骤数组：", _recorded_steps)
	print("[Playback] 总步数：", _recorded_steps.size())
	
	# 🔥 录制完成后才连接状态机信号
	if _state_machine and _state_machine.has_signal("state_changed"):
		_state_machine.state_changed.connect(_on_player_state_changed)
		print("[Playback] 🔊 已连接状态机信号，开始监听玩家行动")
	else:
		push_error("[Playback] 无法连接状态机信号")
	
	print("[Playback] ⏳ 等待玩家下一次行动...")
	
	playback_started.emit()

# =====================================================
# === 玩家状态切换回调 ===
# =====================================================
func _on_player_state_changed(previous: State, current: State) -> void:
	## 当玩家从 idle 跳出时，发送下一个指令给幻影
	if not _is_playing:
		print("[Playback] 🔍 DEBUG: 状态切换但未在回放中，跳过")
		return
	
	if previous == null or current == null:
		print("[Playback] 🔍 DEBUG: previous 或 current 为 null，跳过")
		return
	
	# 🔥 DEBUG: 显示是哪个对象的状态切换
	var owner_name = "未知"
	if _state_machine and _state_machine.get_parent():
		owner_name = _state_machine.get_parent().name
	
	var prev_name = previous.name
	var curr_name = current.name
	
	print("[Playback] 🔍 DEBUG: 【%s】状态切换 [%s] → [%s]" % [owner_name, prev_name, curr_name])
	print("[Playback] 🔍 DEBUG: _current_step_index = %d" % _current_step_index)
	
	# 🔥 只在玩家从 idle 切换到其他状态时发送指令
	if prev_name == "idle" and curr_name != "idle":
		print("[Playback] 🔍 DEBUG: 检测到从 idle 跳出，发送指令")
		_send_next_command()
	else:
		print("[Playback] 🔍 DEBUG: 不满足发送条件，跳过")

# =====================================================
# === 发送下一个指令 ===
# =====================================================
## 发送下一个指令给幻影
func _send_next_command() -> void:
	print("[Playback] 🔍 DEBUG: _send_next_command() 被调用")
	print("[Playback] 🔍 DEBUG: _current_step_index = %d, 总步数 = %d" % [_current_step_index, _recorded_steps.size()])
	
	if _current_step_index >= _recorded_steps.size():
		print("[Playback] 🔍 DEBUG: 已到达数组末尾，完成回放")
		_complete_playback()
		return
	
	var command = _recorded_steps[_current_step_index]
	
	print("[Playback] 📤 发送第 %d 步：%s" % [_current_step_index + 1, command])
	
	# 发送指令信号
	playback_command.emit(command)
	playback_step.emit(_current_step_index, command)
	
	# 步进
	_current_step_index += 1
	print("[Playback] 🔍 DEBUG: 步进后 _current_step_index = %d" % _current_step_index)
	
	# 检查是否完成
	if _current_step_index >= _recorded_steps.size():
		print("[Playback] 所有指令已发送，等待最后一步完成...")

# =====================================================
# === 完成回放 ===
# =====================================================
func _complete_playback() -> void:
	## 回放完成（不禁用幻影，保持 idle 状态）
	if not _is_playing:
		return
	
	_is_playing = false
	
	# 🔥 回放完成后断开状态机信号
	if _state_machine and _state_machine.has_signal("state_changed"):
		if _state_machine.state_changed.is_connected(_on_player_state_changed):
			_state_machine.state_changed.disconnect(_on_player_state_changed)
			print("[Playback] 🔇 已断开状态机信号")
	
	playback_completed.emit()
	
	print("[Playback] 🎉 回放完成！")
	print("[Playback] 总共执行了 %d 步" % _recorded_steps.size())
	print("[Playback] 幻影保持 idle 状态")

# =====================================================
# === 公共接口 ===
# =====================================================
## 手动开始回放（如果需要）
func start_playback(steps: Array[String]) -> void:
	_recorded_steps = steps.duplicate()
	_current_step_index = 0
	_is_playing = true
	
	print("[Playback] 手动启动回放")
	print("[Playback] 步骤数组：", _recorded_steps)
	
	playback_started.emit()

## 停止回放
func stop_playback() -> void:
	if not _is_playing:
		return
	
	_is_playing = false
	print("[Playback] 回放已停止")

## 重置回放
func reset_playback() -> void:
	_recorded_steps.clear()
	_current_step_index = 0
	_is_playing = false
	print("[Playback] 回放已重置")

## 获取当前进度
func get_progress() -> Dictionary:
	return {
		"current_step": _current_step_index,
		"total_steps": _recorded_steps.size(),
		"is_playing": _is_playing,
		"remaining_steps": _recorded_steps.size() - _current_step_index
	}

## 是否正在回放
func is_playing() -> bool:
	return _is_playing
