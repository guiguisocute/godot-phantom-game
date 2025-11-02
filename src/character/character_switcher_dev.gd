# character_switcher_dev.gd - Dev场景的角色切换控制器
# 负责处理玩家和幻影之间的控制权切换
extends Node

# 角色引用（需要在编辑器中设置，或通过代码查找）
@export var player: CharacterBody2D
@export var phantom: CharacterBody2D

# 当前控制的角色索引 (0 = player, 1 = phantom)
var current_character := 0

func _ready() -> void:
	# 如果没有手动设置，尝试自动查找
	if player == null:
		player = get_node_or_null("../Player")
	if phantom == null:
		phantom = get_node_or_null("../Phantom")
	
	# 确保找到了两个角色
	if player == null or phantom == null:
		push_error("Character Switcher: 无法找到 Player 或 Phantom 节点！")
		return
	# 初始化控制状态
	update_control_state()

func _unhandled_input(event: InputEvent) -> void:
	# 检测切换角色的输入
	if event.is_action_pressed("change_character_dev"):
		switch_character()

func switch_character() -> void:
	"""切换控制角色"""
	# 切换索引
	current_character = 1 - current_character
	
	# 更新控制状态
	update_control_state()
	
	# 打印调试信息
	var character_name = "Player" if current_character == 0 else "Phantom"
	print_rich("[color=cyan]切换到控制: %s[/color]" % character_name)

func update_control_state() -> void:
	"""更新两个角色的控制状态"""
	if player == null or phantom == null:
		return
	
	# 再次检查方法是否存在（防御性编程）
	if not player.has_method("set_controlled") or not phantom.has_method("set_controlled"):
		return
	
	# 设置控制权
	if current_character == 0:
		# 控制玩家
		player.set_controlled(true)
		phantom.set_controlled(false)
	else:
		# 控制幻影
		player.set_controlled(false)
		phantom.set_controlled(true)
