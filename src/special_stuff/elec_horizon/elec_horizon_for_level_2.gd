extends AnimatedSprite2D
signal Charactor_pass_elect_orange



#PROCESS_MODE_INHERIT = 0
#从该节点的父节点继承 process_mode。这是任何新创建的节点的默认设置。
#● PROCESS_MODE_PAUSABLE = 1
#当 SceneTree.paused 为 true 时停止处理。这是 PROCESS_MODE_WHEN_PAUSED 的逆，也是根节点的默认值。
#● PROCESS_MODE_WHEN_PAUSED = 2
#仅当 SceneTree.paused 为 true 时处理。与 PROCESS_MODE_PAUSABLE 相反。
#● PROCESS_MODE_ALWAYS = 3
#始终处理。忽略 SceneTree.paused 的取值，保持处理。与 PROCESS_MODE_DISABLED 相反。
#● PROCESS_MODE_DISABLED = 4
#从不处理。完全禁用处理，忽略 SceneTree.paused。与 PROCESS_MODE_ALWAYS 相反。

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_DISABLED
	self.set_visible(true)
	self.process_mode = Node.PROCESS_MODE_INHERIT
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player or body is Phantom or body is Phantom_dev or body is Player_dev:
		print_rich("[color=orange]💡 %s 正在通过橙色水平电流！[/color]" % body.name)
		Charactor_pass_elect_orange.emit()


func _on_button_orange_charactor_pess_button_orange() -> void:
	self.set_visible(false)
	self.process_mode = Node.PROCESS_MODE_DISABLED

func _on_button_orange_charactor_pop_button_orange() -> void:
	self.process_mode = Node.PROCESS_MODE_INHERIT
	self.set_visible(true)
