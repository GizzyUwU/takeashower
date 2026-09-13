extends Node2D

@export var enemy_count: int = 10
@export var min_player_distance: float = 300.0
@export var spawn_distance_variation: float = 200.0
@export var enemy_spacing: float = 50.0
@export var ground_search_height: float = 2000.0
@export var enemy_ground_offset: float = 28.0

@onready var player: Node2D = get_tree().get_first_node_in_group("Player")

var tile_map: TileMapLayer


func _ready() -> void:
	var maps := get_tree().current_scene.find_children(
		"*",
		"TileMapLayer",
		true,
		false
	)

	if maps.is_empty():
		return

	tile_map = maps[0] as TileMapLayer

	if tile_map == null:
		return

	var enemies := get_tree().get_nodes_in_group("Enemy")

	if enemies.is_empty():
		return

	var template: Node2D = enemies[0]

	for i in range(enemy_count - enemies.size()):
		spawn_enemy(template)


func spawn_enemy(template: Node2D) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("Player")

	if player == null:
		print("ENEMY SPAWNER: No player found")
		return

	for attempt in range(100):
		var direction: float = -1.0 if randf() < 0.5 else 1.0

		var distance: float = randf_range(
			min_player_distance,
			min_player_distance + spawn_distance_variation
		)

		var x: float = player.global_position.x + direction * distance

		var ray_start := Vector2(
			x,
			player.global_position.y - ground_search_height
		)

		var ray_end := Vector2(
			x,
			player.global_position.y + ground_search_height
		)

		var query := PhysicsRayQueryParameters2D.create(
			ray_start,
			ray_end
		)

		query.exclude = [player]

		var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)

		if result.is_empty():
			continue

		var collider: Object = result["collider"]
		var hit_position: Vector2 = result["position"]
		var hit_normal: Vector2 = result["normal"]

		if collider != tile_map:
			continue

		if hit_position.y <= player.global_position.y:
			continue

		var spawn_position := Vector2(
			x,
			hit_position.y - enemy_ground_offset
		)

		var player_distance: float = spawn_position.distance_to(
			player.global_position
		)

		if player_distance < min_player_distance:
			continue

		var valid := true

		var enemies: Array[Node] = get_tree().get_nodes_in_group("Enemy")

		for other: Node in enemies:
			if not is_instance_valid(other):
				continue

			var other_2d := other as Node2D

			if other_2d == null:
				continue

			var enemy_distance: float = spawn_position.distance_to(
				other_2d.global_position
			)

			print(
				other_2d.global_position,
				enemy_distance
			)

			if enemy_distance < enemy_spacing:
				valid = false
				break

		if not valid:
			continue

		var enemy: Node2D = template.duplicate()

		add_child(enemy)
		enemy.global_position = spawn_position
		enemy.add_to_group("Enemy")

		return
