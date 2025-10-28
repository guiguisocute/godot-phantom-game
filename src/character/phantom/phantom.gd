#phantom.gd
extends CharacterBody2D
class_name Phantom
signal test
@onready  var anim = $AnimatedSprite2D


func _on_spike_phantom_hit() -> void:
	print("黑厄接触尖刺信号测试")



	
