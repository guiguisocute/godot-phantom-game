# phantom_dev.gd - Dev场景的幻影控制脚本
# 支持流畅的移动、跳跃和攻击，并可通过输入切换控制权
extends CharacterBody2D
class_name Phantom_dev

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
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	# 初始化，幻影默认不被控制，半透明
	modulate.a = 0.5

func _physics_process(delta: float) -> void:
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
	# 注意：幻影场景可能没有attack动画，需要检查
	if anim.sprite_frames.has_animation("attack"):
		anim.play("attack")

func update_animation() -> void:
	"""更新动画状态"""
	if is_attacking and anim.sprite_frames.has_animation("attack"):
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
	# 当获得控制时，变为不透明；失去控制时，变为半透明
	modulate.a = 1.0 if controlled else 0.5
