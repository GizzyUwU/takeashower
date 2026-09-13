extends RigidBody2D
@export var enemy_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(Vector2(0, 0), Vector2(1000, 600))
@onready var player: Node2D = get_tree().get_first_node_in_group("Player")
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var grounded: bool = false
var speed: float = 300.0
var detection_range: float = 900.0
var unload_range: float = 1400.0  # beyond this, despawn & respawn elsewhere
var stop_distance: float = 32.0
var buffer: float = 4.0

var _pending_unload: bool = false  # guards against double-triggering in one frame

func _ready() -> void:
	lock_rotation = true
	stop_distance = _get_shape_radius(collision_shape) + _get_player_radius() + buffer

func _get_shape_radius(cs: CollisionShape2D) -> float:
	if cs == null or cs.shape == null:
		return 16.0
	var shape = cs.shape
	if shape is CircleShape2D:
		return shape.radius
	elif shape is RectangleShape2D:
		return shape.size.length() / 2.0
	elif shape is CapsuleShape2D:
		return max(shape.radius, shape.height / 2.0)
	else:
		return 16.0

func _get_player_radius() -> float:
	if player == null:
		return 16.0
	var player_cs: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	return _get_shape_radius(player_cs)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _pending_unload:
		return

	grounded = false
	for i in range(state.get_contact_count()):
		var normal = state.get_contact_local_normal(i)
		if normal.dot(Vector2.UP) > 0.5:
			grounded = true
			break

	if player == null:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance > unload_range:
		_pending_unload = true
		call_deferred("_unload_and_respawn")
		return

	if distance <= stop_distance or distance > detection_range:
		state.linear_velocity.x = 0
	else:
		state.linear_velocity = to_player.normalized() * speed

	if state.linear_velocity.y < 0:
		state.linear_velocity.y = 0

	if abs(to_player.x) > 0.01:
		sprite.flip_h = to_player.x > 0

func _unload_and_respawn() -> void:
	spawn_enemy()
	queue_free()

func spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()
	var random_pos = Vector2.ZERO
	var min_distance_from_player: float = 200.0

	var attempts = 0
	while attempts < 20:
		random_pos = Vector2(
			randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
			randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
		)
		if player == null or random_pos.distance_to(player.global_position) >= min_distance_from_player:
			break
		attempts += 1

	enemy.global_position = random_pos

	var parent = get_parent()
	if parent != null:
		parent.add_child(enemy)
	else:
		get_tree().current_scene.add_child(enemy)
