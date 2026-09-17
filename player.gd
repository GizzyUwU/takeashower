extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -900.0
var idle_time := 0.0
var jumps := 0
const walk = preload("res://assets/tbh_left.png")
const sit = preload("res://assets/tbh_sit.png")

func _ready() -> void:
	add_to_group("Player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps = 0
	if Input.is_action_just_pressed("Jump") and jumps < 2:
		velocity.y = JUMP_VELOCITY
		jumps += 1

	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
		idle_time = 0.0
		$Sprite2D.flip_h = direction > 0
		$Sprite2D.texture = walk
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		idle_time += delta
		if idle_time >= 2.0:
			$Sprite2D.texture = sit

	move_and_slide()


func _on_rigid_body_2d_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file.call_deferred("res://gameover.tscn")

func _on_void_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file.call_deferred("res://gameover.tscn")
