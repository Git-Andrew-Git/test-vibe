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
var current_boost_time := 0.0
var vehicle_health := 100.0
var shield_time := 0.0
var surface_breach_time := 0.0
var surface_breach_cooldown := 0.0
var swim_rig: Node2D
var arm_rigs: Array[Node2D] = []
var leg_rigs: Array[Node2D] = []

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

	swim_rig = Node2D.new()
	swim_rig.position.y = -9.0
	add_child(swim_rig)
	for side in [-1.0, 1.0]:
		arm_rigs.append(_create_limb(Vector2(side * 8.0, -10.0), side, true))
		leg_rigs.append(_create_limb(Vector2(side * 4.0, 9.0), side, false))

	diver_sprite = Sprite2D.new()
	diver_sprite.texture = DIVER_ART
	diver_sprite.scale = Vector2(0.095, 0.095)
	diver_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	swim_rig.add_child(diver_sprite)

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
	current_boost_time = maxf(0.0, current_boost_time - _delta)
	shield_time = maxf(0.0, shield_time - _delta)
	surface_breach_cooldown = maxf(0.0, surface_breach_cooldown - _delta)
	var direction := Vector2(
		float(Input.is_action_pressed("move_right")) - float(Input.is_action_pressed("move_left")),
		float(Input.is_action_pressed("move_down")) - float(Input.is_action_pressed("move_up"))
	)
	var boost := has_fins and Input.is_physical_key_pressed(KEY_SHIFT)
	var speed := _effective_movement_speed(boost)
	if current_boost_time > 0.0:
		speed *= 1.48
	if (
		surface_breach_time <= 0.0
		and surface_breach_cooldown <= 0.0
		and global_position.y >= 0.0
		and global_position.y <= 24.0
		and direction.y < -0.1
	):
		surface_breach_time = 0.75
		velocity = Vector2(direction.x * speed * 0.55, -220.0)

	if surface_breach_time > 0.0:
		surface_breach_time = maxf(0.0, surface_breach_time - _delta)
		velocity.x = direction.x * speed * 0.45
		velocity.y += 430.0 * _delta
		move_and_slide()
		if velocity.y > 0.0 and surface_breach_time <= 0.0:
			global_position.y = maxf(0.0, global_position.y)
			velocity.y = 0.0
			surface_breach_cooldown = 1.2
	else:
		velocity = direction * speed
		if global_position.y <= 0.0 and direction.y < 0.0:
			velocity.y = 0.0
		move_and_slide()
	global_position.x = clampf(global_position.x, -HORIZONTAL_LIMIT, HORIZONTAL_LIMIT)
	global_position.y = clampf(global_position.y, -110.0, 2400.0)

	var moving := direction.length_squared() > 0.01
	swim_time += _delta * (7.8 if moving else 2.2)
	swim_rig.position.y = -9.0 + sin(swim_time) * (2.4 if moving else 1.1)
	swim_rig.scale.x = -1.0 if direction.x < -0.1 else 1.0 if direction.x > 0.1 else swim_rig.scale.x
	diver_sprite.rotation = (
		clampf(direction.x, -1.0, 1.0) * 0.11
		+ clampf(direction.y, -1.0, 1.0) * 0.08
	)
	var stroke := 0.34 if moving else 0.11
	for index in range(arm_rigs.size()):
		var side := -1.0 if index == 0 else 1.0
		arm_rigs[index].rotation = sin(swim_time + side * 0.9) * stroke
		leg_rigs[index].rotation = sin(swim_time + side * 1.2 + PI) * stroke * 1.25
	helmet_sprite.position.y = swim_rig.position.y
	fins_sprite.position.y = swim_rig.position.y
	helmet_sprite.rotation = diver_sprite.rotation
	fins_sprite.rotation = diver_sprite.rotation
	if has_submersible:
		submersible_sprite.position.y = -7.0 + sin(swim_time * 0.5) * 1.1

func _create_limb(anchor: Vector2, side: float, arm: bool) -> Node2D:
	var pivot := Node2D.new()
	pivot.position = anchor
	pivot.z_index = -1
	swim_rig.add_child(pivot)
	var line := Line2D.new()
	line.points = (
		PackedVector2Array([Vector2.ZERO, Vector2(side * 5.0, 8.0), Vector2(side * 8.0, 16.0)])
		if arm
		else PackedVector2Array([Vector2.ZERO, Vector2(side * 4.0, 12.0), Vector2(side * 5.0, 23.0)])
	)
	line.width = 6.0 if arm else 7.0
	line.default_color = Color(0.96, 0.59, 0.36) if arm else Color(0.20, 0.57, 0.72)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	pivot.add_child(line)
	var hand_or_foot := Polygon2D.new()
	if arm:
		hand_or_foot.polygon = PackedVector2Array([
			Vector2(side * 5.0, 14.0), Vector2(side * 11.0, 14.0),
			Vector2(side * 11.0, 19.0), Vector2(side * 5.0, 19.0)
		])
		hand_or_foot.color = Color(1.0, 0.75, 0.51)
	else:
		hand_or_foot.polygon = PackedVector2Array([
			Vector2(side * 3.0, 21.0), Vector2(side * 9.0, 21.0),
			Vector2(side * 13.0, 27.0), Vector2(side * 12.0, 30.0),
			Vector2(side * 3.0, 29.0)
		])
		hand_or_foot.color = Color(0.08, 0.30, 0.48)
	pivot.add_child(hand_or_foot)
	return pivot

func _effective_movement_speed(boost_pressed: bool) -> float:
	return movement_speed * (BOOST_MULTIPLIER if has_fins and boost_pressed else 1.0)
