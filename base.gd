extends Node2D

@export var camera: Camera2D
@export var tile_map: TileMapLayer
@export var max_loops: int = 5

var base_x: float
var width: float
var left: TileMapLayer
var right: TileMapLayer

var current_slot: int = 0
var loops: int = 0


func _ready() -> void:
	if not tile_map:
		push_error("Tile Map not assigned!")
		return

	var used_rect := tile_map.get_used_rect()

	width = used_rect.size.x * tile_map.tile_set.tile_size.x
	base_x = tile_map.position.x

	left = tile_map.duplicate()
	add_child(left)

	right = tile_map.duplicate()
	add_child(right)

	current_slot = floor(camera.global_position.x / width)


func _process(_delta: float) -> void:
	if not camera or not tile_map:
		return

	var slot: int = floor(camera.global_position.x / width)

	if slot != current_slot:
		loops += abs(slot - current_slot)
		current_slot = slot

		print("Loop: ", loops)

		if loops > max_loops:
			get_tree().change_scene_to_file("res://win.tscn")
			return

	tile_map.position.x = base_x + float(slot) * width
	left.position.x = base_x + float(slot - 1) * width
	right.position.x = base_x + float(slot + 1) * width
