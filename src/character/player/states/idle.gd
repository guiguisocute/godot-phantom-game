extends State

# 引用其他状态（在 Inspector 中连接）
@export var move_state: State
@export var up_state: State
@export var fall_state: State
@export var attack_state: State
@export var down_state: State  # 新增：快速下落状态
@export var death_spike_state: State
@export var death_enermy_state: State

func process_input(event: InputEvent) -> State:
	# 检测跳跃输入
	if Input.is_action_just_pressed('goat_up') and parent.is_legalto_up():
		return up_state
	
	# 检测快速下落输入（需要特殊条件：在梯子上或特定区域）
	if Input.is_action_just_pressed('goat_down') and parent.is_legal_to_down():
		return down_state
	
	# 检测水平移动输入
	if Input.is_action_just_pressed('goat_right') or Input.is_action_just_pressed('goat_left'):
		if parent.is_on_floor():
			return move_state
	
	if Input.is_action_just_pressed("attack_test"):
		return attack_state
	
	return null

func process_physics(delta: float) -> State:
	# 应用重力
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
	
	# 确保速度归零（待机状态）
	parent.velocity.x = 0
	parent.velocity.y = move_toward(parent.velocity.y, 0, gravity * delta) if parent.is_on_floor() else parent.velocity.y
	
	parent.move_and_slide()
	
	# 如果离开地面，切换到下落状态
	if not parent.is_on_floor():
		return fall_state
	
	#
	if parent.is_dead_spike:
		return death_spike_state
	
	
	if parent.is_dead_enermy:
		return death_enermy_state
	
	
	
	return null
