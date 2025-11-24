
class_name State		# 定义类名，在gdscript中每一个文件都是一个类，没有类名只能通过路径访问，如果有名的话就可以像python那种方式调用
extends Node   

@export
var animation_name: String           # 对应状态播放的动画名称，例如 "idle"、"move"、"jump"


var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var parent: CharacterBody2D 





# 当状态被“切换进入”时调用（相当于 enter() 生命周期）
func enter() -> void:
	parent.animations.play(animation_name)


# 当状态被“切换离开”时调用（相当于 exit() 生命周期）
func exit() -> void:
	pass


# 输入事件逻辑（键盘、手柄、触屏等）
# 一般用于检测“是否触发状态切换”
func process_input(event: InputEvent) -> State:
	return null   # 默认不切换状态（需要子类中重写）


# 普通逐帧逻辑（_process）
# 通常用于非物理的处理，比如动画、视觉特效等。		guiguisocute：在我们项目中一班用于黑厄的死亡检测
func process_frame(delta: float) -> State:
	return null   # 默认不切换状态（需要子类中重写）


# 物理逻辑（_physics_process）
# 通常用于移动、重力、碰撞检测等物理行为。guiguisocute：在我们这个项目这个状态只用于坠崖检测
func process_physics(delta: float) -> State:
	return null   # 默认不切换状态（需要子类中重写）
