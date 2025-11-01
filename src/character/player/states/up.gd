extends  State

@export var idle_state: State
@export var fall_state: State
@export var death_spike_state:State
@export var death_enermy_state:State


func is_on_ladder_down()->bool:
	return true

func is_on_ladder_up() -> bool:			# 梯子的逻辑后面再写
	return true

func enter() -> void:		# 进入这个状态，你应该做什么？
	super.enter()
	parent.velocity.y = parent.jump_speed
	
func process_input(_event: InputEvent) -> State:    # 如果在这个状态下，检测到了某个输入操作，会进入什么新的状态？
	return null
	
func process_frame(_delta: float) -> State:     # 在这个状态下，需要你每帧执行什么操作？
	return null   # 默认不切换状态（需要子类中重写）
	
func process_physics(delta: float) -> State:	# 在这个状态下，需要你每物理帧执行什么操作？
	if parent.velocity.y < 0 :
		parent.velocity.y += gravity* delta;
	if parent.velocity.y > 0:
		return fall_state
	if parent.velocity.y == 0 and parent.is_on_floor() :
		return idle_state
	parent.move_and_slide()
	
	if parent.is_dead_spike:
		return death_spike_state
	
	
	if parent.is_dead_enermy:
		return death_enermy_state
	
	return null

func exit() -> void:     # 退出这个状态的时候，应该做什么
	pass
