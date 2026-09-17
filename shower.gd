extends RigidBody2D

@export var speed: float = 300.0
@export var detection_range: float = 900.0
@export var unload_range: float = 1400.0
@export var buffer: float = 4.0

@onready var player: Node2D = get_tree().get_first_node_in_group("Player")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var ground_check: RayCast2D = $GroundCheck
@onready var jump_check: RayCast2D = $JumpCheck
@onready var block_check: RayCast2D = $BlockCheck
@onready var block_check2: RayCast2D = $BlockCheck2
@onready var block_check3: RayCast2D = $BlockCheck3
const JUMP_VELOCITY: float = -900.0

var grounded: bool = false
var jumps: int = 0
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
		var normal: Vector2 = state.get_contact_local_normal(i)

		if normal.dot(Vector2.UP) > 0.5:
			grounded = true
			break

	if grounded:
		jumps = 0

	if player == null:
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()

	if distance > unload_range:
		_pending_unload = true
		call_deferred("_unload")
		return

	if distance <= stop_distance or distance > detection_range:
		state.linear_velocity.x = 0.0
	else:
		state.linear_velocity.x = to_player.normalized().x * speed

	var direction: float = signf(state.linear_velocity.x)

	if grounded and direction != 0.0:

		block_check.target_position.x = direction * 50.0
		block_check.force_raycast_update()
		
		block_check2.target_position.x = direction * 50.0
		block_check2.force_raycast_update()
		
		block_check3.target_position.x = direction * 50.0
		block_check3.force_raycast_update()

		if block_check.is_colliding() or block_check2.is_colliding() or block_check3.is_colliding():
			state.linear_velocity.y = JUMP_VELOCITY
			jumps += 1

	if abs(to_player.x) > 0.01:
		sprite.flip_h = to_player.x > 0


func _unload() -> void:
	var main: Node = get_parent()

	if main != null and main.has_method("spawn_enemy"):
		main.spawn_enemy(self)

	queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		call_deferred("_game_over")


func _game_over() -> void:
	get_tree().change_scene_to_file("res://gameover.tscn")
