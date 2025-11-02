# player_dev.gd - Dev场景的玩家控制脚本
# 支持流畅的移动、跳跃和攻击，并可通过输入切换控制权
extends CharacterBody2D
class_name  Player_dev

# 节点引用
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# 移动参数
@export var SPEED := 300.0              # 水平移动速度
@export var JUMP_VELOCITY := -500.0     # 跳跃初速度
@export var ACCELERATION := 2000.0      # 加速度
@export var FRICTION := 1500.0          # 摩擦力/减速度
@export var AIR_RESISTANCE := 100.0     # 空中阻力

# 攻击参数
@export var ATTACK_DURATION := 0.5      # 攻击持续时间

# 状态变量
var is_controlled := true               # 是否当前被控制
var is_attacking := false               # 是否正在攻击
var is_dead := false                    # 是否死亡
var attack_timer := 0.0                 # 攻击计时器
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var death_screen_scene = preload("res://src/ui/death_interface.tscn")

func _ready() -> void:
	# 初始化
	pass

func _physics_process(delta: float) -> void:
	# 如果死亡，停止所有逻辑
	if is_dead:
		return
	
	# 如果不被控制，只执行物理模拟，不响应输入
	if not is_controlled:
		apply_gravity(delta)
		move_and_slide()
		update_animation()
		return
	
	# 应用重力
	apply_gravity(delta)
	
	# 处理攻击状态
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
		# 攻击时仍可移动和跳跃
	
	# 处理跳跃（持续检测，允许长按）
	if Input.is_action_pressed("goat_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# 处理水平移动（持续检测输入）
	var direction := 0.0
	if Input.is_action_pressed("goat_left"):
		direction -= 1.0
	if Input.is_action_pressed("goat_right"):
		direction += 1.0
	
	# 应用水平移动
	if direction != 0:
		# 加速
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		# 更新朝向
		anim.flip_h = direction < 0
	else:
		# 减速
		var deceleration = FRICTION if is_on_floor() else AIR_RESISTANCE
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	# 处理攻击
	if Input.is_action_just_pressed("attack_test") and not is_attacking:
		start_attack()
	
	# 执行移动
	move_and_slide()
	
	# 更新动画
	update_animation()

func apply_gravity(delta: float) -> void:
	"""应用重力"""
	if not is_on_floor():
		velocity.y += gravity * delta

func start_attack() -> void:
	"""开始攻击"""
	is_attacking = true
	attack_timer = ATTACK_DURATION
	anim.play("attack")

func update_animation() -> void:
	"""更新动画状态"""
	# 死亡状态优先级最高
	if is_dead:
		return
	
	if is_attacking:
		# 攻击动画由 start_attack 设置，这里不改变
		return
	
	if not is_on_floor():
		# 在空中
		if velocity.y < 0:
			anim.play("up")
		else:
			anim.play("fall")
	else:
		# 在地面上
		if abs(velocity.x) > 10:
			anim.play("move")
		else:
			anim.play("idle")

func set_controlled(controlled: bool) -> void:
	"""设置是否被控制"""
	is_controlled = controlled
	# 当失去控制时，可以添加视觉反馈
	modulate.a = 1.0 if controlled else 0.5


func _on_phantom_test() -> void:
	print("收到去死信号")
	is_dead = true
	await get_tree().create_timer(0.5).timeout
	anim.play("death")

	
	
func _on_spike_character_hit() -> void:
	print("我要死了")
	is_dead = true
	anim.play("death")
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://src/ui/death_interface.tscn")


func _on_spike_2_character_hit() -> void:
	print("我要死了2")
	is_dead = true
	anim.play("death")


func _on_spike_3_character_hit() -> void:
	is_dead = true
	anim.play("death")


func _on_spike_4_character_hit() -> void:
	is_dead = true
	anim.play("death")
