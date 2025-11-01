# state_machine.gd
# =====================================================
# 【状态机 StateMachine】
# 这是整个 FSM（有限状态机）的核心控制器。
# 它不会处理“具体逻辑”，而是负责：
#   1. 保存当前状态（current_state）
#   2. 调用状态的 enter / exit / process_* 接口
#   3. 根据状态返回值切换状态
# =====================================================

extends Node

# -----------------------------------------------------
# === 可在编辑器中配置的变量 ===
# -----------------------------------------------------

@export
var starting_state: State   # 初始状态（例如 IdleState，设置成export代表可以暴露给其它类和检查器）

var current_state: State            # 当前状态对象（运行中的状态）

signal state_changed(previous: State, current: State)

# -----------------------------------------------------
# === 初始化（相当于 setup / start） ===
# -----------------------------------------------------
# 由 Player 调用，将自身（父节点）传入状态机。
# 每个状态都要能访问到 Player，所以这里要统一传递引用。
# -----------------------------------------------------
func init(parent: Player) -> void:
	# 遍历 StateMachine 的所有子节点（通常是各个状态节点）
	for child in get_children():
		child.parent = parent   # 将父节点（也就是parent）Player引用赋给每个子状态
								# 这样状态中就能访问： parent.velocity, parent.animations 等
	change_state(starting_state)

# 如果这个状态定义了 action_emitted 信号，就把它连接到状态机自己的回调 _on_state_action
# 便于集中处理所有动作事件。


# -----------------------------------------------------
# === 状态切换函数 ===
# -----------------------------------------------------
# 负责安全地退出旧状态 → 进入新状态。
# 可由状态返回触发（例如 process_input() 中返回 MoveState）。
# -----------------------------------------------------
func change_state(new_state: State) -> void:
	if new_state == null or new_state == current_state:
		return

	var previous := current_state

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()

	emit_signal("state_changed", previous, current_state)


# -----------------------------------------------------
# === 物理逻辑处理（每物理帧调用） ===
# -----------------------------------------------------
# 通常由 Player._physics_process(delta) 调用。
# 如果状态返回了一个新的状态对象，则立即切换过去。
# -----------------------------------------------------
func process_physics(delta: float) -> void:
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)


# -----------------------------------------------------
# === 输入逻辑处理 ===
# -----------------------------------------------------
# 在 Player._unhandled_input(event) 中调用。
# 由当前状态响应输入（例如按下跳跃键时返回 JumpState）。
# -----------------------------------------------------
func process_input(event: InputEvent) -> void:
	var new_state = current_state.process_input(event)
	if new_state:
		change_state(new_state)


# -----------------------------------------------------
# === 每帧逻辑处理（非物理） ===
# -----------------------------------------------------
# 通常在 Player._process(delta) 调用。
# 用于动画、视觉更新或 UI 控制。
# -----------------------------------------------------
func process_frame(delta: float) -> void:
	var new_state = current_state.process_frame(delta)
	if new_state:
		change_state(new_state)
