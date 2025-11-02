extends Node
class_name Recorder_dev

# =====================================================
# 【Recorder 录制器】
# -----------------------------------------------------
# 作用：
#   - 监听状态机的 state_changed 信号
#   - 在玩家从 Idle -> 非 Idle 状态时开始录制
#   - 在玩家回到 Idle 状态时结束录制
#   - 将录制的关键帧（时间、状态、位置）保存到 _buffer
# -----------------------------------------------------
# 使用方式：
#   1. 在检查器中绑定 Player 和 StateMachine 节点路径
#   2. 在 _ready() 时自动连接状态机信号
#   3. 可通过 max_steps 控制最多录制多少步
# =====================================================

@export var player: Player						# 引用玩家节点，用于记录位置
@export var state_machine_path: NodePath		# 状态机路径
@export var max_steps := 5						# 录制最大步数（0 表示无限制）

var _state_machine: Node						# 状态机引用
var _buffer: Array = []							# 当前录制缓存
var _is_recording := true						# 当前是否正在录制


func _ready() -> void:
	# 初始化时获取状态机节点并连接 state_changed 信号
	_state_machine = get_node(state_machine_path)
	if not _state_machine:
		push_error("❌ Recorder: 找不到 StateMachine 节点！路径无效: %s" % state_machine_path)
		return
	
	_state_machine.state_changed.connect(_on_state_changed)
	print_debug("[Recorder] ✅ 初始化完成，已连接状态机信号。")


# =====================================================
# 状态切换时回调
# -----------------------------------------------------
# - 当玩家从 Idle 切换到其他状态：开始录制
# - 当玩家从任意状态切换回 Idle：结束录制
# =====================================================
func _on_state_changed(previous: State, current: State) -> void:
	if previous == null or current == null:
		print_debug("[Recorder] ⚠️ 状态切换事件无效，previous 或 current 为 null。")
		return

	print_debug("[Recorder] 🔄 状态切换：%s → %s" % [previous.name, current.name])

	if previous.name == "Idle" and current.name != "Idle":
		print_debug("[Recorder] ▶ 检测到从 Idle 离开，开始录制。")
		_start_record(previous, current)
	elif current.name == "Idle" and _is_recording:
		print_debug("[Recorder] ⏹ 检测到回到 Idle，停止录制。")
		_stop_record()


# =====================================================
# 开始录制
# -----------------------------------------------------
# - 初始化缓冲区
# - 记录起始关键帧（含状态名与位置）
# =====================================================
func _start_record(previous: State, current: State) -> void:
	if _is_recording:
		print_debug("[Recorder] ⚠️ 已在录制中，忽略重复调用。")
		return
	
	if max_steps > 0 and _buffer.size() >= max_steps:
		print_debug("[Recorder] ⚠️ 达到最大录制步数 %d，无法继续录制。" % max_steps)
		return

	_is_recording = true
	_buffer.clear()

	var frame_data := {
		"time": Engine.get_physics_frames(),
		"from": previous.name,
		"to": current.name,
		"position": player.global_position
	}

	_buffer.append(frame_data)
	print_debug("[Recorder] 🟢 开始录制，初始帧: %s" % str(frame_data))


# =====================================================
# 停止录制
# -----------------------------------------------------
# - 将缓冲区内容输出
# - 可扩展为写入文件 / 发送信号触发幻影回放
# =====================================================
func _stop_record() -> void:
	_is_recording = false

	if _buffer.is_empty():
		print_debug("[Recorder] ⚠️ 没有录制数据可输出。")
		return

	print_debug("[Recorder] 🔴 录制结束，共记录 %d 帧。" % _buffer.size())
	print_debug("[Recorder] 📜 数据内容: %s" % str(_buffer))
	# TODO: 保存到历史数组 / 发 signal 给幻影回放
