extends CharacterBody2D
class_name OceanDiver

const MOVE_SPEED := 185.0
const BOOST_MULTIPLIER := 1.75
const HORIZONTAL_LIMIT := 1420.0
const DIVER_ART := preload("res://assets/art/diver.svg")
const SUBMERSIBLE_ART := preload("res://assets/art/pocket_sub.svg")
const HELMET_ART := preload("res://assets/art/diver_helmet.svg")
const FIN_ART := preload("res://assets/art/diver_fins.svg")

var depth_limit := 500.0
var movement_speed := MOVE_SPEED
var has_fins := false
var has_submersible := false
var diver_sprite: Sprite2D
var helmet_sprite: Sprite2D
var fins_sprite: Sprite2D
var submersible_sprite: Sprite2D
var swim_time := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	add_child(collision)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)

	submersible_sprite = Sprite2D.new()
	submersible_sprite.texture = SUBMERSIBLE_ART
	submersible_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	submersible_sprite.scale = Vector2(0.58, 0.58)
	submersible_sprite.position = Vector2(0, -7)
	submersible_sprite.visible = false
	add_child(submersible_sprite)

	diver_sprite = Sprite2D.new()
	diver_sprite.texture = DIVER_ART
	diver_sprite.scale = Vector2(0.38, 0.38)
	diver_sprite.position = Vector2(0, -9)
	diver_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(diver_sprite)

	helmet_sprite = Sprite2D.new()
	helmet_sprite.texture = HELMET_ART
	helmet_sprite.scale = Vector2(0.38, 0.38)
	helmet_sprite.position = Vector2(0.0, -9.0)
	helmet_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	helmet_sprite.visible = false
	add_child(helmet_sprite)

	fins_sprite = Sprite2D.new()
	fins_sprite.texture = FIN_ART
	fins_sprite.scale = Vector2(0.38, 0.38)
	fins_sprite.position = Vector2(0.0, -9.0)
	fins_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fins_sprite.visible = false
	add_child(fins_sprite)

func _physics_process(_delta: float) -> void:
	var direction := Vector2(
		float(Input.is_action_pressed("move_right")) - float(Input.is_action_pressed("move_left")),
		float(Input.is_action_pressed("move_down")) - float(Input.is_action_pressed("move_up"))
	)
	var boost := has_fins and Input.is_physical_key_pressed(KEY_SHIFT)
	velocity = direction.normalized() * _effective_movement_speed(boost)
	move_and_slide()
	global_position.x = clampf(global_position.x, -HORIZONTAL_LIMIT, HORIZONTAL_LIMIT)
	global_position.y = clampf(global_position.y, -700.0, depth_limit + 77.0)
	if velocity.length_squared() > 8.0:
		swim_time += _delta * 8.0
		diver_sprite.rotation = clampf(velocity.x / (movement_speed * BOOST_MULTIPLIER), -1.0, 1.0) * 0.12
		diver_sprite.position.y = -9.0 + sin(swim_time) * 2.2
		helmet_sprite.position.y = diver_sprite.position.y
		fins_sprite.position.y = diver_sprite.position.y
		helmet_sprite.rotation = diver_sprite.rotation
		fins_sprite.rotation = diver_sprite.rotation
	else:
		diver_sprite.rotation = move_toward(diver_sprite.rotation, 0.0, _delta * 0.7)
		diver_sprite.position.y = lerpf(diver_sprite.position.y, -9.0, _delta * 2.0)
		helmet_sprite.position.y = diver_sprite.position.y
		fins_sprite.position.y = diver_sprite.position.y
		helmet_sprite.rotation = diver_sprite.rotation
		fins_sprite.rotation = diver_sprite.rotation
		if has_submersible:
			submersible_sprite.position.y = -7.0 + sin(swim_time * 0.5) * 1.1

func _effective_movement_speed(boost_pressed: bool) -> float:
	return movement_speed * (BOOST_MULTIPLIER if has_fins and boost_pressed else 1.0)
