extends Node


@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

func play_bgm(Stream: AudioStream) -> void:
	if bgm_player.stream == Stream and bgm_player.playing:
		return
	bgm_player.stream=Stream
	bgm_player.play()
