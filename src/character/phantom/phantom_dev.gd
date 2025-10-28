# phantom_dev.gd - Dev场景的幻影控制脚本
# 支持流畅的移动、跳跃和攻击，并可通过输入切换控制权
extends CharacterBody2D
class_name Phantom_dev
signal test

# 节点引用
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# 移动参数（幻影可以有不同的属性）
@export var SPEED := 350.0              # 水平移动速度（稍快）
@export var JUMP_VELOCITY := -550.0     # 跳跃初速度（稍高）
@export var ACCELERATION := 2200.0      # 加速度
@export var FRICTION := 1600.0          # 摩擦力/减速度
@export var AIR_RESISTANCE := 120.0     # 空中阻力

# 攻击参数
@export var ATTACK_DURATION := 0.5      # 攻击持续时间

# 状态变量
var is_controlled := false              # 是否当前被控制
var is_attacking := false               # 是否正在攻击
var attack_timer := 0.0                 # 攻击计时器
var is_dead := false                    # 是否死亡状态
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	# 初始化，幻影默认不被控制，半透明
	modulate.a = 0.5

func _physics_process(delta: float) -> void:
	# 如果死亡则不响应输入，仅等待动画播放结束
	if is_dead:
		move_and_slide()
		return
	
	# 如果不被控制，只执行物理模拟，不响应输入
	if not is_controlled:
		apply_gravity(delta)
		move_and_slide()
		update_animation()
		return
	
	# 应用重力
	apply_gravity(delta)
	
	# 攻击状态计时
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
	
	# 跳跃（可持续检测）
	if Input.is_action_pressed("goat_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# 水平移动
	var direction := 0.0
	if Input.is_action_pressed("goat_left"):
		direction -= 1.0
	if Input.is_action_pressed("goat_right"):
		direction += 1.0
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		anim.flip_h = direction < 0
	else:
		var deceleration = FRICTION if is_on_floor() else AIR_RESISTANCE
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	# 攻击输入
	if Input.is_action_just_pressed("attack_test") and not is_attacking:
		start_attack()
	
	move_and_slide()
	update_animation()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func start_attack() -> void:
	is_attacking = true
	attack_timer = ATTACK_DURATION
	if anim.sprite_frames.has_animation("attack"):
		anim.play("attack")

func start_death() -> void:
	is_dead = true
	is_controlled = false
	velocity = Vector2.ZERO
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
	modulate.a = 0.3  # 死亡时淡化

func update_animation() -> void:
	# 优先级 1：死亡动画锁定
	if is_dead and anim.is_playing() and anim.animation == "death":
		return
	
	# 优先级 2：攻击动画锁定
	if is_attacking and anim.sprite_frames.has_animation("attack"):
		return
	
	# 优先级 3：空中状态
	if not is_on_floor():
		if velocity.y < 0:
			anim.play("up")
		else:
			anim.play("fall")
		return
	
	# 优先级 4：地面状态
	if abs(velocity.x) > 10:
		anim.play("move")
	else:
		anim.play("idle")

func set_controlled(controlled: bool) -> void:
	is_controlled = controlled
	modulate.a = 1.0 if controlled else 0.5

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player or body is Player_dev:
		start_attack()
		test.emit()
