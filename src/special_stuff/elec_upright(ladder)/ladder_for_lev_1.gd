# ladder_for_lev_1.gd
extends AnimatedSprite2D
@onready var static_body_2d: StaticBody2D = $StaticBody2D
signal is_on_ladder_top
signal is_leave_ladder_top
signal is_on_ladder_button
signal is_leave_ladder_button

@onready var player: Player = $"../Player"
@onready var phantom: Phantom = $"../Phantom"

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		print("[Ladder] ✅ Player 进入梯子顶部")
		body.is_legal_to_down = true
		is_on_ladder_top.emit()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		print("[Ladder] ✅ Player 离开梯子顶部")
		body.is_legal_to_down = false
		is_leave_ladder_top.emit()


func _on_button_body_entered(body: Node2D) -> void:
	if body is Player:
		print("[Ladder] ✅ Player 进入梯子底部")
		body.is_legal_to_jump = true
		is_on_ladder_button.emit()


func _on_button_body_exited(body: Node2D) -> void:
	if body is Player:
		print("[Ladder] ✅ Player 进入梯子底部")
		body.is_legal_to_jump = false
		is_leave_ladder_button.emit()


func _on_player_player_state_change_down() -> void:
	print("[Ladder] ✅梯子顶部已对Player虚化")
	static_body_2d.set_collision_layer_value(4, false)


func _on_phantom_phantom_state_change_down() -> void:
	print("✅梯子顶部已对Phantom虚化")
	static_body_2d.set_collision_layer_value(5, false)


func _on_phantom_phantom_state_change_up() -> void:
	print("[Ladder] 等待 Phantom 速度归零")
	await _wait_for_movement_complete(phantom)
	static_body_2d.set_collision_layer_value(5, true)
	print("[Ladder] ✅ 砖块对 Phantom 实体化")


func _on_player_player_state_change_up() -> void:
	print("[Ladder] 等待 Player 速度归零")
	await _wait_for_movement_complete(player)
	static_body_2d.set_collision_layer_value(4, true)
	print("[Ladder] ✅ 砖块对 Player 实体化")


func _wait_for_movement_complete(character: CharacterBody2D) -> void:
	if character == null or not is_instance_valid(character):
		return
	
	# 阶段1：等待开始跳跃（y速度变为负）
	while character and is_instance_valid(character):
		if character.velocity.y < -50.0:
			break
		await get_tree().physics_frame
	
	# 阶段2：等待离开地面
	while character and is_instance_valid(character):
		if not character.is_on_floor():
			break
		await get_tree().physics_frame
	
	while character and is_instance_valid(character):
		if character.velocity.y == 0:
			break
		await get_tree().physics_frame
