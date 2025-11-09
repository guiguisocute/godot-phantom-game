# 声明类名 Player，可被其他脚本识别和导入
class_name Player
extends CharacterBody2D  # 玩家是一个可移动的物理角色
var is_dead_spike:bool = false
var is_dead_enermy:bool = false
var is_legal_to_jump:bool = false
signal death
signal character_on_ladder


# 延迟绑定节点（在_ready()后才赋值）
@onready var animations = $AnimatedSprite2D       # 角色动画节点
@onready var state_machine = $StateMachine  # 状态机节点


@export var target_move_distance: float = 200.0  # 单次移动目标距离（像素）
@export var jump_speed = -300.0
@export_range(0.0, 2.0, 0.05) var speed_affect: float = 0.5  # 速度系数（0=超慢，1=超快）

# 当场景加载完成时调用
func _ready() -> void:
	# 初始化状态机，并把 player 自身传给它（让状态机里的状态能控制玩家）
	state_machine.init(self)

# 处理未被其它节点拦截的输入事件
func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_input(event)

# 每帧物理计算（固定时间步）
func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)

# 每帧更新（非固定时间步）
func _process(delta: float) -> void:
	state_machine.process_frame(delta)
	

func is_legalto_up() -> bool:
	return is_on_floor() and is_legal_to_jump
	
	
func _on_character_in_elec_area() -> void:
	character_on_ladder.emit()
	
	
func _on_spike_character_hit() -> void:
	is_dead_spike = true
	death.emit()


func _on_phantom_crush() -> void:
	is_dead_enermy = true
	death.emit()
