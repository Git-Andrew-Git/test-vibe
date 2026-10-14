extends Node2D
class_name AlienLifeform

var species_id := ""
var lifeform_id := ""
var specimen_name := ""
var resource_id := ""
var yield_amount := 1
var recipe_id := ""
var species_kind := "flora"
var flora_behavior := ""
var aggressive := false
var hunter_target: Node2D
var sprite_texture: Texture2D
var harvested := false
var scanned := false
var icon: Sprite2D
var home_position := Vector2.ZERO
var swim_phase := 0.0
var stun_remaining := 0.0
var behavior_time := 0.0

func _ready() -> void:
	home_position = position
	swim_phase = float(hash(species_id)) * 0.001
	icon = Sprite2D.new()
	icon.texture = sprite_texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.scale = Vector2(0.92, 0.92)
	add_child(icon)

func _process(delta: float) -> void:
	if harvested:
		return
	behavior_time += delta
	stun_remaining = maxf(0.0, stun_remaining - delta)
	if species_kind == "fauna":
		if stun_remaining > 0.0:
			return
		position.x = move_toward(
			position.x,
			home_position.x + sin(Time.get_ticks_msec() * 0.0003 + swim_phase) * 42.0,
			delta * 12.0
		)
		position.y = home_position.y + sin(Time.get_ticks_msec() * 0.0012 + swim_phase) * 10.0
	elif flora_behavior == "stalk":
		if stun_remaining > 0.0:
			return
		if is_instance_valid(hunter_target) and global_position.distance_to(hunter_target.global_position) < 390.0:
			var direction := (hunter_target.global_position - global_position).normalized()
			global_position += direction * minf(30.0 * delta, global_position.distance_to(hunter_target.global_position))
			icon.rotation = direction.x * 0.16
		else:
			position = position.move_toward(
				home_position + Vector2(sin(behavior_time * 0.7 + swim_phase) * 18.0, 0.0),
				delta * 7.0
			)
	else:
		match flora_behavior:
			"sway":
				icon.rotation = sin(behavior_time * 1.2 + swim_phase) * 0.12
				position.y = home_position.y + sin(behavior_time * 1.7 + swim_phase) * 5.0
			"creep":
				position.x = home_position.x + sin(behavior_time * 0.35 + swim_phase) * 24.0
				position.y = home_position.y + sin(behavior_time * 0.7 + swim_phase) * 2.0
			"pulse":
				position.y = home_position.y + sin(behavior_time * 1.1 + swim_phase) * 7.0
				var pulse := 0.92 + sin(behavior_time * 2.2 + swim_phase) * 0.08
				icon.scale = Vector2.ONE * pulse

	if scanned:
		var pulse := 0.86 + sin(Time.get_ticks_msec() * 0.006 + swim_phase) * 0.12
		if stun_remaining > 0.0:
			icon.modulate = Color(0.65, 0.88, 1.0, pulse)
		else:
			icon.modulate = Color(0.66, 1.0, 0.95, pulse)
	else:
		icon.modulate = Color(0.65, 0.88, 1.0) if stun_remaining > 0.0 else Color.WHITE

func collect() -> void:
	harvested = true
	icon.hide()

func stun() -> void:
	stun_remaining = 5.0
	icon.modulate = Color(0.65, 0.88, 1.0)
