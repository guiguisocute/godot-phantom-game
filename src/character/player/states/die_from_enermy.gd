extends  State

func enter() -> void:		# 进入这个状态，你应该做什么？
	print("我要死了")
	#Game.record_current_scene()
	#parent.velocity = Vector2(0,0)
	await get_tree().create_timer(0.5).timeout
	super.enter()
	await get_tree().create_timer(0.5).timeout
	
func process_input(event: InputEvent) -> State:    # 如果在这个状态下，检测到了某个操作，会进入什么新的状态？
	return null
	
func process_frame(delta: float) -> State:     # 在这个状态下，需要你每帧执行什么操作？
	return null   # 默认不切换状态（需要子类中重写）
	
func process_physics(delta: float) -> State:	# 在这个状态下，需要你每物理帧执行什么操作？
	return null

func exit() -> void:     # 退出这个状态的时候，应该做什么
	pass
