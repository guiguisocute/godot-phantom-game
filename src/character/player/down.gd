# down.gd - 快速下落状态（需要特殊条件触发）
extends State

@export var idle_state: State
@export var fall_state: State
@export var death_spike_state: State
@export var death_enermy_state: State

func enter() -> void:
	super.enter()
	# 速度与 jump_speed 相反（向下为正）
	parent.velocity.y = -parent.jump_speed  # jump_speed 是负数，取反变成正数向下

func process_input(_event: InputEvent) -> State:
	return null

func process_frame(_delta: float) -> State:
	return null

func process_physics(delta: float) -> State:
	# 继续加速下落（应用重力）
	parent.velocity.y += gravity * delta
	
	# 允许空中微调方向
	var horizontal_input = Input.get_axis('goat_left', 'goat_right')
	if horizontal_input != 0:
		parent.animations.flip_h = horizontal_input < 0
	
	parent.move_and_slide()
	
	# 是否死亡判断
	if parent.is_dead_spike:
		return death_spike_state
	
	if parent.is_dead_enermy:
		return death_enermy_state
	
	# 着地检测
	if parent.is_on_floor():
		return idle_state
	
	return null

func exit() -> void:
	pass
