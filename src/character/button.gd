extends Control
@onready var label: Label = $Label
@onready var control: Control = $Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	


func _on_button_pressed() -> void:
	label.set("visible",false)
	control.visible = false
	get_tree().paused = false


func _on_button_2_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")


func _on_button_3_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_pause_pressed() -> void:
	label.set("visible",true)
	control.visible = true
	get_tree().paused = true
	
