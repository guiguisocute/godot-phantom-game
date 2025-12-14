# down.gd - 快速下落状态（需要特殊条件触发）
extends State

@export var idle_state: State
@export var fall_state: State
@export var death_spike_state: State
@export var death_enermy_state: State
signal state_change_down

func enter() -> void:
	super.enter()
	# 速度与 jump_speed 相反（向下为正）
	parent.velocity.y = -parent.jump_speed  # jump_speed 是负数，取反变成正数向下
	state_change_down.emit()

func process_input(_event: InputEvent) -> State:
	return null

func process_frame(_delta: float) -> State:
	parent.move_and_slide()
	if parent.is_on_floor():
		return idle_state
	
	return null

func process_physics(delta: float) -> State:
	return null

func exit() -> void:
	pass
