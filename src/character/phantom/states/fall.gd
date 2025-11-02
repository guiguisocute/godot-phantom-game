# phantom/states/fall.gd - 幻影下落状态
extends State

@export var idle_state: State
@export var move_state: State

func process_physics(delta: float) -> State:
	# 应用重力
	parent.velocity.y += gravity * delta
	
	
	# 着地检测
	if parent.is_on_floor():
		return idle_state
	parent.move_and_slide()
	return null
