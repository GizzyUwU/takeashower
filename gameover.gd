extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_agayian_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_ragequit_pressed() -> void:
	get_tree().quit()
