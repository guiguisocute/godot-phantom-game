# level_1.gd - 添加调试信息
extends Node2D

@onready var timeline: TimelineControler = $TimelineControler

func _ready() -> void:
	# 检查 timeline 是否存在
	if not timeline:
		push_error("[测试] 找不到 TimelineControler 节点！")
		return
	
	timeline.step_recorded.connect(_on_step_recorded)
	
	# 开始录制
	timeline.start_recording()

## level1接受信号测试
func _on_step_recorded(step_name: String) -> void:
	print("[level1] 记录了一步：", step_name)
