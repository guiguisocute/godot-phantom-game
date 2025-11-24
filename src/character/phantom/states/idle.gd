# phantom/states/idle.gd - 幻影待机状态
extends State

# 引用其他状态（在 Inspector 中连接）
@export var move_state: State
@export var up_state: State
@export var fall_state: State
@export var attack_state: State

func process_input(event: InputEvent) -> State:
	# 🔥 幻影不监听键盘输入
	return null

func process_physics(delta: float) -> State:
	# 应用重力
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
	
	# 确保速度归零（待机状态）
	parent.velocity.x = 0
	parent.velocity.y = move_toward(parent.velocity.y, 0, gravity * delta) if parent.is_on_floor() else parent.velocity.y
	
	parent.move_and_slide()
	
	# 🔥 检查 Playback 指令（替代键盘输入）
	if parent.has_jump_command() and parent.is_legalto_up():
		return up_state
	
	if parent.has_horizontal_command() and parent.is_on_floor():
		return move_state
	
	if parent.has_attack_command():
		return attack_state
	
	
	if parent.Player_enter_front:
		parent.Player_enter_front = false
		return attack_state
	if parent.Player_enter_back:
		parent.Player_enter_back = false
		return attack_state
		
	# 如果离开地面，切换到下落状态
	if not parent.is_on_floor():
		return fall_state
	
	return null
