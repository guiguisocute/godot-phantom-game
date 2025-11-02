extends State

@export var idle_state: State
@export var move_state: State
@export var death_spike_state:State
@export var death_enermy_state:State



func process_physics(delta: float) -> State:
	# 应用重力
	parent.velocity.y += gravity * delta
	
	# 允许空中微调方向
	var horizontal_input = Input.get_axis('goat_left', 'goat_right')
	if horizontal_input != 0:
		parent.animations.flip_h = horizontal_input < 0
	
	parent.move_and_slide()
	
	#是否死亡判断
	if parent.is_dead_spike:
		return death_spike_state
	
	if parent.is_dead_enermy:
		return death_enermy_state
	
	# 着地检测
	if parent.is_on_floor():
		return idle_state
	
	return null
