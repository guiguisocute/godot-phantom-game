extends State

@export var idle_state: State

var should_return_to_idle: bool = false

func enter() -> void:
	super.enter()
	
	should_return_to_idle = false
	
	# 连接动画完成信号（一次性）
	parent.animations.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)
	
	# 停止移动
	parent.velocity.x = 0

func process_input(event: InputEvent) -> State:
	return null

func process_frame(delta: float) -> State:
	# 在下一帧检查是否应该返回 idle
	if should_return_to_idle:
		return idle_state
	
	return null

func process_physics(delta: float) -> State:
	# 攻击时应用重力
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
	
	parent.move_and_slide()
	
	return null

func _on_attack_animation_finished() -> void:
	should_return_to_idle = true

func exit() -> void:
	print("[AttackState] 退出攻击状态")
