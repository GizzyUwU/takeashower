extends RigidBody2D

@export var speed: float = 300.0
@export var detection_range: float = 900.0
@export var unload_range: float = 1400.0
@export var buffer: float = 4.0

@onready var player: Node2D = get_tree().get_first_node_in_group("Player")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var grounded: bool = false
var stop_distance: float = 32.0
var _pending_unload: bool = false


func _ready() -> void:
	lock_rotation = true
	stop_distance = _get_shape_radius(collision_shape) + _get_player_radius() + buffer


func _get_shape_radius(cs: CollisionShape2D) -> float:
	if cs == null or cs.shape == null:
		return 16.0

	var shape = cs.shape

	if shape is CircleShape2D:
		return shape.radius

	if shape is RectangleShape2D:
		return max(shape.size.x, shape.size.y) / 2.0

	if shape is CapsuleShape2D:
		return max(shape.radius, shape.height / 2.0)

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
		var normal := state.get_contact_local_normal(i)

		if normal.dot(Vector2.UP) > 0.5:
			grounded = true
			break

	if player == null:
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()

	if distance > unload_range:
		_pending_unload = true
		call_deferred("_unload")
		return

	if distance <= stop_distance or distance > detection_range:
		state.linear_velocity.x = 0.0
	else:
		state.linear_velocity.x = to_player.normalized().x * speed

	if state.linear_velocity.y < 0:
		state.linear_velocity.y = 0

	if abs(to_player.x) > 0.01:
		sprite.flip_h = to_player.x > 0


func _unload() -> void:
	var main := get_parent()

	if main != null and main.has_method("spawn_enemy"):
		main.spawn_enemy(self)

	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		call_deferred("_game_over")


func _game_over() -> void:
	get_tree().change_scene_to_file("res://gameover.tscn")
