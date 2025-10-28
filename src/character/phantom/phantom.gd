#phantom.gd
extends CharacterBody2D
class_name Phantom
signal test
@onready  var anim = $AnimatedSprite2D


func _on_spike_phantom_hit() -> void:
	print("黑厄接触尖刺信号测试")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player or body is Player_dev:
		anim.play("attack")
		test.emit()
	
