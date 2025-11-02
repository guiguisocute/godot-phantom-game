extends Node2D

@export var bgm: AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if bgm:
		SoundManager.play_bgm(bgm)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
