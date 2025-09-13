extends ActorBase
class_name Phantom

var freeze_after_move: bool = false

func freeze_after_last_step() -> void:
	freeze_after_move = true

func _process(delta: float) -> void:
	if freeze_after_move and not is_moving:
		return
	super(delta)
