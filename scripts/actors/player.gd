extends ActorBase
class_name PlayerActor
func _init() -> void:
	AX_SPEED = 260.0	# 测试是否能修改成员



# 如果后面想把输入放到 Player 身上，可以在这里发 move_requested 信号给控制器。
# 目前保持“被动执行”，由 LevelController 调用 move_* 方法即可。
