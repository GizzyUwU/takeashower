extends Node2D

@onready var player: Node2D = get_tree().get_first_node_in_group("Player")
@onready var camera: Camera2D = player.get_node("Camera2D")
@onready var level_label: Label = get_tree().get_first_node_in_group("LevelLabel")
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

	if not camera:
		push_error("Camera not assigned!")
		return

	var used_rect := tile_map.get_used_rect()

	width = used_rect.size.x * tile_map.tile_set.tile_size.x
	base_x = tile_map.position.x

	left = tile_map.duplicate()
	add_child(left)

	right = tile_map.duplicate()
	add_child(right)

	current_slot = floor(camera.global_position.x / width)

	update_level_label()


func _process(_delta: float) -> void:
	if not camera or not tile_map:
		return

	var slot: int = floor(camera.global_position.x / width)

	if slot > current_slot:
		loops += slot - current_slot
		current_slot = slot
		update_level_label()

		if loops > max_loops:
			get_tree().change_scene_to_file("res://win.tscn")
			return
	elif slot < current_slot:
		current_slot = slot

	tile_map.position.x = base_x + float(slot) * width
	left.position.x = base_x + float(slot - 1) * width
	right.position.x = base_x + float(slot + 1) * width

func update_level_label() -> void:
	if level_label:
		level_label.text = "Level %d" % (loops + 1)
		level_label.show()
