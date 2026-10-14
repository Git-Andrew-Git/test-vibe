extends CharacterBody2D
class_name OceanDiver

const MOVE_SPEED := 185.0
const HORIZONTAL_LIMIT := 610.0
const DIVER_ART := preload("res://assets/art/diver.svg")

var depth_limit := 500.0
var diver_sprite: Sprite2D
var swim_time := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	add_child(collision)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)

	diver_sprite = Sprite2D.new()
	diver_sprite.texture = DIVER_ART
	diver_sprite.scale = Vector2(0.74, 0.74)
	diver_sprite.position = Vector2(0, -9)
	diver_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(diver_sprite)

func _physics_process(_delta: float) -> void:
	var direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
			- float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
			- float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	)
	velocity = direction.normalized() * MOVE_SPEED
	move_and_slide()
	global_position.x = clampf(global_position.x, -HORIZONTAL_LIMIT, HORIZONTAL_LIMIT)
	global_position.y = clampf(global_position.y, 72.0, depth_limit + 77.0)
	if velocity.length_squared() > 8.0:
		swim_time += _delta * 8.0
		diver_sprite.rotation = clampf(velocity.x / MOVE_SPEED, -1.0, 1.0) * 0.12
		diver_sprite.position.y = -9.0 + sin(swim_time) * 2.2
	else:
		diver_sprite.rotation = move_toward(diver_sprite.rotation, 0.0, _delta * 0.7)
		diver_sprite.position.y = lerpf(diver_sprite.position.y, -9.0, _delta * 2.0)
