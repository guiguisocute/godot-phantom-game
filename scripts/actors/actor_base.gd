extends CharacterBody2D
class_name ActorBase

@export var AX_SPEED = 200.0			# 默认X轴加速度 
@export var AY_SPEED = 200.0			# 默认Y轴加速度
# guiguisocute：我服了啊GDsript因为不是强静态语言所F2修改变量名，我有点后悔选它了说实话，但是好像有插件可以做到？先不管先原生开发吧
@export var JUMP_VELOCITY = -2000.0
@export var X_VELOCITY = 2000
@export var DEV_FREE_JUMP := true			# 

var g = ProjectSettings.get_setting("physics/2d/default_gravity", 40)

func _physics_process(delta: float) -> void:		# 这个官方函数的delta是完全固定的数值，固定帧数
	
	var floor_ok  := DEV_FREE_JUMP or is_on_floor()
	# 暂时注释掉，因为现阶段先不管重力测试一下上下的功能
	#if not is_on_floor():			# 如果玩家没有站在了一个平台上
		#velocity += get_gravity() * delta			# 速度+=重力加速度

	
	if Input.is_action_just_pressed("goat_up") and floor_ok and velocity.y == 0:		# guiguisocute：后置的条件后面肯定要改的！毕竟只允许在梯子的cell里上下，现在只是测试一下范围
		velocity.y = JUMP_VELOCITY		# y轴赋初速度											# 后续把梯子算做地板类型，这里逻辑应该也不用改了，调整跳跃速度就可以
		
	if Input.is_action_just_pressed("goat_down") and floor_ok and velocity.y == 0:		# guiguisocute：后置的条件后面肯定要改的！毕竟只允许在梯子的cell里上下，现在只是测试一下范围
		velocity.y = -JUMP_VELOCITY
		
	if Input.is_action_just_pressed("goat_right") and floor_ok and velocity.x == 0 :
		velocity.x = X_VELOCITY
		
	if Input.is_action_just_pressed("goat_left") and floor_ok and velocity.x == 0:
		velocity.x = -X_VELOCITY
	
	
	velocity.y = move_toward(velocity.y, 0, AY_SPEED)
	velocity.x = move_toward(velocity.x, 0, AX_SPEED)
		
		
	# 读取玩家方向，那个gex_axis后面的参数是两个布尔型，前参如果真则返回负，意义大概是偏移定轴位置，如果是手柄遥感那就可以精确移动，可惜我们游戏用不到,但毕竟是模版方法，所以留着供我们以后可能学习用
	#var direction := Input.get_axis("goat_left", "goat_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
