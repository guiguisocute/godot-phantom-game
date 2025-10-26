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

	# 进入初始状态（通常是Idle）
	change_state(starting_state)


# -----------------------------------------------------
# === 状态切换函数 ===
# -----------------------------------------------------
# 负责安全地退出旧状态 → 进入新状态。
# 可由状态返回触发（例如 process_input() 中返回 MoveState）。
# -----------------------------------------------------
func change_state(new_state: State) -> void:
	if current_state:
		current_state.exit()     # 调用当前状态的退出逻辑（如停止动画、清变量）

	current_state = new_state
	current_state.enter()         # 调用新状态的进入逻辑（如播放动画）


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


# -----------------------------------------------------
# 【状态机调用关系示例】
# -----------------------------------------------------
# Player.gd 中通常这么写：
#
# func _ready():
#     state_machine.init(self)  # 初始化状态机，把Player传给所有State
#
# func _physics_process(delta):
#     state_machine.process_physics(delta)
#
# func _unhandled_input(event):
#     state_machine.process_input(event)
#
# func _process(delta):
#     state_machine.process_frame(delta)
#
# -----------------------------------------------------


# -----------------------------------------------------
# 【举例：状态流转说明】
# -----------------------------------------------------
# 例如有以下三个状态：
#   IdleState（待机） → MoveState（移动） → JumpState（跳跃）
#
# IdleState.gd:
#     func process_input(event):
#         if event.is_action_pressed("go_right"):
#             return parent.move_state   # 切换到 MoveState
#         return null
#
# MoveState.gd:
#     func process_physics(delta):
#         if not Input.is_action_pressed("go_right"):
#             return parent.idle_state   # 切换回 Idle
#         return null
#
# JumpState.gd:
#     func process_physics(delta):
#         parent.velocity.y += gravity * delta
#         if parent.is_on_floor():
#             return parent.idle_state
#         return null
#
# 运行过程：
#   1️⃣ StateMachine 在 _ready() 中设置初始状态为 IdleState
#   2️⃣ 玩家按下方向键 → IdleState.process_input() 返回 MoveState
#   3️⃣ StateMachine 调用 change_state() → 调用 exit() / enter()
#   4️⃣ MoveState 开始在 process_physics() 中移动角色
#   5️⃣ 松开方向键 → MoveState 返回 IdleState → 状态机再次切换
#
# 这就是完整的有限状态机循环。
# -----------------------------------------------------
